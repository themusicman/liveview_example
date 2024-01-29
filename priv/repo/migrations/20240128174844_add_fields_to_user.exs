defmodule LU.Repo.Migrations.AddFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :import_status, :string
      add :platform_id, :string
    end
  end
end
