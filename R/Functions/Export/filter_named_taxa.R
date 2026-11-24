#' @title Filter taxon records without a name
#' @description Drop the nested taxon records whose name is missing or empty,
#'   then drop the plots left without any named record.
#' @param data_plots A data frame of plots, one row per plot, with a list
#'   column that holds one data frame of taxon records per plot.
#' @param col_taxa Character. Name of the list column with the taxon records.
#' @param col_taxon_name Character. Name of the taxon-name column inside each
#'   element of `col_taxa`.
#' @return A tibble with the columns of `data_plots`. Each element of
#'   `col_taxa` keeps only its named records, and plots without a named
#'   record are removed. The order of plots, records and columns is kept.
#' @details A record is unnamed when its name is `NA` or the empty string
#'   `""`, the two cases the VegVault producer contract rejects
#'   (`value_missing` and `value_empty`). Text made only of spaces is kept,
#'   because the contract accepts it. A plot is dropped when none of its
#'   records is named, including a plot with no records at all, because the
#'   contract requires at least one taxon record per plot. Elements without
#'   unnamed records are returned unchanged. The function aborts when an
#'   element of `col_taxa` is not a data frame with the column
#'   `col_taxon_name`.
filter_named_taxa <- function(
    data_plots,
    col_taxa = "taxa",
    col_taxon_name = "Species") {
  assertthat::assert_that(
    base::is.data.frame(data_plots),
    msg = "`data_plots` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(col_taxa),
    base::length(col_taxa) == 1L,
    !base::is.na(col_taxa),
    msg = "`col_taxa` must be a single column name."
  )

  assertthat::assert_that(
    base::is.character(col_taxon_name),
    base::length(col_taxon_name) == 1L,
    !base::is.na(col_taxon_name),
    msg = "`col_taxon_name` must be a single column name."
  )

  assertthat::assert_that(
    col_taxa %in% base::names(data_plots),
    msg = stringr::str_c(
      "`data_plots` must contain the column '", col_taxa, "'."
    )
  )

  list_taxa <-
    dplyr::pull(data_plots, dplyr::all_of(col_taxa))

  if (
    isFALSE(base::is.list(list_taxa))
  ) {
    cli::cli_abort(
      "The column {.field {col_taxa}} must be a list of data frames."
    )
  }

  vec_malformed <-
    purrr::map_lgl(
      .x = list_taxa,
      .f = ~ isFALSE(base::is.data.frame(.x)) ||
        isFALSE(col_taxon_name %in% base::names(.x))
    ) |>
    base::which()

  if (
    base::length(vec_malformed) > 0L
  ) {
    n_malformed <- base::length(vec_malformed)
    row_first <- vec_malformed[1]

    cli::cli_abort(
      c(
        stringr::str_c(
          "Every element of {.field {col_taxa}} must be a data frame ",
          "with the column {.field {col_taxon_name}}."
        ),
        "x" = "{n_malformed} plot{?s} fail{?s/}, the first in row {row_first}."
      )
    )
  }

  list_taxa_named <-
    purrr::map(
      .x = list_taxa,
      .f = ~ {
        vec_names <- .x[[col_taxon_name]]
        flag_named <- !base::is.na(vec_names) & vec_names != ""

        if (
          base::all(flag_named)
        ) {
          return(.x)
        }

        .x[flag_named, , drop = FALSE]
      }
    )

  flag_keep <-
    purrr::map_lgl(
      .x = list_taxa_named,
      .f = ~ base::nrow(.x) > 0L
    )

  data_named <-
    data_plots

  data_named[[col_taxa]] <- list_taxa_named

  res <-
    data_named[flag_keep, , drop = FALSE] |>
    tibble::as_tibble()

  return(res)
}
