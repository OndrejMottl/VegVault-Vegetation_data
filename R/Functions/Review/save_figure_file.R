#' @title Save a figure file
#' @description Save a `ggplot` figure to a file with the project's figure
#'   options.
#' @param plot_figure A `ggplot` object.
#' @param path_file Character. Output path; its extension (for example
#'   `.pdf` or `.png`) sets the format, and its folder must exist.
#' @param list_graphical A named list with `width`, `height`, `units`, `dpi`
#'   and `bg`, as under `graphical` in `config.yml`.
#' @param size_scale Numeric. Factor applied to `width` and `height`, for
#'   figures that need more room than the default canvas.
#' @return The path of the saved file (character), so the function can be
#'   the command of a `format = "file"` target.
#' @details An existing file at `path_file` is replaced. The function aborts
#'   when the folder does not exist or a graphical option is missing.
save_figure_file <- function(
    plot_figure,
    path_file,
    list_graphical,
    size_scale = 1) {
  assertthat::assert_that(
    ggplot2::is_ggplot(plot_figure),
    msg = "`plot_figure` must be a ggplot object."
  )

  assertthat::assert_that(
    base::is.character(path_file),
    base::length(path_file) == 1L,
    !base::is.na(path_file),
    base::dir.exists(base::dirname(path_file)),
    msg = "`path_file` must be a file path in an existing folder."
  )

  assertthat::assert_that(
    base::is.list(list_graphical),
    base::all(
      c("width", "height", "units", "dpi", "bg") %in% base::names(list_graphical)
    ),
    msg = "`list_graphical` must hold `width`, `height`, `units`, `dpi` and `bg`."
  )

  assertthat::assert_that(
    base::is.numeric(size_scale),
    base::length(size_scale) == 1L,
    !base::is.na(size_scale),
    size_scale > 0,
    msg = "`size_scale` must be a single positive number."
  )

  ggplot2::ggsave(
    filename = path_file,
    plot = plot_figure,
    width = list_graphical[["width"]] * size_scale,
    height = list_graphical[["height"]] * size_scale,
    units = list_graphical[["units"]],
    dpi = list_graphical[["dpi"]],
    bg = list_graphical[["bg"]]
  )

  res <- path_file

  return(res)
}
