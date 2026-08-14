# =============================================================================
# 00_setup.R
# 패키지 로드, 경로 정의, 전역 설정
#
# 이 스크립트는 다른 모든 스크립트의 맨 앞에서 source() 로 불러온다.
# =============================================================================

# --- 패키지 ------------------------------------------------------------------

library(dplyr)
library(ggplot2)

# --- 경로 --------------------------------------------------------------------

dir_data    <- "data"
dir_outputs <- "outputs"
dir_figures <- "figures"

for (d in c(dir_data, dir_outputs, dir_figures)) {
  if (!dir.exists(d)) dir.create(d)
}

# --- 파일 이름 ---------------------------------------------------------------
#
# 자료 파일은 하나뿐이다. Mastretta-Yanes et al. (2024b) 의 583 종
# 종 수준 지표값이며 이것이 공식의 유일한 입력이다.

file_indicators  <- file.path(dir_data, "indicators_full.csv")
file_korea_pools <- file.path(dir_data, "korea_species_pools.csv")

# --- 분석 설정 ---------------------------------------------------------------

# 허용 오차. 지표는 0 에서 1 사이의 값이므로 0.05 는 5 퍼센트 포인트를 뜻한다.
# Hebert et al. (2026) 이 사용한 값이다.
T_TOLERANCE <- 0.05

# 재현을 위한 난수 시드
SEED <- 2026

# 그림 공통 설정
theme_ne500 <- theme_bw(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(size = 10))

message("00_setup.R 완료")
