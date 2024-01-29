defmodule LU.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string

    field(:import_status, Ecto.Enum, values: [:started, :awaiting_platform_id, :finished])

    field :platform_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :import_status, :platform_id])
    |> validate_required([:name])
  end
end
