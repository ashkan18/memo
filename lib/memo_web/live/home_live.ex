defmodule MemoWeb.HomeLive do
  use MemoWeb, :live_view
  alias Memo.Interests.UserInterest
  alias Memo.{Accounts, Things}

  @impl true
  def mount(_params, session, socket) do
    socket = with %{"user_token" => user_token} <- session,
        user <- Accounts.get_user_by_session_token(user_token) do
          assign(socket, :current_user, user)
    else
        _ -> assign(socket, :current_user, nil)
    end
    {:ok, assign(socket, parsed_image: nil, parsed_title: nil)}
  end

  @impl true
  def handle_event("search", params, socket) do
    {socket, params} = merge_socket_and_params(socket, params)
    interests = params
      |> Memo.Interests.search_and_filter()
      |> Enum.map(&interest_to_map/1)
    {:noreply, push_event(socket, "search_results", %{interests: interests})}
  end

  @impl true
  def handle_event("parseInterest", %{"reference" => reference}, socket) do
    parse_result = case URI.parse(reference) do
      %URI{scheme: nil} ->
        # not a uri, try ISBN
        Things.find_by_isbn(reference)
      _ ->
        # uri try unfurl
        Things.unfurl_link(reference)
    end
    case parse_result do
      {:ok, result} ->
        {:noreply, assign(socket, parsed_image: result.image, parsed_title: result.title)}
      _ -> {:noreply, assign(socket, :parsed_image, nil)}
    end
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
      creators: Enum.map(interest.creators, fn c -> c.name end) |> Enum.join(","),
      user: %{
        id: interest.user.id,
        username: interest.user.username,
      },
      location: %{
        latitude: lat,
        longitude: lng
      }
    }
  end

end
