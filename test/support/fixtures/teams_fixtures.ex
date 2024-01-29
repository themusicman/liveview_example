defmodule LU.TeamsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LU.Teams` context.
  """

  @doc """
  Generate a team.
  """
  def team_fixture(attrs \\ %{}) do
    {:ok, team} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> LU.Teams.create_team()

    team
  end
end
