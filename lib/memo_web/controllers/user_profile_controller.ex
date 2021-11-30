defmodule MemoWeb.UserProfileController do
  use MemoWeb, :controller

  alias Memo.Interests

  def index(conn, _params) do
    user = conn.assigns.current_user

    conn
    |> assign(:my_interests, Interests.user_interests(user))
    |> assign(:follow_stats, Interests.follow_stats(user))
    |> render("index.html")
  end
end
