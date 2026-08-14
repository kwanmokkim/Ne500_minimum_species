# =============================================================================
# 01_download_data.R
# Fetch the source dataset.
#
# Data files are not committed to the repository, so that their provenance stays
# explicit and the repository stays small. Running this script once creates
# data/indicators_full.csv.
#
# Only this one file is needed. The formula uses the standard deviation of its
# 583 values and nothing else; the output files of Hebert et al. are not required.
# =============================================================================

source("R/00_setup.R")

# --- 583 species-level indicator values --------------------------------------
#
# Source: Mastretta-Yanes et al. (2024b)
#         Multinational evaluation of genetic diversity indicators for the
#         Kunming-Montreal Global Biodiversity Framework
#         Dryad, doi:10.5061/dryad.bk3j9kdkm
#
# Dryad redirects to the actual file location. R's default download method does
# not always follow that redirect, so we call curl with -L instead.

url_indicators <- "https://datadryad.org/downloads/file_stream/3204611"

download_safely <- function(url, destfile, min_size_kb = 500) {

  if (file.exists(destfile)) {
    message(basename(destfile), " is already present.")
    return(invisible(TRUE))
  }

  message("Downloading ", basename(destfile), " ...")

  ok <- try(
    download.file(url, destfile = destfile, mode = "wb",
                  method = "curl",
                  extra = "-L --fail --silent --show-error"),
    silent = TRUE
  )

  # A failed redirect can still write a small HTML error page, so check the size
  size_kb <- if (file.exists(destfile)) file.size(destfile) / 1024 else 0

  if (inherits(ok, "try-error") || size_kb < min_size_kb) {
    if (file.exists(destfile)) file.remove(destfile)
    stop(sprintf(
      "Could not download %s.\nOpen the URL in a browser and place the file at %s\n%s",
      basename(destfile), destfile, url))
  }

  message(sprintf("  done (%.0f KB)", size_kb))
  invisible(TRUE)
}

download_safely(url_indicators, file_indicators)

# --- check -------------------------------------------------------------------

indic <- read.csv(file_indicators)
dim(indic)
sum(!is.na(indic$indicator1))   # should be 583

message("01_download_data.R done")
