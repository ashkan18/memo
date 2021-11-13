defmodule Memo.Repo.Migrations.RemoveUnusedRelationTable do
  use Ecto.Migration

  def change do
    drop table("user_interest_creators")
  end
end
