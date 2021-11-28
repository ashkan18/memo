defmodule Memo.Repo.Migrations.CreateFollows do
  use Ecto.Migration

  def change do
    create table(:follows) do
      add :user_id, references(:users, on_delete: :nothing)
      add :follow_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:follows, [:user_id])
    create index(:follows, [:follow_id])

    create unique_index(:follows, [:user_id, :follow_id])
  end
end
