
##
# https://developers.google.com/maps/documentation/distance-matrix/usage-and-billing
# distance matrix api limitations
# Maximum of 25 origins or 25 destinations per request.
# Maximum 100 elements per server-side request.
# Maximum 100 elements per client-side request.
# 1000 elements per second (EPS), calculated as the sum of client-side and server-side queries.

# provide a tibble of locations, one per row
# must have lat, lon, and rowid columns. rowid must be sequential integers starting from 1
get_google_distance_api <- function(input_locations, api_key){

  df <- dplyr::select(input_locations, rowid, lat, lon) |>
    sf::st_drop_geometry()

  origin_id <- 1

  results <- dplyr::tribble(~origin_id, ~dest_id, ~origin_address_google, ~dest_address_google, ~dist_m, ~time_s)

  # loop through all origins, getting trips to destinations with greater ids
  # exclude the last one.. it has nowhere left to go!

  for (origin_id in 1:(nrow(df)-1)) {
    message("Origin id: ", origin_id, "/",nrow(df))

    origin_lat <- df[origin_id,]$lat
    origin_lon <- df[origin_id,]$lon
    origin_latlon <- paste0(origin_lat,",",origin_lon)

    df_destinations <- dplyr::filter(df, rowid > origin_id)

    # loop through destinations open to this origin
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



