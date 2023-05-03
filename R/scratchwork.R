
df <- sf::read_sf("data/Municipal_Address_Points.geojson")

api_key <- readr::read_file(".apikey")

## testing google distance matrix API
# https://developers.google.com/maps/documentation/distance-matrix/distance-matrix#maps_http_distancematrix_latlng-js
# Note: If departure time is not specified, choice of route and duration are based on road network and average time-independent traffic conditions. Results for a given request may vary over time due to changes in the road network, updated average traffic conditions, and the distributed nature of the service. Results may also vary between nearly-equivalent routes at any time or frequency.
# default url
url <- paste0("https://maps.googleapis.com/maps/api/distancematrix/json?origins=40.6655101%2C-73.89188969999998&destinations=40.659569%2C-73.933783%7C40.729029%2C-73.851524%7C40.6860072%2C-73.6334271%7C40.598566%2C-73.7527626&key=",api_key)

# bigger url to try an actual matrix
url <- paste0("https://maps.googleapis.com/maps/api/distancematrix/json?origins=40.659569,-73.933783|40.729029,-73.851524|40.6860072,-73.6334271|40.598566,-73.7527626&destinations=40.659569,-73.933783|40.729029,-73.851524|40.6860072,-73.6334271|40.598566,-73.7527626&key=",api_key)


urltools::url_decode(url)

response <- httr::GET(url)
#jsonlite::fromJSON(response)
result <- httr::content(response, encoding = "UTF-8")


result

addr_dest <- unlist(result$destination_addresses)
addr_orig <- unlist(result$origin_addresses)

addr_dest
addr_orig

origins <- result$rows

result <- dplyr::tribble(~origin_id, ~dest_id, ~origin, ~dest, ~dist_m, ~time_s)

for (i in 1:length(origins)){
  message("origin ", i)
  origin <- origins[[i]]$elements

  for (j in 1:length(origin)) {
    message("  destination ", j)

    destination <- origin[[j]]
    dist_m <- destination$distance$value
    time_s <- destination$duration$value
    result <- dplyr::add_row(result,
                             origin_id = i,
                             dest_id = j,
                             origin = addr_orig[[i]],
                             dest = addr_dest[[j]],
                             dist_m = dist_m,
                             time_s = time_s)
  }


}

result
