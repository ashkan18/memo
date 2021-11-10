defmodule Memo.Repo.Migrations.AddInterestModels do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS postgis"

    create table(:creators) do
      add :name, :string
      add :bio, :text

      timestamps()
    end

    create table(:user_interests) do
      add :title, :string
      add :type, :string
      add :ref, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :thumbnail, :string
      add :external_id, :string
      add :location, :geometry
      add :metadata, :jsonb

      timestamps()
    end

    create table(:creator_user_interests) do
      add :user_interest_id, references(:user_interests, on_delete: :nothing)
      add :creator_id, references(:creators, on_delete: :nothing)


      timestamps()
    end

    create index(:creator_user_interests, [:user_interest_id])
    create index(:creator_user_interests, [:creator_id])

    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"
    execute "CREATE INDEX interest_title_idx ON user_interests USING gist (title gist_trgm_ops)"
  end
end
