defmodule Memo.Creators.Creator do
  use Ecto.Schema
  import Ecto.Changeset

  schema "creators" do
    field(:name, :string)
    field(:bio, :string)

    many_to_many(:user_interests, Memo.Interests.UserInterest, join_through: Memo.Creators.CreatorUserInterest)

    timestamps()
  end

  @doc false
  def changeset(creator, attrs) do
    creator
    |> cast(attrs, [:name, :bio])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
