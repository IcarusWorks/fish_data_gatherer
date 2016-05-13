defmodule Waterbody do
  @moduledoc """
  Fetch table data from the Vermont Fish and Wildlife site waterbody
  """

  @doc """
  Gets the HTML document

  Returns a list of maps with nested maps.
  """

  def fetch(id) do
    HTTPoison.start

    "https://anrweb.vt.gov/FWD/FW/FishingRegs.aspx?ID=" <> to_string(id)
    |> get_page
    |> case do
      {:ok, body} -> parse(body)
      {:error, message} -> IO.puts message
    end
  end

  # Find header and continue down the parsing chain if found
  def parse(body) do
    body
    |> Floki.find("#ctl00_ContentPlaceHolder1_gvDetails caption")
    |> case do
      [] -> IO.puts "No header"
      captured ->
        captured
        |> Floki.text
        |> parse(body)
    end
  end

  # private

  defp get_page(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "Not found"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp parse(name, body) do
    Floki.find(body, "#ctl00_ContentPlaceHolder1_gvDetails th")
    |> case do
      [] -> IO.puts "No detail headers"
      captured ->
        captured
        |> Enum.map(&Floki.text/1)
        |> parse(name, body)
    end
  end

  defp parse(headers, name, body) do
    parse_table(body, "#ctl00_ContentPlaceHolder1_gvDetails")
    |> create_map(headers, name)
    |> parse_special(body)
  end

  defp parse_special(map, body) do
    parse_table(body, "#ctl00_ContentPlaceHolder1_gvSpecialRegulations")
    |> parse_special(map, body)
  end

  defp parse_special(values, map, body) do
    value =
      values
      |> Enum.filter(fn(x) -> !Enum.empty?(x) end)
      |> List.flatten

    map = Map.put(map, :special_regulations, value)

    parse_general(map, body)
    |> Enum.concat(parse_ice_fishing(map, body))
  end

  defp parse_general(map, body) do
    parse_headers(body, "#ctl00_ContentPlaceHolder1_gvGeneralRegulations")
    |> parse_general(map, body)
  end

  defp parse_general(headers, map, body) do
    parse_table(body, "#ctl00_ContentPlaceHolder1_gvGeneralRegulations")
    |> create_map(headers, map)
  end

  defp parse_ice_fishing(map, body) do
    parse_headers(body, "#ctl00_ContentPlaceHolder1_gvIceRegs")
    |> parse_ice_fishing(map, body)
  end

  defp parse_ice_fishing(headers, map, body) do
    parse_table(body, "#ctl00_ContentPlaceHolder1_gvIceRegs")
    |> create_map(headers, map)
  end

  defp find_or_create_fish(value) do
    %{name: value}
  end

  defp parse_headers(body, id) do
    headers_content = Floki.find(body, "#{id} th")
    for h <- headers_content, do: Floki.text(h)
  end

  defp parse_table(body, id) do
    Floki.find(body, "#{id} tr")
    |> Enum.map(&(Floki.find(&1, "td")))
    |> Enum.map(fn(x) ->
      Enum.map(x, &Floki.text/1)
    end)
  end

  defp create_map(values, headers, name) when is_binary(name) do
    values
    |> Enum.filter(fn(x) -> !Enum.empty?(x) end)
    |> Enum.map(fn(row) ->
      for {v, vi} <- Enum.with_index(row), {h, hi} <- Enum.with_index(headers), vi == hi, into: %{name: name} do
        key = h
          |> underscore
          |> String.to_atom
        value = String.strip(v)

        if key == :species do
          key = :fish
          value = find_or_create_fish(value)
        end

        {key, value}
      end
    end)
    |> List.first
  end

  defp create_map(values, headers, map) do
    values
    |> Enum.filter(fn(x) -> !Enum.empty?(x) end)
    |> Enum.map(fn(row) ->
      for {v, vi} <- Enum.with_index(row), {h, hi} <- Enum.with_index(headers), vi == hi, into: %{waterbody: map} do
        key = h
          |> underscore
          |> String.to_atom
        value = String.strip(v)

        if key == :species do
          key = :fish
          value = find_or_create_fish(value)
        end

        {key, value}
      end
    end)
  end

  defp underscore(string) do
    string
    |> String.downcase
    |> String.split(" ")
    |> Enum.join("_")
  end
end
