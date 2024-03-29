defmodule LU.Users.User do
  @moduledoc """
  A schema that represents a user in the application
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:name, :string)

    field(:import_status, Ecto.Enum, values: [:started, :awaiting_platform_id, :finished])

    field(:platform_id, :string)

    belongs_to(:team, LU.Teams.Team)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :import_status, :platform_id, :team_id])
    |> validate_required([:name])
  end
end
