#----------------------------------------------------------#
#
#
#                   Vegetation data
#
#              Process and output sPlot data
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

data_splot <-
  RUtilpol::get_latest_file(
    file_name = "data_splot",
    dir = here::here(
      "Data/Processed/sPlot"
    )
  )


#----------------------------------------------------------#
# 3. Proccess data  -----
#----------------------------------------------------------#

dplyr::glimpse(data_splot)

data_splot_subset <-
  data_splot %>%
  tidyr::drop_na(
    PlotObservationID, GIVD_ID,
    Longitude, Latitude, Releve_area
  ) %>%
  janitor::clean_names()

#----------------------------------------------------------#
# 4. Save data  -----
#----------------------------------------------------------#

RUtilpol::save_latest_file(
  object_to_save = data_splot_subset,
  file_name = "data_splot",
  dir = here::here(
    "Outputs/Data/"
  ),
  prefered_format = "qs",
  preset = "archive"
)
