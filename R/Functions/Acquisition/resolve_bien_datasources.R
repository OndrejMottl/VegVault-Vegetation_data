#' @title Resolve the BIEN plot datasources to acquire
#' @description Return the configured BIEN plot datasources. When downloading
#'   is enabled, first check them against the datasources BIEN lists.
#' @param vec_datasources Character vector. BIEN plot datasources to acquire,
#'   as configured.
#' @param flag_download Logical. `TRUE` when the run may download from BIEN.
#' @return The character vector `vec_datasources`, unchanged.
#' @details With `flag_download = FALSE` the function makes no network call.
#'   With `flag_download = TRUE` it queries
#'   `BIEN::BIEN_plot_list_datasource()` and aborts when BIEN lists a
#'   datasource that is not configured or the configuration names one that
#'   BIEN does not list, so that a change in BIEN is never ignored silently.
#'   It also aborts on an empty, missing or duplicated datasource name.
resolve_bien_datasources <- function(
    vec_datasources,
    flag_download) {
  assertthat::assert_that(
    base::is.character(vec_datasources),
    base::length(vec_datasources) > 0L,
    !base::anyNA(vec_datasources),
    base::all(base::nzchar(vec_datasources)),
    msg = paste(
      "`vec_datasources` must be a non-empty character vector",
      "without missing or empty names."
    )
  )

  vec_duplicated <-
    base::unique(vec_datasources[base::duplicated(vec_datasources)])

  if (
    base::length(vec_duplicated) > 0L
  ) {
    cli::cli_abort(
      "`vec_datasources` has duplicated names: {.val {vec_duplicated}}."
    )
  }

  assertthat::assert_that(
    base::is.logical(flag_download),
    base::length(flag_download) == 1L,
    !base::is.na(flag_download),
    msg = "`flag_download` must be TRUE or FALSE."
  )

  if (
    isTRUE(flag_download)
  ) {
    vec_available <-
      BIEN::BIEN_plot_list_datasource() |>
      purrr::chuck("datasource")

    vec_not_configured <-
      base::setdiff(vec_available, vec_datasources)

    vec_not_listed <-
      base::setdiff(vec_datasources, vec_available)

    if (
      base::length(vec_not_configured) + base::length(vec_not_listed) > 0L
    ) {
      cli::cli_abort(
        c(
          "The configured BIEN plot datasources differ from those BIEN lists.",
          "x" = "Listed by BIEN, not configured: {.val {vec_not_configured}}",
          "x" = "Configured, not listed by BIEN: {.val {vec_not_listed}}",
          "i" = "Change {.code bien: datasources} in {.file config.yml} deliberately."
        )
      )
    }
  }

  res <- vec_datasources

  return(res)
}
