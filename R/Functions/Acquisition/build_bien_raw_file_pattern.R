#' @title Build the file-name pattern of a BIEN raw file
#' @description Build the regular expression that matches the raw file name
#'   of exactly one BIEN plot datasource.
#' @param datasource Character. Name of one BIEN plot datasource.
#' @return A regular expression (character) matching
#'   `<datasource>_<YYYY-MM-DD>__<32 hex>__.rds` and nothing else.
#' @details The datasource name is escaped, so characters such as `.` match
#'   literally, and the pattern is anchored at both ends, so the name of a
#'   datasource that starts with this one (for example `CVS_extra` for
#'   `CVS`) never matches. The function aborts unless `datasource` is a
#'   single non-empty character string.
build_bien_raw_file_pattern <- function(datasource) {
  assertthat::assert_that(
    base::is.character(datasource),
    base::length(datasource) == 1L,
    !base::is.na(datasource),
    base::nzchar(datasource),
    msg = "`datasource` must be a single non-empty character string."
  )

  res <-
    stringr::str_c(
      "^",
      stringr::str_escape(datasource),
      "_[0-9]{4}-[0-9]{2}-[0-9]{2}__[0-9a-f]{32}__[.]rds$"
    )

  return(res)
}
