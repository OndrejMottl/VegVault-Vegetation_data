#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("save_bien_plot_datasource() validates arguments", {
  dir_raw <-
    withr::local_tempdir()

  testthat::expect_error(
    save_bien_plot_datasource(
      datasource = "",
      dir_raw = dir_raw
    ),
    regexp = "datasource"
  )

  testthat::expect_error(
    save_bien_plot_datasource(
      datasource = "CVS",
      dir_raw = base::file.path(dir_raw, "missing")
    ),
    regexp = "dir_raw"
  )

  testthat::expect_error(
    save_bien_plot_datasource(
      datasource = "CVS",
      dir_raw = dir_raw,
      date_save = "2026-11-20"
    ),
    regexp = "date_save"
  )
})

testthat::test_that("save_bien_plot_datasource() never overwrites a raw file", {
  dir_raw <-
    withr::local_tempdir()

  path_existing <-
    base::file.path(
      dir_raw,
      base::paste0("CVS_2025-01-01__", base::strrep("a", 32), "__.rds")
    )

  base::saveRDS(object = 1, file = path_existing)

  testthat::local_mocked_bindings(
    BIEN_plot_datasource = function(...) {
      cli::cli_abort("The BIEN database must not be queried.")
    },
    .package = "BIEN"
  )

  testthat::expect_error(
    save_bien_plot_datasource(
      datasource = "CVS",
      dir_raw = dir_raw
    ),
    regexp = "already"
  )

  testthat::expect_identical(base::list.files(dir_raw), base::basename(path_existing))
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("save_bien_plot_datasource() saves the records of one datasource", {
  dir_raw <-
    withr::local_tempdir()

  data_fixture <-
    data.frame(
      plot_name = c("P1", "P1"),
      name_matched = c("Quercus alba", "Acer rubrum"),
      individual_count = c(1L, NA)
    )

  env_capture <-
    base::new.env()

  testthat::local_mocked_bindings(
    BIEN_plot_datasource = function(datasource, ...) {
      base::assign(
        x = "list_args",
        value = c(list(datasource = datasource), list(...)),
        envir = env_capture
      )

      data_fixture
    },
    .package = "BIEN"
  )

  res <-
    save_bien_plot_datasource(
      datasource = "TEAM",
      dir_raw = dir_raw,
      date_save = base::as.Date("2026-11-20")
    )

  testthat::expect_identical(
    base::basename(res),
    base::paste0(
      "TEAM_2026-11-20__", rlang::hash(data_fixture), "__.rds"
    )
  )
  testthat::expect_true(base::file.exists(res))
  testthat::expect_identical(readr::read_rds(res), data_fixture)

  list_args <-
    base::get("list_args", envir = env_capture)

  testthat::expect_identical(list_args$datasource, "TEAM")
  testthat::expect_true(list_args$all.taxonomy)
  testthat::expect_true(list_args$collection.info)
  testthat::expect_true(list_args$all.metadata)
})
