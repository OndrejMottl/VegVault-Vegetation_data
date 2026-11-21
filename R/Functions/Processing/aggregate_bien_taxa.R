#' @title Aggregate BIEN records to one row per taxon and plot
#' @description Merge the BIEN records of one taxon in one plot into one
#'   record: the counts are summed, record-level values are joined, and
#'   taxon-level values must agree.
#' @param data_records A data frame of BIEN records, one row per record.
#' @param vec_columns_plot Character vector. Plot-level columns; together
#'   they identify a plot.
#' @param col_taxon Character. Name of the taxon-name column.
#' @param col_count Character. Name of the numeric count column.
#' @param vec_columns_joined Character vector. Character columns whose
#'   distinct values are joined (record-level columns such as `subplot`).
#' @param vec_columns_agreeing Character vector. Taxon-level columns that
#'   must hold one value within a taxon and plot.
#' @param separator Character. Text placed between joined values.
#' @return A tibble with one row per plot and taxon and the columns of
#'   `data_records` named in the other arguments, in their input order.
#'   Rows are sorted by `vec_columns_plot` and `col_taxon`.
#' @details The count is the sum of the non-missing counts and stays missing
#'   when no record has one. Every record counts, identical records
#'   included, because BIEN gives no record identity to tell a repeated
#'   listing from a second individual. Joined columns keep their distinct
#'   non-missing values, sorted, joined with `separator`, and stay missing
#'   when all are missing. Agreeing columns keep their single value. A taxon
#'   with one record in a plot is returned unchanged. Columns not named in
#'   any argument are dropped, because they have no merge rule. The result
#'   does not depend on the input row order. The function aborts when a
#'   column is missing or named in two roles, a joined column is not
#'   character, a record lacks a taxon name, or an agreeing column holds
#'   two values (a missing value counts as a value) within a taxon and plot.
aggregate_bien_taxa <- function(
    data_records,
    vec_columns_plot,
    col_taxon = "name_matched",
    col_count = "individual_count",
    vec_columns_joined,
    vec_columns_agreeing,
    separator = " | ") {
  assertthat::assert_that(
    base::is.data.frame(data_records),
    msg = "`data_records` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(vec_columns_plot),
    base::length(vec_columns_plot) > 0L,
    base::is.character(vec_columns_joined),
    base::is.character(vec_columns_agreeing),
    msg = "The column arguments must be character vectors."
  )

  assertthat::assert_that(
    assertthat::is.string(col_taxon),
    assertthat::is.string(col_count),
    assertthat::is.string(separator),
    msg = "`col_taxon`, `col_count` and `separator` must be single strings."
  )

  vec_columns_group <-
    c(vec_columns_plot, col_taxon)

  vec_columns_rule <-
    c(vec_columns_group, col_count, vec_columns_joined, vec_columns_agreeing)

  vec_columns_twice <-
    base::unique(vec_columns_rule[base::duplicated(vec_columns_rule)])

  if (
    base::length(vec_columns_twice) > 0L
  ) {
    cli::cli_abort(
      "The column{?s} {.val {vec_columns_twice}} {?is/are} named in two roles."
    )
  }

  vec_missing <-
    base::setdiff(vec_columns_rule, base::names(data_records))

  if (
    base::length(vec_missing) > 0L
  ) {
    cli::cli_abort(
      "The BIEN records lack the column{?s} {.val {vec_missing}}."
    )
  }

  vec_not_character <-
    purrr::discard(
      .x = vec_columns_joined,
      .p = ~ base::is.character(data_records[[.x]])
    )

  if (
    base::length(vec_not_character) > 0L
  ) {
    cli::cli_abort(
      "The joined column{?s} {.val {vec_not_character}} must be character."
    )
  }

  vec_taxon <-
    data_records[[col_taxon]]

  n_unnamed <-
    base::sum(base::is.na(vec_taxon) | vec_taxon == "")

  if (
    n_unnamed > 0L
  ) {
    cli::cli_abort(
      c(
        "Every BIEN record must have a taxon name in {.field {col_taxon}}.",
        "x" = "{n_unnamed} record{?s} {?has/have} none."
      )
    )
  }

  vec_columns_keep <-
    base::names(data_records)[base::names(data_records) %in% vec_columns_rule]

  data_sized <-
    data_records |>
    dplyr::select(dplyr::all_of(vec_columns_keep)) |>
    dplyr::mutate(
      .n_records = dplyr::n(),
      .by = dplyr::all_of(vec_columns_group)
    )

  # A taxon with one record in a plot needs no merge
  data_single <-
    data_sized |>
    dplyr::filter(.n_records == 1L) |>
    dplyr::select(-".n_records")

  data_repeated <-
    data_sized |>
    dplyr::filter(.n_records > 1L) |>
    dplyr::select(-".n_records")

  data_disagreeing <-
    tibble::tibble(column = base::character(0))

  if (
    base::length(vec_columns_agreeing) > 0L
  ) {
    data_disagreeing <-
      data_repeated |>
      dplyr::summarise(
        dplyr::across(
          dplyr::all_of(vec_columns_agreeing),
          ~ dplyr::n_distinct(.x)
        ),
        .by = dplyr::all_of(vec_columns_group)
      ) |>
      tidyr::pivot_longer(
        cols = dplyr::all_of(vec_columns_agreeing),
        names_to = "column",
        values_to = "n_values"
      ) |>
      dplyr::filter(n_values > 1L)
  }

  if (
    base::nrow(data_disagreeing) > 0L
  ) {
    vec_columns_disagreeing <-
      base::unique(dplyr::pull(data_disagreeing, column))

    n_cases <- base::nrow(data_disagreeing)
    name_first <- data_disagreeing[[col_taxon]][1]

    cli::cli_abort(
      c(
        stringr::str_c(
          "Taxon-level column{?s} {.val {vec_columns_disagreeing}} ",
          "disagree{?s/} within a taxon and plot."
        ),
        "x" = "{n_cases} case{?s}; the first taxon is {.val {name_first}}."
      )
    )
  }

  data_merged <-
    data_repeated |>
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(col_count),
        ~ if (base::all(base::is.na(.x))) .x[1] else base::sum(.x, na.rm = TRUE)
      ),
      dplyr::across(
        dplyr::all_of(vec_columns_joined),
        ~ {
          # Text marked as native ("unknown") with non-ASCII characters is
          #   rejected by the locale-independent radix sort; enc2utf8()
          #   marks it as UTF-8 without changing its bytes.
          vec_text <-
            base::enc2utf8(.x)

          vec_values <-
            base::sort(
              base::unique(vec_text[!base::is.na(vec_text)]),
              method = "radix"
            )

          if (base::length(vec_values) == 0L) {
            NA_character_
          } else {
            base::paste(vec_values, collapse = separator)
          }
        }
      ),
      dplyr::across(
        dplyr::all_of(vec_columns_agreeing),
        ~ .x[1]
      ),
      .by = dplyr::all_of(vec_columns_group)
    )

  res <-
    dplyr::bind_rows(data_single, data_merged) |>
    dplyr::select(dplyr::all_of(vec_columns_keep)) |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(vec_columns_group))
    ) |>
    tibble::as_tibble()

  return(res)
}
