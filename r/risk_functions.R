# R/risk_functions.R

# This script connects the mathematical engine to portfolio risk management:
#  1.	Target Log-Posterior: Computes the joint posterior log-density for the 10 asset expected return parameters given the observed return matrix in data/synthetic_returns.csv (combining a weakly informative multivariate prior with the multivariate normal likelihood).
# 2.	Portfolio Loss & Risk Engine: Translates sampled posterior parameter draws into simulated forward portfolio losses, computing Value at Risk (VaR) and Expected Shortfall (ES) at chosen confidence levels (e.g., 95% and 99%).
# 3.	The Dimension Contrast Counter: A utility reporting the computational complexity gap between numerical grid integration (‭$K^D$‬) and MCMC for ‭$D = 2, 10, 20$‬‭‬‭‬ ‭‬‭‬ ‭‬.

# -----------------------------------------------------------------------------
# Evaluates the joint posterior distribution for 10 factor exposures and
# computes tail risk metrics (VaR & Expected Shortfall) from MCMC draws.
# -----------------------------------------------------------------------------

library(tibble)
library(dplyr)
library(readr)

#' Compute Log-Posterior Density for Factor Means (Theta)
#'
#' Assumes returns follow N(theta, Sigma_emp) with a prior theta ~ N(mu_0, Sigma_0).
#'
#' @param theta Numeric vector of candidate mean parameters (length D)
#' @param returns_mat Matrix of observed returns (N days x D assets)
#' @param inv_sigma Pre-computed inverse covariance matrix of returns
#' @param prior_mu Prior mean vector
#' @param inv_prior_var Inverse prior variance scalar (assuming isotropic prior)
compute_log_posterior <- function(theta, returns_mat, inv_sigma, prior_mu = 0, inv_prior_var = 1e-4) {
  n <- nrow(returns_mat)
  d <- length(theta)
  
  # 1. Log-Prior: theta ~ N(0, (1 / inv_prior_var) * I)
  diff_prior <- theta - prior_mu
  log_prior  <- -0.5 * inv_prior_var * sum(diff_prior^2)
  
  # 2. Log-Likelihood: sum_{t=1}^n log N(r_t | theta, Sigma)
  # Efficient matrix evaluation: sum quadratic forms across all days
  diff_mat <- sweep(returns_mat, 2, theta, FUN = "-")
  quad_forms <- rowSums((diff_mat %*% inv_sigma) * diff_mat)
  log_lik <- -0.5 * sum(quad_forms)
  
  log_prior + log_lik
}

#' Factory: Build Target Log-Posterior Function Bound to Synthetic Return Matrix
#'
#' @param csv_path Path to the frozen fixture data/synthetic_returns.csv
#' @return A list with the target function, asset names, and empirical covariance
build_risk_target <- function(csv_path = "data/synthetic_returns.csv") {
  df <- readr::read_csv(csv_path, show_col_types = FALSE)
  returns_mat <- as.matrix(df %>% select(-trading_day))
  asset_names <- colnames(returns_mat)
  d <- ncol(returns_mat)
  
  cov_emp   <- cov(returns_mat)
  inv_sigma <- solve(cov_emp)
  
  target_fn <- function(theta) {
    compute_log_posterior(
      theta = theta,
      returns_mat = returns_mat,
      inv_sigma = inv_sigma,
      prior_mu = rep(0, d),
      inv_prior_var = 1e-3
    )
  }
  
  list(
    target_fn   = target_fn,
    asset_names = asset_names,
    returns_mat = returns_mat,
    cov_emp     = cov_emp,
    d           = d
  )
}

#' Compute Portfolio VaR and Expected Shortfall (CVaR) from MCMC Posterior Draws
#'
#' @param draws_df Tibble of parameter draws from run_metropolis()
#' @param weights Numeric vector of portfolio asset weights (sums to 1)
#' @param cov_mat Covariance matrix of asset returns
#' @param horizon Days forward (default: 1 day)
#' @param alpha Confidence level (e.g., 0.95 or 0.99)
#'
#' @return A tibble with point estimates and posterior credible intervals for VaR and ES
evaluate_portfolio_tail_risk <- function(draws_df,
                                         weights = rep(0.10, 10),
                                         cov_mat,
                                         horizon = 1,
                                         alpha = 0.95) {
  # Strip iteration metadata
  param_cols <- setdiff(colnames(draws_df), c("iteration", "accepted", "log_posterior"))
  theta_draws <- as.matrix(draws_df[, param_cols])
  n_draws <- nrow(theta_draws)
  
  # Portfolio variance is constant under empirical covariance: w' * Sigma * w
  port_var <- as.numeric(t(weights) %*% cov_mat %*% weights)
  port_sd  <- sqrt(port_var * horizon)
  
  # For each posterior draw of mean return theta_s:
  port_mean_draws <- as.numeric(theta_draws %*% weights) * horizon
  
  # Parametric VaR & ES distribution over posterior draws
  # VaR_alpha = -(mu_p + z_{1-alpha} * sigma_p)
  z_alpha <- qnorm(1 - alpha)
  var_draws <- -(port_mean_draws + z_alpha * port_sd)
  
  # ES_alpha = -(mu_p - sigma_p * dnorm(z_alpha) / (1 - alpha))
  es_draws <- -(port_mean_draws - port_sd * (dnorm(z_alpha) / (1 - alpha)))
  
  tibble(
    metric = c(paste0("VaR (", round(alpha * 100), "%)"), paste0("Expected Shortfall (", round(alpha * 100), "%)")),
    mean_estimate = c(mean(var_draws), mean(es_draws)),
    ci_05 = c(quantile(var_draws, 0.05), quantile(es_draws, 0.05)),
    ci_95 = c(quantile(var_draws, 0.95), quantile(es_draws, 0.95))
  )
}

#' Dimension Complexity Comparison Table (K^D)
generate_dimension_comparison <- function() {
  tibble(
    Dimensions = c("2 Assets (simple model)", "10 Assets (current model)", "20 Assets (future model)"),
    Grid_Points_Per_Axis = c(10, 10, 10),
    Total_Grid_Evaluations = c("10^2 = 100", "10^10 = 10,000,000,000", "10^20 = 100,000,000,000,000,000,000"),
    Grid_Feasibility = c("Instantaneous (<1 ms)", "Memory Overflow / Impractical", "Computationally Impossible"),
    MCMC_Iterations_Required = c("1,000 draws", "5,000 draws", "10,000 draws"),
    MCMC_Solve_Time = c("< 0.1 seconds", "~1.5 seconds", "~3.5 seconds")
  )
}
