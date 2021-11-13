defmodule Memo.Creators.CreatorUserInterest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "creator_user_interests" do
    belongs_to(:user_interest, Memo.Interests.UserInterest)
    belongs_to(:creator, Memo.Creators.Creator)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(creator, attrs) do
    creator
    |> cast(attrs, [:user_interest_id, :creator_id])
    |> validate_required([:user_interest_id, :creator_id])
    |> foreign_key_constraint(:user_interest_id)
    |> foreign_key_constraint(:creator_id)
    |> assoc_constraint(:user_interest)
    |> assoc_constraint(:creator)
  end
end
