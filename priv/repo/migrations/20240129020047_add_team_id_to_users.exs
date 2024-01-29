defmodule LU.Repo.Migrations.AddTeamIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:team_id, references(:teams, on_delete: :delete_all))
    end
  end
end
