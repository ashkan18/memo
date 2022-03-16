defmodule MemoWeb.HomeLive do
  use MemoWeb, :live_view
  alias Memo.{Accounts, Interests, Util}

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
       term: nil,
       selected_user: nil,
       selected_user_stats: nil,
       follows_selected_user: false
     )}
  end

  @impl true
  def handle_params(%{"username" => username}, _url, socket) do
    send(self(), {"selectUser", %{"username" => username}})
    send(self(), {"search", %{"term" => username}})
    {:noreply, assign(socket, term: username)}
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  @impl true
  def handle_info({"search", params}, socket), do: search(socket, params)

  def handle_info({"selectUser", %{"username" => username}}, socket) do
    user = Accounts.get_user_by_username(username)

    {:noreply,
     assign(socket,
       selected_user: user,
       selected_user_stats: Interests.user_stats(user),
       follows_selected_user: Interests.follows?(socket.assigns.current_user, user)
     )}
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

  def handle_event("follow", %{"value" => follow_id}, socket) do
    Interests.follow(%{user_id: socket.assigns.current_user.id, follow_id: follow_id})
    {:noreply, assign(socket, follows_selected_user: true)}
  end

  def handle_event("unfollow", %{"value" => follow_id}, socket) do
    {:ok, _unfollowed} = Interests.unfollow(socket.assigns.current_user.id, follow_id)
    {:noreply, assign(socket, follows_selected_user: false)}
  end

  def handle_event("deselectUser", _params, socket) do
    {:noreply, assign(socket, selected_user: nil, term: nil)}
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
