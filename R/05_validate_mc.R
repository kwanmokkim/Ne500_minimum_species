# =============================================================================
# 05_validate_mc.R
# Validation: sample directly from the raw data and compare with the formula.
#
# The formula assumes the sampling error is normally distributed. The 583 source
# values are far from normal: more than half are exactly zero. Whether the normal
# approximation holds at sample sizes as small as 25 therefore has to be checked
# rather than assumed.
#
# The check is simple. Without using the formula, follow the procedure of
# Hebert et al. to find the required number of species, then compare.
#
# This script is not country specific. The aim is to confirm the formula across a
# wide range of pool sizes. The Korean application is in 07_apply_korea.R.
# =============================================================================

source("R/00_setup.R")
source("R/04_formula.R")

sigma_result <- readRDS(file.path(dir_outputs, "02_sigma.rds"))
full <- sigma_result$values
N_donor <- length(full)   # 583

# --- settings ----------------------------------------------------------------

n_pools   <- 20     # species pools drawn per pool size
reps_pool <- 1000   # surveys simulated within each pool
window    <- -6:2   # sample sizes tested, relative to the formula's prediction

# Pool sizes to check. The required proportion changes fast at small N and
# flattens at large N, so the spacing is logarithmic rather than uniform.
N_check <- unique(round(exp(seq(log(30), log(5000), length.out = 50))))

length(N_check)
head(N_check, 12)
tail(N_check, 5)

# --- reproduce the procedure of Hebert et al. --------------------------------
#
# Measure the error when n of N species are surveyed.
#
#   1. draw N values to form the full species list of a virtual country
#   2. take the mean of those N values as the true value
#   3. draw n of them and take the mean
#   4. record the absolute difference
#   5. repeat steps 3 and 4 many times
#
# One thing differs. Hebert et al. run step 1 once per pool size; here it is
# repeated n_pools times. The reason is given below.

measure_error <- function(N, n, pool_source, n_pools, reps_pool) {

  errs <- numeric(0)

  for (p in seq_len(n_pools)) {

    # 1. full species list of a virtual country.
    #    Above 583 there are not enough values to draw without replacement, so
    #    we sample with replacement, as Hebert et al. did for Fig. S7.
    pool <- sample(pool_source, size = N, replace = (N > length(pool_source)))

    # 2. the true value for this country
    true_value <- mean(pool)

    # 3-5. simulate surveying n of the N species, reps_pool times.
    #      This is equivalent to replicate(reps_pool, mean(sample(pool, n)))
    #      but handles all repetitions in one matrix operation, which is faster.
    idx <- replicate(reps_pool, sample.int(N, n))       # n x reps_pool matrix
    samp_means <- colMeans(matrix(pool[idx], nrow = n))

    errs <- c(errs, abs(samp_means - true_value))
  }

  c(D_mean = mean(errs), D_sd = sd(errs))
}

# Why redraw the pool
# ------------------
# Hebert et al. draw each species pool once. Whichever N species happen to be
# drawn may be unusually spread out or unusually tight, and the result follows
# that luck.
#
# The formula assumes sigma = 0.3948, so it has to be compared against a pool of
# average spread. Drawing once mixes two questions: whether the formula is right,
# and whether that particular pool was lucky.
#
# To follow Hebert et al. exactly, set n_pools to 1.

# --- find the required number of species -------------------------------------
#
# Stepping n up from 2 would take too long. Instead, test a window around the
# formula's prediction and confirm that the lowest value fails and the highest
# passes. If the lowest already passes, the formula is overestimating and the
# window needs to be widened.

find_minimum_n <- function(N, pool_source, n_pools, reps_pool,
                           window, T_val = T_TOLERANCE) {

  n_formula <- n_species_needed(N)
  n_try <- pmin(pmax(n_formula + window, 2), N)
  n_try <- sort(unique(n_try))

  cihi <- numeric(length(n_try))

  for (i in seq_along(n_try)) {
    e <- measure_error(N, n_try[i], pool_source, n_pools, reps_pool)
    cihi[i] <- e["D_mean"] + e["D_sd"]
  }

  passed <- which(cihi <= T_val)

  # Check 1. If the smallest n already passes, the answer lies below the window.
  if (length(passed) > 0 && passed[1] == 1 && n_try[1] > 2) {
    return(list(n_mc = NA_integer_, note = "answer below window"))
  }
  # Check 2. If even the largest n fails, the answer lies above the window.
  if (length(passed) == 0) {
    return(list(n_mc = NA_integer_, note = "answer above window"))
  }

  list(n_mc = n_try[passed[1]], note = "ok")
}

# --- run ---------------------------------------------------------------------
#
# 50 pool sizes x 7 sample sizes x 20 pools x 1000 surveys, so this takes a few
# minutes. To shorten it, lower n_pools or reps_pool, or reduce length.out in
# N_check above.

set.seed(SEED)

results_mc <- data.frame(
  N = N_check,
  n_mc = NA_integer_,
  n_formula = n_species_needed(N_check),
  note = NA_character_
)

for (i in seq_along(N_check)) {

  out <- find_minimum_n(N_check[i], full, n_pools, reps_pool, window)

  results_mc$n_mc[i] <- out$n_mc
  results_mc$note[i] <- out$note

  message(sprintf("  N = %5d   sampling %4s   formula %4d   %s",
                  N_check[i],
                  ifelse(is.na(out$n_mc), "-", out$n_mc),
                  results_mc$n_formula[i],
                  out$note))
}

results_mc <- results_mc |>
  mutate(difference = n_mc - n_formula)

# --- results -----------------------------------------------------------------

print(results_mc, row.names = FALSE)

summary_mc <- c(
  n_points  = sum(!is.na(results_mc$difference)),
  mean_diff = mean(results_mc$difference, na.rm = TRUE),
  sd_diff   = sd(results_mc$difference, na.rm = TRUE),
  max_diff  = max(abs(results_mc$difference), na.rm = TRUE),
  within_2  = mean(abs(results_mc$difference) <= 2, na.rm = TRUE)
)
round(summary_mc, 2)

# Split at 583. Below that the pool is drawn without replacement, above it with
# replacement, so the two halves are worth looking at separately.
results_mc |>
  mutate(band = ifelse(N <= N_donor, "N <= 583 (without replacement)",
                                     "N >  583 (with replacement)")) |>
  group_by(band) |>
  summarise(n_points  = n(),
            mean_diff = round(mean(difference, na.rm = TRUE), 2),
            sd_diff   = round(sd(difference, na.rm = TRUE), 2),
            .groups = "drop") |>
  as.data.frame()

# --- interpretation ----------------------------------------------------------
#
# A difference near zero means the formula is right. The remaining scatter is
# simulation noise and shrinks if reps_pool is raised.
#
# The mean sits slightly below zero because the formula rounds up: rounding adds
# about 0.52 species on average. Rounding up is deliberate, since rounding down
# would fall short of the criterion.
#
# That the formula holds despite the skew in the raw values means the normal
# approximation is already working at sample sizes around 25, which is what had
# to be checked.

saveRDS(results_mc, file.path(dir_outputs, "05_validate_mc.rds"))

message(sprintf("\n%d pool sizes checked (N = %d to %d)",
                summary_mc["n_points"], min(N_check), max(N_check)))
message(sprintf("mean difference %+.2f species, SD %.2f",
                summary_mc["mean_diff"], summary_mc["sd_diff"]))
message("05_validate_mc.R done")
