#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("prepare_plot_coordinates() validates arguments", {
  data_records <-
    tibble::tibble(plot_name = "P1", longitude = 1, latitude = 2)

  testthat::expect_error(
    prepare_plot_coordinates(
      data_records = "not a data frame",
      vec_columns_plot = "plot_name",
      max_spread = 0.01
    ),
    regexp = "data_records"
  )

  testthat::expect_error(
    prepare_plot_coordinates(
      data_records = data_records,
      vec_columns_plot = "plot_id",
      max_spread = 0.01
    ),
    regexp = "plot_id"
  )

  testthat::expect_error(
    prepare_plot_coordinates(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      col_longitude = "lon",
      max_spread = 0.01
    ),
    regexp = "lon"
  )

  data_text <-
    dplyr::mutate(data_records, latitude = "2")

  testthat::expect_error(
    prepare_plot_coordinates(
      data_records = data_text,
      vec_columns_plot = "plot_name",
      max_spread = 0.01
    ),
    regexp = "numeric"
  )

  testthat::expect_error(
    prepare_plot_coordinates(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      max_spread = -1
    ),
    regexp = "max_spread"
  )

  testthat::expect_error(
    prepare_plot_coordinates(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      max_spread = NA_real_
    ),
    regexp = "max_spread"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("prepare_plot_coordinates() averages the distinct pairs", {
  data_records <-
    tibble::tibble(
      plot_name = c("P1", "P1", "P1", "P1", "P2"),
      subplot = c("1", "1", "2", "3", "1"),
      longitude = c(-84.0, -84.0, -84.002, -84.004, 10),
      latitude = c(10.0, 10.0, 10.001, 10.002, 50)
    )

  res <-
    prepare_plot_coordinates(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      col_longitude = "longitude",
      col_latitude = "latitude",
      max_spread = 0.01
    )

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_named(res, base::names(data_records))
  testthat::expect_equal(
    dplyr::pull(res, longitude),
    c(-84.002, -84.002, -84.002, -84.002, 10),
    tolerance = 1e-10
  )
  testthat::expect_equal(
    dplyr::pull(res, latitude),
    c(10.001, 10.001, 10.001, 10.001, 50),
    tolerance = 1e-10
  )
  testthat::expect_equal(
    dplyr::pull(res, subplot),
    dplyr::pull(data_records, subplot)
  )
})

testthat::test_that("prepare_plot_coordinates() keeps missing and far pairs", {
  data_records <-
    tibble::tibble(
      plot_name = c("P1", "P1", "P1", "P2", "P2"),
      longitude = c(1, 1.001, NA, 5, 7),
      latitude = c(2, 2.001, NA, 5, 5)
    )

  res <-
    prepare_plot_coordinates(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      max_spread = 0.01
    )

  testthat::expect_equal(
    dplyr::pull(res, longitude),
    c(1.0005, 1.0005, NA, 5, 7),
    tolerance = 1e-10
  )
  testthat::expect_equal(
    dplyr::pull(res, latitude),
    c(2.0005, 2.0005, NA, 5, 5),
    tolerance = 1e-10
  )
})

testthat::test_that("prepare_plot_coordinates() averages up to max_spread", {
  data_records <-
    tibble::tibble(
      plot_name = c("P1", "P1"),
      longitude = c(0, 0.5),
      latitude = c(1, 1)
    )

  res <-
    prepare_plot_coordinates(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      max_spread = 0.5
    )

  testthat::expect_equal(dplyr::pull(res, longitude), c(0.25, 0.25))
})


#----------------------------------------------------------#
# Edge cases -----
#----------------------------------------------------------#

testthat::test_that("prepare_plot_coordinates() keeps single-pair plots", {
  data_single <-
    tibble::tibble(
      plot_name = c("P1", "P1", "P2"),
      longitude = c(1, 1, 3),
      latitude = c(2, 2, 4)
    )

  res_single <-
    prepare_plot_coordinates(
      data_records = data_single,
      vec_columns_plot = "plot_name",
      max_spread = 0.01
    )

  testthat::expect_equal(res_single, data_single)

  data_empty <-
    tibble::tibble(
      plot_name = base::character(0),
      longitude = base::numeric(0),
      latitude = base::numeric(0)
    )

  res_empty <-
    prepare_plot_coordinates(
      data_records = data_empty,
      vec_columns_plot = "plot_name",
      max_spread = 0.01
    )

  testthat::expect_equal(res_empty, data_empty)
})
