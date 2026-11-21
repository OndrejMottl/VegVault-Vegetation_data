#' @title Validate an export artefact against its VegVault contract
#' @description Check a saved export artefact with the VegVault contract
#'   validator (the copy in `R/Functions/Contracts/`).
#' @param path_artefact Character. Path of the saved artefact file.
#' @param path_contract Character. Path of the contract (`.yml`) in the
#'   project's copy of the VegVault contracts (`Data/Contracts/`).
#' @return The input `path_artefact`, unchanged, once the artefact passes.
#' @details The check is `validate_producer_artefact()`: file name, object
#'   class, columns, nested elements, values and keys. Every violation is
#'   reported at once and the function aborts with an error of class
#'   `producer_contract_error`. The artefact is never changed.
validate_export_artefact <- function(
    path_artefact,
    path_contract) {
  assertthat::assert_that(
    base::is.character(path_artefact),
    base::length(path_artefact) == 1L,
    !base::is.na(path_artefact),
    base::file.exists(path_artefact),
    msg = "`path_artefact` must be the path of an existing file."
  )

  assertthat::assert_that(
    base::is.character(path_contract),
    base::length(path_contract) == 1L,
    !base::is.na(path_contract),
    base::file.exists(path_contract),
    msg = "`path_contract` must be the path of an existing contract file."
  )

  validate_producer_artefact(
    contract = path_contract,
    path_artefact = path_artefact,
    verbose = FALSE
  )

  res <- path_artefact

  return(res)
}
