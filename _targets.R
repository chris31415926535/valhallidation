library(targets)
library(sf)
library(dplyr)
library(ggplot2)
library(readr)
#library(valhallr)

api_key <- readr::read_file(".apikey")

set.seed(12345)

list(
  # tar_target(num_to_sample, 200),
  #
  # # input data of Ontario municipal address points, updated 11 Feb 2023
  # # https://open.ottawa.ca/datasets/ottawa::municipal-address-points/about
  # tar_target(create_addresses,
  #            sf::read_sf("data/municipal_addresses/Municipal_Address_Points.shp") |>
  #              dplyr::slice_sample(n = num_to_sample) |>
  #              sf::write_sf("data/municipal_addresses_200.shp")
  # ),

  tar_target(addresses_muni,
             sf::read_sf("data/municipal_addresses_200.shp")),



  NULL
)
