# R/verify_diagnostics.R — sanity checks for compute_ess_robust()
source("R/diagnostics.R")
set.seed(1)
iid <- rnorm(5000)
ar  <- as.numeric(arima.sim(list(ar = 0.9), n = 5000))
cat("IID  ESS (expect ~5000):", compute_ess_robust(iid), "\n")
cat("AR(1) phi=0.9 ESS (expect ~5000*0.1/1.9 = 263):", compute_ess_robust(ar), "\n")
if (requireNamespace("coda", quietly = TRUE)) {
  cat("coda cross-check (AR1):", round(coda::effectiveSize(ar)), "\n")
}
