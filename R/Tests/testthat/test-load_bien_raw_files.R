#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("load_bien_raw_files() validates arguments", {
  dir_raw <-
    withr::local_tempdir()

  path_file <-
    base::file.path(dir_raw, "CVS.rds")

  base::saveRDS(object = data.frame(plot_name = "P1"), file = path_file)

  testthat::expect_error(
    load_bien_raw_files(
      vec_paths = path_file,
      vec_datasources = c("CVS", "TEAM")
    ),
    regexp = "same length"
  )

  testthat::expect_error(
    load_bien_raw_files(
      vec_paths = c(path_file, path_file),
      vec_datasources = c("CVS", "CVS")
    ),
    regexp = "duplicated"
  )

  testthat::expect_error(
    load_bien_raw_files(
      vec_paths = base::file.path(dir_raw, "missing.rds"),
      vec_datasources = "CVS"
    ),
    regexp = "does not exist"
  )
})

testthat::test_that("load_bien_raw_files() aborts when no datasource has records", {
  dir_raw <-
    withr::local_tempdir()

  path_file <-
    base::file.path(dir_raw, "FIA.rds")

  base::saveRDS(object = data.frame(plot_name = character(0)), file = path_file)

  testthat::expect_error(
    load_bien_raw_files(
      vec_paths = path_file,
      vec_datasources = "FIA"
    ),
    regexp = "No BIEN datasource"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("load_bien_raw_files() binds the datasources with records in order", {
  dir_raw <-
    withr::local_tempdir()

  list_objects <-
    list(
      CVS = data.frame(
        plot_name = c("C1", "C2"),
        name_matched = c("Quercus alba", "Acer rubrum")
      ),
      FIA = data.frame(plot_name = character(0), name_matched = character(0)),
      gillespie = NULL,
      SALVIAS = data.frame(plot_name = NA_character_, name_matched = NA_character_),
      TEAM = data.frame(plot_name = "T1", name_matched = "Ficus insipida")
    )

  vec_paths <-
    purrr::imap_chr(
      .x = list_objects,
      .f = ~ {
        path_object <- base::file.path(dir_raw, base::paste0(.y, ".rds"))
        base::saveRDS(object = .x, file = path_object)
        path_object
      }
    )

  res <-
    load_bien_raw_files(
      vec_paths = base::unname(vec_paths[c("TEAM", "CVS", "FIA", "gillespie", "SALVIAS")]),
      vec_datasources = c("TEAM", "CVS", "FIA", "gillespie", "SALVIAS")
    )

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_identical(base::names(res)[1], "datasource")
  testthat::expect_identical(res$datasource, c("TEAM", "CVS", "CVS"))
  testthat::expect_identical(res$plot_name, c("T1", "C1", "C2"))
  testthat::expect_identical(
    res$name_matched,
    c("Ficus insipida", "Quercus alba", "Acer rubrum")
  )
})

testthat::test_that("load_bien_raw_files() names records after the datasource of their file", {
  dir_raw <-
    withr::local_tempdir()

  path_file <-
    base::file.path(dir_raw, "TEAM.rds")

  base::saveRDS(
    object = data.frame(datasource = "as recorded by BIEN", plot_name = "T1"),
    file = path_file
  )

  res <-
    load_bien_raw_files(
      vec_paths = path_file,
      vec_datasources = "TEAM"
    )

  testthat::expect_identical(base::names(res), c("datasource", "plot_name"))
  testthat::expect_identical(res$datasource, "TEAM")
})
