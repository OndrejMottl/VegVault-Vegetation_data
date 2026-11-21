#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

list_graphical_test <-
  list(width = 10, height = 8, units = "cm", dpi = 72, bg = "white")

testthat::test_that("save_figure_file() validates arguments", {
  dir_output <-
    withr::local_tempdir()

  plot_test <-
    ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_point()

  testthat::expect_error(
    save_figure_file(
      plot_figure = "not a plot",
      path_file = base::file.path(dir_output, "figure.pdf"),
      list_graphical = list_graphical_test
    ),
    regexp = "plot_figure"
  )

  testthat::expect_error(
    save_figure_file(
      plot_figure = plot_test,
      path_file = base::file.path(dir_output, "missing", "figure.pdf"),
      list_graphical = list_graphical_test
    ),
    regexp = "path_file"
  )

  testthat::expect_error(
    save_figure_file(
      plot_figure = plot_test,
      path_file = base::file.path(dir_output, "figure.pdf"),
      list_graphical = list(width = 10)
    ),
    regexp = "list_graphical"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("save_figure_file() saves the figure and returns its path", {
  dir_output <-
    withr::local_tempdir()

  plot_test <-
    ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_point()

  path_file <-
    base::file.path(dir_output, "figure.pdf")

  res <-
    save_figure_file(
      plot_figure = plot_test,
      path_file = path_file,
      list_graphical = list_graphical_test,
      size_scale = 2
    )

  testthat::expect_identical(res, path_file)
  testthat::expect_true(base::file.exists(path_file))

  # A 20 cm by 16 cm page is about 567 by 454 points
  vec_pdf_lines <-
    base::readLines(path_file, warn = FALSE, encoding = "latin1")

  testthat::expect_true(
    base::any(base::grepl("/MediaBox \\[0 0 56[67]\\S* 45[34]", vec_pdf_lines, useBytes = TRUE))
  )
})
