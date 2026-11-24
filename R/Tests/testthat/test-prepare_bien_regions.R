#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("prepare_bien_regions() validates arguments", {
  testthat::expect_error(
    prepare_bien_regions(data_plots = tibble::tibble(longitude = 1)),
    regexp = "latitude"
  )

  testthat::expect_error(
    prepare_bien_regions(data_plots = "not a table"),
    regexp = "data_plots"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("prepare_bien_regions() assigns the review regions", {
  data_plots <-
    tibble::tibble(
      plot_name = c("A", "B", "C", "D", "E", "F"),
      longitude = c(-100, -60, -60, 10, NA, -45),
      latitude = c(40, -5, 18, 50, 40, 25)
    )

  res <-
    prepare_bien_regions(data_plots = data_plots)

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_identical(
    base::names(res),
    c("plot_name", "longitude", "latitude", "region")
  )
  testthat::expect_identical(
    res$region,
    c(
      "North America", "Latin America", "Other",
      "Other", "Other", "North America"
    )
  )
})
