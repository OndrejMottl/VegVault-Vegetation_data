#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("save_export_artefact() validates arguments", {
  dir_output <-
    withr::local_tempdir()

  testthat::expect_error(
    save_export_artefact(
      data_export = tibble::tibble(a = 1),
      file_name = "",
      dir_output = dir_output
    ),
    regexp = "file_name"
  )

  testthat::expect_error(
    save_export_artefact(
      data_export = tibble::tibble(a = 1),
      file_name = "data_bien",
      dir_output = base::file.path(dir_output, "missing")
    ),
    regexp = "dir_output"
  )

  testthat::expect_error(
    save_export_artefact(
      data_export = tibble::tibble(a = 1),
      file_name = "data_bien",
      dir_output = dir_output,
      date_save = "2026-11-20"
    ),
    regexp = "date_save"
  )

  testthat::expect_error(
    save_export_artefact(
      data_export = tibble::tibble(a = 1),
      file_name = "data_bien",
      dir_output = dir_output,
      flag_replace_previous = NA
    ),
    regexp = "flag_replace_previous"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("save_export_artefact() writes a qs2 file with the artefact name", {
  dir_output <-
    withr::local_tempdir()

  data_export <-
    tibble::tibble(
      plot_name = c("P1", "P2"),
      plot_data = list(
        tibble::tibble(name_matched = "Quercus alba"),
        tibble::tibble(name_matched = "Acer rubrum")
      )
    )

  res <-
    save_export_artefact(
      data_export = data_export,
      file_name = "data_bien",
      dir_output = dir_output,
      date_save = base::as.Date("2026-11-20")
    )

  testthat::expect_identical(
    base::basename(res),
    base::paste0("data_bien_2026-11-20__", rlang::hash(data_export), "__.qs")
  )
  testthat::expect_identical(qs2::qs_read(res), data_export)
})

testthat::test_that("save_export_artefact() keeps an identical artefact", {
  dir_output <-
    withr::local_tempdir()

  data_export <-
    tibble::tibble(a = 1)

  path_first <-
    save_export_artefact(
      data_export = data_export,
      file_name = "data_bien",
      dir_output = dir_output,
      date_save = base::as.Date("2026-11-20")
    )

  path_second <-
    save_export_artefact(
      data_export = data_export,
      file_name = "data_bien",
      dir_output = dir_output,
      date_save = base::as.Date("2026-11-20")
    )

  testthat::expect_identical(path_second, path_first)
  testthat::expect_identical(base::length(base::list.files(dir_output)), 1L)
})

testthat::test_that("save_export_artefact() never keeps two versions of an artefact", {
  dir_output <-
    withr::local_tempdir()

  path_old <-
    save_export_artefact(
      data_export = tibble::tibble(a = 1),
      file_name = "data_bien",
      dir_output = dir_output,
      date_save = base::as.Date("2026-11-19")
    )

  path_other_artefact <-
    save_export_artefact(
      data_export = tibble::tibble(a = 1),
      file_name = "data_splot",
      dir_output = dir_output,
      date_save = base::as.Date("2026-11-19")
    )

  testthat::expect_error(
    save_export_artefact(
      data_export = tibble::tibble(a = 2),
      file_name = "data_bien",
      dir_output = dir_output,
      date_save = base::as.Date("2026-11-20")
    ),
    regexp = "flag_replace_previous"
  )

  res <-
    save_export_artefact(
      data_export = tibble::tibble(a = 2),
      file_name = "data_bien",
      dir_output = dir_output,
      date_save = base::as.Date("2026-11-20"),
      flag_replace_previous = TRUE
    )

  testthat::expect_false(base::file.exists(path_old))
  testthat::expect_true(base::file.exists(path_other_artefact))
  testthat::expect_true(base::file.exists(res))
  testthat::expect_identical(qs2::qs_read(res), tibble::tibble(a = 2))
})
