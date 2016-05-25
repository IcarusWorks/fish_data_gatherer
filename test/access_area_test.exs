defmodule AccessAreaTest do
  use ExUnit.Case
  doctest FishDataGatherer.AccessArea

  @expected_response %{boat_size: "Medium",
  directions: "http://maps.google.com/maps?f=d&source=s_d&saddr=&daddr=44.878285,-72.154984&hl=en&geocode=&mra=mi&mrsp=0&sz=15&sll=44.877251,-72.155628&sspn=0.0222,0.019526&ie=UTF8&t=h&z=15",
  dock: "No Dock Available", exposure: "Protected",
  fishes: [%{name: "Bullhead"}, %{name: "Chain Pickerel"}, %{name: "Panfish"},
   %{name: "Smallmouth Bass"}, %{name: "Yellow Perch"}], lake_area: "136 acres",
  maximum_depth: "33 feet",
  name: "Brownington Pond, (In Waterbody Brownington Pond) Brownington, VT",
  parking_lot_size: "Medium", ramp_type: "Concrete Plank",
  recommended_season: "All Year", summer_portolet: "No Summer Restroom",
  universal_access: "No Universal Shore Fishing Platform",
  winter_access: "Not Plowed In Winter", winter_portolet: "No Winter Restroom"}

  test "parse/1 correctly parses an html body" do
    {:ok, body} = File.read("test/data/access_area_html.txt")
    assert FishDataGatherer.AccessArea.parse(Macro.unescape_string(body)) == @expected_response
  end
end
