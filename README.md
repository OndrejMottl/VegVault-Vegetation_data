# VegVault: Vegetation data

This is part of the [BIODYNAMICS project](https://ondrejmottl.github.io/projects/BIODYNAMICS/).

This repository gets and prepares the vegetation-plot data of [VegVault](https://github.com/OndrejMottl/VegVault) from two sources: [BIEN](https://bien.nceas.ucsb.edu/bien/) plots and [sPlotOpen](https://doi.org/10.1111/geb.13346). It exports one `qs2` artefact per source, which VegVault imports from a tagged release.

## Structure

The repository follows the [project template](https://github.com/OndrejMottl/Project_template): `{targets}` pipelines grouped into numbered stages, configuration in `config.yml`, and one function per file with a `{testthat}` test. The layout is described in [`.ai/analysis-structure.md`](.ai/analysis-structure.md).

| Stage | What it does |
| --- | --- |
| `R/Analyses/01_Data_acquisition/` | Checks the sPlotOpen file against its recorded version and finds one raw file per BIEN datasource (downloading it only when the download flag is set) |
| `R/Analyses/02_Data_processing/` | Nests the sPlot taxa by plot and joins them to the plots; gives each BIEN plot one coordinate pair, keeps its latest survey, merges the records to one per taxon, and nests them by plot |
| `R/Analyses/03_Data_export/` | Drops sPlot taxon records without a name and merges repeated sPlot taxa, drops incomplete plots, cleans the column names, sorts the rows, adds the BIEN `plot_id`, saves the artefacts to `Outputs/Data/` and checks them against the VegVault contracts |
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

## One record per taxon and plot

Both artefacts hold at most one record per taxon in each plot, so that VegVault can key its sample-taxon table. The rules were approved by Ondřej Mottl in 2026, and their settings are in `config.yml`.

**sPlot** (export stage). Taxon records without a `Species` name are dropped, together with any plot left without a named record. The records of a repeated `Species` are then merged:

- a presence-only record (`pa`) gives way to a measured record;
- covers (`CoverPerc`) combine as overlapping layers, 100 × (1 − ∏(1 − cover / 100)), so the result is at most 100;
- counts of individuals and stems and basal area (`x_IC`, `x_SC`, `x_BA`) are added; relative importance and `x_PF` (`x_IV`, `x_PF`) keep the largest value;
- a taxon that keeps records on two measured scales stops the run;
- `Relative_cover` values are added, and the distinct `Original_species` names are joined with ` | `.

**BIEN** (processing stage).

- **Coordinates.** A plot whose records carry several coordinate pairs within 0.01° (the subplots of three TEAM plots) gets the mean of those pairs.
- **Latest survey.** Only the latest survey year of each plot is kept, so that a tree re-surveyed every year (TEAM) is counted once. A plot without dates keeps all its records.
- **Merge.** The records of one `name_matched` in a plot are merged:
  - `individual_count` is the sum of the non-missing counts, and stays missing when no record has one (all TEAM records);
  - every record counts, identical ones included, because BIEN gives no record identity to tell a repeated listing from a second individual;
  - `subplot`, the verbatim names and the two author columns keep their distinct values joined with ` | `;
  - the other taxon-level columns must agree, or the run stops.
- **Records without coordinates.** These are records in a plot whose other records have coordinates, probably species whose coordinates BIEN withholds. They still fall out with the completeness filter, as in 1.0.0.

**BIEN plot identifier.** `plot_id` is `<datasource>__<plot_name>`, for example `CTFS__Plot 31`. It is unique, never missing, and independent of the row order and of BIEN's internal identifiers. A plot split over several rows stops the export.

## Running the pipeline

- **Main stages:** `Rscript R/Analyses/00_run_main.R` runs acquisition, processing and export in order. Up-to-date targets are skipped.
- **One stage:** `Rscript R/Analyses/<NN>_<Stage>/00_run.R`; the review stage runs only this way.
- **Test run:** with the environment variable `R_CONFIG_ACTIVE=dev`, the export writes to the git-ignored `Outputs/Data_temp/` instead of `Outputs/Data/`.
- **Inspect results:** `targets::tar_read(<target>, store = <store path>)`; each stage keeps its own store under `<data root>/Targets_data/`.

## Outputs and contracts

The export writes `Outputs/Data/data_splot_<date>__<hash>__.qs` and `Outputs/Data/data_bien_<date>__<hash>__.qs` and checks each against its VegVault producer contract (`Data/Contracts/splot_plots.yml`, `Data/Contracts/bien_plots.yml`). These contracts and the validator in `R/Functions/Contracts/` are a copy made with VegVault's `save_contract_copy()`; the VegVault commit is recorded in `Data/Contracts/contract_copy.yml`. Do not edit the copy; changes to a contract go through VegVault.

## Tests

`Rscript R/Tests/Run_tests.R` checks that every function file holds one correctly named function and runs all tests in a clean R session. Tests use small synthetic data, never the real BIEN or sPlot data.
