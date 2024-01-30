defmodule LU.Teams.Team do
  @moduledoc """
  A schema that represents a group of users in the application
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field(:name, :string)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
