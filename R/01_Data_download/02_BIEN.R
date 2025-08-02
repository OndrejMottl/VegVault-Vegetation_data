#----------------------------------------------------------#
#
#
#                   Vegetation data
#
#                 Get the BIEN plot data
#
#
#                      O. Mottl
#                         2023
#
#----------------------------------------------------------#
# Download data using rBIEN package


#----------------------------------------------------------#
# 1. Set up -----
#----------------------------------------------------------#

# Load configuration
source(
  here::here(
    "R/00_Config_file.R"
  )
)

download_de_novo <- FALSE

#----------------------------------------------------------#
# 2. Downloa data and save as individual files  -----
#----------------------------------------------------------#

# Get all the avaibale protocols

vec_datasource <-
  BIEN::BIEN_plot_list_datasource() %>%
  purrr::chuck("datasource")

# path to the directory
sel_path <-
  here::here(
    "Data/Input/BIEN/"
  )

# download each sampling protocol and save it as individual file
purrr::walk(
  .progress = TRUE,
  .x = vec_datasource,
  .f = ~ {
    sel_datasource <- .x

    message(sel_datasource)

    # check if the file is present
    is_present <-
      list.files(sel_path) %>%
      purrr::map_lgl(
        .f = ~ stringr::str_detect(.x, sel_datasource)
      ) %>%
      any()

    if (
      isFALSE(is_present) | isTRUE(download_de_novo)
    ) {
      # download
      data_download <-
        BIEN::BIEN_plot_datasource(
          datasource = sel_datasource,
          all.taxonomy = TRUE,
          collection.info = TRUE,
          all.metadata = TRUE
        )

      # save
      RUtilpol::save_latest_file(
        object_to_save = data_download,
        file_name = sel_datasource,
        dir = sel_path
      )
    }
  }
)
