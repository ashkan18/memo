defmodule Memo.Repo.Migrations.AddUnfollowedAt do
  use Ecto.Migration

  def change do
    alter table(:follows) do
      add :unfollowed_at, :utc_datetime
    end

    drop index(:follows, [:user_id, :follow_id])
    create unique_index(:follows, [:user_id, :follow_id], where: "unfollowed_at is null")
  end
end
