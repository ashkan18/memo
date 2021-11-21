defmodule MemoWeb.HomeLive do
  use MemoWeb, :live_view
  alias Memo.{Accounts, Things, Interests, Creators, Util}

  @impl true
  def mount(_params, session, socket) do
    socket =
      with %{"user_token" => user_token} <- session,
           user <- Accounts.get_user_by_session_token(user_token) do
        assign(socket, :current_user, user)
      else
        _ -> assign(socket, :current_user, nil)
      end

    {:ok,
     assign(socket,
       has_location: false,
       latitude: nil,
       longitude: nil,
       fetching: false,
       fetched: false,
       submitted: false,
       term: nil
     )}
  end

  @impl true
  def handle_params(%{"username" => username}, _url, socket) do
    send(self(), {"search", %{"term" => username}})
    {:noreply, assign(socket, term: username)}
  end
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  @impl true
  def handle_info({"search", params}, socket), do: search(socket, params)

  def handle_info({"fetchReference", %{"reference" => reference}}, socket) do
    parse_result =
      case URI.parse(reference) do
        %URI{scheme: nil} ->
          # not a uri, try ISBN
          Things.find_by_isbn(reference)

        _ ->
          # uri try unfurl
          Things.unfurl_link(reference)
      end

    case parse_result do
      {:ok, result} ->
        {:noreply,
         assign(socket,
           fetched: true,
           fetching: false,
           parsed_results: result,
           reference: reference
         )}

      _ ->
        {:noreply, assign(socket, :fetched, false)}
    end
  end


  @impl true
  def handle_event("search", params, socket), do: search(socket, params)

  @impl true
  def handle_event(
        "setLocation",
        params = %{"latitude" => latitude, "longitude" => longitude},
        socket
      ) do
    socket = assign(socket, has_location: true, latitude: latitude, longitude: longitude)
    send(self(), {"search", params})
    {:noreply, socket}
  end


  def handle_event("parseInterest", %{"reference" => reference}, socket) do
    if is_nil(reference) or String.trim(reference) == "" do
      {:noreply, assign(socket, fetching: false, parsed_result: nil, reference: nil, fetched: false)}
    else
      send(self(), {"fetchReference", %{"reference" => reference}})
      {:noreply, assign(socket, :fetching, true)}
    end
  end

  @impl true
  def handle_event("submitInterest", params, socket) do
    %{latitude: lat, longitude: lng} = socket.assigns

    creator_ids =
      params
      |> Map.get("creator_names")
      |> String.split(",")
      |> Enum.map(&Creators.add_by_name/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn c -> c.id end)

    params
    |> Map.merge(%{
      "latitude" => lat,
      "longitude" => lng,
      "user_id" => socket.assigns.current_user.id,
      "creator_ids" => creator_ids
    })
    |> Interests.add()

    :timer.send_after(1000, self(), {"search", %{}})
    {:noreply, assign(socket, :submitted, true)}
  end

  def handle_event("closeSubmit", _params, socket) do
    {:noreply, assign(socket, submitted: false, fetched: false, parsed_results: nil, reference: nil)}
  end

  defp search(socket, params) do
    if socket.assigns.has_location do
      interests =
        params
        |> Map.merge(%{
          "latitude" => socket.assigns.latitude,
          "longitude" => socket.assigns.longitude
        })
        |> Memo.Interests.search_and_filter()
        |> Enum.map(&Util.interest_to_map/1)

      {:noreply, push_event(socket, "search_results", %{interests: interests})}
    else
      {:noreply, socket}
    end
  end
end
