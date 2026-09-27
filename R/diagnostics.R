# R/diagnostics.R
# -----------------------------------------------------------------------------
# MCMC diagnostics used on the Audit & Diagnostics page.
# -----------------------------------------------------------------------------

#' Effective Sample Size via Geyer's initial monotone sequence estimator
#'
#' Sums autocorrelations in adjacent pairs, Gamma_k = rho_{2k} + rho_{2k+1},
#' stops at the first non-positive pair, and enforces monotone decline.
#' Integrated autocorrelation time: tau = -1 + 2 * sum(Gamma_k).
#' Reference: Geyer (1992), "Practical Markov Chain Monte Carlo", Stat. Sci.
#'
#' @param x Numeric vector of post-burn-in draws for one parameter
#' @return ESS (rounded), capped at length(x)
compute_ess_robust <- function(x) {
  x <- as.numeric(x)
  n <- length(x)
  if (n < 4 || stats::var(x) == 0) return(NA_real_)

  rho <- stats::acf(x, lag.max = n - 1, plot = FALSE)$acf[, 1, 1]  # lags 0..n-1
  m   <- floor(length(rho) / 2)
  gamma <- rho[2 * seq_len(m) - 1] + rho[2 * seq_len(m)]           # Gamma_0..Gamma_{m-1}

  first_neg <- which(gamma <= 0)[1]
  if (!is.na(first_neg)) gamma <- gamma[seq_len(first_neg - 1)]
  gamma <- cummin(gamma)                                           # monotone

  tau <- -1 + 2 * sum(gamma)
  round(min(n, n / tau))
}

#' Split-R-hat (Gelman et al., 2013) for a list of chains of equal length
compute_split_rhat <- function(chains) {
  halves <- unlist(lapply(chains, function(ch) {
    h <- floor(length(ch) / 2)
    list(ch[1:h], ch[(h + 1):(2 * h)])
  }), recursive = FALSE)
  n <- length(halves[[1]])
  means <- vapply(halves, mean, numeric(1))
  vars  <- vapply(halves, stats::var, numeric(1))
  W <- mean(vars)
  B <- n * stats::var(means)
  sqrt(((n - 1) / n * W + B / n) / W)
}
