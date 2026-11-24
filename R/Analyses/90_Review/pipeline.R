#----------------------------------------------------------#
#
#
#                   Vegetation data
#
#                    Review pipeline
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Defines the review target graph: maps of the processed sPlot and BIEN
#   plots and the most common plot size per continent or region. Outside
#   the main chain; nothing downstream depends on it.
# Run with:
#   R/Analyses/90_Review/00_run.R
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

vec_splot_continents <-
  load_config_value(value = c("review", "splot_continents")) |>
  base::unlist()

vec_bien_regions <-
  load_config_value(value = c("review", "bien_regions")) |>
  base::unlist()

figure_size_scale <-
  load_config_value(value = c("review", "figure_size_scale"))

path_figure_splot_map <-
  here::here("Outputs", "Figures", "sPlot_map.pdf")

path_figure_bien_map <-
  here::here("Outputs", "Figures", "BIEN_map.pdf")


#----------------------------------------------------------#
# 1. Upstream contract -----
#----------------------------------------------------------#

# Only these public targets of the upstream store are imported
vec_public_targets_data_processing <-
  c(
    "data_splot_processed",
    "data_bien_processed"
  )

store_data_processing <-
  resolve_pipeline_store_path(
    path_data_storage = path_data_storage,
    store_relative_path = "data_processing"
  )

runner_data_processing <- "R/Analyses/02_Data_processing/00_run.R"


#----------------------------------------------------------#
# 2. Define targets -----
#----------------------------------------------------------#

list(
  # Fingerprint the upstream public targets so that a change upstream
  #   invalidates the imports below; the check itself is cheap metadata.
  targets::tar_target(
    name = "fingerprint_data_processing",
    command = compute_target_store_fingerprint(
      store = store_data_processing,
      target_names = vec_public_targets_data_processing,
      runner = runner_data_processing
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  # Import the processed sPlot plots; reruns only when the fingerprint
  #   changes.
  targets::tar_target(
    name = "data_splot_processed",
    command = {
      fingerprint_data_processing

      load_target_store_value(
        store = store_data_processing,
        target_name = "data_splot_processed",
        runner = runner_data_processing
      )
    }
  ),
  # Import the processed BIEN plots.
  targets::tar_target(
    name = "data_bien_processed",
    command = {
      fingerprint_data_processing

      load_target_store_value(
        store = store_data_processing,
        target_name = "data_bien_processed",
        runner = runner_data_processing
      )
    }
  ),
  # Map of the number of sPlot plots.
  targets::tar_target(
    name = "plot_splot_counts",
    command = plot_vegetation_plot_counts(
      data_plots = data_splot_processed,
      col_longitude = "Longitude",
      col_latitude = "Latitude",
      title = "Spatial distribution of sPlot data"
    )
  ),
  # Map of the number of BIEN plots, one panel per data source.
  targets::tar_target(
    name = "plot_bien_counts",
    command = plot_vegetation_plot_counts(
      data_plots = data_bien_processed,
      col_longitude = "longitude",
      col_latitude = "latitude",
      title = "Spatial distribution of BIEN plot data",
      col_facet = "datasource",
      subtitle = "One panel per data source (different methodology)"
    )
  ),
  # The sPlot map file, under the file name of VegVault 1.0.0.
  targets::tar_target(
    name = "path_figure_splot_counts",
    command = save_figure_file(
      plot_figure = plot_splot_counts,
      path_file = path_figure_splot_map,
      list_graphical = graphical_options,
      size_scale = figure_size_scale
    ),
    format = "file"
  ),
  # The BIEN map file, under the file name of VegVault 1.0.0.
  targets::tar_target(
    name = "path_figure_bien_counts",
    command = save_figure_file(
      plot_figure = plot_bien_counts,
      path_file = path_figure_bien_map,
      list_graphical = graphical_options,
      size_scale = figure_size_scale
    ),
    format = "file"
  ),
  # Most common sPlot plot size per continent (square metres).
  targets::tar_target(
    name = "table_splot_common_plot_size",
    command = summarise_common_plot_size(
      data_plots = data_splot_processed,
      col_group = "Continent",
      col_area = "Releve_area",
      vec_columns_plot = "PlotObservationID"
    )
  ),
  # BIEN plots with the coarse region the plot-size review uses.
  targets::tar_target(
    name = "data_bien_regions",
    command = prepare_bien_regions(data_plots = data_bien_processed)
  ),
  # Most common BIEN plot size per region (hectares).
  targets::tar_target(
    name = "table_bien_common_plot_size",
    command = summarise_common_plot_size(
      data_plots = data_bien_regions,
      col_group = "region",
      col_area = "plot_area_ha",
      vec_columns_plot = c(
        "datasource", "methodology_reference", "datasource_id", "plot_name"
      )
    )
  ),
  # sPlot plots of the most common size in the reviewed continents.
  targets::tar_target(
    name = "data_splot_common_size",
    command = select_common_size_plots(
      data_plots = data_splot_processed,
      data_common_size = table_splot_common_plot_size,
      col_group = "Continent",
      col_area = "Releve_area",
      vec_groups = vec_splot_continents
    )
  ),
  # BIEN plots of the most common size in the reviewed regions.
  targets::tar_target(
    name = "data_bien_common_size",
    command = select_common_size_plots(
      data_plots = data_bien_regions,
      data_common_size = table_bien_common_plot_size,
      col_group = "region",
      col_area = "plot_area_ha",
      vec_groups = vec_bien_regions
    )
  ),
  # Map of the sPlot plots of the most common size, one panel per
  #   continent.
  targets::tar_target(
    name = "plot_splot_common_size",
    command = plot_vegetation_plot_locations(
      data_plots = data_splot_common_size,
      col_longitude = "Longitude",
      col_latitude = "Latitude",
      title = "sPlot plots with the most common plot size",
      col_facet = "Continent"
    )
  ),
  # Map of the BIEN plots of the most common size, one panel per region.
  targets::tar_target(
    name = "plot_bien_common_size",
    command = plot_vegetation_plot_locations(
      data_plots = data_bien_common_size,
      col_longitude = "longitude",
      col_latitude = "latitude",
      title = "BIEN plots with the most common plot size",
      col_facet = "region"
    )
  )
)
