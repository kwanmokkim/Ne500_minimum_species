# =============================================================================
# 05_validate_mc.R
# 검증 1. 원자료에서 직접 표본을 뽑아 필요 종수를 구하고 공식과 비교한다.
#
# 공식은 오차가 정규분포를 따른다는 전제 위에 있다. 그런데 583개 원자료는
# 절반 이상이 정확히 0 인 치우친 분포다. 전제가 성립하는지 확인해야 한다.
#
# 확인 방법은 단순하다. 공식을 쓰지 않고 Hebert et al. 의 절차를 그대로
# 실행하여 답을 구한 뒤 공식이 주는 답과 비교한다.
#
# 이 스크립트는 특정 국가와 무관하다. 종풀 크기 30 부터 5000 까지
# 넓은 범위에서 공식이 성립하는지 확인하는 것이 목적이다.
# 한국 적용은 07_apply_korea.R 에 있다.
# =============================================================================

source("R/00_setup.R")
source("R/04_formula.R")

sigma_result <- readRDS(file.path(dir_outputs, "02_sigma.rds"))
full <- sigma_result$values
N_donor <- length(full)   # 583

# --- 설정 --------------------------------------------------------------------

n_pools   <- 20     # 가상 국가를 몇 개 만들 것인가
reps_pool <- 1000   # 한 국가에서 조사를 몇 번 재현할 것인가
window    <- -6:2   # 공식 예측값 주변 어디까지 확인할 것인가

# 확인할 종풀 크기. 필요 비율은 작은 N 에서 급격히 변하고 큰 N 에서
# 평평해지므로 등간격이 아니라 로그 간격으로 나눈다.
N_check <- unique(round(exp(seq(log(30), log(5000), length.out = 50))))

length(N_check)
head(N_check, 12)
tail(N_check, 5)

# --- Hebert et al. 의 절차를 재현하는 함수 -----------------------------------
#
# 종풀 크기 N 에서 n 종을 조사했을 때의 오차 요약값을 구한다.
#
# 절차는 Hebert et al. 과 동일하다.
#   1. 583개 값에서 N 종을 뽑아 가상 국가의 전체 종목록을 만든다
#   2. 그 N 종의 평균을 참값으로 둔다
#   3. N 종 중 n 종만 뽑아 평균을 낸다
#   4. 참값과의 차이를 절댓값으로 기록한다
#   5. 3 과 4 를 여러 번 반복한다
#
# 한 군데만 다르다. Hebert et al. 은 1 번을 한 번만 실행하지만
# 여기서는 n_pools 번 반복한다. 이유는 아래 주석에 있다.

measure_error <- function(N, n, pool_source, n_pools, reps_pool) {

  errs <- numeric(0)

  for (p in seq_len(n_pools)) {

    # 1. 가상 국가의 전체 종목록
    #    N 이 583 을 넘으면 비복원추출이 불가능하므로 복원추출을 쓴다.
    #    Hebert et al. 이 Fig. S7 에서 사용한 방식과 같다.
    pool <- sample(pool_source, size = N, replace = (N > length(pool_source)))

    # 2. 이 국가의 참값
    true_value <- mean(pool)

    # 3-5. n 종만 조사한 경우를 reps_pool 번 재현한다.
    #      아래는 replicate(reps_pool, mean(sample(pool, n))) 과 같은 계산이며
    #      행렬로 한 번에 처리하여 속도를 높인 것이다.
    idx <- replicate(reps_pool, sample.int(N, n))       # n x reps_pool 행렬
    samp_means <- colMeans(matrix(pool[idx], nrow = n))

    errs <- c(errs, abs(samp_means - true_value))
  }

  c(D_mean = mean(errs), D_sd = sd(errs))
}

# 왜 종풀을 여러 번 뽑는가
# ------------------------
# Hebert et al. 은 각 종풀 크기마다 자루를 한 번만 뽑는다. 그러면 그 N 종이
# 우연히 흩어짐이 큰 조합일 수도 작은 조합일 수도 있고 결과가 그 운에 좌우된다.
# 공식은 sigma = 0.3948 을 전제로 하므로 그 전제에 맞는 평균적 자루와
# 비교해야 공식 자체를 시험하는 것이 된다. 자루를 한 번만 뽑으면
# 공식이 맞는가와 이 자루가 운이 좋았는가가 섞인다.
#
# Hebert et al. 의 절차를 글자 그대로 재현하려면 n_pools 를 1 로 두면 된다.

# --- 최소 종수를 찾는 함수 ---------------------------------------------------
#
# n 을 2 부터 하나씩 늘리면 시간이 너무 걸린다. 공식이 예측한 값 주변만
# 확인하되 아래쪽이 실패하고 위쪽이 통과하는지를 함께 본다.
# 아래쪽이 이미 통과하면 공식이 과대추정하고 있다는 뜻이므로 범위를 넓힌다.

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

  # 확인 1. 가장 작은 n 이 이미 통과하면 범위 밖에 답이 있다
  if (length(passed) > 0 && passed[1] == 1 && n_try[1] > 2) {
    return(list(n_mc = NA_integer_, note = "범위 아래에 답이 있다"))
  }
  # 확인 2. 가장 큰 n 도 통과하지 못하면 역시 범위 밖이다
  if (length(passed) == 0) {
    return(list(n_mc = NA_integer_, note = "범위 위에 답이 있다"))
  }

  list(n_mc = n_try[passed[1]], note = "정상")
}

# --- 실행 --------------------------------------------------------------------
#
# 종풀 크기 50 개 x 확인할 n 값 7 개 x 20 자루 x 1000 회 이므로
# 컴퓨터에 따라 수 분이 걸린다. 시간을 줄이려면 위의 n_pools 와
# reps_pool 을 낮추거나 N_check 의 length.out 을 줄인다.

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

  message(sprintf("  N = %5d   Monte Carlo %4s   공식 %4d   %s",
                  N_check[i],
                  ifelse(is.na(out$n_mc), "-", out$n_mc),
                  results_mc$n_formula[i],
                  out$note))
}

results_mc <- results_mc |>
  mutate(차이 = n_mc - n_formula)

# --- 결과 --------------------------------------------------------------------

print(results_mc, row.names = FALSE)

# 요약
summary_mc <- c(
  지점수 = sum(!is.na(results_mc$차이)),
  평균차이 = mean(results_mc$차이, na.rm = TRUE),
  표준편차 = sd(results_mc$차이, na.rm = TRUE),
  최대차이 = max(abs(results_mc$차이), na.rm = TRUE),
  이종이내비율 = mean(abs(results_mc$차이) <= 2, na.rm = TRUE)
)
round(summary_mc, 2)

# 583 을 기준으로 나누어 본다.
# 583 이하는 비복원추출이고 초과는 복원추출이므로 성격이 조금 다르다.
results_mc |>
  mutate(구간 = ifelse(N <= N_donor, "583 이하 (비복원)", "583 초과 (복원)")) |>
  group_by(구간) |>
  summarise(지점수 = n(),
            평균차이 = round(mean(차이, na.rm = TRUE), 2),
            표준편차 = round(sd(차이, na.rm = TRUE), 2),
            .groups = "drop") |>
  as.data.frame()

# --- 해석 --------------------------------------------------------------------
#
# 차이가 0 근처이면 공식이 옳다는 뜻이다.
# 남는 산포는 Monte Carlo 반복 오차이며 반복 횟수를 늘리면 줄어든다.
#
# 원자료가 심하게 치우쳐 있음에도 공식이 맞는다는 것은
# 표본 크기가 25 정도일 때부터 정규 근사가 작동한다는 뜻이다.
# 2.5 절의 전제가 실제로 성립하며 따라서 공식을 적용할 수 있다.

saveRDS(results_mc, file.path(dir_outputs, "05_validate_mc.rds"))

message(sprintf("\n비교 지점 %d 개 (N = %d ~ %d)",
                summary_mc["지점수"], min(N_check), max(N_check)))
message(sprintf("평균 차이 %+.2f 종, 표준편차 %.2f 종",
                summary_mc["평균차이"], summary_mc["표준편차"]))
message("05_validate_mc.R 완료")
