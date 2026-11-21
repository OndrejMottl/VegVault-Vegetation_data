#' @title Prepare the BIEN plots
#' @description Select the configured BIEN columns and nest the record-level
#'   columns by plot.
#' @param data_bien_raw A data frame of BIEN records with the columns
#'   `datasource` and `plot_name`.
#' @param vec_columns_selected Character vector. Columns to keep; columns
#'   absent from `data_bien_raw` are skipped.
#' @param vec_columns_nested Character vector. Record-level columns to nest
#'   into `plot_data`; all must be present.
#' @return An ungrouped tibble with one row per combination of the selected
#'   plot-level columns and a list-column `plot_data` holding the nested
#'   record-level columns.
#' @details As in VegVault 1.0.0, the records are grouped by `datasource` and
#'   `plot_name` and nested, so the selected columns that are not nested
#'   (for example the coordinates) also define a row: a plot whose records
#'   differ in such a column becomes several rows. The function aborts when
#'   `datasource`, `plot_name` or a nested column is missing.
prepare_bien_plots <- function(
    data_bien_raw,
    vec_columns_selected,
    vec_columns_nested) {
  assertthat::assert_that(
    base::is.data.frame(data_bien_raw),
    msg = "`data_bien_raw` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(vec_columns_selected),
    base::length(vec_columns_selected) > 0L,
    msg = "`vec_columns_selected` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(vec_columns_nested),
    base::length(vec_columns_nested) > 0L,
    msg = "`vec_columns_nested` must be a non-empty character vector."
  )

  vec_columns_key <- c("datasource", "plot_name")

  vec_missing <-
    base::setdiff(
      c(vec_columns_key, vec_columns_nested),
      base::intersect(vec_columns_selected, base::names(data_bien_raw))
    )

  if (
    base::length(vec_missing) > 0L
  ) {
    cli::cli_abort(
      "The BIEN records lack the selected column{?s} {.val {vec_missing}}."
    )
  }

  res <-
    data_bien_raw |>
    dplyr::select(
      dplyr::any_of(vec_columns_selected)
    ) |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(vec_columns_key))
    ) |>
    tidyr::nest(
      plot_data = dplyr::all_of(vec_columns_nested)
    ) |>
    dplyr::ungroup()

  return(res)
}
