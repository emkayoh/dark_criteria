# dc_rit_error_figure.R  (JMFK)
# The RIT error propagation figure: how the error in calculated RIT
# (from fitted parameters) against true RIT (from simulation truth)
# scales with the rod slope S2.
#
# Two panels:
#   (a) absolute median RIT error vs |S2|, log-log, with the fitted power
#       law exponent annotated. Theory predicts exponent ~ -2 (variance
#       goes as S2^-4, so typical absolute error goes as S2^-2).
#   (b) relative error (error / true RIT) vs |S2|, showing that relative
#       precision is roughly flat while absolute error explodes.
#
# Row for the shallowest slope is split at MAXTIME (the test window) so
# that fitting error is not conflated with unobservability: beyond the
# window RIT is censored, not mis-estimated.

rm(list = ls())

library(dplyr)
library(tidyr)
library(ggplot2)

## ---- configuration --------------------------------------------------------

dir_mac <- "~/Dropbox/Mumac_/CODE_1/dark_criteria/results/Mac_dark_criteria_results/"

mac_f <- c(
    "dc_experiment_results_tau0.6_2026-08-20_113721_pid3341.csv",
    "dc_experiment_results_tau1.2_2026-08-20_113721_pid3342.csv",
    "dc_experiment_results_tau1.8_2026-08-20_113721_pid3343.csv",
    "dc_experiment_results_tau2.4_2026-08-20_113721_pid3344.csv"
)

CRIT    <- -3.0      # criterion threshold; state explicitly in any write-up
MAXTIME <- 20         # test window, minutes; adjust to match the protocol
RIT_CAP <- 1e5         # sanity bound for implausible RIT values (fit failure)

RITc <- function(alpha, s2, ct, crit = CRIT) alpha + (crit - ct) / s2

vars <- c("S2_real", "alpha_real", "ct_real", "noise_sd",
          "S2_profile", "alpha_profile", "ct_profile",
          "tau_profile", "cc_profile")

## ---- load all four tau sets and pool ---------------------------------------
# The scaling of RIT error with |S2| is a property of the criterion and the
# parameters, not of tau, so pooling across cone regimes is appropriate here
# (report per-tau if a reviewer asks whether it holds within each regime).

read_one <- function(f) {
    d <- read.csv(file.path(path.expand(dir_mac), f), sep = ",")
    d[, vars]
}

dat <- bind_rows(lapply(mac_f, read_one)) |> as_tibble()

## ---- compute true and fitted RIT -------------------------------------------

dat <- dat |>
    filter(noise_sd > 0, S2_real < 0) |>          # noiseless rows are a
                                                    # separate sanity check;
                                                    # null truth has no RIT
    mutate(
        rit_true = RITc(alpha_real, S2_real, ct_real),
        rit_fit  = ifelse(S2_profile < 0,
                          RITc(alpha_profile, S2_profile, ct_profile),
                          NA_real_),
        degenerate = tau_profile <= 0.0101 | cc_profile > 4,
        observable = rit_true <= MAXTIME
    ) |>
    filter(is.finite(rit_fit), rit_fit > 0, rit_fit < RIT_CAP,
           rit_true > 0, rit_true < RIT_CAP)

## ---- quantile table by |S2|, split by observability ------------------------

qtab <- dat |>
    mutate(abs_err = abs(rit_fit - rit_true),
           rel_err = abs_err / rit_true) |>
    summarise(
        n           = n(),
        pct_observable = mean(observable) * 100,
        med_abs     = median(abs_err),
        q90_abs     = quantile(abs_err, 0.90),
        q99_abs     = quantile(abs_err, 0.99),
        med_rel     = median(rel_err),
        q90_rel     = quantile(rel_err, 0.90),
        .by = S2_real
    ) |>
    arrange(desc(S2_real))
print(qtab, n = 20)

# Same, restricted to cases where true RIT falls inside the test window:
# this isolates fitting error from censoring.
qtab_obs <- dat |> filter(observable) |>
    mutate(abs_err = abs(rit_fit - rit_true),
           rel_err = abs_err / rit_true) |>
    summarise(
        n       = n(),
        med_abs = median(abs_err), q90_abs = quantile(abs_err, 0.90),
        med_rel = median(rel_err), q90_rel = quantile(rel_err, 0.90),
        .by = S2_real
    ) |>
    arrange(desc(S2_real))
cat("\n--- restricted to true RIT within the test window ---\n")
print(qtab_obs, n = 20)

## ---- fit the power-law exponent on the observable subset -------------------
# Theory: Var(RIT) ~ S2^-4  =>  typical absolute error ~ |S2|^-2.
# Fit on qtab_obs so extrapolation-dominated rows don't bias the exponent.

fit <- lm(log(med_abs) ~ log(abs(S2_real)), data = qtab_obs)
exponent <- unname(coef(fit)[2])
cat(sprintf("\nFitted exponent: %.2f  (theory predicts approximately -2)\n",
            exponent))
print(summary(fit))

## ---- robustness check: degenerate vs non-degenerate, matched -------------
# Does cone-parameter degeneracy (tau at the grid bound) matter to RIT
# error, once S2 and noise are held fixed? Prediction: no, since RIT does
# not depend on cc or tau.

robust <- dat |> filter(observable) |>
    mutate(abs_err = abs(rit_fit - rit_true)) |>
    summarise(n = n(), med_abs = median(abs_err),
              .by = c(S2_real, noise_sd, degenerate)) |>
    arrange(S2_real, noise_sd, degenerate)
cat("\n--- degenerate vs non-degenerate RIT error, matched on S2 and noise ---\n")
print(robust, n = 60)

## ---- Figure: the candidate central figure ----------------------------------

fig_dat <- qtab_obs |>
    mutate(abs_S2 = abs(S2_real)) |>
    select(abs_S2, med_abs, q90_abs, med_rel, q90_rel) |>
    pivot_longer(c(med_abs, q90_abs), names_to = "stat", values_to = "abs_err") |>
    mutate(stat = recode(stat, med_abs = "median", q90_abs = "90th percentile"))

p_abs <- ggplot(fig_dat, aes(abs_S2, abs_err, colour = stat, shape = stat)) +
    geom_point(size = 2) + geom_line() +
    scale_x_log10(name = "|S2| (log units / min)") +
    scale_y_log10(name = "|RIT error| (min)") +
    annotate("text", x = min(fig_dat$abs_S2), y = max(fig_dat$abs_err),
             hjust = 0, vjust = 1,
             label = sprintf("fitted exponent (median): %.2f", exponent)) +
    labs(colour = NULL, shape = NULL,
         title = "Error in calculated RIT vs true RIT, by rod slope",
         subtitle = "restricted to true RIT within the test window") +
    theme_minimal()
print(p_abs)

fig_rel <- qtab_obs |> mutate(abs_S2 = abs(S2_real)) |>
    select(abs_S2, med_rel, q90_rel) |>
    pivot_longer(c(med_rel, q90_rel), names_to = "stat", values_to = "rel_err") |>
    mutate(stat = recode(stat, med_rel = "median", q90_rel = "90th percentile"))

p_rel <- ggplot(fig_rel, aes(abs_S2, rel_err, colour = stat, shape = stat)) +
    geom_point(size = 2) + geom_line() +
    scale_x_log10(name = "|S2| (log units / min)") +
    scale_y_continuous(name = "relative RIT error", labels = scales::percent) +
    labs(colour = NULL, shape = NULL,
         title = "Relative error is comparatively flat",
         subtitle = "same data as above, expressed as a fraction of true RIT") +
    theme_minimal()
print(p_rel)

results_dir <- path.expand(dir_mac)
ggsave(file.path(results_dir, "rit_error_absolute.pdf"), p_abs,
       width = 6.5, height = 4.5)
ggsave(file.path(results_dir, "rit_error_relative.pdf"), p_rel,
       width = 6.5, height = 4.5)

## ---- what to check before using this in the write-up ----------------------
# 1. Does the fitted exponent come out near -2? If not, the discrepancy
#    itself is worth understanding (covariance terms, ct contribution,
#    or the influence of alpha's anticonservative coverage).
# 2. Does the shallowest slope's "pct_observable" collapse as expected
#    (most cases beyond the test window)? If so, state plainly that the
#    tail there is censoring, not fitting failure -- cite Higgins et al.
#    (2021) as the reference for handling it statistically.
# 3. In the robustness table, do degenerate and non-degenerate rows agree
#    at matched S2 and noise? If so, that is the demonstration that RIT
#    is robust to cone-parameter instability specifically, independent of
#    the slope-dependent argument above.