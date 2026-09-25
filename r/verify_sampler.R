# R/verify_sampler.R
# -----------------------------------------------------------------------------
# USED FOR VERIFICATION PURPOSES ONLY
# Verifies and tests the sampler engine on a 2D test problem:
# -----------------------------------------------------------------------------




source("R/metropolis_sampler.R")

# 2D Bivariate Normal Test Target
target_test <- function(theta) {
  mu <- c(0, 0)
  sigma <- matrix(c(1, 0.7, 0.7, 1), nrow = 2)
  # Unnormalized log-density
  -0.5 * t(theta - mu) %*% solve(sigma) %*% (theta - mu)
}

test_chain <- run_metropolis(
  target_log_posterior = target_test,
  initial_theta = c(-3, 3), # Start far out in the low-density tail
  iterations = 1000,
  proposal_sd = 0.5,
  seed = 42
)

cat("MCMC Test Chain Run Complete.\n")
cat("Acceptance Rate:", round(test_chain$acceptance_rate * 100, 1), "%\n")
