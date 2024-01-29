defmodule LUWeb.UserLive.Index do
  use LUWeb, :live_view

  alias LU.Users
  alias LU.Users.User
  import Flamel.Wrap, only: [noreply: 1, ok: 1]

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:teams, LU.Teams.list_teams())
    |> stream(:users, Users.list_users())
    |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Users.get_user!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_info({LUWeb.UserLive.FormComponent, {:saved, user}}, socket) do
    socket
    |> stream_insert(:users, user)
    |> noreply()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Users.get_user!(id)
    {:ok, _} = Users.delete_user(user)

    socket
    |> stream_delete(:users, user)
    |> noreply()
  end

  @impl true
  def handle_event("delete-all", _params, socket) do
    LU.Users.list_users() |> Enum.each(fn u -> LU.Users.delete_user(u) end)

    socket
    |> stream(:users, [], reset: true)
    |> put_flash(:info, "Purged users!")
    |> noreply()
  end
end
