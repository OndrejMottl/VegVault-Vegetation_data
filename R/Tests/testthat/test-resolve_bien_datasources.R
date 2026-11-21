#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("resolve_bien_datasources() validates arguments", {
  testthat::expect_error(
    resolve_bien_datasources(
      vec_datasources = character(0),
      flag_download = FALSE
    ),
    regexp = "vec_datasources"
  )

  testthat::expect_error(
    resolve_bien_datasources(
      vec_datasources = c("CVS", NA),
      flag_download = FALSE
    ),
    regexp = "vec_datasources"
  )

  testthat::expect_error(
    resolve_bien_datasources(
      vec_datasources = c("CVS", ""),
      flag_download = FALSE
    ),
    regexp = "vec_datasources"
  )

  testthat::expect_error(
    resolve_bien_datasources(
      vec_datasources = c("CVS", "CVS"),
      flag_download = FALSE
    ),
    regexp = "duplicated"
  )

  testthat::expect_error(
    resolve_bien_datasources(
      vec_datasources = "CVS",
      flag_download = NA
    ),
    regexp = "flag_download"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("resolve_bien_datasources() makes no network call without the flag", {
  testthat::local_mocked_bindings(
    BIEN_plot_list_datasource = function(...) {
      cli::cli_abort("The BIEN database must not be queried.")
    },
    .package = "BIEN"
  )

  res <-
    resolve_bien_datasources(
      vec_datasources = c("CVS", "TEAM"),
      flag_download = FALSE
    )

  testthat::expect_identical(res, c("CVS", "TEAM"))
})

testthat::test_that("resolve_bien_datasources() accepts the datasources BIEN lists", {
  testthat::local_mocked_bindings(
    BIEN_plot_list_datasource = function(...) {
      data.frame(datasource = c("TEAM", "CVS"))
    },
    .package = "BIEN"
  )

  res <-
    resolve_bien_datasources(
      vec_datasources = c("CVS", "TEAM"),
      flag_download = TRUE
    )

  testthat::expect_identical(res, c("CVS", "TEAM"))
})

testthat::test_that("resolve_bien_datasources() rejects a datasource that is not configured", {
  testthat::local_mocked_bindings(
    BIEN_plot_list_datasource = function(...) {
      data.frame(datasource = c("CVS", "TEAM", "FIA"))
    },
    .package = "BIEN"
  )

  testthat::expect_error(
    resolve_bien_datasources(
      vec_datasources = c("CVS", "TEAM"),
      flag_download = TRUE
    ),
    regexp = "FIA"
  )
})

testthat::test_that("resolve_bien_datasources() rejects a datasource BIEN does not list", {
  testthat::local_mocked_bindings(
    BIEN_plot_list_datasource = function(...) {
      data.frame(datasource = "CVS")
    },
    .package = "BIEN"
  )

  testthat::expect_error(
    resolve_bien_datasources(
      vec_datasources = c("CVS", "TEAM"),
      flag_download = TRUE
    ),
    regexp = "TEAM"
  )
})
