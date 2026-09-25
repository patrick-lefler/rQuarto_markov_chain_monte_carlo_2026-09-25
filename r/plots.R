# R/plots.R
# -----------------------------------------------------------------------------
# Publication-grade ggplot2 visualizations for MCMC in Action.
# Uses consistent minimalist styling tailored for HTML rendering.
# -----------------------------------------------------------------------------

library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)

# Consistent clean theme
theme_mcmc <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(color = "#555555", size = 10),
      axis.title = element_text(face = "bold", size = 10),
      legend.position = "bottom"
    )
}

#' Hero Chart: 2D Random Walk Path on Correlated Posterior Contours
#'
#' Visualizes the first N steps of a chain climbing into the stationary zone.
plot_random_walk_2d <- function(draws_df, n_steps = 150) {
  walk_sub <- draws_df %>% slice_head(n = n_steps)
  
  # Synthetic 2D density grid for background contour
  grid_seq <- seq(-3.5, 3.5, length.out = 100)
  grid_df <- expand.grid(x = grid_seq, y = grid_seq)
  # Correlated bivariate Gaussian (rho = 0.70)
  rho <- 0.70
  grid_df$density <- exp(-0.5 / (1 - rho^2) * (grid_df$x^2 - 2 * rho * grid_df$x * grid_df$y + grid_df$y^2))
  
  ggplot() +
    # Posterior contours
    geom_contour_filled(data = grid_df, aes(x = x, y = y, z = density), alpha = 0.35, show.legend = FALSE) +
    # Trajectory path (arrows and points)
    geom_path(data = walk_sub, aes(x = theta_1, y = theta_2), color = "#2c3e50", alpha = 0.6, linewidth = 0.7) +
    geom_point(data = walk_sub, aes(x = theta_1, y = theta_2, color = iteration), size = 1.6) +
    # Start and current markers
    geom_point(data = slice_head(walk_sub, n = 1), aes(x = theta_1, y = theta_2), color = "#d9534f", size = 3.5) +
    annotate("text", x = walk_sub$theta_1[1] + 0.3, y = walk_sub$theta_2[1], label = "Start (Cold)", fontface = "bold", color = "#d9534f", hjust = 0) +
    scale_color_viridis_c(option = "mako", name = "Iteration") +
    labs(
      title = "Metropolis-Hastings Random Walk in Action",
      subtitle = sprintf("First %d iterations climbing from low-density tail into posterior core", n_steps),
      x = expression(theta[1] ~ "(Equity Factor Mean)"),
      y = expression(theta[2] ~ "(Credit Spread Mean)")
    ) +
    theme_mcmc()
}

#' Diagnostic Comparison: Proposal Step-Size Tuning (Timid vs. Wild vs. Calibrated)
plot_step_size_comparison <- function(chain_small, chain_large, chain_tuned) {
  diag_df <- bind_rows(
    chain_small$draws %>% select(iteration, value = 1) %>% mutate(Tuning = sprintf("Too Small (Acc: %.1f%%)", chain_small$acceptance_rate * 100)),
    chain_large$draws %>% select(iteration, value = 1) %>% mutate(Tuning = sprintf("Too Large (Acc: %.1f%%)", chain_large$acceptance_rate * 100)),
    chain_tuned$draws %>% select(iteration, value = 1) %>% mutate(Tuning = sprintf("Calibrated (Acc: %.1f%%)", chain_tuned$acceptance_rate * 100))
  )
  
  ggplot(diag_df, aes(x = iteration, y = value, color = Tuning)) +
    geom_line(alpha = 0.8, linewidth = 0.5) +
    facet_wrap(~Tuning, ncol = 1, scales = "free_y") +
    scale_color_manual(values = c("#2e7d32", "#c62828", "#1565c0")) +
    labs(
      title = "The Anatomy of MCMC Tuning: Proposal Step Size Matters",
      subtitle = "Trace plots showing slow diffusion, high freeze rate, and healthy stationary mixing",
      x = "Iteration",
      y = expression(theta[1])
    ) +
    theme_mcmc() +
    theme(legend.position = "none")
}

#' Marginal Posterior Draws vs. True Analytical Parameter
plot_posterior_marginals <- function(draws_df, asset_name, true_val) {
  p_df <- tibble(val = draws_df[[asset_name]])
  
  ggplot(p_df, aes(x = val)) +
    geom_histogram(aes(y = after_stat(density)), bins = 40, fill = "#34495e", color = "white", alpha = 0.75) +
    geom_density(color = "#e67e22", linewidth = 1.1) +
    geom_vline(xintercept = true_val, color = "#c0392b", linetype = "dashed", linewidth = 1) +
    annotate("text", x = true_val, y = 0, label = " Ground Truth", color = "#c0392b", vjust = -1, hjust = 0, fontface = "bold", size = 3.5) +
    scale_x_continuous(labels = label_percent(accuracy = 0.01)) +
    labs(
      title = paste("Posterior Distribution:", asset_name),
      subtitle = "Sampled empirical distribution vs. true parameter (dashed red line)",
      x = "Daily Expected Return",
      y = "Posterior Density"
    ) +
    theme_mcmc()
}
