#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("prepare_plot_export() validates arguments", {
  data_plots <-
    tibble::tibble(PlotObservationID = 1, Releve_area = 100)

  testthat::expect_error(
    prepare_plot_export(
      data_plots = data_plots,
      vec_columns_required = c("PlotObservationID", "GIVD_ID"),
      vec_columns_order = "plot_observation_id"
    ),
    regexp = "GIVD_ID"
  )

  testthat::expect_error(
    prepare_plot_export(
      data_plots = data_plots,
      vec_columns_required = "PlotObservationID",
      vec_columns_order = "PlotObservationID"
    ),
    regexp = "PlotObservationID"
  )

  testthat::expect_error(
    prepare_plot_export(
      data_plots = data_plots,
      vec_columns_required = character(0),
      vec_columns_order = "plot_observation_id"
    ),
    regexp = "vec_columns_required"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("prepare_plot_export() drops incomplete plots, cleans names and sorts", {
  data_plots <-
    tibble::tibble(
      PlotObservationID = c(30, 10, 20, 40),
      GIVD_ID = c("EU-00-003", "EU-00-001", NA, "EU-00-004"),
      Releve_area = c(100, 200, 300, NA),
      Cover_total = c(NA, 80, 90, 70),
      taxa = list(
        tibble::tibble(Species = "Abies alba"),
        tibble::tibble(Species = "Picea abies"),
        tibble::tibble(Species = "Fagus sylvatica"),
        tibble::tibble(Species = "Pinus nigra")
      )
    )

  res <-
    prepare_plot_export(
      data_plots = data_plots,
      vec_columns_required = c("PlotObservationID", "GIVD_ID", "Releve_area"),
      vec_columns_order = "plot_observation_id"
    )

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_identical(
    base::names(res),
    c("plot_observation_id", "givd_id", "releve_area", "cover_total", "taxa")
  )
  testthat::expect_identical(res$plot_observation_id, c(10, 30))
  testthat::expect_identical(res$cover_total, c(80, NA))
  testthat::expect_identical(
    base::names(purrr::chuck(res, "taxa", 1)),
    "Species"
  )
})

testthat::test_that("prepare_plot_export() sorts by several columns in priority order", {
  data_plots <-
    tibble::tibble(
      datasource = c("TEAM", "CVS", "CVS"),
      plot_name = c("A", "B", "A"),
      longitude = c(1, 2, 3)
    )

  res <-
    prepare_plot_export(
      data_plots = data_plots,
      vec_columns_required = "datasource",
      vec_columns_order = c("datasource", "plot_name")
    )

  testthat::expect_identical(res$datasource, c("CVS", "CVS", "TEAM"))
  testthat::expect_identical(res$plot_name, c("A", "B", "A"))
})
