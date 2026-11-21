#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("filter_named_taxa() validates arguments", {
  data_plots <-
    tibble::tibble(
      PlotObservationID = 1,
      taxa = list(tibble::tibble(Species = "Abies alba"))
    )

  testthat::expect_error(
    filter_named_taxa(
      data_plots = "not a data frame",
      col_taxa = "taxa",
      col_taxon_name = "Species"
    ),
    regexp = "data_plots"
  )

  testthat::expect_error(
    filter_named_taxa(
      data_plots = data_plots,
      col_taxa = "plot_taxa",
      col_taxon_name = "Species"
    ),
    regexp = "plot_taxa"
  )

  testthat::expect_error(
    filter_named_taxa(
      data_plots = data_plots,
      col_taxa = c("taxa", "taxa"),
      col_taxon_name = "Species"
    ),
    regexp = "col_taxa"
  )

  testthat::expect_error(
    filter_named_taxa(
      data_plots = data_plots,
      col_taxa = "taxa",
      col_taxon_name = NA_character_
    ),
    regexp = "col_taxon_name"
  )
})

testthat::test_that("filter_named_taxa() rejects malformed taxa elements", {
  data_no_name <-
    tibble::tibble(
      PlotObservationID = c(1, 2),
      taxa = list(
        tibble::tibble(Species = "Abies alba"),
        tibble::tibble(Original_species = "Picea abies")
      )
    )

  testthat::expect_error(
    filter_named_taxa(
      data_plots = data_no_name,
      col_taxa = "taxa",
      col_taxon_name = "Species"
    ),
    regexp = "Species"
  )

  data_not_frame <-
    tibble::tibble(
      PlotObservationID = c(1, 2),
      taxa = list(
        tibble::tibble(Species = "Abies alba"),
        "Picea abies"
      )
    )

  testthat::expect_error(
    filter_named_taxa(
      data_plots = data_not_frame,
      col_taxa = "taxa",
      col_taxon_name = "Species"
    ),
    regexp = "data frame"
  )

  data_not_list <-
    tibble::tibble(
      PlotObservationID = 1,
      taxa = "Abies alba"
    )

  testthat::expect_error(
    filter_named_taxa(
      data_plots = data_not_list,
      col_taxa = "taxa",
      col_taxon_name = "Species"
    ),
    regexp = "list"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("filter_named_taxa() drops missing and empty names", {
  data_plots <-
    tibble::tibble(
      PlotObservationID = c(1, 2),
      Releve_area = c(100, 200),
      taxa = list(
        tibble::tibble(
          Species = c("Abies alba", NA, "Picea abies", ""),
          Original_abundance = c(10, 20, 30, 40)
        ),
        tibble::tibble(
          Species = "Fagus sylvatica",
          Original_abundance = 50
        )
      )
    )

  res <-
    filter_named_taxa(
      data_plots = data_plots,
      col_taxa = "taxa",
      col_taxon_name = "Species"
    )

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_named(res, c("PlotObservationID", "Releve_area", "taxa"))
  testthat::expect_equal(dplyr::pull(res, PlotObservationID), c(1, 2))

  data_taxa_first <-
    dplyr::pull(res, taxa) |>
    purrr::pluck(1)

  testthat::expect_equal(
    data_taxa_first,
    tibble::tibble(
      Species = c("Abies alba", "Picea abies"),
      Original_abundance = c(10, 30)
    )
  )

  data_taxa_second <-
    dplyr::pull(res, taxa) |>
    purrr::pluck(2)

  testthat::expect_identical(
    data_taxa_second,
    purrr::pluck(dplyr::pull(data_plots, taxa), 2)
  )
})

testthat::test_that("filter_named_taxa() keeps names made of spaces", {
  data_plots <-
    tibble::tibble(
      PlotObservationID = 1,
      taxa = list(tibble::tibble(Species = c(" ", "Abies alba")))
    )

  res <-
    filter_named_taxa(
      data_plots = data_plots,
      col_taxa = "taxa",
      col_taxon_name = "Species"
    )

  data_taxa <-
    dplyr::pull(res, taxa) |>
    purrr::pluck(1)

  testthat::expect_equal(dplyr::pull(data_taxa, Species), c(" ", "Abies alba"))
})

testthat::test_that("filter_named_taxa() drops plots without named taxa", {
  data_plots <-
    tibble::tibble(
      PlotObservationID = c(1, 2, 3, 4),
      taxa = list(
        tibble::tibble(Species = c(NA, "")),
        tibble::tibble(Species = "Abies alba"),
        tibble::tibble(Species = base::character(0)),
        tibble::tibble(Species = c("Picea abies", NA))
      )
    )

  res <-
    filter_named_taxa(
      data_plots = data_plots,
      col_taxa = "taxa",
      col_taxon_name = "Species"
    )

  testthat::expect_equal(dplyr::pull(res, PlotObservationID), c(2, 4))

  vec_n_records <-
    dplyr::pull(res, taxa) |>
    purrr::map_int(.f = ~ base::nrow(.x))

  testthat::expect_equal(vec_n_records, c(1L, 1L))
})

testthat::test_that("filter_named_taxa() uses the given column names", {
  data_plots <-
    tibble::tibble(
      plot_name = c("a", "b"),
      plot_data = list(
        tibble::tibble(name_matched = c("Abies alba", NA)),
        tibble::tibble(name_matched = NA_character_)
      )
    )

  res <-
    filter_named_taxa(
      data_plots = data_plots,
      col_taxa = "plot_data",
      col_taxon_name = "name_matched"
    )

  testthat::expect_equal(dplyr::pull(res, plot_name), "a")

  data_taxa <-
    dplyr::pull(res, plot_data) |>
    purrr::pluck(1)

  testthat::expect_equal(dplyr::pull(data_taxa, name_matched), "Abies alba")
})


#----------------------------------------------------------#
# Edge cases -----
#----------------------------------------------------------#

testthat::test_that("filter_named_taxa() returns zero plots unchanged", {
  data_plots <-
    tibble::tibble(
      PlotObservationID = base::numeric(0),
      taxa = list()
    )

  res <-
    filter_named_taxa(
      data_plots = data_plots,
      col_taxa = "taxa",
      col_taxon_name = "Species"
    )

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_equal(base::nrow(res), 0L)
  testthat::expect_named(res, c("PlotObservationID", "taxa"))
})

testthat::test_that("filter_named_taxa() handles many plots", {
  set.seed(900723)

  data_plots <-
    tibble::tibble(
      PlotObservationID = base::seq_len(2000),
      taxa = purrr::map(
        .x = base::seq_len(2000),
        .f = ~ tibble::tibble(
          Species = base::sample(
            x = c("Abies alba", "Picea abies", NA, ""),
            size = 5,
            replace = TRUE
          )
        )
      )
    )

  res <-
    filter_named_taxa(
      data_plots = data_plots,
      col_taxa = "taxa",
      col_taxon_name = "Species"
    )

  vec_names <-
    dplyr::pull(res, taxa) |>
    purrr::map(.f = ~ dplyr::pull(.x, Species)) |>
    base::unlist()

  vec_n_records <-
    dplyr::pull(res, taxa) |>
    purrr::map_int(.f = ~ base::nrow(.x))

  testthat::expect_false(base::anyNA(vec_names))
  testthat::expect_false(base::any(vec_names == ""))
  testthat::expect_true(base::all(vec_n_records > 0L))
  testthat::expect_false(base::is.unsorted(dplyr::pull(res, PlotObservationID)))
})
