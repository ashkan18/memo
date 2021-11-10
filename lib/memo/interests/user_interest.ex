defmodule Memo.Interests.UserInterest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_interests" do
    field(:ref, :string)
    field(:title, :string)
    field(:type, Ecto.Enum, values: [:read, :watched, :saw, :listened])
    field(:thumbnail, :string)
    field(:location, Geo.PostGIS.Geometry)
    field(:external_id, :string)
    field(:metadata, {:array, :map})

    belongs_to(:user, Memo.Accounts.User)
    many_to_many(:creators, Memo.Creators.Creator, join_through: Memo.Interests.UserInterestCreator)

    timestamps()
  end

  @doc false
  def changeset(user_interest, attrs) do
    user_interest
    |> cast(attrs, [:title, :type, :ref, :user_id, :thumbnail, :location, :external_id, :metadata])
    |> validate_required([:title, :type, :ref, :user_id])
    |> assoc_constraint(:user)
  end
end
