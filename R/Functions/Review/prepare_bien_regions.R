#' @title Prepare BIEN plots with a coarse region
#' @description Add a column `region` that assigns each BIEN plot to North
#'   America, Latin America or Other by its coordinates.
#' @param data_plots A data frame of BIEN plots with the numeric columns
#'   `longitude` and `latitude` (decimal degrees).
#' @return `data_plots` as a tibble with the added character column
#'   `region`.
#' @details The rule is the one of the VegVault 1.0.0 review: west of 40 W,
#'   a plot north of 18 N is "North America" and one south of 18 N is
#'   "Latin America"; every other plot, including those at exactly 18 N or
#'   with a missing coordinate, is "Other". The regions serve the review of
#'   plot sizes only. The function aborts when a coordinate column is
#'   missing.
prepare_bien_regions <- function(data_plots) {
  assertthat::assert_that(
    base::is.data.frame(data_plots),
    msg = "`data_plots` must be a data frame."
  )

  vec_missing <-
    base::setdiff(c("longitude", "latitude"), base::names(data_plots))

  if (
    base::length(vec_missing) > 0L
  ) {
    cli::cli_abort("The BIEN plots lack the column{?s} {.val {vec_missing}}.")
  }

  res <-
    data_plots |>
    dplyr::mutate(
      region = dplyr::case_when(
        .data$latitude > 18 & .data$longitude < -40 ~ "North America",
        .data$latitude < 18 & .data$longitude < -40 ~ "Latin America",
        .default = "Other"
      )
    ) |>
    tibble::as_tibble()

  return(res)
}
