#----------------------------------------------------------#
#
#
#                   Vegetation data
#
#                  Data export pipeline
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Defines the data export target graph: complete plots (and, for sPlot,
#   only named taxon records) with clean column names in a documented row
#   order, saved as the `qs2` artefacts that VegVault reads.
# Run with:
#   R/Analyses/03_Data_export/00_run.R
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

splot_column_taxa <-
  load_config_value(value = c("splot", "column_taxa"))

splot_column_taxon_name <-
  load_config_value(value = c("splot", "column_taxon_name"))

vec_splot_columns_required <-
  load_config_value(value = c("splot", "columns_required")) |>
  base::unlist()

vec_splot_columns_order <-
  load_config_value(value = c("splot", "columns_order")) |>
  base::unlist()

vec_bien_columns_required <-
  load_config_value(value = c("bien", "columns_required")) |>
  base::unlist()

vec_bien_columns_order <-
  load_config_value(value = c("bien", "columns_order")) |>
  base::unlist()

dir_export <-
  here::here(
    load_config_value(value = c("export", "dir_output"))
  )

flag_replace_previous_export <-
  load_config_value(value = c("export", "flag_replace_previous"))

# The project's copy of the VegVault contracts (see Data/Contracts/README in
#   VegVault and Data/Contracts/contract_copy.yml here)
path_contract_splot_file <-
  here::here("Data", "Contracts", "splot_plots.yml")

path_contract_bien_file <-
  here::here("Data", "Contracts", "bien_plots.yml")


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
  # sPlot plots with only named taxon records: the VegVault sPlot contract
  #   rejects records whose name is missing or empty.
  targets::tar_target(
    name = "data_splot_named_taxa",
    command = filter_named_taxa(
      data_plots = data_splot_processed,
      col_taxa = splot_column_taxa,
      col_taxon_name = splot_column_taxon_name
    )
  ),
  # Public target: complete sPlot plots in export form and order.
  targets::tar_target(
    name = "data_splot_export",
    command = prepare_plot_export(
      data_plots = data_splot_named_taxa,
      vec_columns_required = vec_splot_columns_required,
      vec_columns_order = vec_splot_columns_order
    )
  ),
  # Public target: complete BIEN plots in export form and order.
  targets::tar_target(
    name = "data_bien_export",
    command = prepare_plot_export(
      data_plots = data_bien_processed,
      vec_columns_required = vec_bien_columns_required,
      vec_columns_order = vec_bien_columns_order
    )
  ),
  # The sPlot artefact for VegVault, tracked as a file.
  targets::tar_target(
    name = "path_splot_export",
    command = save_export_artefact(
      data_export = data_splot_export,
      file_name = "data_splot",
      dir_output = dir_export,
      flag_replace_previous = flag_replace_previous_export
    ),
    format = "file"
  ),
  # The BIEN artefact for VegVault, tracked as a file.
  targets::tar_target(
    name = "path_bien_export",
    command = save_export_artefact(
      data_export = data_bien_export,
      file_name = "data_bien",
      dir_output = dir_export,
      flag_replace_previous = flag_replace_previous_export
    ),
    format = "file"
  ),
  # The sPlot contract, tracked as a file so that a new copy of the
  #   contracts reruns the check below.
  targets::tar_target(
    name = "path_contract_splot",
    command = path_contract_splot_file,
    format = "file"
  ),
  # The BIEN contract, tracked as a file for the same reason.
  targets::tar_target(
    name = "path_contract_bien",
    command = path_contract_bien_file,
    format = "file"
  ),
  # Public target: the sPlot artefact once it passes its VegVault contract;
  #   a violation stops the run.
  targets::tar_target(
    name = "path_splot_export_validated",
    command = validate_export_artefact(
      path_artefact = path_splot_export,
      path_contract = path_contract_splot
    )
  ),
  # Public target: the BIEN artefact once it passes its VegVault contract.
  targets::tar_target(
    name = "path_bien_export_validated",
    command = validate_export_artefact(
      path_artefact = path_bien_export,
      path_contract = path_contract_bien
    )
  )
)
