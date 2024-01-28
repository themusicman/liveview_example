defmodule LU.UsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LU.Users` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> LU.Users.create_user()

    user
  end
end
