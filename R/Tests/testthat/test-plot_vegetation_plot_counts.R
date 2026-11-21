#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("plot_vegetation_plot_counts() validates arguments", {
  data_plots <-
    tibble::tibble(longitude = c(10, 11), latitude = c(50, 51))

  testthat::expect_error(
    plot_vegetation_plot_counts(
      data_plots = data_plots,
      col_longitude = "lon",
      col_latitude = "latitude",
      title = "Plots"
    ),
    regexp = "lon"
  )

  testthat::expect_error(
    plot_vegetation_plot_counts(
      data_plots = data_plots,
      col_longitude = "longitude",
      col_latitude = "latitude",
      title = "Plots",
      col_facet = "datasource"
    ),
    regexp = "datasource"
  )

  testthat::expect_error(
    plot_vegetation_plot_counts(
      data_plots = data_plots,
      col_longitude = "longitude",
      col_latitude = "latitude",
      title = ""
    ),
    regexp = "title"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("plot_vegetation_plot_counts() builds a hexagon count map", {
  data_plots <-
    tibble::tibble(
      datasource = c("CVS", "CVS", "TEAM"),
      longitude = c(-80, -81, -70),
      latitude = c(35, 36, NA)
    )

  res <-
    plot_vegetation_plot_counts(
      data_plots = data_plots,
      col_longitude = "longitude",
      col_latitude = "latitude",
      title = "BIEN plots",
      subtitle = "By data source"
    )

  vec_geoms <-
    purrr::map_chr(res$layers, ~ base::class(.x$geom)[1])

  testthat::expect_s3_class(res, "ggplot")
  testthat::expect_true("GeomHex" %in% vec_geoms)
  testthat::expect_s3_class(res$facet, "FacetNull")
  testthat::expect_identical(ggplot2::get_labs(res)$title, "BIEN plots")
  testthat::expect_identical(ggplot2::get_labs(res)$subtitle, "By data source")
  testthat::expect_identical(ggplot2::get_labs(res)$fill, "Number of plots")
  testthat::expect_identical(base::nrow(res$data), 2L)
})

testthat::test_that("plot_vegetation_plot_counts() draws one panel per group", {
  data_plots <-
    tibble::tibble(
      datasource = c("CVS", "TEAM"),
      longitude = c(-80, -70),
      latitude = c(35, -5)
    )

  res <-
    plot_vegetation_plot_counts(
      data_plots = data_plots,
      col_longitude = "longitude",
      col_latitude = "latitude",
      title = "BIEN plots",
      col_facet = "datasource"
    )

  testthat::expect_s3_class(res$facet, "FacetWrap")
})
