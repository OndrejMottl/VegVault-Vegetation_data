#' @title Select the plots of the most common size
#' @description Keep, for the chosen groups, the plots whose size is the most
#'   common size of their group.
#' @param data_plots A data frame of plots.
#' @param data_common_size A tibble from `summarise_common_plot_size()` with
#'   the columns `group` and `plot_area`.
#' @param col_group Character. Name of the grouping column of `data_plots`.
#' @param col_area Character. Name of the plot-size column of `data_plots`.
#' @param vec_groups Character vector. Groups to keep.
#' @return A tibble with the rows of `data_plots` that belong to one of
#'   `vec_groups` and have that group's most common size, in their original
#'   order.
#' @details Sizes are compared exactly, as in the VegVault 1.0.0 review. The
#'   function aborts when a named column is missing or a group of
#'   `vec_groups` is not in `data_common_size`.
select_common_size_plots <- function(
    data_plots,
    data_common_size,
    col_group,
    col_area,
    vec_groups) {
  assertthat::assert_that(
    base::is.data.frame(data_plots),
    base::is.data.frame(data_common_size),
    msg = "`data_plots` and `data_common_size` must be data frames."
  )

  assertthat::assert_that(
    base::is.character(vec_groups),
    base::length(vec_groups) > 0L,
    msg = "`vec_groups` must be a non-empty character vector."
  )

  vec_missing <-
    c(
      base::setdiff(c(col_group, col_area), base::names(data_plots)),
      base::setdiff(c("group", "plot_area"), base::names(data_common_size))
    )

  if (
    base::length(vec_missing) > 0L
  ) {
    cli::cli_abort("The inputs lack the column{?s} {.val {vec_missing}}.")
  }

  vec_groups_unknown <-
    base::setdiff(vec_groups, data_common_size$group)

  if (
    base::length(vec_groups_unknown) > 0L
  ) {
    cli::cli_abort(
      "No common plot size is known for the group{?s} {.val {vec_groups_unknown}}."
    )
  }

  data_common_selected <-
    data_common_size |>
    dplyr::filter(.data$group %in% vec_groups) |>
    dplyr::select("group", "plot_area")

  res <-
    data_plots |>
    dplyr::semi_join(
      data_common_selected,
      by = rlang::set_names(c("group", "plot_area"), c(col_group, col_area))
    ) |>
    tibble::as_tibble()

  return(res)
}
