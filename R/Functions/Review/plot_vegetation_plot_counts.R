#' @title Plot a map of vegetation-plot counts
#' @description Map the number of vegetation plots in hexagonal cells over a
#'   grey world basemap, optionally in one panel per group.
#' @param data_plots A data frame of plots with coordinate columns.
#' @param col_longitude Character. Name of the longitude column (decimal
#'   degrees).
#' @param col_latitude Character. Name of the latitude column (decimal
#'   degrees).
#' @param title Character. Plot title.
#' @param col_facet Character or `NULL`. Name of a column whose values get
#'   one panel each; `NULL` draws one panel.
#' @param subtitle Character or `NULL`. Plot subtitle.
#' @return A `ggplot` object; nothing is drawn or saved.
#' @details The map uses 90 hexagonal bins, a viridis fill on a `log1p`
#'   scale (labelled "Number of plots") and `coord_quickmap()`, as the maps
#'   of VegVault 1.0.0. The basemap is a polygon layer of
#'   `ggplot2::map_data("world")`, drawn in every panel. Plots with a missing
#'   coordinate are left out. The function aborts when a named column is
#'   missing.
plot_vegetation_plot_counts <- function(
    data_plots,
    col_longitude,
    col_latitude,
    title,
    col_facet = NULL,
    subtitle = NULL) {
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
      plot_base
    } else {
      plot_base +
        ggplot2::facet_wrap(ggplot2::vars(.data[[col_facet]]))
    }

  res <-
    plot_faceted +
    ggplot2::scale_fill_viridis_c(
      transform = "log1p",
      breaks = c(0, 10, 100, 1e3, 1e4, 1e5)
    ) +
    ggplot2::coord_quickmap() +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Longitude",
      y = "Latitude",
      fill = "Number of plots"
    ) +
    ggplot2::theme_classic() +
    # annotation_borders() passes the map groups as one fixed vector, which
    #   fails as soon as facets copy the map into several panels (ggplot2
    #   4.0); a polygon layer with mapped groups is copied correctly.
    ggplot2::geom_polygon(
      data = ggplot2::map_data("world"),
      mapping = ggplot2::aes(
        x = .data[["long"]],
        y = .data[["lat"]],
        group = .data[["group"]]
      ),
      inherit.aes = FALSE,
      fill = "gray80",
      colour = NA
    ) +
    ggplot2::geom_hex(bins = 90)

  return(res)
}
