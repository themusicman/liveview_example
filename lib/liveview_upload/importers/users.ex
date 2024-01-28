defmodule LU.Importers.Users do
  alias LU.Users
  alias Phoenix.PubSub
  alias NimbleCSV.RFC4180, as: NimbleCSV
  alias LU.Importers.Error

  def import(import_id, dest) do
    result =
      dest
      |> File.stream!(read_ahead: 100_000)
      |> NimbleCSV.parse_stream()
      |> Stream.map(fn [name] ->
        import_row(import_id, %{name: :binary.copy(name)})
      end)
      |> Stream.run()

    IO.inspect(result: result)

    :ok

    # File.stream!(dest, [read_ahead: 100_000], 1000)
    # |> CSV.decode(headers: true)
    # |> Enum.each(&import_row/1)
  end

  def import_row(import_id, row) do
    row_id = LU.random_string()

    row
    |> Map.put(:imported, true)
    |> Users.create_user()
    |> case do
      {:ok, user} ->
        PubSub.broadcast(LU.PubSub, "import:users", {:user_imported, import_id, user})
        :timer.sleep(random_sleep(100, 250))

        Flamel.Task.background(fn ->
          case Users.update_user(user, %{platform_id: LU.random_string()}) do
            {:ok, user} ->
              :timer.sleep(random_sleep(1000, 10000))

              PubSub.broadcast(
                LU.PubSub,
                "import:users",
                {:user_platform_imported, import_id, user}
              )

            _ ->
              PubSub.broadcast(
                LU.PubSub,
                "import:users",
                {:user_import_error, import_id,
                 %Error{id: row_id, reason: "Error saving platform_id"}}
              )
          end
        end)

      _ ->
        PubSub.broadcast(
          LU.PubSub,
          "import:users",
          {:user_import_error, import_id,
           %Error{id: row_id, reason: "Error importing row=#{inspect(row)}"}}
        )
    end
  end

  defp random_sleep(start_range, end_range) do
    Enum.random(start_range..end_range)
  end
end
