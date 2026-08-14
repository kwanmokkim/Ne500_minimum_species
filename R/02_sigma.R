# =============================================================================
# 02_sigma.R
# Compute sigma, the standard deviation of the 583 species-level values.
#
# Sigma is the only quantity the analysis takes from data. Everything else is
# either a choice or a mathematical constant.
# =============================================================================

source("R/00_setup.R")

# --- read --------------------------------------------------------------------

indic <- read.csv(file_indicators)

dim(indic)
names(indic)

# The indicator1 column holds the species-level Ne500 indicator: the proportion
# of a species' populations with an effective size above 500. It runs from 0 to 1.

full <- indic$indicator1[!is.na(indic$indicator1)]

length(full)   # should be 583

# --- inspect the distribution ------------------------------------------------
#
# The raw values are far from normal: more than half are exactly zero. Sample
# means are nonetheless normal, which is checked in 05_validate_mc.R.

summary(full)

table(cut(full, breaks = c(-0.01, 0, 0.25, 0.5, 0.75, 0.999, 1),
          labels = c("exactly 0", "0 to 0.25", "0.25-0.5",
                     "0.5-0.75", "0.75 to <1", "exactly 1")))

round(mean(full == 0), 3)   # proportion at zero
round(mean(full == 1), 3)   # proportion at one

# --- sigma -------------------------------------------------------------------
#
# All 583 values are used, so this is a measurement rather than an estimate.
# The population standard deviation (divisor N) is therefore the right one.

sigma_pop <- sqrt(mean((full - mean(full))^2))

# For reference: R's sd() divides by n-1. With 583 values the difference is tiny.
c(population_sd = sigma_pop, sd_function = sd(full))

# --- save --------------------------------------------------------------------

sigma_result <- list(
  values = full,
  n_species = length(full),
  mean = mean(full),
  sigma = sigma_pop
)

saveRDS(sigma_result, file.path(dir_outputs, "02_sigma.rds"))

message(sprintf("species : %d", sigma_result$n_species))
message(sprintf("mean    : %.4f", sigma_result$mean))
message(sprintf("sigma   : %.6f", sigma_result$sigma))
message("02_sigma.R done")
