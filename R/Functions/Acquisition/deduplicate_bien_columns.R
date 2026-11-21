#' @title Deduplicate repeated BIEN columns
#' @description Collapse the columns that share a name into one column,
#'   after checking that their copies hold the same values.
#' @param data_raw A data frame of BIEN records as returned by the BIEN
#'   package; several of its columns may share a name.
#' @return A tibble with one column per name. The first copy of a repeated
#'   column is kept at its position; the other columns and all rows are
#'   unchanged.
#' @details `BIEN::BIEN_plot_datasource()` with `collection.info` and
#'   `all.metadata` returns `recorded_by` and `date_collected` twice. Without
#'   this step, binding the datasources renames the copies by their position
#'   (for example `date_collected...30`), so later steps could not rely on
#'   the column name. Copies agree when they are identical, missing values
#'   and classes included. The function aborts when the copies of a name
#'   differ, because it cannot tell which one is right.
deduplicate_bien_columns <- function(data_raw) {
  assertthat::assert_that(
    base::is.data.frame(data_raw),
    msg = "`data_raw` must be a data frame."
  )

  vec_names <-
    base::names(data_raw)

  vec_names_repeated <-
    base::unique(vec_names[base::duplicated(vec_names)])

  list_columns <-
    base::as.list(data_raw)

  vec_names_differing <-
    purrr::keep(
      .x = vec_names_repeated,
      .p = ~ base::length(
        base::unique(base::unname(list_columns[vec_names == .x]))
      ) > 1L
    )

  if (
    base::length(vec_names_differing) > 0L
  ) {
    cli::cli_abort(
      c(
        "Copies of the BIEN column{?s} {.val {vec_names_differing}} differ.",
        "i" = "Without one value per record, the right copy is unknown."
      )
    )
  }

  res <-
    data_raw[, !base::duplicated(vec_names), drop = FALSE] |>
    tibble::as_tibble()

  return(res)
}
