#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("validate_export_artefact() validates arguments", {
  dir_output <-
    withr::local_tempdir()

  testthat::expect_error(
    validate_export_artefact(
      path_artefact = base::file.path(dir_output, "missing.qs"),
      path_contract = here::here("Data", "Contracts", "splot_plots.yml")
    ),
    regexp = "path_artefact"
  )

  path_artefact <-
    base::file.path(dir_output, "data_splot.qs")

  qs2::qs_save(object = tibble::tibble(a = 1), file = path_artefact)

  testthat::expect_error(
    validate_export_artefact(
      path_artefact = path_artefact,
      path_contract = base::file.path(dir_output, "missing.yml")
    ),
    regexp = "path_contract"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("validate_export_artefact() passes a valid artefact", {
  dir_output <-
    withr::local_tempdir()

  list_fixture <-
    build_splot_plots_fixture()

  path_artefact <-
    base::file.path(dir_output, base::names(list_fixture))

  qs2::qs_save(object = list_fixture[[1]], file = path_artefact)

  res <-
    validate_export_artefact(
      path_artefact = path_artefact,
      path_contract = here::here("Data", "Contracts", "splot_plots.yml")
    )

  testthat::expect_identical(res, path_artefact)
})

testthat::test_that("validate_export_artefact() rejects an artefact that breaks the contract", {
  dir_output <-
    withr::local_tempdir()

  list_fixture <-
    build_splot_plots_fixture()

  data_broken <-
    dplyr::mutate(
      list_fixture[[1]],
      taxa = purrr::map(
        .x = taxa,
        .f = ~ dplyr::mutate(.x, Species = NA_character_)
      )
    )

  path_artefact <-
    base::file.path(dir_output, base::names(list_fixture))

  qs2::qs_save(object = data_broken, file = path_artefact)

  testthat::expect_error(
    validate_export_artefact(
      path_artefact = path_artefact,
      path_contract = here::here("Data", "Contracts", "splot_plots.yml")
    ),
    class = "producer_contract_error"
  )
})

testthat::test_that("validate_export_artefact() rejects a wrong file name", {
  dir_output <-
    withr::local_tempdir()

  list_fixture <-
    build_splot_plots_fixture()

  path_artefact <-
    base::file.path(dir_output, "data_splot_latest.qs")

  qs2::qs_save(object = list_fixture[[1]], file = path_artefact)

  testthat::expect_error(
    validate_export_artefact(
      path_artefact = path_artefact,
      path_contract = here::here("Data", "Contracts", "splot_plots.yml")
    ),
    class = "producer_contract_error"
  )
})
