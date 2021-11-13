defmodule Memo.Interests do
  @moduledoc """
  The Interests context.
  """

  import Ecto.Query, warn: false
  alias Memo.Repo

  alias Memo.Interests.UserInterest
  alias Memo.Creators


  def user_feed(user) do
    from(ui in UserInterest,
      join: f in Follow,
      on: f.user_id == ui.user_id,
      where: f.follower_id == ^user.id
    )
    |> Repo.all()
  end


  def search_and_filter(args) do
    UserInterest
    |> by_term(args)
    |> by_types(args)
    |> near(args)
    |> filter_users(args)
    |> Repo.all()
    |> Repo.preload([:creators, :user])
  end

  def near(query, %{"latitude" => lat, "longitude" => lng}) do
    point = %Geo.Point{coordinates: {lng, lat}, srid: 4326}
    {lng, lat} = point.coordinates

    from(book_instance in query,
      order_by: fragment("? <-> ST_SetSRID(ST_MakePoint(?,?), ?)", book_instance.location, ^lng, ^lat, ^point.srid)
    )
  end

  def near(query, _), do: query

  def by_term(query, %{"term" => term}) when not is_nil(term) do
    from(ui in query,
      join: user in assoc(ui, :user),
      join: creator in assoc(ui, :creators),
      where: fragment("LOWER(?) % LOWER(?) OR LOWER(?) % LOWER(?) OR LOWER(?) % LOWER(?)", ui.title, ^term, user.username, ^term, creator.name, ^term),
      order_by: fragment("similarity(LOWER(?), LOWER(?)) DESC", ui.title, ^term)
    )
  end

  def by_term(query, _), do: query

  def by_types(query, %{"types" => types}) do
    from(ui in query,
      where: ui.types in ^types
    )
  end

  def by_types(query, _), do: query

  def filter_users(query, %{filter_user_ids: filter_user_ids}) do
    from(ui in query,
      where: ui.user_id not in ^filter_user_ids
    )
  end

  def filter_users(query, _), do: query


  @doc """
  Creates a user_interest.

  ## Examples

      iex> add(%{field: value})
      {:ok, %UserInterest{}}

      iex> add(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def add(attrs \\ %{}) do
    with {creator_ids, attrs} <- Map.pop(attrs, :creator_ids),
         changeset <- UserInterest.changeset(%UserInterest{}, attrs),
         {:ok, user_interest} <- Repo.insert(changeset),
         Enum.map(creator_ids, fn creator_id -> Creators.create_user_interest_creator(%{user_interest_id: user_interest.id, creator_id: creator_id}) end) do
      {:ok, user_interest}
    else
      {:error, error = %Ecto.Changeset{}} -> {:error, error}
      error -> error
    end
  end
end
