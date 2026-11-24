#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("validate_splot_raw_file() validates arguments", {
  sha_valid <- base::strrep("a", 64)

  testthat::expect_error(
    validate_splot_raw_file(
      path_file = 1,
      sha256_expected = sha_valid,
      version_label = "sPlotOpen test version"
    ),
    regexp = "path_file"
  )

  testthat::expect_error(
    validate_splot_raw_file(
      path_file = "sPlotOpen.RData",
      sha256_expected = "abc",
      version_label = "sPlotOpen test version"
    ),
    regexp = "sha256_expected"
  )

  testthat::expect_error(
    validate_splot_raw_file(
      path_file = "sPlotOpen.RData",
      sha256_expected = sha_valid,
      version_label = ""
    ),
    regexp = "version_label"
  )
})

testthat::test_that("validate_splot_raw_file() names the manual step for a missing file", {
  path_missing <-
    base::file.path(base::tempdir(), "no_such_sPlotOpen.RData")

  testthat::expect_error(
    validate_splot_raw_file(
      path_file = path_missing,
      sha256_expected = base::strrep("a", 64),
      version_label = "sPlotOpen test version"
    ),
    regexp = "manual"
  )

  testthat::expect_error(
    validate_splot_raw_file(
      path_file = path_missing,
      sha256_expected = base::strrep("a", 64),
      version_label = "sPlotOpen test version"
    ),
    regexp = "sPlotOpen test version"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("validate_splot_raw_file() returns the path of the recorded version", {
  path_file <-
    withr::local_tempfile(fileext = ".RData")

  base::writeLines("sPlotOpen fixture", con = path_file)

  sha_file <-
    digest::digest(file = path_file, algo = "sha256")

  res <-
    validate_splot_raw_file(
      path_file = path_file,
      sha256_expected = sha_file,
      version_label = "sPlotOpen test version"
    )

  testthat::expect_identical(res, path_file)
})

testthat::test_that("validate_splot_raw_file() rejects another version of the file", {
  path_file <-
    withr::local_tempfile(fileext = ".RData")

  base::writeLines("another sPlotOpen version", con = path_file)

  testthat::expect_error(
    validate_splot_raw_file(
      path_file = path_file,
      sha256_expected = base::strrep("0", 64),
      version_label = "sPlotOpen test version"
    ),
    regexp = "checksum"
  )
})
