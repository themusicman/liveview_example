defmodule LU.Importers.Users do
  @moduledoc """
  Handles the logic for importing users
  """
  require Logger
  import Flamel.Wrap
  alias LU.Importers.Error
  alias LU.Users
  alias NimbleCSV.RFC4180, as: NimbleCSV
  alias Phoenix.PubSub

  def factory(id, args \\ %{}) do
    name = name(id)

    Logger.debug(
      "#{__MODULE__}.factory(#{inspect(id)}, #{inspect(args)}) with module=#{inspect(__MODULE__)} and name=#{inspect(name)}"
    )

    initial_state = Map.merge(args, %{id: id})

    result =
      DynamicSupervisor.start_child(
        LU.DynamicSupervisor,
        {__MODULE__, [name: name, initial_state: initial_state]}
      )

    Logger.debug(
      "#{__MODULE__}.factory(#{inspect(id)}, #{inspect(args)}) with result=#{inspect(result)}"
    )

    result
  end

  def handle_info(:do_import, %{id: import_id, rows: rows} = state) do
    results =
      Task.Supervisor.async_stream_nolink(
        LU.TaskSupervisor,
        rows,
        fn row ->
          create_user(row, import_id)
          |> start_platform_import(import_id)
          |> finish_platform_import(import_id)
        end,
        timeout: 10 * 60_000
      )
      |> Enum.to_list()

    PubSub.broadcast(
      LU.PubSub,
      "import:users",
      {:user_import_finished, import_id}
    )

    stop(:shutdown, %{state | results: results})
  end

  def handle_info(
        {:DOWN, _ref, :process, _pid, reason},
        %{id: import_id} = state
      ) do
    PubSub.broadcast(
      LU.PubSub,
      "import:users",
      {:user_import_failed, import_id}
    )

    IO.inspect(reason: reason)

    raise "here"

    stop(:shutdown, state)
  end

  def get_rows(dest) do
    dest
    |> File.stream!(read_ahead: 100_000)
    |> NimbleCSV.parse_stream()
    |> Stream.map(fn [name] ->
      %{name: :binary.copy(name)}
    end)
    |> Enum.to_list()
  end

  def create_user(row, import_id) do
    row_id = Flamel.Random.string()

    row
    |> Map.put(:import_status, "started")
    |> Users.create_user()
    |> case do
      {:ok, user} ->
        PubSub.broadcast(
          LU.PubSub,
          "import:users",
          {:user_import_update, import_id, user}
        )

        user

      _ ->
        PubSub.broadcast(
          LU.PubSub,
          "import:users",
          {:user_import_error, import_id,
           %Error{id: row_id, reason: "Error importing row=#{inspect(row)}"}}
        )

        nil
    end
  end

  defp start_platform_import(nil, _import_id), do: nil

  defp start_platform_import(user, import_id) do
    row_id = Flamel.Random.string()

    case Users.update_user(user, %{import_status: :awaiting_platform_id}) do
      {:ok, user} ->
        PubSub.broadcast(
          LU.PubSub,
          "import:users",
          {:user_import_update, import_id, user}
        )

        user

      _ ->
        PubSub.broadcast(
          LU.PubSub,
          "import:users",
          {:user_import_error, import_id, %Error{id: row_id, reason: "Error importing"}}
        )

        nil
    end
  end

  defp finish_platform_import(nil, _import_id), do: nil

  defp finish_platform_import(user, import_id) do
    row_id = Flamel.Random.string()

    case Users.update_user(user, %{platform_id: Flamel.Random.string()}) do
      {:ok, user} ->
        :timer.sleep(random_sleep(1000, 5000))

        case Users.update_user(user, %{import_status: :finished}) do
          {:ok, user} ->
            PubSub.broadcast(LU.PubSub, "import:users", {:user_import_update, import_id, user})
            user

          _ ->
            PubSub.broadcast(
              LU.PubSub,
              "import:users",
              {:user_import_error, import_id,
               %Error{id: row_id, reason: "Error saving platform_id"}}
            )

            nil
        end

      _ ->
        PubSub.broadcast(
          LU.PubSub,
          "import:users",
          {:user_import_error, import_id, %Error{id: row_id, reason: "Error saving platform_id"}}
        )

        nil
    end
  end

  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    initial_state = Keyword.get(opts, :initial_state, %{})

    %{
      id: "#{__MODULE__}_#{name}",
      start: {__MODULE__, :start_link, [name, initial_state]},
      restart: :transient,
      shutdown: 5_000
    }
  end

  def init(args) do
    ok(args, {:continue, :import})
  end

  def handle_continue(:import, %{destination: destination} = state) do
    rows = get_rows(destination)

    state =
      state
      |> Map.put(:rows, rows)
      |> Map.put(:results, [])

    Process.send_after(self(), :do_import, 1000)
    noreply(state)
  end

  def start_link(name, initial_state) do
    case GenServer.start_link(__MODULE__, initial_state, name: via_tuple(name)) do
      {:ok, pid} ->
        Logger.info(
          "#{__MODULE__}.start_link here: starting #{inspect(via_tuple(name))} on node=#{inspect(Node.self())}"
        )

        ok(pid)

      {:error, {:already_started, pid}} ->
        Logger.info(
          "#{__MODULE__}.start_link: already started at #{inspect(pid)}, returning :ignore on node=#{inspect(Node.self())}"
        )

        :ignore

      :ignore ->
        Logger.info("#{__MODULE__}.start_link :ignore on node=#{inspect(Node.self())}")
        :ignore
    end
  end

  def via(id) do
    id
    |> name()
    |> via_tuple()
  end

  def name(id) do
    "importers:users:#{id}"
  end

  def via_tuple(id) do
    Logger.debug("#{__MODULE__}.via_tuple(#{inspect(id)})")
    {:via, Registry, {LU.Registry, id}}
  end

  defp random_sleep(start_range, end_range) do
    Enum.random(start_range..end_range)
  end
end
