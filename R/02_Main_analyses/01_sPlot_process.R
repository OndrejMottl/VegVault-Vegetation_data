#----------------------------------------------------------#
#
#
#                   Vegetation data
#
#                Process the sPlot data
#
#
#                      O. Mottl
#                         2023
#
#----------------------------------------------------------#
# Process the sPlotOpen to save as one file with relevant data


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

data_splot_taxa <-
  RUtilpol::get_latest_file(
    file_name = "data_splot_taxa",
    dir = here::here(
      "Data/Input/sPlot"
    )
  )

data_splot_meta <-
  RUtilpol::get_latest_file(
    file_name = "data_splot_meta",
    dir = here::here(
      "Data/Input/sPlot"
    )
  )

#----------------------------------------------------------#
# 3. Process data  -----
#----------------------------------------------------------#

data_splot_taxa_nested <-
  data_splot_taxa %>%
  dplyr::group_by(PlotObservationID) %>%
  tidyr::nest(
    taxa = -PlotObservationID
  )

data_splot <-
  data_splot_meta %>%
  dplyr::inner_join(
    data_splot_taxa_nested,
    by = "PlotObservationID"
  )

#----------------------------------------------------------#
# 4. Save  -----
#----------------------------------------------------------#

RUtilpol::save_latest_file(
  object_to_save = data_splot,
  dir = here::here(
    "Data/Processed/sPlot"
  )
)
