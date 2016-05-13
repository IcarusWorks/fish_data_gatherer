defmodule Fisher do
  @waterbody_num 524
  @access_area_num 200

  def fetch_waterbody do
    for i <- 1..@waterbody_num do
      Waterbody.fetch(i)
    end
  end

  def fetch_access_area do
    for i <- 1..@access_area_num do
      AccessArea.fetch(i)
    end
  end
end
