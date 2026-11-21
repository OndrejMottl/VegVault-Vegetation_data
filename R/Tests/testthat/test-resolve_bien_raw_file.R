#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("resolve_bien_raw_file() validates arguments", {
  dir_raw <-
    withr::local_tempdir()

  testthat::expect_error(
    resolve_bien_raw_file(
      dir_raw = base::file.path(dir_raw, "missing"),
      datasource = "CVS",
      flag_download = FALSE
    ),
    regexp = "dir_raw"
  )

  testthat::expect_error(
    resolve_bien_raw_file(
      dir_raw = dir_raw,
      datasource = NA_character_,
      flag_download = FALSE
    ),
    regexp = "datasource"
  )

  testthat::expect_error(
    resolve_bien_raw_file(
      dir_raw = dir_raw,
      datasource = "CVS",
      flag_download = "no"
    ),
    regexp = "flag_download"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("resolve_bien_raw_file() returns the one file of the datasource", {
  dir_raw <-
    withr::local_tempdir()

  vec_file_names <-
    c(
      base::paste0("CVS_2026-11-20__", base::strrep("a", 32), "__.rds"),
      base::paste0("CVSX_2026-11-20__", base::strrep("b", 32), "__.rds"),
      base::paste0("CVS_extra_2026-11-20__", base::strrep("c", 32), "__.rds"),
      "CVS.txt"
    )

  purrr::walk(
    .x = vec_file_names,
    .f = ~ base::saveRDS(object = 1, file = base::file.path(dir_raw, .x))
  )

  base::dir.create(base::file.path(dir_raw, "CVS"))

  res <-
    resolve_bien_raw_file(
      dir_raw = dir_raw,
      datasource = "CVS",
      flag_download = FALSE
    )

  testthat::expect_identical(
    base::normalizePath(res),
    base::normalizePath(base::file.path(dir_raw, vec_file_names[1]))
  )
})

testthat::test_that("resolve_bien_raw_file() treats the datasource name literally", {
  dir_raw <-
    withr::local_tempdir()

  base::saveRDS(
    object = 1,
    file = base::file.path(
      dir_raw,
      base::paste0("aXb_2026-11-20__", base::strrep("a", 32), "__.rds")
    )
  )

  testthat::expect_error(
    resolve_bien_raw_file(
      dir_raw = dir_raw,
      datasource = "a.b",
      flag_download = FALSE
    ),
    regexp = "flag_download"
  )
})

testthat::test_that("resolve_bien_raw_file() names the download flag for a missing file", {
  dir_raw <-
    withr::local_tempdir()

  testthat::expect_error(
    resolve_bien_raw_file(
      dir_raw = dir_raw,
      datasource = "TEAM",
      flag_download = FALSE
    ),
    regexp = "flag_download"
  )

  testthat::expect_error(
    resolve_bien_raw_file(
      dir_raw = dir_raw,
      datasource = "TEAM",
      flag_download = FALSE
    ),
    regexp = "TEAM"
  )
})

testthat::test_that("resolve_bien_raw_file() never chooses between several files", {
  dir_raw <-
    withr::local_tempdir()

  purrr::walk(
    .x = c("2025-01-01", "2026-11-20"),
    .f = ~ base::saveRDS(
      object = 1,
      file = base::file.path(
        dir_raw,
        base::paste0("CVS_", .x, "__", base::strrep("a", 32), "__.rds")
      )
    )
  )

  testthat::expect_error(
    resolve_bien_raw_file(
      dir_raw = dir_raw,
      datasource = "CVS",
      flag_download = FALSE
    ),
    regexp = "more than one"
  )
})

testthat::test_that("resolve_bien_raw_file() downloads a missing file only with the flag", {
  dir_raw <-
    withr::local_tempdir()

  testthat::local_mocked_bindings(
    BIEN_plot_datasource = function(...) {
      data.frame(plot_name = "P1", name_matched = "Quercus alba")
    },
    .package = "BIEN"
  )

  res <-
    resolve_bien_raw_file(
      dir_raw = dir_raw,
      datasource = "TEAM",
      flag_download = TRUE
    )

  testthat::expect_true(base::file.exists(res))
  testthat::expect_match(
    base::basename(res),
    "^TEAM_[0-9]{4}-[0-9]{2}-[0-9]{2}__[0-9a-f]{32}__[.]rds$"
  )
})

testthat::test_that("resolve_bien_raw_file() never downloads an existing file again", {
  dir_raw <-
    withr::local_tempdir()

  path_existing <-
    base::file.path(
      dir_raw,
      base::paste0("TEAM_2026-11-20__", base::strrep("a", 32), "__.rds")
    )

  base::saveRDS(object = 1, file = path_existing)

  testthat::local_mocked_bindings(
    BIEN_plot_datasource = function(...) {
      cli::cli_abort("The BIEN database must not be queried.")
    },
    .package = "BIEN"
  )

  res <-
    resolve_bien_raw_file(
      dir_raw = dir_raw,
      datasource = "TEAM",
      flag_download = TRUE
    )

  testthat::expect_identical(
    base::normalizePath(res),
    base::normalizePath(path_existing)
  )
})
