# =============================================================================
# 07_apply_korea.R
# 공식을 국내 11 개 분류군에 적용한다.
#
# 이 스크립트는 적용 예시다. 다른 나라에서 사용할 경우
# data/korea_species_pools.csv 를 자국 자료로 바꾸면 된다.
#
# 종풀 크기 N 은 국가생물적색목록 평가 완료 종수에서 자료부족(DD) 을 제외한
# 값이다. 따라서 보고 대상은 적색목록 평가 완료 종이다.
# =============================================================================

source("R/00_setup.R")
source("R/04_formula.R")

# --- 종풀 크기 읽기 ----------------------------------------------------------

korea <- read.csv(file_korea_pools)

korea
sum(korea$N)

# --- 두 기준으로 적용 --------------------------------------------------------
#
# Hebert 기준은 허용 오차 안에 들어올 확률이 83.9% 다.
# 95% 기준을 병기하는 이유는 방법론 문서 7.1 절에 있다.

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

# --- 합계 --------------------------------------------------------------------

totals <- korea_result |>
  summarise(N = sum(N),
            n_hebert = sum(n_hebert),
            n_95 = sum(n_95)) |>
  mutate(pct_hebert = round(100 * n_hebert / N, 1),
         pct_95 = round(100 * n_95 / N, 1))

totals

# --- 전수조사 대상 확인 ------------------------------------------------------
#
# 필요 비율이 80% 를 넘으면 표본조사로 절약되는 종수가 적어
# 전수조사가 설계상 단순하고 결과적으로도 우월하다.

korea_result |>
  filter(pct_hebert >= 80) |>
  mutate(절약되는_종수 = N - n_hebert) |>
  select(taxon_kr, N, n_hebert, pct_hebert, 절약되는_종수)

# --- 저장 --------------------------------------------------------------------

write.csv(korea_result,
          file.path(dir_outputs, "07_korea_minimum_species.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

message(sprintf("합계: 종풀 %d 종 중 Hebert 기준 %d 종, 95%% 기준 %d 종",
                totals$N, totals$n_hebert, totals$n_95))
message("07_apply_korea.R 완료")
