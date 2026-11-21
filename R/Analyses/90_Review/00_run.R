#----------------------------------------------------------#
#
#
#                   Vegetation data
#
#                Run stage 90: review
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Builds the review pipeline in its own store under
#   `<data root>/Targets_data/`. Needs the data processing stage first.
#   Outside the main chain, so `R/Analyses/00_run_main.R` does not run it.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

flag_visualise_pipeline <- FALSE


#----------------------------------------------------------#
# 1. Run pipelines -----
#----------------------------------------------------------#

run_target_pipeline(
  script = here::here("R/Analyses/90_Review/pipeline.R"),
  store = resolve_pipeline_store_path(
    path_data_storage = path_data_storage,
    store_relative_path = "review"
  ),
  visualise = flag_visualise_pipeline
)
