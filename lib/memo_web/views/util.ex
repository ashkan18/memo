defmodule MemoWeb.Views.Util do
  alias Memo.Interests.UserInterest

  def interest_thumbnail(%UserInterest{thumbnail: thumbnail, type: type}) when is_nil(thumbnail) do
    case type do
      :listened -> "/images/audio.png"
    end
  end

  def interest_thumbnail(%UserInterest{thumbnail: thumbnail}) do
    thumbnail
  end
end
