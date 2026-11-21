#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("prepare_splot_plots() validates arguments", {
  data_taxa <-
    tibble::tibble(PlotObservationID = 1, Species = "Abies alba")

  data_meta <-
    tibble::tibble(PlotObservationID = 1, GIVD_ID = "EU-00-001")

  testthat::expect_error(
    prepare_splot_plots(
      data_taxa = dplyr::select(data_taxa, -PlotObservationID),
      data_meta = data_meta
    ),
    regexp = "PlotObservationID"
  )

  testthat::expect_error(
    prepare_splot_plots(
      data_taxa = data_taxa,
      data_meta = dplyr::select(data_meta, -PlotObservationID)
    ),
    regexp = "PlotObservationID"
  )

  testthat::expect_error(
    prepare_splot_plots(
      data_taxa = "not a table",
      data_meta = data_meta
    ),
    regexp = "data_taxa"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("prepare_splot_plots() nests taxa and keeps plots that have taxa", {
  data_taxa <-
    tibble::tibble(
      PlotObservationID = c(2, 1, 1, 4),
      Species = c("Fagus sylvatica", "Picea abies", "Abies alba", "Pinus nigra"),
      Original_abundance = c(30, 10, 5, 1)
    )

  data_meta <-
    tibble::tibble(
      PlotObservationID = c(3, 1, 2),
      GIVD_ID = c("EU-00-003", "EU-00-001", "EU-00-002"),
      Releve_area = c(100, 200, 300)
    )

  res <-
    prepare_splot_plots(
      data_taxa = data_taxa,
      data_meta = data_meta
    )

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_false(dplyr::is_grouped_df(res))
  testthat::expect_identical(
    base::names(res),
    c("PlotObservationID", "GIVD_ID", "Releve_area", "taxa")
  )
  testthat::expect_identical(res$PlotObservationID, c(1, 2))
  testthat::expect_identical(res$GIVD_ID, c("EU-00-001", "EU-00-002"))

  data_taxa_plot_1 <-
    purrr::chuck(res, "taxa", 1)

  testthat::expect_s3_class(data_taxa_plot_1, "tbl_df")
  testthat::expect_identical(
    base::names(data_taxa_plot_1),
    c("Species", "Original_abundance")
  )
  testthat::expect_identical(
    data_taxa_plot_1$Species,
    c("Picea abies", "Abies alba")
  )
})
