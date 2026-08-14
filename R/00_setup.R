# =============================================================================
# 00_setup.R
# Packages, paths, and global settings.
#
# Sourced at the top of every other script.
# =============================================================================

# --- packages ----------------------------------------------------------------

library(dplyr)
library(ggplot2)

# --- paths -------------------------------------------------------------------

dir_data    <- "data"
dir_outputs <- "outputs"
dir_figures <- "figures"

for (d in c(dir_data, dir_outputs, dir_figures)) {
  if (!dir.exists(d)) dir.create(d)
}

# --- file names --------------------------------------------------------------
#
# There is only one source dataset: the 583 species-level indicator values of
# Mastretta-Yanes et al. (2024b). It is the only data input to the formula.

file_indicators  <- file.path(dir_data, "indicators_full.csv")
file_korea_pools <- file.path(dir_data, "korea_species_pools.csv")

# --- analysis settings -------------------------------------------------------

# Tolerated deviation. The indicator runs from 0 to 1, so 0.05 means five
# percentage points. This is the value used by Hebert et al. (2026).
T_TOLERANCE <- 0.05

# Seed, for reproducibility
SEED <- 2026

# Shared plot theme
theme_ne500 <- theme_bw(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(size = 10))

message("00_setup.R done")
