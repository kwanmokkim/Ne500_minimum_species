# =============================================================================
# 07_apply_korea.R
# Apply the formula to eleven Korean taxonomic groups.
#
# This is a worked example. To use it for another country, replace
# data/korea_species_pools.csv with your own pool sizes.
#
# N is the number of species assessed in the Korean National Red List, excluding
# Data Deficient. The reporting universe is therefore the assessed species.
# =============================================================================

source("R/00_setup.R")
source("R/04_formula.R")

# --- read the pool sizes -----------------------------------------------------

korea <- read.csv(file_korea_pools)

korea
sum(korea$N)

# --- apply both criteria -----------------------------------------------------
#
# The Hebert criterion holds the error within tolerance about 84% of the time.
# The 95% criterion is reported alongside it; see the README for why.

k_hebert <- sqrt(2 / pi) + sqrt(1 - 2 / pi)
k_95 <- k_for_coverage(0.95)

korea_result <- korea |>
  mutate(
    n_hebert = n_species_needed(N, k = k_hebert),
    pct_hebert = round(100 * n_hebert / N, 1),
    n_95 = n_species_needed(N, k = k_95),
    pct_95 = round(100 * n_95 / N, 1)
  )

korea_result

# --- totals ------------------------------------------------------------------

totals <- korea_result |>
  summarise(N = sum(N),
            n_hebert = sum(n_hebert),
            n_95 = sum(n_95)) |>
  mutate(pct_hebert = round(100 * n_hebert / N, 1),
         pct_95 = round(100 * n_95 / N, 1))

totals

# --- groups better surveyed in full ------------------------------------------
#
# Where the required proportion exceeds about 80%, sampling saves so few species
# that a full census is both simpler to design and better.

korea_result |>
  filter(pct_hebert >= 80) |>
  mutate(species_saved = N - n_hebert) |>
  select(taxon, N, n_hebert, pct_hebert, species_saved)

# --- save --------------------------------------------------------------------

write.csv(korea_result,
          file.path(dir_outputs, "07_korea_minimum_species.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

message(sprintf("Total: %d species in the pools; %d needed (Hebert), %d needed (95%%)",
                totals$N, totals$n_hebert, totals$n_95))
message("07_apply_korea.R done")
