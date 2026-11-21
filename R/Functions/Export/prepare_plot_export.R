#' @title Prepare plots for export
#' @description Drop incomplete plots, clean the column names and sort the
#'   rows into the documented export order.
#' @param data_plots A data frame of plots, one row per plot.
#' @param vec_columns_required Character vector. Columns (names before
#'   cleaning) that must not be missing; plots missing any are dropped.
#' @param vec_columns_order Character vector. Columns (names after cleaning)
#'   that define the row order, sorted ascending in the given priority.
#' @return A tibble with the complete plots, column names cleaned with
#'   `janitor::clean_names()`, sorted by `vec_columns_order`.
#' @details Only top-level column names are cleaned; nested data frames keep
#'   their names. The sort makes the row order independent of the order in
#'   which a source delivered its records. The function aborts when a
#'   required or ordering column is missing.
prepare_plot_export <- function(
    data_plots,
    vec_columns_required,
    vec_columns_order) {
  assertthat::assert_that(
    base::is.data.frame(data_plots),
    msg = "`data_plots` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(vec_columns_required),
    base::length(vec_columns_required) > 0L,
    msg = "`vec_columns_required` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(vec_columns_order),
    base::length(vec_columns_order) > 0L,
    msg = "`vec_columns_order` must be a non-empty character vector."
  )

  vec_missing_required <-
    base::setdiff(vec_columns_required, base::names(data_plots))

  if (
    base::length(vec_missing_required) > 0L
  ) {
    cli::cli_abort(
      "The plots lack the required column{?s} {.val {vec_missing_required}}."
    )
  }

  data_clean <-
    data_plots |>
    tidyr::drop_na(
      dplyr::all_of(vec_columns_required)
    ) |>
    janitor::clean_names()

  vec_missing_order <-
    base::setdiff(vec_columns_order, base::names(data_clean))

  if (
    base::length(vec_missing_order) > 0L
  ) {
    cli::cli_abort(
      c(
        "The cleaned plots lack the ordering column{?s} {.val {vec_missing_order}}.",
        "i" = "Ordering columns use the names after {.fn janitor::clean_names}."
      )
    )
  }

  res <-
    data_clean |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(vec_columns_order))
    ) |>
    tibble::as_tibble()

  return(res)
}
