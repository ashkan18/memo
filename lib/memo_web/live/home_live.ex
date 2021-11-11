defmodule MemoWeb.HomeLive do
  use MemoWeb, :live_view
  alias Memo.Interests.UserInterest
  alias Memo.Accounts

  @impl true
  def mount(_params, session, socket) do
    socket = with %{"user_token" => user_token} <- session,
        user <- Accounts.get_user_by_session_token(user_token) do
          assign(socket, :current_user, user)
    else
        _ ->   assign(socket, :current_user, nil)
    end
    {:ok, socket}
  end

  @impl true
  def handle_event("search", params, socket) do
    {socket, params} = merge_socket_and_params(socket, params)
    IO.inspect(params)
    interests = params
      |> Memo.Interests.search_and_filter()
      |> Enum.map(&interest_to_map/1)
    {:noreply, push_event(socket, "search_results", %{interests: interests})}
  end

  defp merge_socket_and_params(socket, params = %{"latitude" => _lat, "longitude" => _lng}) do
    # we had lat/lng in params, update socket
    { assign(socket, Map.take(params, ["latitude", "longitude"])), params}
  end

  defp merge_socket_and_params(socket = %{assigns: %{"latitude" => _lat, "longitude" => _lng}}, params) do
    # we had lat/lng in socket, update params
    { socket , Map.merge(params, Map.take(socket.assigns, ["latitude", "longitude"]))}
  end

  defp merge_socket_and_params(socket, params), do: {socket, params}

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
