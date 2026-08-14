# =============================================================================
# 06_figures.R
# 그림을 그린다.
#
# 그림 1  583종 지표값의 분포              자료가 정규분포가 아님을 보인다
# 그림 2  중심극한정리                     그럼에도 평균은 정규분포가 된다
# 그림 3  오차 곡선과 통과점               공식이 무엇을 계산하는지 보인다
# 그림 4  검증: 표본추출 결과와 공식        05 의 결과
# 그림 5  최종 곡선과 국내 분류군           7 장의 적용 결과
#
# 그림 4 가 핵심이다. 공식을 쓰지 않고 원자료에서 직접 뽑아 구한 종수와
# 공식이 주는 종수를 나란히 놓은 것이다.
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

# --- 그림 1. 583종 지표값의 분포 ---------------------------------------------

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

# --- 그림 2. 중심극한정리 ----------------------------------------------------
#
# 원자료는 정규분포가 아니지만 여러 개를 평균내면 정규분포에 가까워진다.
# 이것이 공식의 상수 k 가 성립하는 근거다.

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

# --- 그림 3. 오차 곡선과 통과점 ----------------------------------------------
#
# 공식이 실제로 계산하는 것이 무엇인지 보인다.
# 조사 종수가 늘면 오차가 줄고 허용 오차와 만나는 지점이 필요 종수다.

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

# --- 그림 4. 검증: 표본추출 결과와 공식 --------------------------------------
#
# 05 의 결과다. 공식을 쓰지 않고 583 개 원자료에서 직접 표본을 뽑아
# 구한 필요 종수와 공식이 주는 종수를 비교한다.

mc <- readRDS(file.path(dir_outputs, "05_validate_mc.rds"))

curve4 <- data.frame(N = seq(20, 5200, length.out = 600)) |>
  mutate(n = n_species_needed_raw(N))

# (a) 종수 척도. 점이 곡선 위에 놓이면 일치한다.
p4a <- ggplot() +
  geom_line(data = curve4, aes(x = N, y = n),
            colour = col_b, linewidth = 0.9) +
  geom_point(data = mc, aes(x = N, y = n_mc),
             colour = col_a, size = 1.8) +
  geom_hline(yintercept = n0, colour = col_c,
             linetype = "dashed", linewidth = 0.4) +
  # 수식은 plotmath 로 그린다. 유니코드 문자를 쓰면 글꼴에 따라 네모로 나온다.
  # 주의: 한 수식에 == 는 한 번만 쓸 수 있다. 글자를 섞으려면 paste() 로 감싼다.
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
       title = "(a) direct sampling (points) against the formula (line)") +
  theme_ne500

# (b) 차이. 0 근처에 모이면 일치한다.
p4b <- ggplot(mc, aes(x = N, y = 차이)) +
  geom_hline(yintercept = 0, colour = col_c, linewidth = 0.5) +
  geom_hline(yintercept = mean(mc$차이, na.rm = TRUE),
             colour = col_b, linetype = "dashed", linewidth = 0.6) +
  geom_point(colour = col_a, size = 1.8) +
  annotate("text", x = 40, y = mean(mc$차이, na.rm = TRUE) - 0.45,
           label = sprintf("mean %.2f", mean(mc$차이, na.rm = TRUE)),
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

# --- 그림 5. 최종 곡선과 국내 분류군 -----------------------------------------

korea <- read.csv(file_korea_pools) |>
  mutate(n_hebert = n_species_needed(N),
         pct = 100 * n_hebert / N)

df5 <- bind_rows(
  data.frame(N = 20:800,
             y = 100 * n_species_needed(20:800) / (20:800),
             기준 = "84% (Hebert)"),
  data.frame(N = 20:800,
             y = 100 * n_species_needed(20:800, k = k_for_coverage(0.95)) / (20:800),
             기준 = "95%")
)

p5 <- ggplot() +
  geom_line(data = df5, aes(x = N, y = y, colour = 기준), linewidth = 0.9) +
  geom_point(data = korea, aes(x = N, y = pct), size = 2) +
  geom_text(data = korea,
            aes(x = N, y = pct, label = taxon_en,
                vjust = ifelse(taxon_en == "Amphibian_Reptile", 1.9, -0.9)),
            hjust = -0.05, size = 2.5) +
  scale_colour_manual(values = c(col_a, col_b)) +
  coord_cartesian(xlim = c(0, 850), ylim = c(0, 100)) +
  labs(x = "Species pool size (N)", y = "Species to monitor (%)",
       colour = NULL,
       title = "Minimum species to monitor, with Korean taxa marked") +
  theme_ne500 + theme(legend.position = "bottom")

ggsave(file.path(dir_figures, "fig5_final.png"), p5,
       width = 7, height = 4.5, dpi = 150)

message("그림을 figures/ 에 저장했다.")
message("06_figures.R 완료")
