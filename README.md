# VegVault: Vegetation data

This is part of the [BIODYNAMICS project](https://ondrejmottl.github.io/projects/BIODYNAMICS/).

This repository gets and prepares the vegetation-plot data of [VegVault](https://github.com/OndrejMottl/VegVault) from two sources: [BIEN](https://bien.nceas.ucsb.edu/bien/) plots and [sPlotOpen](https://doi.org/10.1111/geb.13346). It exports one `qs2` artefact per source, which VegVault imports from a tagged release.

## Structure

The repository follows the [project template](https://github.com/OndrejMottl/Project_template): `{targets}` pipelines grouped into numbered stages, configuration in `config.yml`, and one function per file with a `{testthat}` test. The layout is described in [`.ai/analysis-structure.md`](.ai/analysis-structure.md).

| Stage | What it does |
| --- | --- |
| `R/Analyses/01_Data_acquisition/` | Checks the sPlotOpen file against its recorded version and finds one raw file per BIEN datasource (downloading it only when the download flag is set) |
| `R/Analyses/02_Data_processing/` | Nests the sPlot taxa by plot and joins them to the plots; selects the BIEN columns and nests the records by plot |
| `R/Analyses/03_Data_export/` | Drops sPlot taxon records without a name, drops incomplete plots, cleans the column names, sorts the rows, saves the artefacts to `Outputs/Data/` and checks them against the VegVault contracts |
| `R/Analyses/90_Review/` | Maps of the plots (`Outputs/Figures/`) and the most common plot size per continent or region |

## Getting started

1. Clone the repository and run `Rscript R/___Init_project___.R` from the project root to restore the package versions.
2. Copy `secrets_example.yaml` to `secrets.yaml` and set `Data:` to the folder that holds the raw inputs (`Input/`) and the pipeline stores (`Targets_data/`). Without `secrets.yaml`, `Data/` in the project is used.
3. Place the sPlotOpen file (below) and the BIEN raw files, or download BIEN with the flag (below).
4. Run `Rscript R/Tests/Run_tests.R` to check the code.

## Raw inputs

### sPlotOpen (manual download)

sPlotOpen is downloaded by hand from the iDiv data portal, [dataset 3474](https://idata.idiv.de/ddm/Data/ShowData/3474?version=76), and saved as `<data root>/Input/sPlot/Raw/sPlotOpen.RData`. The pipeline never downloads it. `config.yml` records the expected version (`splot: raw_file_version`) and its SHA-256 checksum (`splot: raw_file_sha256`); a missing or different file stops the run. To use a new version, place the file and change both values deliberately. The file is git-ignored; do not redistribute it beyond its licence.

### BIEN plots (flag-controlled download)

BIEN plots are downloaded with the [BIEN R package](https://cran.r-project.org/package=BIEN), one file per datasource listed under `bien: datasources` in `config.yml`, into `<data root>/Input/BIEN/` as `<datasource>_<date>__<hash>__.rds`. A normal run never downloads: with `bien: flag_download: false` a missing file stops the run. To download, set `bien: flag_download: true`, run the acquisition stage, and set it back to `false`. Only datasources without a file are downloaded; an existing file is never replaced, and a datasource with two files stops the run. With the flag on, the run also stops if BIEN lists a different set of datasources than `config.yml`.

## Running the pipeline

- **Main stages:** `Rscript R/Analyses/00_run_main.R` runs acquisition, processing and export in order. Up-to-date targets are skipped.
- **One stage:** `Rscript R/Analyses/<NN>_<Stage>/00_run.R`; the review stage runs only this way.
- **Test run:** with the environment variable `R_CONFIG_ACTIVE=dev`, the export writes to the git-ignored `Outputs/Data_temp/` instead of `Outputs/Data/`.
- **Inspect results:** `targets::tar_read(<target>, store = <store path>)`; each stage keeps its own store under `<data root>/Targets_data/`.

## Outputs and contracts

The export writes `Outputs/Data/data_splot_<date>__<hash>__.qs` and `Outputs/Data/data_bien_<date>__<hash>__.qs` and checks each against its VegVault producer contract (`Data/Contracts/splot_plots.yml`, `Data/Contracts/bien_plots.yml`). These contracts and the validator in `R/Functions/Contracts/` are a copy made with VegVault's `save_contract_copy()`; the VegVault commit is recorded in `Data/Contracts/contract_copy.yml`. Do not edit the copy; changes to a contract go through VegVault.

## Tests

`Rscript R/Tests/Run_tests.R` checks that every function file holds one correctly named function and runs all tests in a clean R session. Tests use small synthetic data, never the real BIEN or sPlot data.
