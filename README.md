The Brilliance of Markov Chain Monte Carlo

Taming High-Dimensional Risk Models Through Random Walks
Author: Patrick Lefler Published: [not stated in source — confirm before publishing] Rendered:

Project Introduction

A pure-R Metropolis-Hastings sampler replaces intractable grid integration with a random walk, pricing 10-factor portfolio VaR and Expected Shortfall in seconds.
Overview

Correlated multi-asset portfolio risk requires a joint posterior over every factor exposure at once, and grid integration collapses well before ten assets — roughly ten billion evaluations at that scale, and past what any machine can hold at twenty. This project implements a Metropolis-Hastings sampler from first principles in pure R and applies it to a ten-factor portfolio spanning equity, credit, duration, and commodity exposures. Instead of solving the posterior integral directly, the sampler takes a calibrated random walk through parameter space, converging on the true distribution in under two seconds. For investment committees and model-validation teams, the outcome is a Value-at-Risk and Expected Shortfall estimate with a full Bayesian credible interval, backed by convergence diagnostics an auditor can verify rather than a black-box output.

Tech Stack

Language: R
Framework: Quarto multi-page site (Sandstone theme, navbar)
Primary Libraries: tidyverse (dplyr, ggplot2, purrr, readr, stringr, tibble, tidyr), gt, reactable, scales, sessioninfo
Deployment/Output: Four-page self-contained HTML site (index.qmd, 01-mechanics.qmd, 02-risk-application.qmd, 03-reproducibility.qmd)
Repository Structure

```
mcmc-in-action/
├── _quarto.yml               # Quarto configuration (Sandstone theme, navbar)
├── index.qmd                 # Intuition & 2D random walk visualization
├── 01-mechanics.qmd          # Metropolis-Hastings engine & tuning diagnostics
├── 02-risk-application.qmd   # 10-factor portfolio risk model & tail estimates
├── 03-reproducibility.qmd    # Convergence diagnostics & computational manifest
├── R/
│   ├── generate_data.R       # Generates synthetic 10-asset returns fixture
│   ├── metropolis_sampler.R  # Pure R Metropolis-Hastings sampler
│   ├── risk_functions.R      # Joint log-posterior & tail risk evaluation
│   └── plots.R               # ggplot2 themes and diagnostic plots
└── data/
    └── synthetic_returns.csv # Frozen 250-day x 10-factor returns matrix
```
 
Key Findings

Grid search becomes computationally impossible past roughly ten correlated risk factors (10^10 evaluations at 10 assets, 10^20 at 20), while the pure R sampler produces thousands of joint posterior draws in under two seconds — a curse-of-dimensionality problem turned into a problem of waiting, not a dead end.
Sampling the full ten-factor joint posterior, rather than plugging in point estimates for expected returns and covariances, yields VaR(95%) = 1.05% [0.99%, 1.11%] and Expected Shortfall(95%) = 1.33% [1.27%, 1.39%] — a 12-basis-point credible interval on VaR alone, equivalent to roughly $120,000 of estimation uncertainty on a $100M portfolio before any market shock occurs.
Multi-chain convergence checks and Effective Sample Size audits (39–82 effective draws per 2,500 post-burn-in iterations, roughly 1.6%–3.3% efficiency) confirm the chain reaches its stationary distribution independent of starting point, giving model-validation teams the audit trail needed before production sign-off.
License

This project is licensed under the MIT License. See the LICENSE file for details.

Contact

Patrick Lefler [https://www.linkedin.com/in/patricklefler/] | [patrick-lefler.github.io] | [https://substack.com/@pflefler]
