# =============================================================================
# 06_figures.R
# Figures.
#
# fig1  distribution of the 583 values      the source data is not normal
# fig2  central limit theorem               but its means are
# fig3  error curve and crossing point      what the formula computes
# fig4  validation: sampling vs formula     output of 05
# fig5  final curve with Korean taxa        output of 07
#
# fig4 is the important one: the requirement found by sampling directly from the
# raw data, set against the requirement given by the formula.
# =============================================================================

source("R/00_setup.R")
source("R/04_formula.R")

sigma_result <- readRDS(file.path(dir_outputs, "02_sigma.rds"))
constants    <- readRDS(file.path(dir_outputs, "03_constants.rds"))
full  <- sigma_result$values
sigma <- constants$sigma
k     <- constants$k_hebert
n0    <- constants$n0_hebert

col_a <- "#2C6E9B"
col_b <- "#C1552B"
col_c <- "#4A4A4A"

# --- fig1. distribution of the 583 values ------------------------------------

p1 <- ggplot(data.frame(x = full), aes(x = x)) +
  geom_histogram(binwidth = 0.05, boundary = 0,
                 fill = col_a, colour = "white") +
  geom_vline(xintercept = mean(full), colour = col_b,
             linetype = "dashed", linewidth = 0.8) +
  annotate("text", x = mean(full) + 0.03, y = Inf, vjust = 2,
           label = sprintf("mean = %.3f", mean(full)),
           colour = col_b, size = 3) +
  labs(x = "Species-level indicator value (indicator1)",
       y = "Number of species",
       title = sprintf("583 species-level values, sigma = %.4f", sigma)) +
  theme_ne500

ggsave(file.path(dir_figures, "fig1_histogram.png"), p1,
       width = 6, height = 3.4, dpi = 150)

# --- fig2. central limit theorem ---------------------------------------------
#
# The raw values are not normal, but averaging several of them produces a normal
# distribution. This is what licenses the constant k.

set.seed(SEED)
pool <- sample(full, size = 94)
mu   <- mean(pool)
xbar <- replicate(20000, mean(sample(pool, size = 54)))
D    <- abs(xbar - mu)

df2 <- bind_rows(
  data.frame(value = pool, panel = "(a) 94 raw values"),
  data.frame(value = xbar, panel = "(b) means of n = 54"),
  data.frame(value = D,    panel = "(c) |error| = D")
)

p2 <- ggplot(df2, aes(x = value)) +
  geom_histogram(bins = 40, fill = col_a, colour = "white") +
  facet_wrap(~ panel, scales = "free") +
  labs(x = NULL, y = "frequency",
       title = "Raw values are skewed but their means are normal") +
  theme_ne500

ggsave(file.path(dir_figures, "fig2_clt.png"), p2,
       width = 9, height = 3, dpi = 150)

# --- fig3. error curve and crossing point ------------------------------------
#
# What the formula actually computes. The error falls as more species are
# surveyed; the requirement is where the curve meets the tolerated error.

df3 <- expand.grid(N = c(94, 214, 712), n = 2:712) |>
  filter(n < N) |>
  mutate(cihi = k * (sigma / sqrt(n)) * sqrt((N - n) / (N - 1)),
         N_lab = factor(paste0("N = ", N), levels = paste0("N = ", c(94, 214, 712))))

df3_cross <- data.frame(N = c(94, 214, 712)) |>
  mutate(n = n_species_needed_raw(N),
         N_lab = factor(paste0("N = ", N), levels = levels(df3$N_lab)))

p3 <- ggplot(df3, aes(x = n, y = cihi, colour = N_lab)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = T_TOLERANCE, colour = col_c,
             linetype = "dashed", linewidth = 0.5) +
  geom_point(data = df3_cross, aes(x = n, y = T_TOLERANCE, colour = N_lab),
             size = 2.8) +
  geom_text(data = df3_cross,
            aes(x = n, y = T_TOLERANCE + 0.011, label = round(n, 0), colour = N_lab),
            size = 3, show.legend = FALSE) +
  annotate("text", x = 640, y = T_TOLERANCE + 0.008,
           label = "T = 0.05", size = 3, colour = col_c) +
  scale_colour_manual(values = c(col_a, "#2E7D4F", col_b)) +
  coord_cartesian(xlim = c(0, 720), ylim = c(0, 0.15)) +
  labs(x = "Species surveyed (n)", y = expression(bar(D) + s[D]),
       colour = NULL,
       title = "The requirement is where the error curve meets T") +
  theme_ne500 + theme(legend.position = "bottom")

ggsave(file.path(dir_figures, "fig3_errorcurve.png"), p3,
       width = 6.5, height = 4, dpi = 150)

# --- fig4. validation: sampling result vs formula ----------------------------
#
# Output of 05. The requirement found by sampling directly from the 583 raw
# values, with no formula involved, set against the requirement given by the
# formula.

mc <- readRDS(file.path(dir_outputs, "05_validate_mc.rds"))

curve4 <- data.frame(N = seq(20, 5200, length.out = 600)) |>
  mutate(n = n_species_needed_raw(N))

# (a) count scale. Agreement means the points lie on the line.
p4a <- ggplot() +
  geom_line(data = curve4, aes(x = N, y = n),
            colour = col_b, linewidth = 0.9) +
  geom_point(data = mc, aes(x = N, y = n_mc),
             colour = col_a, size = 1.8) +
  geom_hline(yintercept = n0, colour = col_c,
             linetype = "dashed", linewidth = 0.4) +
  # Formulae are drawn with plotmath. Unicode characters render as empty boxes
  # in some fonts. Note that plotmath allows only one == per expression; to mix
  # text with an expression, wrap it in paste().
  annotate("text", x = 26, y = 108, hjust = 0, size = 3.6, colour = col_b,
           parse = TRUE,
           label = "n == n[0] * N / (N - 1 + n[0])") +
  annotate("text", x = 26, y = 98, hjust = 0, size = 3.1, colour = col_b,
           parse = TRUE,
           label = sprintf("paste(n[0] == (k * sigma / T)^2, '   =   %.2f')", n0)) +
  annotate("text", x = 26, y = n0 + 5, hjust = 0, size = 3, colour = col_c,
           parse = TRUE,
           label = sprintf("paste('asymptote   ', n[0] == %.2f)", n0)) +
  scale_x_log10() +
  coord_cartesian(ylim = c(15, 138)) +
  labs(x = "Species pool size (N), log scale",
       y = "Species to monitor (n)",
       title = "Direct sampling (points) against the formula (line)") +
  theme_ne500+
  theme(axis.title = element_text(size = 15),   # 축 제목: "Species pool size (N)..." 등
        axis.text  = element_text(size = 12),
        plot.title = element_text(size=15))   # 눈금 숫자: 30, 100, 1000 ...

# (b) difference. Agreement means the points cluster near zero.
p4b <- ggplot(mc, aes(x = N, y = difference)) +
  geom_hline(yintercept = 0, colour = col_c, linewidth = 0.5) +
  geom_hline(yintercept = mean(mc$difference, na.rm = TRUE),
             colour = col_b, linetype = "dashed", linewidth = 0.6) +
  geom_point(colour = col_a, size = 1.8) +
  annotate("text", x = 40, y = mean(mc$difference, na.rm = TRUE) - 0.45,
           label = sprintf("mean %.2f", mean(mc$difference, na.rm = TRUE)),
           size = 3, colour = col_b, hjust = 0) +
  scale_x_log10() +
  labs(x = "Species pool size (N), log scale",
       y = "Sampling result - formula (species)",
       title = "(b) difference; the offset is the ceiling in the formula") +
  theme_ne500

ggsave(file.path(dir_figures, "fig4a_validation.png"), p4a,
       width = 6, height = 3.8, dpi = 150)
ggsave(file.path(dir_figures, "fig4b_validation_diff.png"), p4b,
       width = 6, height = 3.4, dpi = 150)

# --- fig5. final curve with Korean taxa --------------------------------------

korea <- read.csv(file_korea_pools) |>
  mutate(n_hebert = n_species_needed(N),
         pct = 100 * n_hebert / N)

df5 <- bind_rows(
  data.frame(N = 20:800,
             y = 100 * n_species_needed(20:800) / (20:800),
             criterion = "84% (Hebert)"),
  data.frame(N = 20:800,
             y = 100 * n_species_needed(20:800, k = k_for_coverage(0.95)) / (20:800),
             criterion = "95%")
)

p5 <- ggplot() +
  geom_line(data = df5, aes(x = N, y = y, colour = criterion), linewidth = 0.9) +
  geom_point(data = korea, aes(x = N, y = pct), size = 2) +
  geom_text(data = korea,
            aes(x = N, y = pct, label = taxon,
                vjust = ifelse(taxon == "Amphibian_Reptile", 1.9, -0.9)),
            hjust = -0.05, size = 2.5) +
  scale_colour_manual(values = c(col_a, col_b)) +
  coord_cartesian(xlim = c(0, 850), ylim = c(0, 100)) +
  labs(x = "Species pool size (N)", y = "Species to monitor (%)",
       colour = NULL,
       title = "Minimum species to monitor, with Korean taxa marked") +
  theme_ne500 + theme(legend.position = "bottom")

ggsave(file.path(dir_figures, "fig5_final.png"), p5,
       width = 7, height = 4.5, dpi = 150)

message("Figures written to figures/")
message("06_figures.R done")
