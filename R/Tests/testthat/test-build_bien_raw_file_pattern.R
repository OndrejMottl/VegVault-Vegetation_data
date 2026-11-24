#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("build_bien_raw_file_pattern() validates arguments", {
  testthat::expect_error(
    build_bien_raw_file_pattern(datasource = ""),
    regexp = "datasource"
  )

  testthat::expect_error(
    build_bien_raw_file_pattern(datasource = c("CVS", "TEAM")),
    regexp = "datasource"
  )

  testthat::expect_error(
    build_bien_raw_file_pattern(datasource = NA_character_),
    regexp = "datasource"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("build_bien_raw_file_pattern() matches only the datasource's raw files", {
  res <-
    build_bien_raw_file_pattern(datasource = "CVS")

  testthat::expect_type(res, "character")
  testthat::expect_length(res, 1L)

  vec_matching <-
    c(
      base::paste0("CVS_2026-11-20__", base::strrep("a", 32), "__.rds"),
      base::paste0("CVS_2023-07-28__", "0123456789abcdef0123456789abcdef", "__.rds")
    )

  vec_not_matching <-
    c(
      base::paste0("CVSX_2026-11-20__", base::strrep("a", 32), "__.rds"),
      base::paste0("CVS_extra_2026-11-20__", base::strrep("a", 32), "__.rds"),
      base::paste0("xCVS_2026-11-20__", base::strrep("a", 32), "__.rds"),
      base::paste0("CVS_2026-11-20__", base::strrep("a", 32), "__.qs"),
      base::paste0("CVS_2026-11-20__", base::strrep("A", 32), "__.rds"),
      base::paste0("CVS_2026-11-20__", base::strrep("a", 31), "__.rds"),
      "CVS_2026-11-20.rds",
      "CVS"
    )

  testthat::expect_true(base::all(base::grepl(res, vec_matching)))
  testthat::expect_false(base::any(base::grepl(res, vec_not_matching)))
})

testthat::test_that("build_bien_raw_file_pattern() treats the datasource name literally", {
  res <-
    build_bien_raw_file_pattern(datasource = "a.b")

  testthat::expect_true(
    base::grepl(res, base::paste0("a.b_2026-11-20__", base::strrep("a", 32), "__.rds"))
  )
  testthat::expect_false(
    base::grepl(res, base::paste0("aXb_2026-11-20__", base::strrep("a", 32), "__.rds"))
  )
})
