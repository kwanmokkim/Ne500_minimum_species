# =============================================================================
# 03_constants.R
# Compute the criterion constant k and the infinite-pool requirement n0.
#
# No data enters the calculation of k. It follows from the criterion alone.
# =============================================================================

source("R/00_setup.R")

sigma_result <- readRDS(file.path(dir_outputs, "02_sigma.rds"))
sigma <- sigma_result$sigma

# --- half-normal constants ---------------------------------------------------
#
# Let D = |x_bar - mu| be the departure of a survey from the true value.
# If x_bar is normal, D is half-normal, and its mean and standard deviation are
# fixed multiples of the standard error SE.

mult_mean <- sqrt(2 / pi)        # mean of D            = SE * this
mult_sd   <- sqrt(1 - 2 / pi)    # standard deviation of D = SE * this

round(c(mean_multiple = mult_mean, sd_multiple = mult_sd), 5)

# --- criterion constant k ----------------------------------------------------
#
# Hebert et al. use the mean of D plus its standard deviation. Expressing that
# sum in units of SE gives k.

k_hebert <- mult_mean + mult_sd

# For a different criterion. These come from normal quantiles and are unrelated
# to the expression above.
k_95   <- qnorm(0.975)           # error falls within T 95% of the time
k_975  <- qnorm(0.9875)          # 97.5% of the time

# Coverage implied by a given k
coverage <- function(k) 2 * pnorm(k) - 1

data.frame(
  criterion = c("mean + SD (Hebert)", "95%", "97.5%"),
  k = round(c(k_hebert, k_95, k_975), 5),
  coverage = round(coverage(c(k_hebert, k_95, k_975)), 4)
)

# --- n0 ----------------------------------------------------------------------
#
# The requirement for an infinitely large species pool, and therefore an upper
# bound on the requirement for any pool.
#
#   k * SE <= T   with   SE = sigma / sqrt(n)   gives   n0 = (k * sigma / T)^2

n0_from <- function(k, sigma, T_val = T_TOLERANCE) (k * sigma / T_val)^2

n0_hebert <- n0_from(k_hebert, sigma)
n0_95     <- n0_from(k_95, sigma)

# Step by step
data.frame(
  step  = c("k * sigma", "k * sigma / T", "n0 = squared"),
  value = round(c(k_hebert * sigma,
                  k_hebert * sigma / T_TOLERANCE,
                  n0_hebert), 5)
)

# --- save --------------------------------------------------------------------

constants <- list(
  sigma = sigma,
  T_tolerance = T_TOLERANCE,
  mult_mean = mult_mean,
  mult_sd = mult_sd,
  k_hebert = k_hebert,
  k_95 = k_95,
  n0_hebert = n0_hebert,
  n0_95 = n0_95
)

saveRDS(constants, file.path(dir_outputs, "03_constants.rds"))

message(sprintf("k (Hebert criterion) : %.5f   coverage %.1f%%",
                k_hebert, 100 * coverage(k_hebert)))
message(sprintf("k (95%% criterion)    : %.5f   coverage %.1f%%",
                k_95, 100 * coverage(k_95)))
message(sprintf("n0 (Hebert criterion): %.2f", n0_hebert))
message(sprintf("n0 (95%% criterion)   : %.2f", n0_95))
message("03_constants.R done")
