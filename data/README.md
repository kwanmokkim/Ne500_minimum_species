# Data

This folder is empty in the repository except for `korea_species_pools.csv`.
The two source datasets are **not redistributed here**. Run
`R/01_download_data.R` to fetch them.

## Files fetched by the download script

| File | Source | Used for |
|---|---|---|
| `indicators_full.csv` | Mastretta-Yanes et al. (2024b), Dryad [doi:10.5061/dryad.bk3j9kdkm](https://doi.org/10.5061/dryad.bk3j9kdkm) | Deriving σ (the only data input to the formula) |
| `04_empirical_results.rds` | [katherinehebert/Ne_scenarios](https://github.com/katherinehebert/Ne_scenarios), `outputs/` | Validation only (Fig. 6 output) |
| `minsample_extendeddataset.rds` | same repository, `outputs/` | Validation only (Fig. S7 output) |

Only the first file is needed to reproduce the formula. The other two are used
in `R/06` and `R/07` to check that the formula reproduces the published results.

## File included in the repository

`korea_species_pools.csv` — species pool sizes for the eleven Korean taxonomic
groups. `N` is the number of species assessed in the Korean National Red List,
excluding Data Deficient. Replace this file to apply the method to another
country.

| Column | Meaning |
|---|---|
| `taxon_kr` | Taxonomic group, Korean |
| `taxon_en` | Taxonomic group, English |
| `N` | Species pool size |
