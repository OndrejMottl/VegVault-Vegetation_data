#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("select_common_size_plots() validates arguments", {
  data_plots <-
    tibble::tibble(Continent = "Europe", Releve_area = 100)

  data_common_size <-
    tibble::tibble(group = "Europe", plot_area = 100, n_plots = 1L)

  testthat::expect_error(
    select_common_size_plots(
      data_plots = data_plots,
      data_common_size = data_common_size,
      col_group = "Continent",
      col_area = "area",
      vec_groups = "Europe"
    ),
    regexp = "area"
  )

  testthat::expect_error(
    select_common_size_plots(
      data_plots = data_plots,
      data_common_size = data_common_size,
      col_group = "Continent",
      col_area = "Releve_area",
      vec_groups = c("Europe", "Oceania")
    ),
    regexp = "Oceania"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("select_common_size_plots() keeps the plots of the common size", {
  data_plots <-
    tibble::tibble(
      PlotObservationID = c(1, 2, 3, 4, 5, 6),
      Continent = c("Europe", "Oceania", "Europe", "Africa", "Oceania", "Europe"),
      Releve_area = c(100, 400, 16, 100, 400, 100)
    )

  data_common_size <-
    tibble::tibble(
      group = c("Africa", "Europe", "Oceania"),
      plot_area = c(100, 100, 400),
      n_plots = c(1L, 2L, 2L)
    )

  res <-
    select_common_size_plots(
      data_plots = data_plots,
      data_common_size = data_common_size,
      col_group = "Continent",
      col_area = "Releve_area",
      vec_groups = c("Europe", "Oceania")
    )

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_identical(base::names(res), base::names(data_plots))
  testthat::expect_identical(res$PlotObservationID, c(1, 2, 5, 6))
})
