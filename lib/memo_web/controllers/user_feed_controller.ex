defmodule MemoWeb.UserFeedController do
  use MemoWeb, :controller

  alias Memo.Interests

  def my_interests(conn, _params) do
    user = conn.assigns.current_user
    conn
    |> assign(:my_interests, Interests.user_interests(user))
    |> render("my_interests.html")
  end
end
