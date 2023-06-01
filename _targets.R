library(targets)
library(sf)
library(dplyr)
library(ggplot2)
library(readr)
#library(valhallr)

api_key <- readr::read_lines(".apikey")
source ("R/functions.R")

set.seed(12345)

list(
  # tar_target(num_to_sample, 200),

  # # input data of Ontario municipal address points, updated 11 Feb 2023
  # # https://open.ottawa.ca/datasets/ottawa::municipal-address-points/about
  # tar_target(create_addresses,
  #            sf::read_sf("data/municipal_addresses/Municipal_Address_Points.shp") |>
  #              dplyr::slice_sample(n = num_to_sample) |>

               #sf::write_sf("data/municipal_addresses_200.shp")
  #),

  tar_target(addresses_muni,
             sf::read_sf("data/municipal_addresses_200.shp") %>%
               dplyr::bind_cols(sf::st_coordinates(.)) |>
               dplyr::rename(lon = X, lat = Y) |>
               tibble::rowid_to_column()
             ),

  tar_target(muni_google_apiresults,
             get_google_distance_api(addresses_muni, api_key)),



  NULL
)
