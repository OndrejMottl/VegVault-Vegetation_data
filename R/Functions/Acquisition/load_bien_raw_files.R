#' @title Load and bind the raw BIEN plot files
#' @description Read the raw file of every BIEN plot datasource, drop the
#'   datasources without records, and bind the rest into one table.
#' @param vec_paths Character vector. Paths of the raw `.rds` files, one per
#'   datasource.
#' @param vec_datasources Character vector. Datasource names, in the same
#'   order as `vec_paths`.
#' @return A tibble with one row per BIEN record and a first column
#'   `datasource` holding the datasource name of each record.
#' @details A datasource is dropped when its file holds `NULL`, an object
#'   whose values are all missing, or a data frame without rows, as in the
#'   VegVault 1.0.0 processing. The remaining tables are bound in the order of
#'   `vec_datasources` with `dplyr::bind_rows(.id = "datasource")`, which
#'   replaces the `datasource` column that BIEN records carry with the
#'   datasource name of their file. The
#'   function aborts when the two vectors differ in length, a name is
#'   duplicated, a file does not exist, or no datasource has records.
load_bien_raw_files <- function(
    vec_paths,
    vec_datasources) {
  assertthat::assert_that(
    base::is.character(vec_paths),
    base::is.character(vec_datasources),
    msg = "`vec_paths` and `vec_datasources` must be character vectors."
  )

  if (
    base::length(vec_paths) != base::length(vec_datasources)
  ) {
    cli::cli_abort(
      "`vec_paths` and `vec_datasources` must have the same length."
    )
  }

  vec_duplicated <-
    base::unique(vec_datasources[base::duplicated(vec_datasources)])

  if (
    base::length(vec_duplicated) > 0L
  ) {
    cli::cli_abort(
      "`vec_datasources` has duplicated names: {.val {vec_duplicated}}."
    )
  }

  vec_missing <-
    vec_paths[!base::file.exists(vec_paths)]

  if (
    base::length(vec_missing) > 0L
  ) {
    cli::cli_abort(
      "A BIEN raw file does not exist: {.path {vec_missing}}"
    )
  }

  list_raw <-
    purrr::map(
      .x = vec_paths,
      .f = ~ readr::read_rds(file = .x)
    ) |>
    rlang::set_names(vec_datasources)

  # The three rules and their order are those of the VegVault 1.0.0
  #   processing; `is.na(NULL)` is empty, so `all()` drops NULL already
  list_with_records <-
    list_raw |>
    purrr::discard(
      .p = ~ base::all(base::is.na(.x))
    ) |>
    purrr::discard(
      .p = ~ base::is.null(.x)
    ) |>
    purrr::discard(
      .p = ~ base::nrow(.x) < 1
    )

  if (
    base::length(list_with_records) == 0L
  ) {
    cli::cli_abort("No BIEN datasource has records.")
  }

  res <-
    list_with_records |>
    dplyr::bind_rows(.id = "datasource") |>
    tibble::as_tibble()

  return(res)
}
