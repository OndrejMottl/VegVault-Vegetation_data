#' @title Validate the sPlotOpen raw file
#' @description Check that the manually downloaded sPlotOpen file exists and
#'   is the recorded version, identified by its SHA-256 checksum.
#' @param path_file Character. Path to the sPlotOpen `.RData` file.
#' @param sha256_expected Character. Expected SHA-256 checksum of the file
#'   (64 lower-case hexadecimal characters).
#' @param version_label Character. Human-readable name of the expected
#'   version, used in error messages.
#' @return The input `path_file`, unchanged, so that the function can be the
#'   command of a `format = "file"` target.
#' @details sPlotOpen is downloaded manually from the iDiv data portal
#'   (dataset 3474); the pipeline never downloads it. The function aborts
#'   with a message that names the manual download step and the expected
#'   version when the file is missing, and with both checksums when the file
#'   differs from the recorded version. It never substitutes another file.
validate_splot_raw_file <- function(
    path_file,
    sha256_expected,
    version_label) {
  assertthat::assert_that(
    base::is.character(path_file),
    base::length(path_file) == 1L,
    !base::is.na(path_file),
    base::nzchar(path_file),
    msg = "`path_file` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(sha256_expected),
    base::length(sha256_expected) == 1L,
    !base::is.na(sha256_expected),
    base::grepl("^[0-9a-f]{64}$", sha256_expected),
    msg = paste(
      "`sha256_expected` must be a SHA-256 checksum",
      "(64 lower-case hexadecimal characters)."
    )
  )

  assertthat::assert_that(
    base::is.character(version_label),
    base::length(version_label) == 1L,
    !base::is.na(version_label),
    base::nzchar(version_label),
    msg = "`version_label` must be a single non-empty character string."
  )

  if (
    isFALSE(base::file.exists(path_file))
  ) {
    cli::cli_abort(
      c(
        "The sPlotOpen raw file does not exist: {.path {path_file}}",
        "i" = paste(
          "sPlotOpen is a manual download from the iDiv data portal",
          "(dataset 3474); the pipeline never downloads it."
        ),
        "i" = "Place {version_label} at this path."
      )
    )
  }

  sha256_file <-
    digest::digest(
      object = path_file,
      algo = "sha256",
      file = TRUE
    )

  if (
    isFALSE(base::identical(sha256_file, sha256_expected))
  ) {
    cli::cli_abort(
      c(
        "The sPlotOpen raw file is not the recorded version ({version_label}).",
        "x" = "Its SHA-256 checksum is {sha256_file}.",
        "i" = "The recorded checksum is {sha256_expected}.",
        "i" = paste(
          "Restore the recorded file, or change the version and checksum",
          "in {.file config.yml} deliberately."
        )
      )
    )
  }

  res <- path_file

  return(res)
}
