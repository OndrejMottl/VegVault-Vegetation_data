#' @title Save an export artefact
#' @description Save an exported data object as a `qs2` file with the
#'   artefact file name the VegVault producer contracts expect.
#' @param data_export The R object to save.
#' @param file_name Character. Artefact prefix, for example `"data_bien"`.
#' @param dir_output Character. Existing output directory.
#' @param date_save Date. Save date written into the file name.
#' @param flag_replace_previous Logical. `TRUE` removes earlier artefacts
#'   with the same prefix before saving.
#' @return The path of the artefact (character).
#' @details The file is named `<file_name>_<YYYY-MM-DD>__<hash>__.qs`, where
#'   `<hash>` is `rlang::hash()` of `data_export`, and written with
#'   `qs2::qs_save()`. If that exact file already exists, nothing is written
#'   and its path is returned. Another artefact with the same prefix makes
#'   the function abort unless `flag_replace_previous = TRUE`, so that the
#'   output directory never holds two versions of one artefact. Only files
#'   matching the artefact pattern of this prefix are ever removed.
save_export_artefact <- function(
    data_export,
    file_name,
    dir_output,
    date_save = Sys.Date(),
    flag_replace_previous = FALSE) {
  assertthat::assert_that(
    base::is.character(file_name),
    base::length(file_name) == 1L,
    !base::is.na(file_name),
    base::nzchar(file_name),
    msg = "`file_name` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(dir_output),
    base::length(dir_output) == 1L,
    !base::is.na(dir_output),
    base::dir.exists(dir_output),
    msg = "`dir_output` must be the path of an existing directory."
  )

  assertthat::assert_that(
    base::inherits(date_save, "Date"),
    base::length(date_save) == 1L,
    !base::is.na(date_save),
    msg = "`date_save` must be a single Date."
  )

  assertthat::assert_that(
    base::is.logical(flag_replace_previous),
    base::length(flag_replace_previous) == 1L,
    !base::is.na(flag_replace_previous),
    msg = "`flag_replace_previous` must be TRUE or FALSE."
  )

  name_artefact <-
    stringr::str_c(
      file_name,
      "_",
      base::format(date_save, "%Y-%m-%d"),
      "__",
      rlang::hash(data_export),
      "__.qs"
    )

  path_artefact <-
    base::file.path(dir_output, name_artefact)

  vec_previous <-
    base::list.files(
      path = dir_output,
      pattern = stringr::str_c(
        "^",
        stringr::str_escape(file_name),
        "_[0-9]{4}-[0-9]{2}-[0-9]{2}__[0-9a-f]{32}__[.]qs$"
      )
    ) |>
    base::setdiff(name_artefact)

  if (
    base::length(vec_previous) > 0L && isFALSE(flag_replace_previous)
  ) {
    cli::cli_abort(
      c(
        "{.path {dir_output}} already holds another version of {.val {file_name}}.",
        "x" = "{.file {vec_previous}}",
        "i" = "Remove it deliberately, or set {.arg flag_replace_previous} to TRUE."
      )
    )
  }

  if (
    base::length(vec_previous) > 0L
  ) {
    vec_removed <-
      base::file.remove(base::file.path(dir_output, vec_previous))

    if (
      isFALSE(base::all(vec_removed))
    ) {
      cli::cli_abort(
        "Could not remove the earlier artefact{?s} {.file {vec_previous[!vec_removed]}}."
      )
    }
  }

  if (
    isFALSE(base::file.exists(path_artefact))
  ) {
    qs2::qs_save(
      object = data_export,
      file = path_artefact
    )
  }

  res <- path_artefact

  return(res)
}
