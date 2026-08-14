# =============================================================================
# 02_sigma.R
# 583종 종별 지표값에서 표준편차 sigma 를 산출한다.
#
# sigma 는 이 분석에서 자료가 공급하는 유일한 값이다.
# 나머지는 모두 선택이거나 수학 상수다.
# =============================================================================

source("R/00_setup.R")

# --- 자료 읽기 ---------------------------------------------------------------

indic <- read.csv(file_indicators)

dim(indic)
names(indic)

# indicator1 열이 종 수준 Ne500 지표값이다.
# 한 종의 개체군 중 유효집단크기가 500 을 넘는 비율이며 0 에서 1 사이의 값이다.

full <- indic$indicator1[!is.na(indic$indicator1)]

length(full)   # 583 이어야 한다

# --- 분포 확인 ---------------------------------------------------------------
#
# 원자료는 정규분포가 아니다. 절반 이상이 정확히 0 이다.
# 그럼에도 표본평균은 정규분포를 따르며 이는 05_validate_mc.R 에서 확인한다.

summary(full)

table(cut(full, breaks = c(-0.01, 0, 0.25, 0.5, 0.75, 0.999, 1),
          labels = c("정확히 0", "0 초과 0.25", "0.25-0.5",
                     "0.5-0.75", "0.75 미만", "정확히 1")))

round(mean(full == 0), 3)   # 0 인 비율
round(mean(full == 1), 3)   # 1 인 비율

# --- sigma 산출 --------------------------------------------------------------
#
# 583종 전부를 사용하므로 이는 추정이 아니라 측정이다.
# 따라서 분모를 n-1 이 아니라 n 으로 하는 모집단 표준편차를 쓴다.

sigma_pop <- sqrt(mean((full - mean(full))^2))

# 참고: R 의 sd() 는 분모가 n-1 이다. 583개에서는 차이가 미미하다.
c(모집단_표준편차 = sigma_pop, sd_함수 = sd(full))

# --- 저장 --------------------------------------------------------------------

sigma_result <- list(
  values = full,
  n_species = length(full),
  mean = mean(full),
  sigma = sigma_pop
)

saveRDS(sigma_result, file.path(dir_outputs, "02_sigma.rds"))

message(sprintf("종 수  : %d", sigma_result$n_species))
message(sprintf("평균   : %.4f", sigma_result$mean))
message(sprintf("sigma  : %.6f", sigma_result$sigma))
message("02_sigma.R 완료")
