#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("select_latest_survey() validates arguments", {
  data_records <-
    tibble::tibble(
      datasource = "TEAM",
      plot_name = "P1",
      date_collected = base::as.Date("2010-01-01")
    )

  testthat::expect_error(
    select_latest_survey(
      data_records = "not a data frame",
      vec_columns_plot = "plot_name",
      col_date = "date_collected"
    ),
    regexp = "data_records"
  )

  testthat::expect_error(
    select_latest_survey(
      data_records = data_records,
      vec_columns_plot = c("datasource", "plot_id"),
      col_date = "date_collected"
    ),
    regexp = "plot_id"
  )

  testthat::expect_error(
    select_latest_survey(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      col_date = "survey_date"
    ),
    regexp = "survey_date"
  )

  data_text_date <-
    dplyr::mutate(data_records, date_collected = "2010-01-01")

  testthat::expect_error(
    select_latest_survey(
      data_records = data_text_date,
      vec_columns_plot = "plot_name",
      col_date = "date_collected"
    ),
    regexp = "Date"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("select_latest_survey() keeps the latest year per plot", {
  data_records <-
    tibble::tibble(
      datasource = "TEAM",
      plot_name = c("P1", "P1", "P1", "P1", "P2", "P2"),
      name_matched = c("a", "b", "a", "b", "c", "d"),
      date_collected = base::as.Date(
        c(
          "2010-03-01", "2011-02-01", "2011-11-30", "2009-01-01",
          "2005-06-01", "2005-06-01"
        )
      )
    )

  res <-
    select_latest_survey(
      data_records = data_records,
      vec_columns_plot = c("datasource", "plot_name"),
      col_date = "date_collected"
    )

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_named(res, base::names(data_records))
  testthat::expect_equal(res, data_records[c(2, 3, 5, 6), ])
})

testthat::test_that("select_latest_survey() handles undated records", {
  data_records <-
    tibble::tibble(
      plot_name = c("P1", "P1", "P2", "P2", "P2"),
      date_collected = base::as.Date(
        c(NA, NA, "2003-05-01", NA, "2001-05-01")
      )
    )

  res <-
    select_latest_survey(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      col_date = "date_collected"
    )

  testthat::expect_equal(res, data_records[c(1, 2, 3), ])
})


#----------------------------------------------------------#
# Edge cases -----
#----------------------------------------------------------#

testthat::test_that("select_latest_survey() groups missing plot values", {
  data_records <-
    tibble::tibble(
      plot_name = c(NA, NA, "P1"),
      date_collected = base::as.Date(
        c("2001-01-01", "2002-01-01", "2001-01-01")
      )
    )

  res <-
    select_latest_survey(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      col_date = "date_collected"
    )

  testthat::expect_equal(res, data_records[c(2, 3), ])
})

testthat::test_that("select_latest_survey() returns zero rows unchanged", {
  data_records <-
    tibble::tibble(
      plot_name = base::character(0),
      date_collected = base::as.Date(base::character(0))
    )

  res <-
    select_latest_survey(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      col_date = "date_collected"
    )

  testthat::expect_equal(res, data_records)
})
