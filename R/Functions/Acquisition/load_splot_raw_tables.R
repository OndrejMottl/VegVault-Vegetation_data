#' @title Load the sPlotOpen raw tables
#' @description Load the taxon table (`DT2.oa`) and the plot table
#'   (`header.oa`) from the sPlotOpen `.RData` file.
#' @param path_file Character. Path to the sPlotOpen `.RData` file.
#' @return A named list with two data frames: `data_taxa` (`DT2.oa`, one row
#'   per taxon record) and `data_meta` (`header.oa`, one row per plot).
#' @details The file is loaded into a new environment, so nothing is written
#'   to the caller's or the global environment. The function aborts when the
#'   file does not exist or does not contain both objects as data frames.
load_splot_raw_tables <- function(path_file) {
  assertthat::assert_that(
    base::is.character(path_file),
    base::length(path_file) == 1L,
    !base::is.na(path_file),
    msg = "`path_file` must be a single character string."
  )

  if (
    isFALSE(base::file.exists(path_file))
  ) {
    cli::cli_abort("The sPlotOpen file does not exist: {.path {path_file}}")
  }

  env_load <-
    base::new.env(parent = base::emptyenv())

  vec_loaded <-
    base::load(file = path_file, envir = env_load)

  vec_required <- c("DT2.oa", "header.oa")

  vec_missing <-
    base::setdiff(vec_required, vec_loaded)

  if (
    base::length(vec_missing) > 0L
  ) {
    cli::cli_abort(
      "The sPlotOpen file does not contain {.val {vec_missing}}."
    )
  }

  vec_not_table <-
    vec_required[
      !purrr::map_lgl(
        .x = vec_required,
        .f = ~ base::is.data.frame(env_load[[.x]])
      )
    ]

  if (
    base::length(vec_not_table) > 0L
  ) {
    cli::cli_abort(
      "In the sPlotOpen file, {.val {vec_not_table}} is not a data frame."
    )
  }

  res <-
    list(
      data_taxa = env_load[["DT2.oa"]],
      data_meta = env_load[["header.oa"]]
    )

  return(res)
}
