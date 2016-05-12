defmodule Waterbody do
  @moduledoc """
  Fetch table data from the Vermont Fish and Wildlife site waterbody
  """

  @doc """
  Gets the HTML document

  Returns a list of maps with nested maps.

  ## Examples

  iex> MyApp.Hello.world(:john)
  :ok

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

  # Find header and continue down the parsing chain if found
  defp parse(body) do
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
    Floki.find(body, "#ctl00_ContentPlaceHolder1_gvDetails tr")
    |> Enum.map(&(Floki.find(&1, "td")))
    |> Enum.map(fn(x) ->
      Enum.map(x, &Floki.text/1)
    end)
    |> parse(headers, name, body)
  end

  defp parse(values, headers, name, body) do
    values
    |> Enum.filter(fn(x) -> !Enum.empty?(x) end)
    |> Enum.map(fn(row) ->
      row
      |> Enum.with_index
      |> Enum.reduce(%{}, fn({value, index}, map) ->
        label = Enum.at(headers, index)
          |> underscore
          |> String.to_atom
        value = String.strip(value)
        Map.put(map, label, value)
      end)
      |> Map.put(:name, name)
      |> parse_special(body)
    end)
    |> List.flatten
  end

  defp parse_special(map, body) do
    Floki.find(body, "#ctl00_ContentPlaceHolder1_gvSpecialRegulations tr")
    |> Enum.map(&(Floki.find(&1, "td")))
    |> Enum.map(fn(x) ->
      Enum.map(x, &Floki.text/1)
    end)
    |> parse_special(map, body)
  end

  defp parse_special(values, map, body) do
    value =
      values
      |> Enum.filter(fn(x) -> !Enum.empty?(x) end)
      |> List.flatten

    map = Map.put(map, :special_regulations, value)

    parse_general(map, body)
    |> Enum.into(parse_ice_fishing(map, body))
  end

  defp parse_general(map, body) do
    Floki.find(body, "#ctl00_ContentPlaceHolder1_gvGeneralRegulations th")
    |> case do
      [] -> map
      captured ->
        captured
        |> Enum.map(&Floki.text/1)
        |> parse_general(map, body)
    end
  end

  defp parse_general(headers, map, body) do
    Floki.find(body, "#ctl00_ContentPlaceHolder1_gvGeneralRegulations tr")
    |> Enum.map(&(Floki.find(&1, "td")))
    |> Enum.map(fn(x) ->
      Enum.map(x, &Floki.text/1)
    end)
    |> parse_general(headers, map, body)
  end

  defp parse_general(values, headers, map, _body) do
    values
    |> Enum.filter(fn(x) -> !Enum.empty?(x) end)
    |> Enum.map(fn(row) ->
      row
      |> Enum.with_index
      |> Enum.reduce(%{}, fn({value, index}, map) ->
        label = Enum.at(headers, index)
          |> underscore
          |> String.to_atom
        value = String.strip(value)

        if label == :species do
          label = :fish
          value = find_or_create_fish(value)
        end

        Map.put(map, label, value)
      end)
      |> Map.put(:waterbody, map)
    end)
  end

  defp parse_ice_fishing(map, body) do
    Floki.find(body, "#ctl00_ContentPlaceHolder1_gvIceRegs th")
    |> case do
      [] -> []
      captured ->
        captured
        |> Enum.map(&Floki.text/1)
        |> parse_ice_fishing(map, body)
    end
  end

  defp parse_ice_fishing(headers, map, body) do
    Floki.find(body, "#ctl00_ContentPlaceHolder1_gvIceRegs tr")
    |> Enum.map(&(Floki.find(&1, "td")))
    |> Enum.map(fn(x) ->
      Enum.map(x, &Floki.text/1)
    end)
    |> parse_ice_fishing(headers, map, body)
  end

  defp parse_ice_fishing(values, headers, map, _body) do
    values
    |> Enum.filter(fn(x) -> !Enum.empty?(x) end)
    |> Enum.map(fn(row) ->
      row
      |> Enum.with_index
      |> Enum.reduce(%{}, fn({value, index}, map) ->
        label = Enum.at(headers, index)
          |> underscore
          |> String.to_atom
        value = String.strip(value)

        if label == :species do
          label = :fish
          value = find_or_create_fish(value)
        end

        Map.put(map, label, value)
      end)
      |> Map.put(:waterbody, map)
    end)
  end

  def find_or_create_fish(value) do
    %{name: value}
  end

  defp underscore(string) do
    string
    |> String.downcase
    |> String.split(" ")
    |> Enum.join("_")
  end
end
