#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("plot_vegetation_plot_locations() validates arguments", {
  data_plots <-
    tibble::tibble(Longitude = c(10, 11), Latitude = c(50, 51))

  testthat::expect_error(
    plot_vegetation_plot_locations(
      data_plots = data_plots,
      col_longitude = "Longitude",
      col_latitude = "lat",
      title = "Plots"
    ),
    regexp = "lat"
  )

  testthat::expect_error(
    plot_vegetation_plot_locations(
      data_plots = tibble::tibble(Longitude = NA_real_, Latitude = 50),
      col_longitude = "Longitude",
      col_latitude = "Latitude",
      title = "Plots"
    ),
    regexp = "coordinates"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("plot_vegetation_plot_locations() builds a point and density map", {
  data_plots <-
    tibble::tibble(
      Continent = c("Europe", "Europe", "Europe", "Oceania", "Oceania"),
      Longitude = c(10, 11, 12, 150, NA),
      Latitude = c(50, 51, 49, -30, -31)
    )

  res <-
    plot_vegetation_plot_locations(
      data_plots = data_plots,
      col_longitude = "Longitude",
      col_latitude = "Latitude",
      title = "sPlot plots",
      caption = "N plots = 4"
    )

  vec_geoms <-
    purrr::map_chr(res$layers, ~ base::class(.x$geom)[1])

  testthat::expect_s3_class(res, "ggplot")
  testthat::expect_true(base::all(c("GeomPoint", "GeomDensity2d") %in% vec_geoms))
  testthat::expect_s3_class(res$facet, "FacetNull")
  testthat::expect_identical(ggplot2::get_labs(res)$title, "sPlot plots")
  testthat::expect_identical(ggplot2::get_labs(res)$caption, "N plots = 4")
  testthat::expect_identical(base::nrow(res$data), 4L)
})

testthat::test_that("plot_vegetation_plot_locations() draws one panel per group", {
  data_plots <-
    tibble::tibble(
      Continent = c("Europe", "Europe", "Oceania", "Oceania"),
      Longitude = c(10, 11, 150, 151),
      Latitude = c(50, 51, -30, -31)
    )

  res <-
    plot_vegetation_plot_locations(
      data_plots = data_plots,
      col_longitude = "Longitude",
      col_latitude = "Latitude",
      title = "sPlot plots",
      col_facet = "Continent"
    )

  testthat::expect_s3_class(res$facet, "FacetWrap")
})
