#----------------------------------------------------------#
#
#
#                   Vegetation data
#
#              Process and output BIEN data
#
#
#                      O. Mottl
#                         2023
#
#----------------------------------------------------------#
# based on the review and supplemetary visulaisation, make a output file


#----------------------------------------------------------#
# 1. Set up -----
#----------------------------------------------------------#

# Load configuration
source(
  here::here(
    "R/00_Config_file.R"
  )
)

#----------------------------------------------------------#
# 2. Load data  -----
#----------------------------------------------------------#

data_bien <-
  RUtilpol::get_latest_file(
    file_name = "data_bien",
    dir = here::here(
      "Data/Processed/BIEN"
    )
  )

#----------------------------------------------------------#
# 3. Proccess data  -----
#----------------------------------------------------------#

dplyr::glimpse(data_bien)

data_bien_subset <-
  data_bien %>%
  tidyr::drop_na(
    datasource_id, datasource,
    plot_name,
    longitude, latitude, plot_area_ha
  ) %>%
  janitor::clean_names()

#----------------------------------------------------------#
# 4. Save data  -----
#----------------------------------------------------------#

RUtilpol::save_latest_file(
  object_to_save = data_bien_subset,
  file_name = "data_bien",
  dir = here::here(
    "Outputs/Data/"
  ),
  prefered_format = "qs",
  preset = "archive"
)
