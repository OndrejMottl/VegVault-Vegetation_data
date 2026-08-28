# VegVault-Vegetation_data Repository Contract

## Role and outputs

This repository owns acquisition, cleaning, harmonisation, review, and export of BIEN and sPlot vegetation data.

The reviewed downstream contracts are:

- `Outputs/Data/data_bien_2023-12-06__7893b8a80ceb1550103667f95b695e6b__.qs`
- `Outputs/Data/data_splot_2023-12-06__cbf9022330b5d47a5c76bf7ca6b226b4__.qs`

Treat filenames, identifiers, coordinates, taxa, abundances, plot metadata, units, and nested object structure as interfaces consumed by the main VegVault repository.

## Safety

- BIEN and sPlot inputs may be licensed, restricted, or non-redistributable. Never expose raw data, credentials, request tokens, ignored extracts, or derived records beyond their licence.
- Do not add ignored BIEN/sPlot inputs or large processed files to Git.
- Broad downloads, raw-data refreshes, harmonisation reruns, and output replacement require explicit user authorization.
- Preserve project-specific manual decisions and do not impose unrelated style refactors on legacy processing code.
- Use narrow fixtures or sampled objects for validation; write debugging artifacts only to ignored temporary locations.

## Change and validation contract

For changes to output shape or meaning, trace consumers in `../VegVault/R/02_Main_analyses/01_Import_splot_data.R` and `../VegVault/R/02_Main_analyses/02_Import_bien_data.R`, coordinate producer documentation and a reviewed tag, and update the pinned integration reference. Validate taxon, plot, coordinate, abundance, and provenance fields before proposing a contract change.
