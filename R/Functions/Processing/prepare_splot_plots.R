#' @title Prepare the sPlot plots
#' @description Nest the sPlotOpen taxon records by plot and join them to the
#'   plot table.
#' @param data_taxa A data frame of taxon records (`DT2.oa`) with the column
#'   `PlotObservationID`.
#' @param data_meta A data frame of plots (`header.oa`) with the column
#'   `PlotObservationID`.
#' @return A tibble with the columns of `data_meta` and a list-column `taxa`
#'   holding, per plot, a tibble of its taxon records without
#'   `PlotObservationID`.
#' @details The join is an inner join, as in VegVault 1.0.0: plots without
#'   taxon records and taxon records without a plot are dropped. Rows keep
#'   the order of `data_meta`, and records keep their order within a plot.
#'   The function aborts when a required column is missing.
prepare_splot_plots <- function(
    data_taxa,
    data_meta) {
  assertthat::assert_that(
    base::is.data.frame(data_taxa),
    msg = "`data_taxa` must be a data frame."
  )

  assertthat::assert_that(
    base::is.data.frame(data_meta),
    msg = "`data_meta` must be a data frame."
  )

  assertthat::assert_that(
    assertthat::has_name(data_taxa, "PlotObservationID"),
    msg = "`data_taxa` must have the column `PlotObservationID`."
  )

  assertthat::assert_that(
    assertthat::has_name(data_meta, "PlotObservationID"),
    msg = "`data_meta` must have the column `PlotObservationID`."
  )

  data_taxa_nested <-
    tidyr::nest(
      data_taxa,
      .by = "PlotObservationID",
      .key = "taxa"
    )

  res <-
    dplyr::inner_join(
      data_meta,
      data_taxa_nested,
      by = "PlotObservationID",
      relationship = "one-to-one"
    ) |>
    tibble::as_tibble()

  return(res)
}
