#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("prepare_bien_plots() validates arguments", {
  data_bien_raw <-
    tibble::tibble(
      datasource = "CVS",
      plot_name = "P1",
      name_matched = "Quercus alba"
    )

  testthat::expect_error(
    prepare_bien_plots(
      data_bien_raw = dplyr::select(data_bien_raw, -plot_name),
      vec_columns_selected = c("datasource", "plot_name", "name_matched"),
      vec_columns_nested = "name_matched"
    ),
    regexp = "plot_name"
  )

  testthat::expect_error(
    prepare_bien_plots(
      data_bien_raw = data_bien_raw,
      vec_columns_selected = c("datasource", "plot_name", "name_matched"),
      vec_columns_nested = c("name_matched", "individual_count")
    ),
    regexp = "individual_count"
  )

  testthat::expect_error(
    prepare_bien_plots(
      data_bien_raw = data_bien_raw,
      vec_columns_selected = character(0),
      vec_columns_nested = "name_matched"
    ),
    regexp = "vec_columns_selected"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("prepare_bien_plots() nests the records of each plot", {
  data_bien_raw <-
    tibble::tibble(
      datasource = c("CVS", "CVS", "CVS", "TEAM"),
      plot_name = c("P2", "P1", "P2", "T1"),
      longitude = c(-80, -81, -80, -70),
      latitude = c(35, 36, 35, -5),
      recorded_by = c("a", "b", "c", "d"),
      subplot = c("1", "1", "2", NA),
      name_matched = c("Quercus alba", "Acer rubrum", "Quercus alba", "Ficus insipida"),
      individual_count = c(1L, NA, 3L, 1L)
    )

  res <-
    prepare_bien_plots(
      data_bien_raw = data_bien_raw,
      vec_columns_selected = c(
        "datasource", "plot_name", "longitude", "latitude",
        "subplot", "name_matched", "individual_count", "methodology_reference"
      ),
      vec_columns_nested = c("subplot", "name_matched", "individual_count")
    )

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_false(dplyr::is_grouped_df(res))
  testthat::expect_identical(
    base::names(res),
    c("datasource", "plot_name", "longitude", "latitude", "plot_data")
  )
  testthat::expect_identical(res$plot_name, c("P2", "P1", "T1"))

  data_plot_p2 <-
    purrr::chuck(res, "plot_data", 1)

  testthat::expect_s3_class(data_plot_p2, "tbl_df")
  testthat::expect_identical(
    base::names(data_plot_p2),
    c("subplot", "name_matched", "individual_count")
  )
  testthat::expect_identical(data_plot_p2$subplot, c("1", "2"))
  testthat::expect_identical(data_plot_p2$individual_count, c(1L, 3L))
})

testthat::test_that("prepare_bien_plots() splits a plot whose records differ in a plot-level column", {
  data_bien_raw <-
    tibble::tibble(
      datasource = c("TEAM", "TEAM"),
      plot_name = c("T1", "T1"),
      longitude = c(-70.1, -70.2),
      latitude = c(-5, -5),
      name_matched = c("Ficus insipida", "Inga edulis")
    )

  res <-
    prepare_bien_plots(
      data_bien_raw = data_bien_raw,
      vec_columns_selected = c(
        "datasource", "plot_name", "longitude", "latitude", "name_matched"
      ),
      vec_columns_nested = "name_matched"
    )

  testthat::expect_identical(base::nrow(res), 2L)
})
