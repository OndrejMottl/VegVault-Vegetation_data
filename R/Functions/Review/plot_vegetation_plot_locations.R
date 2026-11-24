#' @title Plot a map of vegetation-plot locations
#' @description Map vegetation plots as points with their two-dimensional
#'   density over a grey world basemap, zoomed to the plots.
#' @param data_plots A data frame of plots with coordinate columns.
#' @param col_longitude Character. Name of the longitude column (decimal
#'   degrees).
#' @param col_latitude Character. Name of the latitude column (decimal
#'   degrees).
#' @param title Character. Plot title.
#' @param col_facet Character or `NULL`. Name of a column whose values get
#'   one panel each, with free scales; `NULL` draws one panel.
#' @param caption Character or `NULL`. Plot caption.
#' @return A `ggplot` object; nothing is drawn or saved.
#' @details Points are semi-transparent and overlaid by density contours, as
#'   in the VegVault 1.0.0 review. Plots with a missing coordinate are left
#'   out. The function aborts when a named column is missing or no plot has
#'   both coordinates.
plot_vegetation_plot_locations <- function(
    data_plots,
    col_longitude,
    col_latitude,
    title,
    col_facet = NULL,
    caption = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_plots),
    msg = "`data_plots` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(title),
    base::length(title) == 1L,
    !base::is.na(title),
    base::nzchar(title),
    msg = "`title` must be a single non-empty character string."
  )

  vec_missing <-
    base::setdiff(
      c(col_longitude, col_latitude, col_facet),
      base::names(data_plots)
    )

  if (
    base::length(vec_missing) > 0L
  ) {
    cli::cli_abort("The plots lack the column{?s} {.val {vec_missing}}.")
  }

  data_located <-
    tidyr::drop_na(
      data_plots,
      dplyr::all_of(c(col_longitude, col_latitude))
    )

  if (
    base::nrow(data_located) == 0L
  ) {
    cli::cli_abort("No plot has both coordinates.")
  }

  plot_base <-
    data_located |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = .data[[col_longitude]],
        y = .data[[col_latitude]]
      )
    )

  plot_faceted <-
    if (
      base::is.null(col_facet)
    ) {
      plot_base +
        ggplot2::coord_quickmap(
          xlim = base::range(data_located[[col_longitude]]),
          ylim = base::range(data_located[[col_latitude]])
        )
    } else {
      plot_base +
        ggplot2::facet_wrap(
          ggplot2::vars(.data[[col_facet]]),
          scales = "free"
        )
    }

  res <-
    plot_faceted +
    ggplot2::labs(
      title = title,
      caption = caption,
      x = "Longitude",
      y = "Latitude"
    ) +
    ggplot2::theme_classic() +
    ggplot2::geom_point(alpha = 0.5) +
    ggplot2::geom_density2d(alpha = 0.5)

  return(res)
}
