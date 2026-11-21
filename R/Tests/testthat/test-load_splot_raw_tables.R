#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("load_splot_raw_tables() validates arguments", {
  testthat::expect_error(
    load_splot_raw_tables(path_file = 1),
    regexp = "path_file"
  )

  testthat::expect_error(
    load_splot_raw_tables(
      path_file = base::file.path(base::tempdir(), "missing.RData")
    ),
    regexp = "does not exist"
  )
})

testthat::test_that("load_splot_raw_tables() aborts when a table is missing", {
  path_file <-
    withr::local_tempfile(fileext = ".RData")

  env_fixture <-
    base::list2env(
      list(
        DT2.oa = tibble::tibble(PlotObservationID = 1, Species = "Abies alba")
      )
    )

  base::save(list = "DT2.oa", envir = env_fixture, file = path_file)

  testthat::expect_error(
    load_splot_raw_tables(path_file = path_file),
    regexp = "header.oa"
  )
})

testthat::test_that("load_splot_raw_tables() aborts when a table is not a data frame", {
  path_file <-
    withr::local_tempfile(fileext = ".RData")

  env_fixture <-
    base::list2env(
      list(
        DT2.oa = tibble::tibble(PlotObservationID = 1, Species = "Abies alba"),
        header.oa = "not a table"
      )
    )

  base::save(
    list = c("DT2.oa", "header.oa"),
    envir = env_fixture,
    file = path_file
  )

  testthat::expect_error(
    load_splot_raw_tables(path_file = path_file),
    regexp = "header.oa"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("load_splot_raw_tables() returns both tables unchanged", {
  path_file <-
    withr::local_tempfile(fileext = ".RData")

  data_taxa <-
    tibble::tibble(
      PlotObservationID = c(1, 1, 2),
      Species = c("Abies alba", "Picea abies", "Fagus sylvatica")
    )

  data_meta <-
    tibble::tibble(
      PlotObservationID = c(1, 2),
      GIVD_ID = c("EU-00-001", "EU-00-002")
    )

  env_fixture <-
    base::list2env(list(DT2.oa = data_taxa, header.oa = data_meta))

  base::save(
    list = c("DT2.oa", "header.oa"),
    envir = env_fixture,
    file = path_file
  )

  res <-
    load_splot_raw_tables(path_file = path_file)

  testthat::expect_type(res, "list")
  testthat::expect_named(res, c("data_taxa", "data_meta"))
  testthat::expect_identical(res$data_taxa, data_taxa)
  testthat::expect_identical(res$data_meta, data_meta)
  testthat::expect_false(
    base::exists("DT2.oa", envir = base::globalenv(), inherits = FALSE)
  )
})
