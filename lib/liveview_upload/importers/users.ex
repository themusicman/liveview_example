defmodule LU.Importers.Users do
  alias LU.Users
  alias Phoenix.PubSub
  alias NimbleCSV.RFC4180, as: NimbleCSV
  alias LU.Importers.Error
  import Flamel.Wrap
  alias Flamel.Context

  def import(import_id, dest) do
    dest
    |> File.stream!(read_ahead: 100_000)
    |> NimbleCSV.parse_stream()
    |> Stream.map(fn [name] ->
      import_row(import_id, %{name: :binary.copy(name)})
    end)
    |> Stream.run()

    PubSub.broadcast(
      LU.PubSub,
      "import:users",
      {:user_import_finished, import_id}
    )

    :ok
  end

  def import_row(import_id, row) do
    row_id = Flamel.Random.string()

    Context.assign(%Context{}, %{import_id: import_id, row: row, row_id: row_id})
    |> start_import()
    |> start_platform_import()
    |> finish_platform_import()
  end

  defp start_import(%{assigns: %{row: row, import_id: import_id, row_id: row_id}} = context) do
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

        Context.assign(context, :user, user)

      _ ->
        PubSub.broadcast(
          LU.PubSub,
          "import:users",
          {:user_import_error, import_id,
           %Error{id: row_id, reason: "Error importing row=#{inspect(row)}"}}
        )

        Context.halt!(context, "import error")
    end
  end

  defp start_platform_import(%{halt?: true} = context) do
    context
  end

  defp start_platform_import(
         %{halt?: false, assigns: %{row_id: row_id, user: user, import_id: import_id}} = context
       ) do
    :timer.sleep(random_sleep(100, 1000))

    case Users.update_user(user, %{import_status: :awaiting_platform_id}) do
      {:ok, user} ->
        PubSub.broadcast(
          LU.PubSub,
          "import:users",
          {:user_import_update, import_id, user}
        )

        Context.assign(context, :user, user)

      _ ->
        PubSub.broadcast(
          LU.PubSub,
          "import:users",
          {:user_import_error, import_id, %Error{id: row_id, reason: "Error importing"}}
        )

        Context.halt!(context, "import error")
    end
  end

  defp finish_platform_import(%{halt?: true} = context) do
    context
  end

  defp finish_platform_import(
         %{halt?: false, assigns: %{row_id: row_id, user: user, import_id: import_id}} = context
       ) do
    Flamel.Task.background(fn ->
      case Users.update_user(user, %{platform_id: Flamel.Random.string()}) do
        {:ok, user} ->
          :timer.sleep(random_sleep(1000, 5000))
          Context.assign(context, :user, user)

          case Users.update_user(user, %{import_status: :finished}) do
            {:ok, user} ->
              PubSub.broadcast(LU.PubSub, "import:users", {:user_import_update, import_id, user})

              Context.assign(context, :user, user)

            _ ->
              PubSub.broadcast(
                LU.PubSub,
                "import:users",
                {:user_import_error, import_id,
                 %Error{id: row_id, reason: "Error saving platform_id"}}
              )

              Context.halt!(context, "import error")
          end

        _ ->
          PubSub.broadcast(
            LU.PubSub,
            "import:users",
            {:user_import_error, import_id,
             %Error{id: row_id, reason: "Error saving platform_id"}}
          )

          Context.halt!(context, "import error")
      end
    end)
  end

  defp random_sleep(start_range, end_range) do
    Enum.random(start_range..end_range)
  end
end
