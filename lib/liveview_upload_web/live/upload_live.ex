defmodule LUWeb.UploadLive do
  use LUWeb, :live_view
  alias Phoenix.PubSub

  @topic "import:users"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(LU.PubSub, @topic)

    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> assign(:import_id, nil)
     |> stream(:users, [])
     |> stream(:errors, [])
     |> allow_upload(:import, accept: ~w(.csv), max_entries: 1)}
  end

  @impl true
  def handle_info({:user_imported, import_id, user}, socket) do
    if socket.assigns.import_id == import_id do
      socket
      |> stream_insert(:users, user)
      |> Flamel.Wrap.noreply()
    else
      Flamel.Wrap.noreply(socket)
    end
  end

  def handle_info({:user_platform_imported, import_id, user}, socket) do
    if socket.assigns.import_id == import_id do
      socket
      |> stream_insert(:users, user)
      |> Flamel.Wrap.noreply()
    else
      Flamel.Wrap.noreply(socket)
    end
  end

  def handle_info({:user_import_error, import_id, error}, socket) do
    if socket.assigns.import_id == import_id do
      socket
      |> stream_insert(:errors, error)
      |> Flamel.Wrap.noreply()
    else
      Flamel.Wrap.noreply(socket)
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :import, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", _params, socket) do
    import_id = LU.random_string()

    uploaded_files =
      consume_uploaded_entries(socket, :import, fn %{path: path}, _entry ->
        IO.inspect(path: path)

        dest =
          Path.join([:code.priv_dir(:liveview_upload), "static", "uploads", Path.basename(path)])

        File.cp!(path, dest)

        Flamel.Task.background(fn ->
          IO.inspect("here--------------------------------")
          :timer.sleep(500)
          LU.Importers.Users.import(import_id, dest)
        end)

        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    socket
    |> update(:uploaded_files, &(&1 ++ uploaded_files))
    |> assign(:import_id, import_id)
    |> Flamel.Wrap.noreply()
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
