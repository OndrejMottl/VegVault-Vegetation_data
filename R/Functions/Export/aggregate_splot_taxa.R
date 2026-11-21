#' @title Aggregate sPlot taxon records to one row per taxon and plot
#' @description Merge the nested taxon records of one taxon in one plot into
#'   one record with the approved sPlot rules.
#' @param data_plots A data frame of sPlot plots, one row per plot, with a
#'   list column of taxon records.
#' @param col_taxa Character. Name of the list column with the records.
#' @param col_taxon Character. Name of the taxon-name column in the records.
#' @param col_scale Character. Name of the abundance-scale column.
#' @param col_abundance Character. Name of the numeric abundance column.
#' @param col_relative_cover Character. Name of the numeric relative-cover
#'   column.
#' @param col_original_name Character. Name of the original-name column.
#' @param scale_presence,scale_cover,vec_scales_summed,vec_scales_maximum
#'   Abundance scales and their rules, passed to
#'   `compute_merged_abundance()`.
#' @param separator Character. Text placed between joined original names.
#' @return A tibble with the columns and rows of `data_plots`. In each
#'   element of `col_taxa`, the records of a repeated taxon are replaced by
#'   one record at the position of the first; the other records, the
#'   columns and their classes are unchanged.
#' @details For a taxon with several records in a plot: presence-only
#'   records (`scale_presence`) are dropped when a record on another scale
#'   exists; the remaining records must share one scale, and their
#'   abundance is merged by `compute_merged_abundance()`; the relative cover
#'   is the sum of the non-missing values (missing when all are missing);
#'   the original names keep their distinct non-missing values, sorted and
#'   joined with `separator`. Elements without a repeated taxon are returned
#'   unchanged. The function aborts when a column is missing, a record
#'   column has no merge rule, or a repeated taxon keeps two scales.
aggregate_splot_taxa <- function(
    data_plots,
    col_taxa = "taxa",
    col_taxon = "Species",
    col_scale = "Abundance_scale",
    col_abundance = "Original_abundance",
    col_relative_cover = "Relative_cover",
    col_original_name = "Original_species",
    scale_presence = "pa",
    scale_cover = "CoverPerc",
    vec_scales_summed = c("x_IC", "x_SC", "x_BA"),
    vec_scales_maximum = c("x_IV", "x_PF"),
    separator = " | ") {
  assertthat::assert_that(
    base::is.data.frame(data_plots),
    msg = "`data_plots` must be a data frame."
  )

  vec_columns_record <-
    c(
      col_taxon, col_scale, col_abundance, col_relative_cover,
      col_original_name
    )

  assertthat::assert_that(
    assertthat::is.string(col_taxa),
    base::is.character(vec_columns_record),
    base::length(vec_columns_record) == 5L,
    assertthat::is.string(separator),
    msg = "The column names and `separator` must be single strings."
  )

  if (
    isFALSE(col_taxa %in% base::names(data_plots))
  ) {
    cli::cli_abort(
      "The plots lack the column {.val {col_taxa}}."
    )
  }

  list_taxa <-
    data_plots[[col_taxa]]

  if (
    isFALSE(base::is.list(list_taxa)) ||
      isFALSE(base::all(purrr::map_lgl(list_taxa, base::is.data.frame)))
  ) {
    cli::cli_abort(
      "The column {.field {col_taxa}} must be a list of data frames."
    )
  }

  if (
    base::length(list_taxa) == 0L
  ) {
    res <-
      tibble::as_tibble(data_plots)

    return(res)
  }

  vec_names_found <-
    purrr::map(.x = list_taxa, .f = base::names) |>
    base::unlist() |>
    base::unique()

  vec_missing <-
    base::setdiff(vec_columns_record, vec_names_found)

  flag_complete <-
    purrr::map_lgl(
      .x = list_taxa,
      .f = ~ base::all(vec_columns_record %in% base::names(.x))
    )

  if (
    base::length(vec_missing) > 0L || isFALSE(base::all(flag_complete))
  ) {
    vec_missing_any <-
      base::setdiff(
        vec_columns_record,
        base::Reduce(base::intersect, purrr::map(list_taxa, base::names))
      )

    cli::cli_abort(
      "The taxon records lack the column{?s} {.val {vec_missing_any}}."
    )
  }

  vec_without_rule <-
    base::setdiff(vec_names_found, vec_columns_record)

  if (
    base::length(vec_without_rule) > 0L
  ) {
    cli::cli_abort(
      "Taxon column{?s} {.val {vec_without_rule}} {?has/have} no merge rule."
    )
  }

  vec_rows_repeated <-
    purrr::map_lgl(
      .x = list_taxa,
      .f = ~ base::anyDuplicated(.x[[col_taxon]]) > 0L
    ) |>
    base::which()

  if (
    base::length(vec_rows_repeated) == 0L
  ) {
    res <-
      tibble::as_tibble(data_plots)

    return(res)
  }

  vec_names_taxa <-
    base::names(list_taxa[[vec_rows_repeated[1]]])

  data_long <-
    tibble::tibble(
      .plot_row = vec_rows_repeated,
      .taxa = list_taxa[vec_rows_repeated]
    ) |>
    tidyr::unnest(cols = ".taxa") |>
    dplyr::mutate(
      .row = dplyr::row_number(),
      .by = ".plot_row"
    ) |>
    dplyr::mutate(
      .n_records = dplyr::n(),
      .row_first = base::min(.row),
      .by = dplyr::all_of(c(".plot_row", col_taxon))
    )

  data_single <-
    data_long |>
    dplyr::filter(.n_records == 1L)

  # Rule 1: a presence-only record gives way to a measured one
  data_repeated <-
    data_long |>
    dplyr::filter(.n_records > 1L) |>
    dplyr::filter(
      !(
        .data[[col_scale]] %in% scale_presence &
          base::any(!(.data[[col_scale]] %in% scale_presence))
      ),
      .by = dplyr::all_of(c(".plot_row", col_taxon))
    )

  data_two_scales <-
    data_repeated |>
    dplyr::summarise(
      .n_scales = dplyr::n_distinct(.data[[col_scale]]),
      .by = dplyr::all_of(c(".plot_row", col_taxon))
    ) |>
    dplyr::filter(.n_scales > 1L)

  if (
    base::nrow(data_two_scales) > 0L
  ) {
    n_cases <- base::nrow(data_two_scales)
    name_first <- data_two_scales[[col_taxon]][1]
    row_first <- data_two_scales[[".plot_row"]][1]

    cli::cli_abort(
      c(
        "A repeated taxon keeps records on two measured abundance scales.",
        "x" = stringr::str_c(
          "{n_cases} case{?s}; the first is {.val {name_first}} ",
          "in plot row {row_first}."
        )
      )
    )
  }

  data_merged <-
    data_repeated |>
    dplyr::summarise(
      .row = .row_first[1],
      "{col_scale}" := .data[[col_scale]][1],
      "{col_abundance}" := compute_merged_abundance(
        vec_abundance = .data[[col_abundance]],
        scale = .data[[col_scale]][1],
        scale_presence = scale_presence,
        scale_cover = scale_cover,
        vec_scales_summed = vec_scales_summed,
        vec_scales_maximum = vec_scales_maximum
      ),
      "{col_relative_cover}" := if (
        base::all(base::is.na(.data[[col_relative_cover]]))
      ) {
        .data[[col_relative_cover]][1]
      } else {
        base::sum(.data[[col_relative_cover]], na.rm = TRUE)
      },
      "{col_original_name}" := {
        # sPlotOpen marks its non-ASCII names as native ("unknown"), which
        #   the locale-independent radix sort rejects; enc2utf8() marks
        #   them as UTF-8 without changing their bytes.
        vec_names <-
          base::enc2utf8(.data[[col_original_name]])

        vec_values <-
          base::sort(
            base::unique(vec_names[!base::is.na(vec_names)]),
            method = "radix"
          )

        if (base::length(vec_values) == 0L) {
          NA_character_
        } else {
          base::paste(vec_values, collapse = separator)
        }
      },
      .by = dplyr::all_of(c(".plot_row", col_taxon))
    )

  data_nested <-
    dplyr::bind_rows(data_single, data_merged) |>
    dplyr::arrange(.plot_row, .row) |>
    dplyr::select(".plot_row", dplyr::all_of(vec_names_taxa)) |>
    tidyr::nest(.taxa = -".plot_row")

  list_taxa[dplyr::pull(data_nested, .plot_row)] <-
    dplyr::pull(data_nested, .taxa)

  res <-
    data_plots |>
    tibble::as_tibble()

  res[[col_taxa]] <- list_taxa

  return(res)
}
