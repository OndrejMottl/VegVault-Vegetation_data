#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("aggregate_splot_taxa() validates arguments", {
  data_plots <-
    tibble::tibble(
      plot_observation_id = 1,
      taxa = list(
        tibble::tibble(
          Species = "Abies alba",
          Original_species = "Abies alba",
          Original_abundance = 1,
          Abundance_scale = "pa",
          Relative_cover = 1
        )
      )
    )

  testthat::expect_error(
    aggregate_splot_taxa(data_plots = "not a data frame"),
    regexp = "data_plots"
  )

  testthat::expect_error(
    aggregate_splot_taxa(data_plots = data_plots, col_taxa = "plot_taxa"),
    regexp = "plot_taxa"
  )

  testthat::expect_error(
    aggregate_splot_taxa(data_plots = data_plots, col_scale = "Scale"),
    regexp = "Scale"
  )
})

testthat::test_that("aggregate_splot_taxa() aborts on columns without rule", {
  data_plots <-
    tibble::tibble(
      plot_observation_id = 1,
      taxa = list(
        tibble::tibble(
          Species = c("Abies alba", "Abies alba"),
          Original_species = "Abies alba",
          Original_abundance = c(10, 20),
          Abundance_scale = "CoverPerc",
          Relative_cover = c(0.4, 0.6),
          Layer = c("1", "2")
        )
      )
    )

  testthat::expect_error(
    aggregate_splot_taxa(data_plots = data_plots),
    regexp = "Layer"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("aggregate_splot_taxa() merges with the approved rules", {
  data_plots <-
    tibble::tibble(
      plot_observation_id = c(1, 2, 3),
      givd_id = c("EU-00-001", "EU-00-001", "EU-00-002"),
      taxa = list(
        tibble::tibble(
          Species = c("Abies alba", "Abies alba", "Picea abies"),
          Original_species = c("Abies alba", "Abies alba Mill.", "Picea abies"),
          Original_abundance = c(1, 3, 2),
          Abundance_scale = c("pa", "x_IC", "x_IC"),
          Relative_cover = c(0.1, 0.2, 0.3)
        ),
        tibble::tibble(
          Species = c("Fagus sylvatica", "Quercus robur", "Fagus sylvatica"),
          Original_species = c(
            "Fagus sylvatica", "Quercus robur", "Fagus sylvatica"
          ),
          Original_abundance = c(50, 10, 50),
          Abundance_scale = "CoverPerc",
          Relative_cover = c(0.4, 0.1, NA)
        ),
        tibble::tibble(
          Species = "Pinus nigra",
          Original_species = "Pinus nigra",
          Original_abundance = 5,
          Abundance_scale = "x_SC",
          Relative_cover = 1
        )
      )
    )

  res <-
    aggregate_splot_taxa(data_plots = data_plots)

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_named(res, base::names(data_plots))
  testthat::expect_equal(
    dplyr::select(res, -taxa),
    dplyr::select(data_plots, -taxa)
  )

  list_taxa <-
    dplyr::pull(res, taxa)

  testthat::expect_equal(
    purrr::pluck(list_taxa, 1),
    tibble::tibble(
      Species = c("Abies alba", "Picea abies"),
      Original_species = c("Abies alba Mill.", "Picea abies"),
      Original_abundance = c(3, 2),
      Abundance_scale = c("x_IC", "x_IC"),
      Relative_cover = c(0.2, 0.3)
    )
  )

  testthat::expect_equal(
    purrr::pluck(list_taxa, 2),
    tibble::tibble(
      Species = c("Fagus sylvatica", "Quercus robur"),
      Original_species = c("Fagus sylvatica", "Quercus robur"),
      Original_abundance = c(75, 10),
      Abundance_scale = c("CoverPerc", "CoverPerc"),
      Relative_cover = c(0.4, 0.1)
    )
  )

  testthat::expect_identical(
    purrr::pluck(list_taxa, 3),
    purrr::pluck(dplyr::pull(data_plots, taxa), 3)
  )
})

testthat::test_that("aggregate_splot_taxa() joins names and sums covers", {
  data_plots <-
    tibble::tibble(
      plot_observation_id = 1,
      taxa = list(
        tibble::tibble(
          Species = c("Abies alba", "Abies alba", "Abies alba"),
          Original_species = c(
            "Abies alba Mill.", "Abies alba", "Abies alba Mill."
          ),
          Original_abundance = c(2, 3, 1),
          Abundance_scale = "x_SC",
          Relative_cover = c(NA_real_, NA_real_, NA_real_)
        )
      )
    )

  res <-
    aggregate_splot_taxa(data_plots = data_plots)

  data_taxa <-
    dplyr::pull(res, taxa) |>
    purrr::pluck(1)

  testthat::expect_equal(base::nrow(data_taxa), 1L)
  testthat::expect_equal(
    dplyr::pull(data_taxa, Original_species),
    "Abies alba | Abies alba Mill."
  )
  testthat::expect_equal(dplyr::pull(data_taxa, Original_abundance), 6)
  testthat::expect_identical(dplyr::pull(data_taxa, Relative_cover), NA_real_)
})

testthat::test_that("aggregate_splot_taxa() keeps presence-only pairs at 1", {
  data_plots <-
    tibble::tibble(
      plot_observation_id = 1,
      taxa = list(
        tibble::tibble(
          Species = c("Abies alba", "Abies alba"),
          Original_species = c("Abies alba", "Abies alba"),
          Original_abundance = c(1, 1),
          Abundance_scale = "pa",
          Relative_cover = c(0.5, 0.5)
        )
      )
    )

  res <-
    aggregate_splot_taxa(data_plots = data_plots)

  data_taxa <-
    dplyr::pull(res, taxa) |>
    purrr::pluck(1)

  testthat::expect_equal(dplyr::pull(data_taxa, Original_abundance), 1)
  testthat::expect_equal(dplyr::pull(data_taxa, Relative_cover), 1)
})

testthat::test_that("aggregate_splot_taxa() aborts on two measured scales", {
  data_plots <-
    tibble::tibble(
      plot_observation_id = 1,
      taxa = list(
        tibble::tibble(
          Species = c("Abies alba", "Abies alba"),
          Original_species = c("Abies alba", "Abies alba"),
          Original_abundance = c(3, 40),
          Abundance_scale = c("x_IC", "CoverPerc"),
          Relative_cover = c(0.5, 0.5)
        )
      )
    )

  testthat::expect_error(
    aggregate_splot_taxa(data_plots = data_plots),
    regexp = "scale"
  )
})


#----------------------------------------------------------#
# Edge cases -----
#----------------------------------------------------------#

testthat::test_that("aggregate_splot_taxa() returns zero plots unchanged", {
  data_plots <-
    tibble::tibble(
      plot_observation_id = base::numeric(0),
      taxa = list()
    )

  res <-
    aggregate_splot_taxa(data_plots = data_plots)

  testthat::expect_equal(res, data_plots)
})

testthat::test_that("aggregate_splot_taxa() joins names in native encoding", {
  # sPlotOpen marks its non-ASCII names as native ("unknown"), which a
  #   radix sort rejects unless they are marked as UTF-8 first.
  vec_original <-
    c("Hierochlo\u00eb alpina", "Hierochlo\u00eb odorata")

  base::Encoding(vec_original) <- "unknown"

  data_plots <-
    tibble::tibble(
      plot_observation_id = 1,
      taxa = list(
        tibble::tibble(
          Species = c("Anthoxanthum", "Anthoxanthum"),
          Original_species = vec_original,
          Original_abundance = c(10, 20),
          Abundance_scale = "CoverPerc",
          Relative_cover = c(0.4, 0.6)
        )
      )
    )

  res <-
    aggregate_splot_taxa(data_plots = data_plots)

  vec_joined <-
    res |>
    dplyr::pull(taxa) |>
    purrr::chuck(1) |>
    dplyr::pull(Original_species)

  testthat::expect_identical(
    base::charToRaw(vec_joined),
    base::charToRaw(base::paste(vec_original, collapse = " | "))
  )
})
