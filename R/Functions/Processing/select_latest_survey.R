#' @title Select the latest survey of each plot
#' @description Keep, for every plot, only the records of its latest survey
#'   year.
#' @param data_records A data frame of records, one row per record.
#' @param vec_columns_plot Character vector. Columns that identify a plot.
#' @param col_date Character. Name of the `Date` column with the survey date
#'   of each record.
#' @return A tibble with the columns of `data_records` and, for every plot,
#'   the records of its latest survey year, in their original order.
#' @details The survey year is the calendar year of `col_date`, so the
#'   records of one survey that took several days stay together. A plot
#'   whose records are all undated keeps all of them, as one survey. In a
#'   plot with dated records, an undated record cannot be assigned to a
#'   survey and is dropped with the earlier years. Records with the same
#'   values in `vec_columns_plot`, missing values included, form one plot.
#'   Keeping one survey stops a plot that was surveyed repeatedly (for
#'   example TEAM, every year) from counting the same individual more than
#'   once when its records are merged.
select_latest_survey <- function(
    data_records,
    vec_columns_plot,
    col_date) {
  assertthat::assert_that(
    base::is.data.frame(data_records),
    msg = "`data_records` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(vec_columns_plot),
    base::length(vec_columns_plot) > 0L,
    msg = "`vec_columns_plot` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(col_date),
    base::length(col_date) == 1L,
    !base::is.na(col_date),
    msg = "`col_date` must be a single column name."
  )

  vec_missing <-
    base::setdiff(c(vec_columns_plot, col_date), base::names(data_records))

  if (
    base::length(vec_missing) > 0L
  ) {
    cli::cli_abort(
      "The records lack the column{?s} {.val {vec_missing}}."
    )
  }

  if (
    isFALSE(base::inherits(data_records[[col_date]], "Date"))
  ) {
    cli::cli_abort(
      "The survey date {.field {col_date}} must be of class {.cls Date}."
    )
  }

  vec_year <-
    base::as.integer(base::format(data_records[[col_date]], "%Y"))

  res <-
    data_records |>
    dplyr::mutate(.year_survey = vec_year) |>
    dplyr::filter(
      base::all(base::is.na(.year_survey)) |
        (
          !base::is.na(.year_survey) &
            .year_survey == base::suppressWarnings(
              base::max(.year_survey, na.rm = TRUE)
            )
        ),
      .by = dplyr::all_of(vec_columns_plot)
    ) |>
    dplyr::select(-".year_survey") |>
    tibble::as_tibble()

  return(res)
}
