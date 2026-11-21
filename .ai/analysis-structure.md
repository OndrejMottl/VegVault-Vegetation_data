# Analysis structure

The project layout is a contract. It follows `OndrejMottl/Project_template`. Change it deliberately, update this file in the same change, and check every caller.

## Layout

```text
config.yml                 project configuration, read via load_config_value()
secrets.yaml               git-ignored machine-local values (see secrets_example.yaml)
Data/
  Contracts/               copy of the VegVault producer contracts (see below)
  Input/                   raw inputs, under the data root (not modified by code)
    sPlot/Raw/sPlotOpen.RData   manual download, git-ignored
    BIEN/<datasource>_<date>__<hash>__.rds   one per BIEN datasource, git-ignored
  Temp/                    disposable scratch and debug scripts (git-ignored)
  Targets_data/            one {targets} store per pipeline (git-ignored)
Outputs/
  Data/                    release artefacts read by VegVault (tracked)
  Data_temp/               test-run artefacts of the `dev` profile (git-ignored)
  Figures/                 review maps
R/
  ___Init_project___.R     one-time environment restore or initialisation
  ___setup_project___.R    shared setup sourced by every script and pipeline
  package_dependencies.R   generated; do not edit
  Functions/<Area>/        one function per file, named after the function
  Functions/Contracts/     copied from VegVault; never edit here
  Analyses/
    00_run_main.R          runs the main stages in order (01 to 03)
    01_Data_acquisition/   sPlotOpen file check, BIEN raw files
    02_Data_processing/    sPlot taxa nested and joined, BIEN selected and nested
    03_Data_export/        unnamed sPlot taxa, completeness filters, export order, qs2 artefacts, contract check
    90_Review/             maps and plot-size review, outside the main chain
  Tests/
    Run_tests.R            full suite runner
    testthat/test-<function_name>.R
```

## Data root

- `resolve_data_storage_path()` gives the data root: the `Data:` entry of `secrets.yaml` if present, otherwise `data_storage_path` in `config.yml` (`Data` in the project).
- Raw inputs live under `<data root>/Input/` at the paths named in `config.yml` (`splot: raw_file`, `bien: raw_dir`). The stores live under `<data root>/Targets_data/`.
- A second checkout or worktree points its `Data:` entry at the data root that holds the raw inputs. Never copy raw-data trees between checkouts.

## Stages and pipelines

- Each stage is a numbered folder under `R/Analyses/` with a `00_run.R` that sources the setup and calls `run_target_pipeline()`, and a `pipeline.R` that only declares targets. `00_run_main.R` runs stages 01 to 03; run `90_Review/00_run.R` on its own.
- Each pipeline owns one store, resolved with `resolve_pipeline_store_path()`: `data_acquisition`, `data_processing`, `data_export` and `review`. Never share a store between pipelines.
- Target names are quoted strings. Above each target, a short plain comment says what it provides and why it is in the graph.
- When a target command is more than one function call, move the logic into a function in `R/Functions/`. The upstream-import target is the one exception.

## Raw inputs and downloads

- sPlotOpen is a manual download from the iDiv data portal (dataset 3474). `path_splot_raw_file` is a `format = "file"` target that checks the file against `splot: raw_file_sha256`; a missing or different file stops the run. The pipeline never downloads it.
- BIEN is downloaded only when `bien: flag_download` is `true`, and only for a datasource without a raw file. `path_bien_raw_file` branches over `bien: datasources`; each branch is a `format = "file"` target that resolves exactly one raw file per datasource and never picks "the latest" of several. With the flag on, the configured datasources are first compared with `BIEN::BIEN_plot_list_datasource()`. Keep the flag `false` in committed configuration.

## Cross-pipeline contracts

- A downstream pipeline imports only the public targets of an upstream store, listed in its "Upstream contract" section with the upstream runner.
- Import pattern: a `fingerprint_<stage>` target calls `compute_target_store_fingerprint()` with `cue = targets::tar_cue(mode = "always")`, and each import target references the fingerprint and calls `load_target_store_value()`.
- A missing or failed upstream store is an error that names the runner to execute first (`validate_target_store_contract()`).
- Public targets: `data_splot_taxa_raw`, `data_splot_meta_raw` and `data_bien_raw` (acquisition); `data_splot_processed` and `data_bien_processed` (processing); `data_splot_export`, `data_bien_export`, `path_splot_export_validated` and `path_bien_export_validated` (export). Renaming or removing one is a contract change: search the downstream pipelines first.

## Export and producer contracts

- The export stage writes `data_splot_<YYYY-MM-DD>__<hash>__.qs` and `data_bien_<YYYY-MM-DD>__<hash>__.qs` (`qs2` content, `<hash>` is `rlang::hash()` of the object) to `export: dir_output`. It never keeps two versions of an artefact in that folder unless `export: flag_replace_previous` is `true`.
- Before the completeness filter, `filter_named_taxa()` drops the sPlot taxon records whose name (`splot: column_taxon_name`) is missing or empty, and the plots left without a named record, because the sPlot contract rejects both. The processed sPlot data still hold these records.
- Row order is explicit (`splot: columns_order`, `bien: columns_order`), so it does not depend on the order in which a source delivered its records. VegVault's v1 import names BIEN plots by row number, so a change of order is a contract change.
- Each artefact is checked with `validate_producer_artefact()` against its contract in `Data/Contracts/`; a violation stops the run.
- `Data/Contracts/` (`splot_plots.yml`, `bien_plots.yml`, `contract_copy.yml`) and `R/Functions/Contracts/` are a copy made by VegVault's `save_contract_copy()` from one VegVault commit, recorded in `contract_copy.yml`. Never edit them here. To update, run `save_contract_copy()` from a clean VegVault checkout on the shared release branch (see VegVault's `Data/Contracts/README.md`) and commit the result. `test-validate_contract_copy.R` checks the copy against the sibling VegVault checkout. Contract changes go through the VegVault pipeline lane.
- The copied functions are tested in VegVault and have no test files here.

## Configuration

- Analysis values (seed, column lists, flags, review groups, package lists) live in `config.yml` and are read only through `load_config_value()`. Do not call `config::get()` directly.
- The `dev` profile (`R_CONFIG_ACTIVE=dev`) writes the export artefacts to `Outputs/Data_temp/` instead of `Outputs/Data/`. Use it for test runs, such as the parity check against the old scripts.

## Setup and packages

- Every stage runner, pipeline and test run starts with `library(here)` and `source(here::here("R/___setup_project___.R"))`.
- The setup aborts if the data root does not exist, loads every file in `R/Functions/` (including the copied contract functions), attaches `packages: attach` from `config.yml`, regenerates `R/package_dependencies.R`, sets the seed and ggplot theme, and resolves `path_data_storage`.
- Add a package by listing it in `config.yml` (attach or tools) or by calling it as `pkg::fun()`, then install it with `renv::install()` and snapshot deliberately.

## Tests

- Every function in `R/Functions/` outside `Contracts/` has `R/Tests/testthat/test-<function_name>.R`, written before the implementation. Shared fixtures go in `helper-*.R` files.
- Tests use small synthetic inputs, never the real BIEN or sPlot data. BIEN calls are mocked with `testthat::local_mocked_bindings(.package = "BIEN")`.
- `Rscript R/Tests/Run_tests.R` validates the function files (`validate_function_names()`) and runs the suite in a clean subprocess (`run_project_tests()`).
- Focused run: source the setup, then `run_test_file(test_file = ...)`.
