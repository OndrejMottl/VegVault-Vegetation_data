#----------------------------------------------------------#
#
#
#                   Vegetation data
#
#                Data processing pipeline
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Defines the data processing target graph: sPlot taxa nested by plot and
#   joined to the plots; BIEN records with one coordinate pair per plot,
#   from the latest survey of each plot, merged to one record per taxon and
#   plot, then nested by plot.
# Run with:
#   R/Analyses/02_Data_processing/00_run.R
# Sourcing this script only declares targets; it does not execute them.


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

vec_bien_columns_selected <-
  load_config_value(value = c("bien", "columns_selected")) |>
  base::unlist()

vec_bien_columns_nested <-
  load_config_value(value = c("bien", "columns_nested")) |>
  base::unlist()

# The selected columns that are not nested describe the plot
vec_bien_columns_plot <-
  base::setdiff(vec_bien_columns_selected, vec_bien_columns_nested)

vec_bien_columns_plot_key <-
  load_config_value(value = c("bien", "columns_plot_key")) |>
  base::unlist()

bien_coordinate_max_spread <-
  load_config_value(value = c("bien", "coordinate_max_spread"))

bien_column_date <-
  load_config_value(value = c("bien", "column_date"))

bien_column_taxon <-
  load_config_value(value = c("bien", "column_taxon"))

bien_column_count <-
  load_config_value(value = c("bien", "column_count"))

vec_bien_columns_joined <-
  load_config_value(value = c("bien", "columns_joined")) |>
  base::unlist()

vec_bien_columns_agreeing <-
  load_config_value(value = c("bien", "columns_agreeing")) |>
  base::unlist()

bien_merge_separator <-
  load_config_value(value = c("bien", "merge_separator"))


#----------------------------------------------------------#
# 1. Upstream contract -----
#----------------------------------------------------------#

# Only these public targets of the upstream store are imported
vec_public_targets_data_acquisition <-
  c(
    "data_splot_taxa_raw",
    "data_splot_meta_raw",
    "data_bien_raw"
  )

store_data_acquisition <-
  resolve_pipeline_store_path(
    path_data_storage = path_data_storage,
    store_relative_path = "data_acquisition"
  )

runner_data_acquisition <- "R/Analyses/01_Data_acquisition/00_run.R"


#----------------------------------------------------------#
# 2. Define targets -----
#----------------------------------------------------------#

list(
  # Fingerprint the upstream public targets so that a change upstream
  #   invalidates the imports below; the check itself is cheap metadata.
  targets::tar_target(
    name = "fingerprint_data_acquisition",
    command = compute_target_store_fingerprint(
      store = store_data_acquisition,
      target_names = vec_public_targets_data_acquisition,
      runner = runner_data_acquisition
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  # Import the sPlotOpen taxon records; reruns only when the fingerprint
  #   changes.
  targets::tar_target(
    name = "data_splot_taxa_raw",
    command = {
      fingerprint_data_acquisition

      load_target_store_value(
        store = store_data_acquisition,
        target_name = "data_splot_taxa_raw",
        runner = runner_data_acquisition
      )
    }
  ),
  # Import the sPlotOpen plots.
  targets::tar_target(
    name = "data_splot_meta_raw",
    command = {
      fingerprint_data_acquisition

      load_target_store_value(
        store = store_data_acquisition,
        target_name = "data_splot_meta_raw",
        runner = runner_data_acquisition
      )
    }
  ),
  # Import the BIEN records.
  targets::tar_target(
    name = "data_bien_raw",
    command = {
      fingerprint_data_acquisition

      load_target_store_value(
        store = store_data_acquisition,
        target_name = "data_bien_raw",
        runner = runner_data_acquisition
      )
    }
  ),
  # Public target: one row per sPlot plot that has taxon records, with its
  #   records nested in `taxa`.
  targets::tar_target(
    name = "data_splot_processed",
    command = prepare_splot_plots(
      data_taxa = data_splot_taxa_raw,
      data_meta = data_splot_meta_raw
    )
  ),
  # BIEN records with one coordinate pair per plot where a plot's records
  #   carry several nearby pairs (the subplots of three TEAM plots).
  targets::tar_target(
    name = "data_bien_located",
    command = prepare_plot_coordinates(
      data_records = data_bien_raw,
      vec_columns_plot = vec_bien_columns_plot_key,
      col_longitude = "longitude",
      col_latitude = "latitude",
      max_spread = bien_coordinate_max_spread
    )
  ),
  # BIEN records of the latest survey year of each plot, so that a
  #   re-surveyed individual is not counted twice in the merge below.
  targets::tar_target(
    name = "data_bien_latest_survey",
    command = select_latest_survey(
      data_records = data_bien_located,
      vec_columns_plot = vec_bien_columns_plot_key,
      col_date = bien_column_date
    )
  ),
  # One BIEN record per taxon and plot.
  targets::tar_target(
    name = "data_bien_taxa",
    command = aggregate_bien_taxa(
      data_records = data_bien_latest_survey,
      vec_columns_plot = vec_bien_columns_plot,
      col_taxon = bien_column_taxon,
      col_count = bien_column_count,
      vec_columns_joined = vec_bien_columns_joined,
      vec_columns_agreeing = vec_bien_columns_agreeing,
      separator = bien_merge_separator
    )
  ),
  # Public target: one row per BIEN plot (and per combination of its
  #   plot-level columns), with one record per taxon nested in `plot_data`.
  targets::tar_target(
    name = "data_bien_processed",
    command = prepare_bien_plots(
      data_bien_raw = data_bien_taxa,
      vec_columns_selected = vec_bien_columns_selected,
      vec_columns_nested = vec_bien_columns_nested
    )
  )
)
