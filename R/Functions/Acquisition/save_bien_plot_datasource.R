#' @title Save one BIEN plot datasource
#' @description Download the plot records of one BIEN datasource and save
#'   them as a raw `.rds` file.
#' @param datasource Character. Name of one BIEN plot datasource, as listed
#'   by `BIEN::BIEN_plot_list_datasource()`.
#' @param dir_raw Character. Existing directory for the raw BIEN files.
#' @param date_save Date. Download date written into the file name.
#' @return The path of the written file (character).
#' @details The records come from `BIEN::BIEN_plot_datasource()` with
#'   `all.taxonomy`, `collection.info` and `all.metadata` set to `TRUE` and
#'   the package defaults otherwise (natives only, no cultivated records),
#'   as in VegVault 1.0.0. The file is named
#'   `<datasource>_<date>__<hash>__.rds`, where `<hash>` is `rlang::hash()`
#'   of the records, and written with gzip compression. The function aborts
#'   when `dir_raw` does not exist or a file for the datasource is already
#'   present, so that a raw file is never overwritten.
save_bien_plot_datasource <- function(
    datasource,
    dir_raw,
    date_save = Sys.Date()) {
  assertthat::assert_that(
    base::is.character(datasource),
    base::length(datasource) == 1L,
    !base::is.na(datasource),
    base::nzchar(datasource),
    msg = "`datasource` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(dir_raw),
    base::length(dir_raw) == 1L,
    !base::is.na(dir_raw),
    base::dir.exists(dir_raw),
    msg = "`dir_raw` must be the path of an existing directory."
  )

  assertthat::assert_that(
    base::inherits(date_save, "Date"),
    base::length(date_save) == 1L,
    !base::is.na(date_save),
    msg = "`date_save` must be a single Date."
  )

  vec_existing <-
    base::list.files(
      path = dir_raw,
      pattern = build_bien_raw_file_pattern(datasource = datasource)
    )

  if (
    base::length(vec_existing) > 0L
  ) {
    cli::cli_abort(
      c(
        "A raw file of BIEN datasource {.val {datasource}} is already present.",
        "x" = "{.file {vec_existing}}",
        "i" = "Raw files are never overwritten; remove the file deliberately to download again."
      )
    )
  }

  data_download <-
    BIEN::BIEN_plot_datasource(
      datasource = datasource,
      all.taxonomy = TRUE,
      collection.info = TRUE,
      all.metadata = TRUE
    )

  path_file <-
    base::file.path(
      dir_raw,
      stringr::str_c(
        datasource,
        "_",
        base::format(date_save, "%Y-%m-%d"),
        "__",
        rlang::hash(data_download),
        "__.rds"
      )
    )

  readr::write_rds(
    x = data_download,
    file = path_file,
    compress = "gz"
  )

  res <- path_file

  return(res)
}
