#' @title Summarise the most common plot size per group
#' @description Find, for each group of plots (for example a continent), the
#'   plot size shared by the most plots.
#' @param data_plots A data frame of plots.
#' @param col_group Character. Name of the grouping column.
#' @param col_area Character. Name of the plot-size column.
#' @param vec_columns_plot Character vector. Columns that identify a plot;
#'   rows that agree on these columns, the group and the size count once.
#' @return A tibble with one row per group and the columns `group`,
#'   `plot_area` and `n_plots` (the number of plots of that size), sorted
#'   by `group`.
#' @details Rows with a missing group or size are ignored. When several
#'   sizes are equally common in a group, the smallest is reported. The
#'   unit of `plot_area` is that of `col_area`. The function aborts when a
#'   named column is missing.
summarise_common_plot_size <- function(
    data_plots,
    col_group,
    col_area,
    vec_columns_plot) {
  assertthat::assert_that(
    base::is.data.frame(data_plots),
    msg = "`data_plots` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(col_group),
    base::length(col_group) == 1L,
    base::is.character(col_area),
    base::length(col_area) == 1L,
    base::is.character(vec_columns_plot),
    base::length(vec_columns_plot) > 0L,
    msg = paste(
      "`col_group` and `col_area` must be single column names and",
      "`vec_columns_plot` a non-empty character vector."
    )
  )

  vec_columns_used <-
    base::unique(c(vec_columns_plot, col_group, col_area))

  vec_missing <-
    base::setdiff(vec_columns_used, base::names(data_plots))

  if (
    base::length(vec_missing) > 0L
  ) {
    cli::cli_abort("The plots lack the column{?s} {.val {vec_missing}}.")
  }

  res <-
    data_plots |>
    tidyr::drop_na(dplyr::all_of(c(col_group, col_area))) |>
    dplyr::distinct(dplyr::across(dplyr::all_of(vec_columns_used))) |>
    dplyr::count(
      group = .data[[col_group]],
      plot_area = .data[[col_area]],
      name = "n_plots"
    ) |>
    dplyr::arrange(
      .data$group,
      dplyr::desc(.data$n_plots),
      .data$plot_area
    ) |>
    dplyr::distinct(.data$group, .keep_all = TRUE) |>
    tibble::as_tibble()

  return(res)
}
