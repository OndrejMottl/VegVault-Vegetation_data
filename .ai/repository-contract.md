# VegVault-Vegetation_data Repository Contract

## Role and outputs

This repository owns acquisition, cleaning, harmonisation, review, and export of BIEN and sPlot vegetation data.

The downstream contracts are VegVault's producer contracts, copied into this repository: `Data/Contracts/splot_plots.yml` and `Data/Contracts/bien_plots.yml` (the VegVault commit is recorded in `Data/Contracts/contract_copy.yml`). The released artefacts are the files they describe, in `Outputs/Data/` of a reviewed tag:

- `Outputs/Data/data_splot_<YYYY-MM-DD>__<hash>__.qs`
- `Outputs/Data/data_bien_<YYYY-MM-DD>__<hash>__.qs`

Both hold `qs2` content under the `.qs` extension. VegVault fetches them from the raw GitHub URL at the tag, so they are committed in the tagged tree, stay below GitHub's 100 MB file limit and are never stored with Git LFS. Tag `v1.0.0` holds the legacy `qs` files `data_bien_2023-12-06__7893b8a80ceb1550103667f95b695e6b__.qs` and `data_splot_2023-12-06__cbf9022330b5d47a5c76bf7ca6b226b4__.qs`, which `qs2` cannot read.

Treat filenames, identifiers, coordinates, taxa, abundances, plot metadata, units, row order, and nested object structure as interfaces consumed by the main VegVault repository.

## Safety

- BIEN and sPlot inputs may be licensed, restricted, or non-redistributable. Never expose raw data, credentials, request tokens, ignored extracts, or derived records beyond their licence.
- Do not add ignored BIEN/sPlot inputs or large processed files to Git.
- Broad downloads (`bien: flag_download: true`), raw-data refreshes, pipeline runs, and output replacement require explicit user authorization.
- Preserve project-specific manual decisions and do not impose unrelated style refactors on established processing code.
- Use narrow fixtures or sampled objects for validation; write debugging artifacts only to ignored temporary locations.

## Change and validation contract

For changes to output shape or meaning, trace consumers in VegVault (`R/Analyses/01_Producer_import/` and, while it is in use, `R/02_Main_analyses/01_Import_splot_data.R` and `R/02_Main_analyses/02_Import_bien_data.R`), ask for the contract change through the VegVault pipeline lane, update the copy with `save_contract_copy()`, coordinate producer documentation and a reviewed tag, and hand file names, sizes and SHA-256 checksums to the VegVault pin manifest. Validate taxon, plot, coordinate, abundance, and provenance fields before proposing a contract change.
