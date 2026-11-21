#' @title Prepare one coordinate pair per plot
#' @description Give the records of a plot that carry several nearby
#'   coordinate pairs the mean of those pairs.
#' @param data_records A data frame of records, one row per record.
#' @param vec_columns_plot Character vector. Columns that identify a plot.
#' @param col_longitude Character. Name of the numeric longitude column.
#' @param col_latitude Character. Name of the numeric latitude column.
#' @param max_spread Numeric. Largest difference, in degrees, between the
#'   longitudes or between the latitudes of a plot for which the mean is
#'   used.
#' @return A tibble with the columns, rows and row order of `data_records`.
#'   Only the coordinates of plots with more than one distinct complete pair
#'   within `max_spread` change.
#' @details The mean is taken over the distinct complete pairs (both values
#'   present), so it does not depend on how many records share a pair; when
#'   each subplot has one coordinate pair, it is the centre of the subplots.
#'   Records without a complete pair keep their coordinates. A plot whose
#'   pairs spread further than `max_spread` keeps its coordinates, so that
#'   distant locations are never averaged. The mean is not suited to plots
#'   that cross the antimeridian (longitudes near 180 and -180). Records with
#'   the same values in `vec_columns_plot`, missing values included, form
#'   one plot.
prepare_plot_coordinates <- function(
    data_records,
    vec_columns_plot,
    col_longitude = "longitude",
    col_latitude = "latitude",
    max_spread) {
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
    base::is.numeric(max_spread),
    base::length(max_spread) == 1L,
    !base::is.na(max_spread),
    max_spread >= 0,
    msg = "`max_spread` must be a single non-negative number."
  )

  vec_columns_coordinate <-
    c(col_longitude, col_latitude)

  vec_missing <-
    base::setdiff(
      c(vec_columns_plot, vec_columns_coordinate),
      base::names(data_records)
    )

  if (
    base::length(vec_missing) > 0L
  ) {
    cli::cli_abort(
      "The records lack the column{?s} {.val {vec_missing}}."
    )
  }

  if (
    isFALSE(base::is.numeric(data_records[[col_longitude]])) ||
      isFALSE(base::is.numeric(data_records[[col_latitude]]))
  ) {
    cli::cli_abort(
      "The coordinates {.field {vec_columns_coordinate}} must be numeric."
    )
  }

  # One row per distinct complete pair, so that the mean does not depend on
  #   how many records share a pair
  data_centre <-
    data_records |>
    dplyr::select(
      dplyr::all_of(c(vec_columns_plot, vec_columns_coordinate))
    ) |>
    dplyr::filter(
      !base::is.na(.data[[col_longitude]]),
      !base::is.na(.data[[col_latitude]])
    ) |>
    dplyr::distinct() |>
    dplyr::summarise(
      .n_pairs = dplyr::n(),
      # Guarded, because summarise() also evaluates an empty group
      .spread = if (dplyr::n() > 1L) {
        base::max(
          base::diff(base::range(.data[[col_longitude]])),
          base::diff(base::range(.data[[col_latitude]]))
        )
      } else {
        0
      },
      .longitude_mean = base::mean(.data[[col_longitude]]),
      .latitude_mean = base::mean(.data[[col_latitude]]),
      .by = dplyr::all_of(vec_columns_plot)
    ) |>
    dplyr::filter(
      .n_pairs > 1L,
      .spread <= max_spread
    ) |>
    dplyr::select(
      dplyr::all_of(vec_columns_plot),
      ".longitude_mean",
      ".latitude_mean"
    )

  res <-
    data_records |>
    dplyr::left_join(
      data_centre,
      by = vec_columns_plot,
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      .flag_centre = !base::is.na(.longitude_mean) &
        !base::is.na(.data[[col_longitude]]) &
        !base::is.na(.data[[col_latitude]]),
      dplyr::across(
        dplyr::all_of(col_longitude),
        ~ dplyr::if_else(.flag_centre, .longitude_mean, .x)
      ),
      dplyr::across(
        dplyr::all_of(col_latitude),
        ~ dplyr::if_else(.flag_centre, .latitude_mean, .x)
      )
    ) |>
    dplyr::select(
      -dplyr::all_of(c(".longitude_mean", ".latitude_mean", ".flag_centre"))
    ) |>
    tibble::as_tibble()

  return(res)
}
