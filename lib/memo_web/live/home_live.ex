defmodule MemoWeb.HomeLive do
  use MemoWeb, :live_view
  alias Memo.Interests.UserInterest

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :things, "test")
    {:ok, socket}
  end

  @impl true
  def handle_event("search", params, socket) do
    IO.inspect(params)
    interests = Memo.Interests.search_and_filter(params)
      |> Enum.map(&interest_to_map/1)

    {:noreply, push_event(socket, "search_results", %{interests: interests})}

  end

  defp interest_to_map(interest = %UserInterest{}) do
    {lat, lng} = interest.location.coordinates
    %{
      id:  interest.id,
      title: interest.title,
      type: interest.type,
      thumbnail: interest.thumbnail,
      location: %{
        latitude: lat,
        longitude: lng
      }
    }
  end

end
