# =============================================================================
# 01_download_data.R
# 원자료를 내려받는다.
#
# 저장소에는 자료 파일을 포함하지 않는다. 자료의 출처를 명확히 하고
# 저장소 용량을 줄이기 위해서다. 이 스크립트를 한 번 실행하면
# data/indicators_full.csv 가 생긴다.
#
# 필요한 파일은 이것 하나다. 공식은 이 583 개 값의 표준편차만 사용하며
# Hebert et al. 의 계산 결과물은 필요하지 않다.
# =============================================================================

source("R/00_setup.R")

# --- 종별 지표값 583종 -------------------------------------------------------
#
# 출처: Mastretta-Yanes et al. (2024b)
#       Multinational evaluation of genetic diversity indicators for the
#       Kunming-Montreal Global Biodiversity Framework
#       Dryad, doi:10.5061/dryad.bk3j9kdkm
#
# Dryad 는 실제 파일이 있는 주소로 넘겨주는 리다이렉트 방식을 쓴다.
# R 의 기본 방식은 이를 따라가지 못하는 경우가 있으므로 curl 을 쓰되
# -L 옵션(리다이렉트 따라가기)을 붙인다.

url_indicators <- "https://datadryad.org/downloads/file_stream/3204611"

download_safely <- function(url, destfile, min_size_kb = 500) {

  if (file.exists(destfile)) {
    message(basename(destfile), " 가 이미 있다.")
    return(invisible(TRUE))
  }

  message(basename(destfile), " 를 내려받는다 ...")

  ok <- try(
    download.file(url, destfile = destfile, mode = "wb",
                  method = "curl",
                  extra = "-L --fail --silent --show-error"),
    silent = TRUE
  )

  # 실패했거나 파일이 지나치게 작으면 오류 페이지를 받은 것이다
  size_kb <- if (file.exists(destfile)) file.size(destfile) / 1024 else 0

  if (inherits(ok, "try-error") || size_kb < min_size_kb) {
    if (file.exists(destfile)) file.remove(destfile)
    stop(sprintf(
      "%s 다운로드에 실패했다.\n브라우저로 아래 주소를 열어 내려받은 뒤 %s 에 넣는다.\n%s",
      basename(destfile), destfile, url))
  }

  message(sprintf("  완료 (%.0f KB)", size_kb))
  invisible(TRUE)
}

download_safely(url_indicators, file_indicators)

# --- 확인 --------------------------------------------------------------------

indic <- read.csv(file_indicators)
dim(indic)
sum(!is.na(indic$indicator1))   # 583 이어야 한다

message("01_download_data.R 완료")
