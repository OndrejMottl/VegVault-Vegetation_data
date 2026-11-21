#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("deduplicate_bien_columns() validates its input", {
  testthat::expect_error(
    deduplicate_bien_columns(data_raw = "not a data frame"),
    regexp = "data_raw"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("deduplicate_bien_columns() collapses identical copies", {
  data_raw <-
    base::data.frame(
      plot_name = c("P1", "P2"),
      recorded_by = c("A. Smith", NA),
      date_collected = base::as.Date(c("2010-05-01", NA)),
      datasource = c("CVS", "CVS"),
      recorded_by = c("A. Smith", NA),
      date_collected = base::as.Date(c("2010-05-01", NA)),
      check.names = FALSE
    )

  res <-
    deduplicate_bien_columns(data_raw = data_raw)

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_named(
    res,
    c("plot_name", "recorded_by", "date_collected", "datasource")
  )
  testthat::expect_equal(base::nrow(res), 2L)
  testthat::expect_equal(dplyr::pull(res, recorded_by), c("A. Smith", NA))
  testthat::expect_s3_class(dplyr::pull(res, date_collected), "Date")
})

testthat::test_that("deduplicate_bien_columns() keeps tables without copies", {
  data_raw <-
    base::data.frame(plot_name = c("P1", "P2"), subplot = c("1", NA))

  res <-
    deduplicate_bien_columns(data_raw = data_raw)

  testthat::expect_equal(res, tibble::as_tibble(data_raw))
})

testthat::test_that("deduplicate_bien_columns() aborts when copies differ", {
  data_differ <-
    base::data.frame(
      plot_name = c("P1", "P2"),
      recorded_by = c("A", "B"),
      recorded_by = c("A", "C"),
      check.names = FALSE
    )

  testthat::expect_error(
    deduplicate_bien_columns(data_raw = data_differ),
    regexp = "recorded_by"
  )

  data_one_missing <-
    base::data.frame(
      plot_name = "P1",
      recorded_by = "A",
      recorded_by = NA_character_,
      check.names = FALSE
    )

  testthat::expect_error(
    deduplicate_bien_columns(data_raw = data_one_missing),
    regexp = "recorded_by"
  )
})


#----------------------------------------------------------#
# Edge cases -----
#----------------------------------------------------------#

testthat::test_that("deduplicate_bien_columns() handles tables without rows", {
  data_raw <-
    base::data.frame(
      plot_name = base::character(0),
      recorded_by = base::character(0),
      recorded_by = base::character(0),
      check.names = FALSE
    )

  res <-
    deduplicate_bien_columns(data_raw = data_raw)

  testthat::expect_named(res, c("plot_name", "recorded_by"))
  testthat::expect_equal(base::nrow(res), 0L)
})
