
df <- sf::read_sf("data/Municipal_Address_Points.geojson")

api_key <- readr::read_lines(".apikey")

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




##
# https://developers.google.com/maps/documentation/distance-matrix/usage-and-billing
# distance matrix api limitations
# Maximum of 25 origins or 25 destinations per request.
# Maximum 100 elements per server-side request.
# Maximum 100 elements per client-side request.
# 1000 elements per second (EPS), calculated as the sum of client-side and server-side queries.

# provide a tibble of locations, one per row
# must have lat, lon, and rowid columns. rowid must be sequential integers starting from 1
get_google_distance_api <- function(input_locations){

  df <- dplyr::select(input_locations, rowid, lat, lon) |>
    sf::st_drop_geometry()

  origin_id <- 1

  results <- dplyr::tribble(~origin_id, ~dest_id, ~origin_address_google, ~dest_address_google, ~dist_m, ~time_s)

  # loop through all origins, getting trips to destinations with greater ids

  for (origin_id in 195:nrow(df)) {
    message("Origin id: ", origin_id, "/",nrow(df))

    origin_lat <- df[origin_id,]$lat
    origin_lon <- df[origin_id,]$lon
    origin_latlon <- paste0(origin_lat,",",origin_lon)

    df_destinations <- dplyr::filter(df, rowid > origin_id)

    for (dest_index in 1:nrow(df_destinations)){
      message("     Dest index: ", dest_index, "/",nrow(df_destinations))
      df_dest <- df_destinations[dest_index,]

      dest_id <- df_dest$rowid
      dest_lat <- df_dest$lat
      dest_lon <- df_dest$lon
      dest_latlon <- paste0(dest_lat,",",dest_lon)

      #url <- paste0("https://maps.googleapis.com/maps/api/distancematrix/json?origins=40.659569,-73.933783|40.729029,-73.851524|40.6860072,-73.6334271|40.598566,-73.7527626&destinations=40.659569,-73.933783|40.729029,-73.851524|40.6860072,-73.6334271|40.598566,-73.7527626&key=",api_key)
      url <- sprintf("https://maps.googleapis.com/maps/api/distancematrix/json?origins=%s&destinations=%s&key=%s",origin_latlon, dest_latlon, api_key)
      #message("       ", url)

      # query API
      response <- httr::GET(url)
      #jsonlite::fromJSON(response)
      response <- httr::content(response, encoding = "UTF-8")

      origins <- response$rows


      destination <- origins[[1]]
      dist_m <- destination$elements[[1]]$distance$value
      time_s <- destination$elements[[1]]$duration$value

      results <- dplyr::add_row(results,
                                origin_id = origin_id,
                                dest_id = dest_id,
                                origin_address_google = response$origin_addresses[[1]],
                                dest_address_google = response$destination_addresses[[1]],
                                dist_m = dist_m,
                                time_s = time_s)

    } # end for dest_index in 1:nrow(df_destinations)



  } # end for origin_index in 1:nrow(df)

#  results

  tryCatch(readr::write_csv(results, paste0("outputs/google-api-outout-",Sys.Date(),".csv")))

  return(results)
}




### check results:: are postal codes the same?

pcodes_google <- muni_google_apiresults |>
  dplyr::select(rowid = origin_id, address_google = origin_address_google) |>
  dplyr::distinct() |>
  dplyr::mutate(postalcode_google = stringr::str_extract(address_google, "\\w\\d\\w \\d\\w\\d")) |>
  dplyr::mutate(postalcode_google = stringr::str_remove_all(postalcode_google, "\\s")) |>
  dplyr::select(-address_google)

pcodes_ottawa <- sf::st_drop_geometry(addresses_muni) |>
  dplyr::select(rowid, postalcode_ottawa = POSTAL_COD)

dplyr::left_join(pcodes_ottawa, pcodes_google, by = "rowid") |>
  dplyr::mutate(diff = postalcode_ottawa != postalcode_google) |> View()
  dplyr::summarise(num_diffs = sum(diff),
                   pct_diffs = mean(diff))
