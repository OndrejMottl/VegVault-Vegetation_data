#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("summarise_common_plot_size() validates arguments", {
  data_plots <-
    tibble::tibble(Continent = "Europe", PlotObservationID = 1, Releve_area = 100)

  testthat::expect_error(
    summarise_common_plot_size(
      data_plots = data_plots,
      col_group = "continent",
      col_area = "Releve_area",
      vec_columns_plot = "PlotObservationID"
    ),
    regexp = "continent"
  )

  testthat::expect_error(
    summarise_common_plot_size(
      data_plots = data_plots,
      col_group = "Continent",
      col_area = "Releve_area",
      vec_columns_plot = "plot_id"
    ),
    regexp = "plot_id"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("summarise_common_plot_size() finds the most common size per group", {
  data_plots <-
    tibble::tibble(
      Continent = c(
        "Europe", "Europe", "Europe", "Europe", "Europe",
        "Oceania", "Oceania", "Oceania", NA
      ),
      PlotObservationID = c(1, 1, 2, 3, 4, 5, 6, 7, 8),
      Releve_area = c(100, 100, 100, 16, 16, 400, 25, NA, 100)
    )

  res <-
    summarise_common_plot_size(
      data_plots = data_plots,
      col_group = "Continent",
      col_area = "Releve_area",
      vec_columns_plot = "PlotObservationID"
    )

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_named(res, c("group", "plot_area", "n_plots"))
  testthat::expect_identical(res$group, c("Europe", "Oceania"))
  testthat::expect_identical(res$plot_area, c(16, 25))
  testthat::expect_identical(res$n_plots, c(2L, 1L))
})
