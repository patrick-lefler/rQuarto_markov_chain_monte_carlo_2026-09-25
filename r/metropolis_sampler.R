# R/metropolis_sampler.R
# -----------------------------------------------------------------------------
# Pure R implementation of Random-Walk Metropolis-Hastings.
# Demonstrates high-dimensional joint posterior sampling without black-box packages.
# -----------------------------------------------------------------------------

library(tibble)
library(dplyr)

#' Random-Walk Metropolis-Hastings Sampler
#'
#' @param target_log_posterior Function computing unnormalized log p(theta | data)
#' @param initial_theta Numeric vector: starting coordinates in parameter space
#' @param iterations Integer: total number of MCMC iterations to run
#' @param proposal_sd Numeric or Matrix: standard deviation (or covariance) of jump proposals
#' @param seed Optional integer for deterministic reproducibility
#'
#' @return A list containing:
#'   - draws: tibble of parameter coordinates at each step
#'   - acceptance_rate: scalar proportion of accepted proposal steps
#'   - diagnostics: tibble tracking acceptance decisions and log-posterior density
run_metropolis <- function(target_log_posterior,
                           initial_theta,
                           iterations = 5000,
                           proposal_sd = 0.05,
                           seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  
  d <- length(initial_theta)
  theta_current <- initial_theta
  log_p_current <- target_log_posterior(theta_current)
  
  # Pre-allocate storage matrices for speed
  draws_mat <- matrix(NA_real_, nrow = iterations, ncol = d)
  accepted  <- logical(iterations)
  log_probs <- numeric(iterations)
  
  # Metropolis-Hastings Loop
  for (t in 1:iterations) {
    # 1. Propose candidate coordinates (Gaussian Random Walk)
    if (is.matrix(proposal_sd)) {
      theta_candidate <- MASS::mvrnorm(1, mu = theta_current, Sigma = proposal_sd)
    } else {
      theta_candidate <- rnorm(d, mean = theta_current, sd = proposal_sd)
    }
    
    # 2. Evaluate candidate log-posterior
    log_p_candidate <- target_log_posterior(theta_candidate)
    
    # 3. Acceptance Ratio: alpha = min(1, p(candidate) / p(current))
    # In log space: log_alpha = log_p_candidate - log_p_current
    log_alpha <- log_p_candidate - log_p_current
    
    # 4. Accept / Reject Decision
    if (!is.na(log_alpha) && log(runif(1)) < log_alpha) {
      theta_current <- theta_candidate
      log_p_current <- log_p_candidate
      accepted[t]   <- TRUE
    } else {
      accepted[t]   <- FALSE
    }
    
    draws_mat[t, ] <- theta_current
    log_probs[t]   <- log_p_current
  }
  
  param_names <- if (!is.null(names(initial_theta))) {
    names(initial_theta)
  } else {
    paste0("theta_", seq_len(d))
  }
  
  draws_df <- as_tibble(draws_mat, .name_repair = "minimal")
  colnames(draws_df) <- param_names
  draws_df <- draws_df %>% mutate(iteration = seq_len(iterations))
  
  diagnostics_df <- tibble(
    iteration = seq_len(iterations),
    accepted = accepted,
    log_posterior = log_probs
  )
  
  list(
    draws = draws_df,
    acceptance_rate = mean(accepted),
    diagnostics = diagnostics_df,
    dimensions = d,
    proposal_sd = proposal_sd
  )
}
