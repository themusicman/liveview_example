defmodule LU.Repo.Migrations.AddFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :imported, :boolean
      add :platform_id, :string
    end
  end
end
