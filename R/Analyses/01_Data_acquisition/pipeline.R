#----------------------------------------------------------#
#
#
#                   Vegetation data
#
#                Data acquisition pipeline
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Defines the data acquisition target graph: the manually downloaded
#   sPlotOpen file and one raw file per BIEN plot datasource.
# Run with:
#   R/Analyses/01_Data_acquisition/00_run.R
# Sourcing this script only declares targets; it does not execute them.
# BIEN is downloaded only when `bien: flag_download` is true in config.yml,
#   and only for datasources without a raw file.


#----------------------------------------------------------#
# 0. Configure pipeline -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

targets::tar_option_set(
  seed = config_seed
)

path_splot_raw <-
  base::file.path(
    path_data_storage,
    load_config_value(value = c("splot", "raw_file"))
  )

sha256_splot_raw <-
  load_config_value(value = c("splot", "raw_file_sha256"))

version_splot_raw <-
  load_config_value(value = c("splot", "raw_file_version"))

dir_bien_raw <-
  base::file.path(
    path_data_storage,
    load_config_value(value = c("bien", "raw_dir"))
  )

vec_bien_datasources_config <-
  load_config_value(value = c("bien", "datasources")) |>
  base::unlist()

flag_download_bien <-
  load_config_value(value = c("bien", "flag_download"))


#----------------------------------------------------------#
# 1. Define targets -----
#----------------------------------------------------------#

list(
  # The sPlotOpen file, checked against the recorded version. As a file
  #   target, a changed or missing file reruns the check and its readers.
  targets::tar_target(
    name = "path_splot_raw_file",
    command = validate_splot_raw_file(
      path_file = path_splot_raw,
      sha256_expected = sha256_splot_raw,
      version_label = version_splot_raw
    ),
    format = "file"
  ),
  # Both sPlotOpen tables, read once from the raw file.
  targets::tar_target(
    name = "list_splot_raw",
    command = load_splot_raw_tables(path_file = path_splot_raw_file)
  ),
  # Public target: sPlotOpen taxon records (`DT2.oa`).
  targets::tar_target(
    name = "data_splot_taxa_raw",
    command = purrr::chuck(list_splot_raw, "data_taxa")
  ),
  # Public target: sPlotOpen plots (`header.oa`).
  targets::tar_target(
    name = "data_splot_meta_raw",
    command = purrr::chuck(list_splot_raw, "data_meta")
  ),
  # The configured BIEN plot datasources; checked against BIEN only when
  #   downloading is enabled.
  targets::tar_target(
    name = "vec_bien_datasources",
    command = resolve_bien_datasources(
      vec_datasources = vec_bien_datasources_config,
      flag_download = flag_download_bien
    )
  ),
  # One raw file per datasource. A missing file is downloaded only with the
  #   download flag; an existing file is never downloaded again.
  targets::tar_target(
    name = "path_bien_raw_file",
    command = resolve_bien_raw_file(
      dir_raw = dir_bien_raw,
      datasource = vec_bien_datasources,
      flag_download = flag_download_bien
    ),
    # {targets} parses patterns itself and rejects a namespaced `map()`
    pattern = map(vec_bien_datasources),
    format = "file"
  ),
  # Public target: all BIEN records with their datasource name.
  targets::tar_target(
    name = "data_bien_raw",
    command = load_bien_raw_files(
      vec_paths = path_bien_raw_file,
      vec_datasources = vec_bien_datasources
    )
  )
)
