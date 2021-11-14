defmodule MemoWeb.HomeLive do
  use MemoWeb, :live_view
  alias Memo.Interests.UserInterest
  alias Memo.{Accounts, Things, Interests, Creators}

  @impl true
  def mount(_params, session, socket) do
    socket = with %{"user_token" => user_token} <- session,
        user <- Accounts.get_user_by_session_token(user_token) do
          assign(socket, :current_user, user)
    else
        _ -> assign(socket, :current_user, nil)
    end
    {:ok, assign(socket, has_location: false, latitude: nil, longitude: nil, fetched: false, submitted: false)}
  end

  @impl true
  def handle_info({"search", params}, socket) do
    IO.inspect(params, label: "doing search info ===>")
    if socket.assigns.has_location do
      interests = params
        |> Map.merge(%{"latitude" => socket.assigns.latitude, "longitude" => socket.assigns.longitude })
        |> Memo.Interests.search_and_filter()
        |> Enum.map(&interest_to_map/1)
      {:noreply, push_event(socket, "search_results", %{interests: interests})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("setLocation", params = %{"latitude" => latitude, "longitude" => longitude}, socket) do
    socket = assign(socket, has_location: true, latitude: latitude, longitude: longitude)
    send(self(), {"search", params})
    :timer.send_after(1000, self(), {"search", %{}})
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", params, socket) do
    if socket.assigns.has_location do
      interests = params
        |> Map.merge(%{"latitude" => socket.assigns.latitude, "longitude" => socket.assigns.longitude })
        |> Memo.Interests.search_and_filter()
        |> Enum.map(&interest_to_map/1)
      {:noreply, push_event(socket, "search_results", %{interests: interests})}
    else
      {:noreply, socket}
    end
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
        {:noreply, assign(socket,
          fetched: true,
          parsed_results: result,
          reference: reference)}
      _ ->
        {:noreply, assign(socket, :fetched, false)}
    end
  end

  @impl true
  def handle_event("submitInterest", params, socket) do
    %{latitude: lat, longitude: lng} = socket.assigns


    creator_ids = params
      |> Map.get("creator_names")
      |> String.split(",")
      |> Enum.map(&Creators.add_by_name/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn c -> c.id end)

    params
      |> Map.merge(
        %{"latitude" => lat,
        "longitude" => lng,
        "user_id" => socket.assigns.current_user.id,
        "craetor_ids" => creator_ids})
      |> IO.inspect(label: :submit_params)
      |> Interests.add()
      |> IO.inspect()
    {:noreply, assign(socket, :submitted, true)}
  end

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
