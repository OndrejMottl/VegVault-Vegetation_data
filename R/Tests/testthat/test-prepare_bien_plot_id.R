#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("prepare_bien_plot_id() validates arguments", {
  data_plots <-
    tibble::tibble(datasource = "CTFS", plot_name = "Plot 31")

  testthat::expect_error(
    prepare_bien_plot_id(data_plots = "not a data frame"),
    regexp = "data_plots"
  )

  testthat::expect_error(
    prepare_bien_plot_id(
      data_plots = data_plots,
      col_plot_name = "plot"
    ),
    regexp = "plot"
  )

  data_with_id <-
    dplyr::mutate(data_plots, plot_id = "x")

  testthat::expect_error(
    prepare_bien_plot_id(data_plots = data_with_id),
    regexp = "plot_id"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("prepare_bien_plot_id() adds plot_id as first column", {
  data_plots <-
    tibble::tibble(
      datasource = c("CTFS", "CVS"),
      plot_name = c("Plot 31", "002-05-0034"),
      longitude = c(-79.9, -80.1)
    )

  res <-
    prepare_bien_plot_id(
      data_plots = data_plots,
      col_datasource = "datasource",
      col_plot_name = "plot_name",
      separator = "__"
    )

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_named(
    res,
    c("plot_id", "datasource", "plot_name", "longitude")
  )
  testthat::expect_equal(
    dplyr::pull(res, plot_id),
    c("CTFS__Plot 31", "CVS__002-05-0034")
  )
  testthat::expect_equal(dplyr::select(res, -plot_id), data_plots)
})

testthat::test_that("prepare_bien_plot_id() ignores the row order", {
  data_plots <-
    tibble::tibble(
      datasource = c("CTFS", "CVS", "TEAM"),
      plot_name = c("Plot 31", "002-05-0034", "VG-VB-2")
    )

  res <-
    prepare_bien_plot_id(data_plots = data_plots)

  res_reordered <-
    prepare_bien_plot_id(data_plots = data_plots[c(3, 1, 2), ])

  testthat::expect_equal(
    dplyr::pull(res_reordered, plot_id),
    dplyr::pull(res, plot_id)[c(3, 1, 2)]
  )
})

testthat::test_that("prepare_bien_plot_id() aborts on split or bad plots", {
  data_split <-
    tibble::tibble(
      datasource = c("TEAM", "TEAM"),
      plot_name = c("VG-VB-2", "VG-VB-2"),
      longitude = c(-84.0377, -84.0375)
    )

  testthat::expect_error(
    prepare_bien_plot_id(data_plots = data_split),
    regexp = "VG-VB-2"
  )

  data_missing <-
    tibble::tibble(datasource = c("CVS", "CVS"), plot_name = c("P1", NA))

  testthat::expect_error(
    prepare_bien_plot_id(data_plots = data_missing),
    regexp = "missing or empty"
  )

  data_empty_text <-
    tibble::tibble(datasource = "", plot_name = "P1")

  testthat::expect_error(
    prepare_bien_plot_id(data_plots = data_empty_text),
    regexp = "missing or empty"
  )
})


#----------------------------------------------------------#
# Edge cases -----
#----------------------------------------------------------#

testthat::test_that("prepare_bien_plot_id() handles zero plots", {
  data_plots <-
    tibble::tibble(
      datasource = base::character(0),
      plot_name = base::character(0)
    )

  res <-
    prepare_bien_plot_id(data_plots = data_plots)

  testthat::expect_named(res, c("plot_id", "datasource", "plot_name"))
  testthat::expect_equal(base::nrow(res), 0L)
  testthat::expect_type(dplyr::pull(res, plot_id), "character")
})
