#' @title Prepare the BIEN plot identifier
#' @description Add `plot_id`, built from the datasource and the plot name,
#'   as the first column.
#' @param data_plots A data frame of BIEN plots, one row per plot.
#' @param col_datasource Character. Name of the datasource column.
#' @param col_plot_name Character. Name of the plot-name column.
#' @param separator Character. Text placed between the two parts.
#' @return A tibble with the column `plot_id` (character) first, followed by
#'   the columns of `data_plots`; rows and their order are unchanged.
#' @details `plot_id` is `<datasource><separator><plot_name>`, for example
#'   `CTFS__Plot 31`. It depends only on these two source values, never on
#'   the row order or on BIEN's internal identifiers, so it stays the same
#'   when rows are added, removed or reordered. The function aborts when a
#'   part is missing or empty, when two rows get the same `plot_id` (a plot
#'   split over several rows), or when `data_plots` already has a column
#'   `plot_id`.
prepare_bien_plot_id <- function(
    data_plots,
    col_datasource = "datasource",
    col_plot_name = "plot_name",
    separator = "__") {
  assertthat::assert_that(
    base::is.data.frame(data_plots),
    msg = "`data_plots` must be a data frame."
  )

  assertthat::assert_that(
    assertthat::is.string(col_datasource),
    assertthat::is.string(col_plot_name),
    assertthat::is.string(separator),
    msg = "The column names and `separator` must be single strings."
  )

  vec_missing <-
    base::setdiff(c(col_datasource, col_plot_name), base::names(data_plots))

  if (
    base::length(vec_missing) > 0L
  ) {
    cli::cli_abort(
      "The plots lack the column{?s} {.val {vec_missing}}."
    )
  }

  if (
    "plot_id" %in% base::names(data_plots)
  ) {
    cli::cli_abort(
      "The plots already have a column {.field plot_id}."
    )
  }

  vec_datasource <-
    base::as.character(data_plots[[col_datasource]])

  vec_plot_name <-
    base::as.character(data_plots[[col_plot_name]])

  n_incomplete <-
    base::sum(
      base::is.na(vec_datasource) | vec_datasource == "" |
        base::is.na(vec_plot_name) | vec_plot_name == ""
    )

  if (
    n_incomplete > 0L
  ) {
    cli::cli_abort(
      stringr::str_c(
        "{n_incomplete} plot{?s} {?has/have} a missing or empty ",
        "datasource or plot name."
      )
    )
  }

  vec_plot_id <-
    stringr::str_c(vec_datasource, separator, vec_plot_name)

  vec_repeated <-
    base::unique(vec_plot_id[base::duplicated(vec_plot_id)])

  if (
    base::length(vec_repeated) > 0L
  ) {
    vec_repeated_first <- utils::head(vec_repeated, 5)

    cli::cli_abort(
      c(
        stringr::str_c(
          "{base::length(vec_repeated)} plot_id{?s} occur{?s/} in several ",
          "rows: {.val {vec_repeated_first}}."
        ),
        "i" = "A plot split over several rows must be merged before export."
      )
    )
  }

  res <-
    data_plots |>
    dplyr::mutate(plot_id = vec_plot_id, .before = 1) |>
    tibble::as_tibble()

  return(res)
}
