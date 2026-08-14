# =============================================================================
# 04_formula.R
# The formula, as a reusable function.
#
# This is the core of the repository. To apply the method to another country,
# this file is the only one you need.
# =============================================================================

source("R/00_setup.R")

# --- the formula -------------------------------------------------------------
#
#   n = n0 * N / (N - 1 + n0)        with   n0 = (k * sigma / T)^2
#
# N      species pool size: all species the indicator is meant to represent
# T      tolerated deviation on the 0-1 indicator scale
# sigma  standard deviation of species-level indicator values. The default is
#        the value measured from the 583-species international dataset
# k      criterion constant, in units of standard error
#
# The derivation is in the README and in the accompanying methods document.

n_species_needed <- function(N,
                             T_val = 0.05,
                             sigma = 0.394826,
                             k = sqrt(2 / pi) + sqrt(1 - 2 / pi)) {
  n0 <- (k * sigma / T_val)^2
  n  <- n0 * N / (N - 1 + n0)
  pmin(ceiling(n), N)     # round up, but never ask for more species than exist
}

# As a proportion
prop_species_needed <- function(N, ...) {
  n_species_needed(N, ...) / N
}

# Without rounding. Used when checking the accuracy of the formula itself.
n_species_needed_raw <- function(N,
                                 T_val = 0.05,
                                 sigma = 0.394826,
                                 k = sqrt(2 / pi) + sqrt(1 - 2 / pi)) {
  n0 <- (k * sigma / T_val)^2
  pmin(n0 * N / (N - 1 + n0), N)
}

# --- using a different criterion ---------------------------------------------
#
# Returns the k corresponding to a target coverage.
#
# The error can fall on either side of the true value, so the two tails are
# split. A 95% bound is therefore qnorm(0.975), not qnorm(0.95), which gives 90%.
# Using this function avoids that slip.

k_for_coverage <- function(coverage) {
  qnorm(1 - (1 - coverage) / 2)
}

round(c(`90%` = k_for_coverage(0.90),
        `95%` = k_for_coverage(0.95),
        `97.5%` = k_for_coverage(0.975)), 5)

# --- check -------------------------------------------------------------------

# However large the pool grows, the requirement never exceeds n0.
data.frame(
  N = c(30, 100, 300, 500, 1000, 5000, 50000),
  n = n_species_needed(c(30, 100, 300, 500, 1000, 5000, 50000))
) |>
  mutate(percent = round(100 * n / N, 1))

# Changing the criterion means changing k and nothing else.
data.frame(
  N = c(94, 388, 712),
  Hebert = n_species_needed(c(94, 388, 712)),
  p95 = n_species_needed(c(94, 388, 712), k = k_for_coverage(0.95))
)

message("04_formula.R done")
