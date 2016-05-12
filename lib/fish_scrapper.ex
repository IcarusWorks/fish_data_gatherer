# defmodule FishScrapper do
#   @increment 25
#
#   # 1) create the waterbody with special regulations as an array data type
#   # 2) create or find the fish then create the general regulation and ice fishing regulation
#
#   # max is 524
#   def fetch_waterbody(limit \\ 524) do
#     HTTPoison.start
#
#     content = _fetch(1, limit, :waterbody)
#     File.write("waterbody.csv", content)
#   end
#
#   # max is 200
#   def fetch_access_area(limit \\ 200) do
#     HTTPoison.start
#
#     content = _fetch(1, limit, :access_area)
#     File.write("access_area.csv", content)
#   end
#
#   def get_page(url) do
#     case HTTPoison.get(url) do
#       {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
#         {:ok, body}
#       {:ok, %HTTPoison.Response{status_code: 404}} ->
#         {:error, "Not found"}
#       {:error, %HTTPoison.Error{reason: reason}} ->
#         {:error, reason}
#     end
#   end
#
#   def extract_data({:ok, body}, type) do
#     case type do
#       :waterbody ->
#         read_header(body, type)
#         |> case do
#         header ->
#           read_details(body, type, header)
#           # read_special(body, caption) ++
#           # read_general(body, caption) ++
#           # read_ice_fishing(body, caption)
#         nil -> []
#         end
#       :access_area ->
#         read_header(body, type) <> "\n"
#         <> read_details(body, type)
#       _ -> ""
#     end
#   end
#
#   def extract_data(_) do
#     ""
#   end
#
#   def read_header(body, type) do
#     case type do
#       :waterbody -> Floki.find(body, "#ctl00_ContentPlaceHolder1_gvDetails caption")
#       :access_area -> Floki.find(body, "#ctl00_ContentPlaceHolder1_pnlDetailHeader")
#       _ -> ""
#     end
#     |> case do
#       [] -> nil
#       x -> Floki.text(x)
#     end
#   end
#
#   def read_details(body, type, header) do
#     case type do
#       :waterbody ->
#         make_list(body, "#ctl00_ContentPlaceHolder1_gvDetails", header, "details")
#       :access_area ->
#         make_list(body, "#ctl00_ContentPlaceHolder1_tblDetails", header, "details")
#       _ -> []
#     end
#   end
#
#   def read_special(body) do
#     make_list(body, "#ctl00_ContentPlaceHolder1_gvSpecialRegulations")
#   end
#
#   def read_general(body) do
#     make_list(body, "#ctl00_ContentPlaceHolder1_gvGeneralRegulations")
#   end
#
#   def read_ice_fishing(body) do
#     make_list(body, "#ctl00_ContentPlaceHolder1_gvIceRegs")
#   end
#
#   ## private methods
#   # [[["daily limit", "whatever"], ["length", "18"]]]
#
#   defp make_list(body, id, header, type) do
#     read_table_headers(body, id)
#     |> Enum.each(fn(x) ->
#       read_table_body(body, id)
#       |> Enum.map(fn(y) ->
#         [x, y]
#       end)
#     end)
#   end
#
#   defp _fetch(from, limit, type) when (from + @increment) < limit do
#     to = (from + @increment)
#     trigger(from, to, type)
#     _fetch(to + 1, limit, type)
#   end
#
#   defp _fetch(from, limit, type) do
#     trigger(from, limit, type)
#   end
#
#   defp trigger(from, to, type) do
#     Enum.to_list(from..to)
#     |> Enum.map(&(Task.async(fn ->
#       &1
#       |> make_url(type)
#       |> get_page
#       |> extract_data(type)
#     end)))
#     |> Enum.map(&Task.await/1)
#   end
#
#   defp read_table_headers(body, id) do
#     Floki.find(body, "#{id} th")
#     |> case do
#       [] -> []
#       x -> Enum.map(x, &Floki.text/1)
#     end
#   end
#
#   # returns [["value 1", "value 2"]]
#   defp read_table_body(body, id) do
#     Floki.find(body, "#{id} tr")
#     |> Enum.map(fn(x) ->
#       Floki.find(x, "td")
#       |> Enum.map(&Floki.text/1)
#     end)
#   end
#
#   defp make_url(id, type) do
#     key = case type do
#       :waterbody -> :waterbody_url
#       :access_area -> :access_area_url
#       _ -> :waterbody_url
#     end
#     Application.get_env(:fish_scrapper, key) <> to_string(id)
#   end
# end
