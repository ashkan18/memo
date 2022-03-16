defmodule MemoWeb.ParseComponent do
  alias Memo.{Things, Creators, Interests}
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_component
  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       fetching: false,
       fetched: false,
       submitted: false,
       parsed_results: nil,
       reference: nil,
       creators: []
     )}
  end

  @impl true
  def handle_event("parseInterest", %{"reference" => reference}, socket) do
    if is_nil(reference) or String.trim(reference) == "" do
      {:noreply, assign(socket, fetching: false, parsed_result: nil, reference: nil, fetched: false)}
    else
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
  end

  def handle_event("findCreator", %{"value" => name}, socket) do
    {:noreply, assign(socket, creators: Creators.search(name))}
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

    {:noreply,
     assign(socket, submitted: true, fetched: false, fetching: false, parsed_results: nil, reference: nil, creators: [])}
  end
end
