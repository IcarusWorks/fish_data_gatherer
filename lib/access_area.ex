defmodule FishDataGatherer.AccessArea do
  @moduledoc """
  Fetch table data from the Vermont Fish and Wildlife site waterbody
  """

  @doc """
  Gets the HTML document

  Returns a list of maps with nested maps.
  """

  def fetch(id) do
    HTTPoison.start

    "https://anrweb.vt.gov/FWD/FW/FishingAccessAreas.aspx?AccessArea=" <> to_string(id)
    |> get_page
    |> case do
      {:ok, body} -> parse(body)
      {:error, message} -> IO.puts message
    end
  end

  # Find header and continue down the parsing chain if found
  def parse(body) do
    body
    |> Floki.find("#ctl00_ContentPlaceHolder1_pnlDetailHeader")
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
    map = parse_table(body, "#ctl00_ContentPlaceHolder1_tblDetails")
    |> create_map(name)

    href = grab_href(body, "#ctl00_ContentPlaceHolder1_tblDetails")
    Map.put(map, :directions, href)
  end

  defp parse_table(body, id) do
    Floki.find(body, "#{id} tr")
    |> Enum.map(&(Floki.find(&1, "td")))
    |> Enum.map(fn(x) ->
      Enum.map(x, &Floki.text/1)
    end)
  end

  defp create_map(values, name) do
    values = values
    |> Enum.filter(fn(x) -> !Enum.empty?(x) end)
    for [h, v] <- values, into: %{name: name} do
      key = h
        |> underscore
        |> String.replace(":", "")
        |> String.to_atom
      value = String.strip(v)

      if key == :fish_species do
        key = :fishes
        value = create_fishes(value)
      end

      {key, value}
    end
  end

  def grab_href(body, id) do
    Floki.find(body, "#{id} td a")
    |> Floki.attribute("href")
    |> List.first
  end

  defp create_fishes(value) do
    for v <- String.split(value, ", "), do: %{name: v}
  end

  defp underscore(string) do
    string
    |> String.downcase
    |> String.split(" ")
    |> Enum.join("_")
  end
end
