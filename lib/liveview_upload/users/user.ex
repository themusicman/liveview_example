defmodule LU.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :imported, :boolean, default: false
    field :platform_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :imported, :platform_id])
    |> validate_required([:name])
  end
end
