#' @title Resolve the raw file of one BIEN plot datasource
#' @description Find the one raw file of a BIEN plot datasource, downloading
#'   it first only when it is missing and downloading is enabled.
#' @param dir_raw Character. Directory of the raw BIEN files.
#' @param datasource Character. Name of one BIEN plot datasource.
#' @param flag_download Logical. `TRUE` when a missing file may be
#'   downloaded with `save_bien_plot_datasource()`.
#' @return The path of the datasource's raw file (character).
#' @details A raw file is named `<datasource>_<YYYY-MM-DD>__<32 hex>__.rds`.
#'   The name must match exactly, so other datasources whose names contain
#'   this one, sub-folders and unrelated files are never picked. The function
#'   aborts when more than one file matches (it never chooses "the latest")
#'   and, with `flag_download = FALSE`, when none matches, naming the flag
#'   that enables the download. An existing file is never downloaded again.
resolve_bien_raw_file <- function(
    dir_raw,
    datasource,
    flag_download) {
  assertthat::assert_that(
    base::is.character(dir_raw),
    base::length(dir_raw) == 1L,
    !base::is.na(dir_raw),
    base::dir.exists(dir_raw),
    msg = "`dir_raw` must be the path of an existing directory."
  )

  assertthat::assert_that(
    base::is.logical(flag_download),
    base::length(flag_download) == 1L,
    !base::is.na(flag_download),
    msg = "`flag_download` must be TRUE or FALSE."
  )

  vec_matching <-
    base::list.files(
      path = dir_raw,
      pattern = build_bien_raw_file_pattern(datasource = datasource),
      full.names = TRUE
    )

  vec_files <-
    vec_matching[!base::dir.exists(vec_matching)]

  if (
    base::length(vec_files) > 1L
  ) {
    cli::cli_abort(
      c(
        "BIEN datasource {.val {datasource}} has more than one raw file.",
        "x" = "{.file {base::basename(vec_files)}}",
        "i" = "Keep exactly one file per datasource; the pipeline never chooses between them."
      )
    )
  }

  if (
    base::length(vec_files) == 0L && isFALSE(flag_download)
  ) {
    cli::cli_abort(
      c(
        "BIEN datasource {.val {datasource}} has no raw file in {.path {dir_raw}}.",
        "i" = paste(
          "Set {.code bien: flag_download: true} in {.file config.yml}",
          "to download it, and back to false afterwards."
        )
      )
    )
  }

  res <-
    if (
      base::length(vec_files) == 1L
    ) {
      vec_files
    } else {
      save_bien_plot_datasource(
        datasource = datasource,
        dir_raw = dir_raw
      )
    }

  return(res)
}
