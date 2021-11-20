defmodule Memo.Things do
  def unfurl_link(url) do
    case Furlex.unfurl(url) do
      {:ok, %Furlex{oembed: data}} when not is_nil(data) ->
        unfurl_oembed(data)

      {:ok, %Furlex{json_ld: data}} when data !== [] ->
        unfurl_json_ld(data)

      {:ok, %Furlex{twitter: data}} when not is_nil(data) ->
        unfurl_twitter(data)

      _error ->
        {:error, "Could not unfurl"}
    end
  end

  defp unfurl_oembed(data) do
    {:ok,
     %{
       creator_names: [cleanup_author_name(data["author_name"])],
       image: data["thumbnail_url"],
       type: map_types(data["type"]),
       title: data["title"]
     }}
  end

  defp unfurl_twitter(data) do
    {:ok,
     %{
       image: data["twitter:image"],
       type: map_types(data["twitter:creator"] || data["twitter:site"]),
       title: data["twitter:title"]
     }}
  end

  defp map_types("MusicRecording"), do: :listened
  defp map_types("@Criterion"), do: :watched
  defp map_types("@criterionchannl"), do: :watched
  defp map_types("@goodreads"), do: :read
  defp map_types("Product"), do: :read
  defp map_types("Movie"), do: :watched
  defp map_types("rich"), do: :read
  defp map_types("CreativeWork"), do: :saw
  defp map_types(something), do: something

  defp unfurl_json_ld([data = %{"@type" => "Movie"} | _]) do
    {:ok,
     %{
       type: :watched,
       title: data["name"],
       image: data["image"],
       creator_names: [fetch_creators_json_ld(data)]
     }}
  end

  defp unfurl_json_ld([data | _]) do
    {:ok,
     %{
       type: map_types(data["@type"]),
       title: data["name"],
       image: data["image"],
       creator_names: [fetch_creators_json_ld(data)]
     }}
  end

  defp fetch_creators_json_ld(data) do
    cond do
      not is_nil(data["author"]) ->
        fetch_person(data["author"])

      not is_nil(data["director"]) ->
        fetch_person(data["director"])

      data["description"] =~ "on Spotify" ->
        # Spotify link description includes artist name in
        # "listen to <something> on Spotify . <creator name> . <type> . <year>."
        # so get creator name from second .
        data["description"]
        |> String.split("·")
        |> Enum.at(0)
        |> String.split(".")
        |> Enum.at(1)
        |> cleanup_author_name()

      true -> ""
    end
  end

  defp fetch_person(person_data) do
    person_data
    |> Enum.map(fn data ->
      case data do
        %{"@type" => "Person", "name" => name} -> name
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(",")
  end

  defp cleanup_author_name(name) do
    name
    |> String.trim()
    |> String.trim_leading("By ")
  end

  def find_by_isbn(isbn) do
    case google_books(isbn) do
      {:found, book} -> {:ok, book}
      _ -> {:not_found}
    end
  end

  defp google_books(isbn) do
    case Memo.GoogleBook.get_book(isbn) do
      {:ok, book} ->
        {:found,
         %{
           type: :read,
           title: book["volumeInfo"]["title"],
           creator_names: book["volumeInfo"]["authors"],
           tags: book["volumeInfo"]["categories"],
           image:
             book["volumeInfo"]["imageLinks"]["large"] ||
               book["volumeInfo"]["imageLinks"]["thumbnail"],
           description: book["volumeInfo"]["description"]
         }}

      _ ->
        {:not_found}
    end
  end
end
