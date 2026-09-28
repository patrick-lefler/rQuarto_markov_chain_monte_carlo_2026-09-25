### The Brilliance of Markov Chain Monte Carlo
#### Taming High-Dimensional Risk Models Through Random Walks
Author: Patrick Lefler 

Original Publish Date: 2026-09-25

Rendered link: https://patrick-lefler.github.io/rQuarto_markov_chain_monte_carlo_2026-09-25/

### Project Introduction

An R Metropolis sampler replaces intractable grid integration with a random walk, pricing 10-factor portfolio VaR and Expected Shortfall in seconds.

### Overview

Correlated multi-asset portfolio risk requires a joint posterior over every 
factor exposure at once, and grid integration scales exponentially with 
dimension: about ten billion evaluations at ten factors. This project builds 
a Random-Walk Metropolis sampler from first principles in pure R and applies 
it to a ten-factor portfolio spanning equity, credit, duration, and commodity 
exposures.

The model is deliberately conjugate. With covariance fixed at its sample 
estimate, the exact posterior of expected returns is known in closed form, so 
every MCMC output (means, standard deviations, credible intervals, VaR, and 
Expected Shortfall) can be checked against the true answer. The project is 
therefore a model-validation case study: it shows how a sampler with a 
textbook acceptance rate can still fail to converge and understate risk, and 
how multi-chain diagnostics and an exact benchmark expose that failure before 
it reaches a risk report.

### Tech Stack

Language: R

Framework: Quarto multi-page site (Sandstone theme, navbar)

Primary Libraries: tidyverse (dplyr, ggplot2, purrr, readr, stringr, tibble, tidyr), gt, reactable, scales, sessioninfo

Deployment/Output: Four-page self-contained HTML site (index.qmd, 01-mechanics.qmd, 02-risk-application.qmd, 03-reproducibility.qmd)

### Repository Structure

```
mcmc-in-action/
├── _quarto.yml                  # Quarto configuration (Sandstone theme, navbar)
├── index.qmd                    # Intuition & 2D random walk visualization
├── 01-mechanics.qmd             # Metropolis-Hastings engine & tuning diagnostics
├── 02-risk-application.qmd      # 10-factor portfolio risk model & tail estimates
├── 03-reproducibility.qmd       # Convergence diagnostics & computational manifest
├── R/
├── ├── disnostics.R             # Diagnostics file
│   ├── generate_data.R          # Generates synthetic 10-asset returns fixture
│   ├── metropolis_sampler.R     # Pure R Metropolis-Hastings sampler
|   |── plots.R                  # ggplot2 themes and diagnostic plots
|   |── remediate.R              # R Remediation script 
│   └── risk_functions.R         # Joint log-posterior & tail risk evaluation
└── data/
    └── synthetic_returns.csv # Frozen 250-day x 10-factor returns matrix
```
 
### Key Findings
- **Point estimates are right.** The sampler reproduces the exact posterior 
  means of portfolio VaR (95%) at 1.05% and Expected Shortfall (95%) at 1.33%, 
  agreeing with the closed-form answer to within about half a basis point.
- **Uncertainty is understated.** The MCMC 90% credible interval for VaR 
  (0.99%–1.11%) is about 17% narrower than the exact interval (0.98%–1.12%), 
  and nine of ten factors show posterior standard deviations 3–18% below 
  the true values. On a $100M portfolio, the exact interval represents about 
  $140,000 of VaR uncertainty from mean-estimation error alone; the sampler 
  reports roughly $120,000.
- **The chains have not converged.** Across four chains started at ±3 
  posterior standard deviations, all ten factors fail the split-R̂ < 1.01 
  test (maximum 1.057, Tech Growth), and the 500-iteration burn-in is too 
  short for overdispersed starts.
- **Effective sample size is far too low.** Pooled across four chains 
  (10,000 draws), bulk ESS is only 65–316 for the audited factors, below the 
  recommended 400. All three pass on tail ESS except Tech Growth (132). 
  Estimates were cross-checked against the `posterior` package.
- **A healthy acceptance rate is not evidence of convergence.** The chain 
  accepts 28.9% of proposals, within the conventional target, yet mixes 
  poorly because a single isotropic step size cannot match factors with very 
  different scales and strong correlations. Covariance-preconditioned or 
  gradient-based samplers are the indicated fix.
- **Parameter recovery is a data problem, not a sampler problem.** With 250 
  daily observations, Tech Growth's posterior sits 2.8 standard deviations 
  above its true generating value. One year of data cannot reliably separate 
  high-drift and low-drift assets.

### License

This project is licensed under the MIT License. See the LICENSE file for details.

### Contact

Patrick Lefler [https://www.linkedin.com/in/patricklefler/] | [patrick-lefler.github.io] | [https://substack.com/@pflefler]
