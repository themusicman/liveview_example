defmodule LUWeb.UserLive.Show do
  use LUWeb, :live_view

  alias LU.Users
  import Flamel.Wrap, only: [noreply: 1, ok: 1]

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:teams, LU.Teams.list_teams())
    |> ok()
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    socket
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> assign(:user, Users.get_user!(id))
    |> noreply()
  end

  defp page_title(:show), do: "Show User"
  defp page_title(:edit), do: "Edit User"
end
