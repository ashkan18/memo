defmodule Memo.Interests.Follow do
  use Ecto.Schema
  import Ecto.Changeset

  schema "follows" do
    field :user_id, :id
    field :follow_id, :id
    field :unfollowed_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:user_id, :follow_id, :unfollowed_at])
    |> validate_required([:user_id, :follow_id])
  end
end
