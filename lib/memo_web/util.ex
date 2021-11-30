defmodule Memo.Util do
  alias Memo.Interests.UserInterest
  alias MemoWeb.Views.Util

  def interest_to_map(interest = %UserInterest{}) do
    {lat, lng} = interest.location.coordinates

    %{
      id: interest.id,
      title: interest.title,
      type: interest.type,
      thumbnail: Util.interest_thumbnail(interest),
      creators: Enum.map(interest.creators, fn c -> c.name end) |> Enum.join(","),
      user: %{
        id: interest.user.id,
        username: interest.user.username
      },
      location: %{
        latitude: lat,
        longitude: lng
      }
    }
  end
end
