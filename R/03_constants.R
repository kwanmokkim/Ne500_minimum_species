# =============================================================================
# 03_constants.R
# 판정 기준 상수 k 를 계산하고 무한 종풀 필요 종수 n0 를 산출한다.
#
# k 는 자료를 사용하지 않는다. 원주율만 있으면 계산되는 이론값이다.
# =============================================================================

source("R/00_setup.R")

sigma_result <- readRDS(file.path(dir_outputs, "02_sigma.rds"))
sigma <- sigma_result$sigma

# --- half-normal 상수 --------------------------------------------------------
#
# 조사 결과 x_bar 가 참값 mu 에서 벗어나는 정도를 D = |x_bar - mu| 라 하자.
# x_bar 가 정규분포를 따르면 D 는 half-normal 분포를 따르고
# 그 평균과 표준편차는 표준오차 SE 의 고정 배수가 된다.

mult_mean <- sqrt(2 / pi)        # D 의 평균  = SE * 이 값
mult_sd   <- sqrt(1 - 2 / pi)    # D 의 표준편차 = SE * 이 값

round(c(평균배수 = mult_mean, 표준편차배수 = mult_sd), 5)

# --- 판정 기준 상수 k --------------------------------------------------------
#
# Hebert et al. 은 D 의 평균과 표준편차를 더한 값을 판정에 사용했다.
# 그 합을 SE 단위로 표현한 것이 k 다.

k_hebert <- mult_mean + mult_sd

# 참고로 다른 기준을 쓰고 싶다면 아래 값을 사용한다.
# 이 값들은 위 식과 무관하며 정규분포 분위수에서 나온다.
k_95   <- qnorm(0.975)           # 오차가 T 안에 들어올 확률 95%
k_975  <- qnorm(0.9875)          # 같은 확률 97.5%

# 각 k 가 몇 퍼센트에 해당하는지 확인한다.
coverage <- function(k) 2 * pnorm(k) - 1

data.frame(
  기준 = c("평균 + 표준편차 (Hebert)", "95%", "97.5%"),
  k = round(c(k_hebert, k_95, k_975), 5),
  포함확률 = round(coverage(c(k_hebert, k_95, k_975)), 4)
)

# --- n0 산출 -----------------------------------------------------------------
#
# 종풀이 무한히 클 때 필요한 종수다. 필요 종수의 상한이기도 하다.
#
#   k * SE <= T  이고  SE = sigma / sqrt(n)  이므로
#   n0 = (k * sigma / T)^2

n0_from <- function(k, sigma, T_val = T_TOLERANCE) (k * sigma / T_val)^2

n0_hebert <- n0_from(k_hebert, sigma)
n0_95     <- n0_from(k_95, sigma)

# 계산 과정을 단계별로 확인한다.
data.frame(
  단계 = c("k * sigma", "k * sigma / T", "n0 = 제곱"),
  값 = round(c(k_hebert * sigma,
               k_hebert * sigma / T_TOLERANCE,
               n0_hebert), 5)
)

# --- 저장 --------------------------------------------------------------------

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

message(sprintf("k (Hebert 기준) : %.5f   포함확률 %.1f%%",
                k_hebert, 100 * coverage(k_hebert)))
message(sprintf("k (95%% 기준)    : %.5f   포함확률 %.1f%%",
                k_95, 100 * coverage(k_95)))
message(sprintf("n0 (Hebert 기준): %.2f", n0_hebert))
message(sprintf("n0 (95%% 기준)   : %.2f", n0_95))
message("03_constants.R 완료")
