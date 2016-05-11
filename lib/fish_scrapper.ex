defmodule FishScrapper do
  def get_data do
    HTTPoison.start

    Enum.to_list(1..524)
    |> Enum.map(&(Task.async(fn ->
      &1
      |> make_url
      |> get_page
      |> extract_data
    end)))
    |> Enum.map(&Task.await/1)
    |> Enum.each(&IO.puts/1)
  end

  def make_url(id) do
    Application.get_env(:fish_scrapper, :report_url) <> to_string(id)
  end

  def get_page(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  def extract_data({:ok, body}) do
    read_caption(body) <> "\n"
    <> read_details(body) <> "\n"
    <> read_special(body) <> "\n"
    <> read_general(body) <> "\n"
    <> read_ice_fishing(body)
  end

  def read_caption(body) do
    Floki.find(body, "#ctl00_ContentPlaceHolder1_gvDetails caption")
    |> case do
      [] -> ""
      x -> Floki.text(x)
    end
  end

  def read_details(body) do
    read_table_headers(body, "#ctl00_ContentPlaceHolder1_gvDetails")
    <> "\n" <> read_table_body(body, "#ctl00_ContentPlaceHolder1_gvDetails")
  end

  def read_special(body) do
    read_table_headers(body, "#ctl00_ContentPlaceHolder1_gvSpecialRegulations")
    <> "\n" <> read_table_body(body, "#ctl00_ContentPlaceHolder1_gvSpecialRegulations")
  end

  def read_general(body) do
    read_table_headers(body, "#ctl00_ContentPlaceHolder1_gvGeneralRegulations")
    <> "\n" <> read_table_body(body, "#ctl00_ContentPlaceHolder1_gvGeneralRegulations")
  end

  def read_ice_fishing(body) do
    read_table_headers(body, "#ctl00_ContentPlaceHolder1_gvIceRegs")
    <> "\n" <> read_table_body(body, "#ctl00_ContentPlaceHolder1_gvIceRegs")
  end

  ## private methods

  defp read_table_headers(body, id) do
    Floki.find(body, "#{id} th")
    |> case do
      [] -> ""
      x -> Enum.map_join(x, ",", &Floki.text/1)
    end
  end

  defp read_table_body(body, id) do
    Floki.find(body, "#{id} tr")
    |> Enum.map_join("\n", fn(x) ->
      Floki.find(x, "td")
      |> Enum.map_join(",", &Floki.text/1)
    end)
  end
end
