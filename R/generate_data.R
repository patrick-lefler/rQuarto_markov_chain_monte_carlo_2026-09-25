# R/generate_data.R
# -----------------------------------------------------------------------------
# Generates a frozen 250-day x 10-asset synthetic return matrix.
# Demonstrates high-dimensional joint posterior sampling via MCMC.
# -----------------------------------------------------------------------------

library(dplyr)
library(MASS)
library(tibble)
library(readr)

generate_synthetic_returns <- function(n_days = 250, seed = 20260924) {
  set.seed(seed)
  
  asset_names <- c(
    "US_LargeCap",   # Core Equity Beta
    "US_SmallCap",   # Size Premium
    "Tech_Growth",   # High-Beta Growth
    "EU_Equity",     # International Developed
    "EM_Equity",     # Emerging Markets
    "US_Treas_10Y",  # Duration / Safe Haven
    "US_Corp_Credit",# Credit Spread Carry
    "Commodities",   # Inflation Hedge
    "Gold",          # Tail Hedge / Safe Haven
    "Real_Estate"    # Real Asset / Rate Sensitive
  )
  
  d <- length(asset_names)
  
  # 1. Define Annualized Expectations and Convert to Daily
  # Daily mean returns (~3% to ~11% annualized)
  ann_returns <- c(0.085, 0.095, 0.110, 0.065, 0.075, 0.035, 0.050, 0.060, 0.045, 0.070)
  mu_daily <- ann_returns / 252
  
  # Daily volatility (~10% to ~28% annualized)
  ann_vols <- c(0.16, 0.22, 0.26, 0.18, 0.24, 0.08, 0.10, 0.20, 0.15, 0.19)
  sigma_daily <- ann_vols / sqrt(252)
  
  # 2. Construct Realistic Correlation Matrix (Rho)
  Rho <- matrix(0.20, nrow = d, ncol = d) # Baseline cross-asset correlation
  diag(Rho) <- 1.0
  
  # Equity cluster correlations (~0.60 to ~0.75)
  eq_idx <- 1:5
  Rho[eq_idx, eq_idx] <- 0.65
  diag(Rho[eq_idx, eq_idx]) <- 1.0
  Rho[1, 3] <- Rho[3, 1] <- 0.78 # LargeCap & Tech Growth
  
  # Treasury correlation with Equities (negative safe-haven offset)
  Rho[6, eq_idx] <- Rho[eq_idx, 6] <- -0.30
  
  # Gold hedge characteristics
  Rho[9, eq_idx] <- Rho[eq_idx, 9] <- -0.05
  Rho[9, 6]      <- Rho[6, 9]      <- 0.25  # Gold & Treasuries positive correlation
  
  # 3. Covariance Matrix: Sigma = diag(sigma) %*% Rho %*% diag(sigma)
  cov_matrix <- diag(sigma_daily) %*% Rho %*% diag(sigma_daily)
  
  # 4. Generate Synthetic Observations (Multivariate Normal)
  returns_raw <- MASS::mvrnorm(n = n_days, mu = mu_daily, Sigma = cov_matrix)
  
  returns_df <- as_tibble(returns_raw, .name_repair = "minimal")
  colnames(returns_df) <- asset_names
  
  # Add trading day index
  returns_df <- tibble(trading_day = 1:n_days) %>% bind_cols(returns_df)
  
  # 5. Export Frozen Fixture
  dir.create("data", showWarnings = FALSE)
  write_csv(returns_df, "data/synthetic_returns.csv")
  
  message("Generated data/synthetic_returns.csv successfully.")
  message(sprintf("Dimensions: %d trading days x %d factor assets", n_days, d))
  
  invisible(list(data = returns_df, mu_true = mu_daily, cov_true = cov_matrix))
}

if (sys.nframe() == 0) {
  fixture <- generate_synthetic_returns()
}
