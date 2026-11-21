#' @title Compute the merged abundance of repeated taxon records
#' @description Combine the abundances of several records of one taxon in
#'   one plot, all on the same abundance scale, into one value.
#' @param vec_abundance Numeric vector. Abundances of the records; a vector
#'   of missing values only is accepted in any class.
#' @param scale Character. The abundance scale shared by the records.
#' @param scale_presence Character. Scale of presence-only records.
#' @param scale_cover Character. Scale of percentage cover (0 to 100).
#' @param vec_scales_summed Character vector. Scales whose values are added,
#'   such as counts of individuals or stems.
#' @param vec_scales_maximum Character vector. Scales whose largest value is
#'   kept, such as relative importance.
#' @return A single numeric value; `NA` when every abundance is missing.
#' @details Missing abundances are ignored, and a single non-missing value is
#'   returned unchanged. Presence keeps the largest value (1 for presence).
#'   Covers are combined as overlapping layers,
#'   100 * (1 - prod(1 - cover / 100)) (Fischer 2015), so the result is at
#'   most 100. The function aborts for a scale that has no rule.
compute_merged_abundance <- function(
    vec_abundance,
    scale,
    scale_presence = "pa",
    scale_cover = "CoverPerc",
    vec_scales_summed = c("x_IC", "x_SC", "x_BA"),
    vec_scales_maximum = c("x_IV", "x_PF")) {
  assertthat::assert_that(
    base::is.numeric(vec_abundance) || base::all(base::is.na(vec_abundance)),
    msg = "`vec_abundance` must be numeric."
  )

  assertthat::assert_that(
    assertthat::is.string(scale),
    !base::is.na(scale),
    msg = "`scale` must be a single, non-missing string."
  )

  assertthat::assert_that(
    base::is.character(vec_scales_summed),
    base::is.character(vec_scales_maximum),
    msg = "The scale lists must be character vectors."
  )

  vec_present <-
    base::as.numeric(vec_abundance[!base::is.na(vec_abundance)])

  flag_known <-
    scale %in% c(
      scale_presence, scale_cover, vec_scales_summed, vec_scales_maximum
    )

  if (
    isFALSE(flag_known)
  ) {
    cli::cli_abort(
      "The abundance scale {.val {scale}} has no merge rule."
    )
  }

  if (
    base::length(vec_present) == 0L
  ) {
    return(NA_real_)
  }

  if (
    base::length(vec_present) == 1L
  ) {
    return(vec_present)
  }

  if (
    scale == scale_cover
  ) {
    res <-
      100 * (1 - base::prod(1 - vec_present / 100))
  } else if (
    scale %in% vec_scales_summed
  ) {
    res <-
      base::sum(vec_present)
  } else {
    # presence and the maximum scales keep the largest value
    res <-
      base::max(vec_present)
  }

  return(res)
}
