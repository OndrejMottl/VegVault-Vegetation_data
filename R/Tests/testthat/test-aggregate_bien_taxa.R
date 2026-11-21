#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("aggregate_bien_taxa() validates arguments", {
  data_records <-
    tibble::tibble(
      plot_name = c("P1", "P1"),
      name_matched = c("Quercus alba", "Quercus alba"),
      individual_count = c(1L, 2L),
      subplot = c("1", "2"),
      family_matched = c("Fagaceae", "Fagaceae")
    )

  testthat::expect_error(
    aggregate_bien_taxa(
      data_records = "not a data frame",
      vec_columns_plot = "plot_name",
      vec_columns_joined = "subplot",
      vec_columns_agreeing = "family_matched"
    ),
    regexp = "data_records"
  )

  testthat::expect_error(
    aggregate_bien_taxa(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      vec_columns_joined = "verbatim_family",
      vec_columns_agreeing = "family_matched"
    ),
    regexp = "verbatim_family"
  )

  testthat::expect_error(
    aggregate_bien_taxa(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      vec_columns_joined = c("subplot", "family_matched"),
      vec_columns_agreeing = "family_matched"
    ),
    regexp = "family_matched"
  )

  data_numeric_subplot <-
    dplyr::mutate(data_records, subplot = c(1, 2))

  testthat::expect_error(
    aggregate_bien_taxa(
      data_records = data_numeric_subplot,
      vec_columns_plot = "plot_name",
      vec_columns_joined = "subplot",
      vec_columns_agreeing = "family_matched"
    ),
    regexp = "character"
  )

  data_no_name <-
    dplyr::mutate(data_records, name_matched = c("Quercus alba", NA))

  testthat::expect_error(
    aggregate_bien_taxa(
      data_records = data_no_name,
      vec_columns_plot = "plot_name",
      vec_columns_joined = "subplot",
      vec_columns_agreeing = "family_matched"
    ),
    regexp = "taxon name"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("aggregate_bien_taxa() merges records per taxon and plot", {
  data_records <-
    tibble::tibble(
      datasource = c("CVS", "CVS", "CVS", "CVS", "TEAM"),
      plot_name = c("P1", "P1", "P1", "P2", "T1"),
      longitude = c(-80, -80, -80, -81, -84),
      name_matched = c(
        "Quercus alba", "Quercus alba", "Acer rubrum", "Quercus alba",
        "Quercus alba"
      ),
      individual_count = c(2L, NA, 1L, 4L, NA),
      subplot = c("2", "1", NA, "1", NA),
      name_matched_author = c("L.", "L.", "L.", "L.", "L."),
      family_matched = c(
        "Fagaceae", "Fagaceae", "Sapindaceae", "Fagaceae", "Fagaceae"
      ),
      date_collected = base::as.Date("2010-01-01")
    )

  res <-
    aggregate_bien_taxa(
      data_records = data_records,
      vec_columns_plot = c("datasource", "plot_name", "longitude"),
      col_taxon = "name_matched",
      col_count = "individual_count",
      vec_columns_joined = c("subplot", "name_matched_author"),
      vec_columns_agreeing = "family_matched",
      separator = " | "
    )

  data_expected <-
    tibble::tibble(
      datasource = c("CVS", "CVS", "CVS", "TEAM"),
      plot_name = c("P1", "P1", "P2", "T1"),
      longitude = c(-80, -80, -81, -84),
      name_matched = c(
        "Acer rubrum", "Quercus alba", "Quercus alba", "Quercus alba"
      ),
      individual_count = c(1L, 2L, 4L, NA),
      subplot = c(NA, "1 | 2", "1", NA),
      name_matched_author = c("L.", "L.", "L.", "L."),
      family_matched = c("Sapindaceae", "Fagaceae", "Fagaceae", "Fagaceae")
    )

  testthat::expect_equal(res, data_expected)
})

testthat::test_that("aggregate_bien_taxa() counts identical records", {
  data_records <-
    tibble::tibble(
      plot_name = c("P1", "P1", "P1"),
      name_matched = c("Ficus insipida", "Ficus insipida", "Ficus insipida"),
      individual_count = c(1L, 1L, 1L),
      subplot = c("3", "3", "3")
    )

  res <-
    aggregate_bien_taxa(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      vec_columns_joined = "subplot",
      vec_columns_agreeing = base::character(0)
    )

  testthat::expect_equal(base::nrow(res), 1L)
  testthat::expect_identical(dplyr::pull(res, individual_count), 3L)
  testthat::expect_equal(dplyr::pull(res, subplot), "3")
})

testthat::test_that("aggregate_bien_taxa() keeps all-missing counts missing", {
  data_records <-
    tibble::tibble(
      plot_name = c("T1", "T1"),
      name_matched = c("Inga edulis", "Inga edulis"),
      individual_count = c(NA_integer_, NA_integer_),
      name_matched_author = c("W. Bartram", "Bartram")
    )

  res <-
    aggregate_bien_taxa(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      vec_columns_joined = "name_matched_author",
      vec_columns_agreeing = base::character(0)
    )

  testthat::expect_identical(dplyr::pull(res, individual_count), NA_integer_)
  testthat::expect_equal(
    dplyr::pull(res, name_matched_author),
    "Bartram | W. Bartram"
  )
})

testthat::test_that("aggregate_bien_taxa() aborts on disagreeing taxon data", {
  data_records <-
    tibble::tibble(
      plot_name = c("P1", "P1"),
      name_matched = c("Quercus alba", "Quercus alba"),
      individual_count = c(1L, 2L),
      family_matched = c("Fagaceae", NA)
    )

  testthat::expect_error(
    aggregate_bien_taxa(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      vec_columns_joined = base::character(0),
      vec_columns_agreeing = "family_matched"
    ),
    regexp = "family_matched"
  )
})

testthat::test_that("aggregate_bien_taxa() ignores the input row order", {
  data_records <-
    tibble::tibble(
      plot_name = c("P1", "P1", "P2", "P1", "P2"),
      name_matched = c("a", "b", "a", "a", "a"),
      individual_count = c(1L, 2L, 3L, 4L, NA),
      subplot = c("x", "y", "z", "w", "v")
    )

  res <-
    aggregate_bien_taxa(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      vec_columns_joined = "subplot",
      vec_columns_agreeing = base::character(0)
    )

  res_reordered <-
    aggregate_bien_taxa(
      data_records = data_records[c(5, 3, 1, 4, 2), ],
      vec_columns_plot = "plot_name",
      vec_columns_joined = "subplot",
      vec_columns_agreeing = base::character(0)
    )

  testthat::expect_identical(res_reordered, res)
  testthat::expect_equal(dplyr::pull(res, subplot), c("w | x", "y", "v | z"))
})


#----------------------------------------------------------#
# Edge cases -----
#----------------------------------------------------------#

testthat::test_that("aggregate_bien_taxa() returns zero rows unchanged", {
  data_records <-
    tibble::tibble(
      plot_name = base::character(0),
      name_matched = base::character(0),
      individual_count = base::integer(0),
      subplot = base::character(0)
    )

  res <-
    aggregate_bien_taxa(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      vec_columns_joined = "subplot",
      vec_columns_agreeing = base::character(0)
    )

  testthat::expect_equal(res, data_records)
})

testthat::test_that("aggregate_bien_taxa() handles many records", {
  set.seed(900723)

  data_records <-
    tibble::tibble(
      plot_name = base::sample(
        x = base::paste0("P", base::seq_len(50)),
        size = 5000,
        replace = TRUE
      ),
      name_matched = base::sample(
        x = base::paste0("Taxon ", base::seq_len(20)),
        size = 5000,
        replace = TRUE
      ),
      individual_count = base::sample(
        x = c(1L, 2L, NA),
        size = 5000,
        replace = TRUE
      ),
      subplot = base::sample(
        x = c("1", "2", "3", NA),
        size = 5000,
        replace = TRUE
      )
    )

  res <-
    aggregate_bien_taxa(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      vec_columns_joined = "subplot",
      vec_columns_agreeing = base::character(0)
    )

  data_keys <-
    dplyr::select(res, plot_name, name_matched)

  testthat::expect_false(base::any(base::duplicated(data_keys)))
  testthat::expect_equal(
    base::sum(dplyr::pull(res, individual_count), na.rm = TRUE),
    base::sum(dplyr::pull(data_records, individual_count), na.rm = TRUE)
  )
})

testthat::test_that("aggregate_bien_taxa() joins values in native encoding", {
  # Text marked as native ("unknown") with non-ASCII characters is rejected
  #   by a radix sort unless it is marked as UTF-8 first.
  vec_author <-
    c("L\u00f6ve", "M\u00fcll. Arg.")

  base::Encoding(vec_author) <- "unknown"

  data_records <-
    tibble::tibble(
      plot_name = c("P1", "P1"),
      name_matched = c("Quercus alba", "Quercus alba"),
      individual_count = c(1L, 2L),
      name_matched_author = vec_author
    )

  res <-
    aggregate_bien_taxa(
      data_records = data_records,
      vec_columns_plot = "plot_name",
      vec_columns_joined = "name_matched_author",
      vec_columns_agreeing = base::character(0)
    )

  testthat::expect_identical(
    base::charToRaw(dplyr::pull(res, name_matched_author)),
    base::charToRaw(base::paste(vec_author, collapse = " | "))
  )
})
