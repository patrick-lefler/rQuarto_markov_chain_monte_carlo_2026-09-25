# R/verify_risk_functions.R
# -----------------------------------------------------------------------------
# USED FOR VERIFICATION PURPOSES ONLY
# Verifies that the target likelihood binds properly to the gererated synthetic_returns.csv file.
# -----------------------------------------------------------------------------

source("R/risk_functions.R")
source("R/metropolis_sampler.R")

# 1. Initialize target from synthetic CSV
model_fixture <- build_risk_target("data/synthetic_returns.csv")

# 2. Run MCMC chain across all 10 assets
init_theta <- rep(0, model_fixture$d)
names(init_theta) <- model_fixture$asset_names

chain_10d <- run_metropolis(
  target_log_posterior = model_fixture$target_fn,
  initial_theta = init_theta,
  iterations = 2000,
  proposal_sd = 0.0008,
  seed = 42
)

# 3. Evaluate tail risk on equal-weighted book (10% each)
weights_eq <- rep(0.10, 10)
risk_table <- evaluate_portfolio_tail_risk(
  draws_df = chain_10d$draws,
  weights = weights_eq,
  cov_mat = model_fixture$cov_emp,
  alpha = 0.95
)

cat("10-Dimensional MCMC Sampler Run Complete.\n")
cat("10D Acceptance Rate:", round(chain_10d$acceptance_rate * 100, 1), "%\n")
print(risk_table)


