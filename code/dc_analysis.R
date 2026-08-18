# dc_analysis.R  (JMFK)
# Analysis of the dark criteria numerical experiment:
#   Q1  does gradient descent refinement add anything to the profiled fit?
#   Q1b what does the NM refinement stage contribute over the raw grid?
#   Q2  parameter detection thresholds by noise level, under honest
#       boundary policies, for the CI rule and the AICc rule.
#   Q3  CI calibration: coverage of S2 and alpha intervals.
# Self-contained: run top to bottom against one parsed results CSV.
# Policies encoded below were settled empirically on 2026-08-17.
# Revised 2026-08-18 for the corrected fit function (exact constrained
# boundary solve) and the 78-column results format.

library(dplyr)
library(ggplot2)
library(tidyr)

## ---- load and check ------------------------------------------------------

res_dir <- "~/Dropbox/Mumac_/CODE_1/dark_criteria/results"

# Select the dataset explicitly. Either set FOI_NAME to a filename, or set
# FOI_INDEX to pick from the reverse-sorted listing (1 = newest).
FOI_NAME  <- NA_character_
FOI_INDEX <- 1L

files <- sort(list.files(res_dir, "^dc_experiment_results_.*\\.csv$",
                         full.names = TRUE), decreasing = TRUE)
foi <- if (!is.na(FOI_NAME)) file.path(res_dir, FOI_NAME) else files[FOI_INDEX]
results <- read.csv(foi) |> as_tibble()
message("Loaded: ", basename(foi), "  (", nrow(results), " rows)")

stopifnot(length(unique(results$git_commit)) == 1)   # one code version only

# Refuse to run silently against the old 64-column format.
new_cols <- c("grid_rss", "grid_S2_boundary", "nm_refined", "nm_skipped",
              "nm_converged", "nm_rss_improvement", "nm_rss_improvement_frac",
              "nm_tau_shift", "nm_alpha_shift", "profile_boundary_mismatch",
              "gdr_status")
stopifnot(all(new_cols %in% names(results)))

# The boundary cross-check flag should be all FALSE; report if not.
n_mismatch <- sum(results$profile_boundary_mismatch, na.rm = TRUE)
if (n_mismatch > 0) {
  warning(n_mismatch, " rows with profile_boundary_mismatch = TRUE")
}

results <- results |>
  mutate(profile_boundary = factor(profile_boundary,
                                   levels = c("interior", "S2_lower", "S2_upper")))

d <- results
TAU <- paste(sort(unique(results$tau_real)), collapse = "_")

## ---- Q1: what does gradient descent add? --------------------------------
# Interior fits only (GD is not attempted from a pinned constraint) and
# genuinely biphasic truth only (alpha_real is meaningless for nulls).

q1 <- d |>
  filter(gdr_attempted, profile_boundary == "interior", true_biphasic) |>
  mutate(
    alpha_gain = abs(alpha_profile - alpha_real) - abs(alpha_est_gdr - alpha_real),
    S2_gain    = abs(S2_profile   - S2_real)    - abs(S2_est_gdr   - S2_real),
    tau_gain   = abs(tau_profile  - tau_real)   - abs(tau_est_gdr  - tau_real)
  )

q1_summary <- q1 |>
  summarise(
    n               = n(),
    rss_impr_med    = median(rss_improvement_fraction),
    rss_impr_q90    = quantile(rss_improvement_fraction, 0.9),
    alpha_better    = mean(alpha_gain > 0),
    alpha_tie       = mean(alpha_gain == 0),
    alpha_worse     = mean(alpha_gain < 0),
    alpha_moved_med = median(abs(alpha_est_gdr - alpha_profile)),
    S2_better       = mean(S2_gain > 0),
    S2_tie          = mean(S2_gain == 0),
    S2_worse        = mean(S2_gain < 0),
    .by = noise_sd) |>
  arrange(noise_sd)
print(q1_summary)

gd_convergence <- d |>
  filter(gdr_attempted) |>
  summarise(gd_fail = mean(!gdr_converged), n = n(), .by = noise_sd)
print(gd_convergence)

# Why GD stops: "no_improving_step" is stationarity evidence, distinct
# from genuine numerical failure.
gd_status_tab <- d |>
  filter(gdr_attempted) |>
  count(noise_sd, gdr_status) |>
  pivot_wider(names_from = gdr_status, values_from = n, values_fill = 0)
print(gd_status_tab)

## ---- Q1b: what does the NM refinement stage contribute? -----------------
# Three-stage accounting: grid -> NM (continuous profiled refinement)
# -> GD (full five-parameter descent). NM's contribution is real but small;
# GD's should be nil. Interior fits only, since NM is skipped on zero pins.

nm_summary <- d |>
  filter(profile_boundary == "interior") |>
  summarise(
    n               = n(),
    nm_refined_rate = mean(nm_refined),
    nm_fail_rate    = mean(!nm_converged, na.rm = TRUE),
    nm_frac_med     = median(nm_rss_improvement_frac),
    nm_frac_q90     = quantile(nm_rss_improvement_frac, 0.9),
    tau_shift_med   = median(abs(nm_tau_shift)),
    tau_shift_q90   = quantile(abs(nm_tau_shift), 0.9),
    alpha_shift_med = median(abs(nm_alpha_shift)),
    alpha_shift_q90 = quantile(abs(nm_alpha_shift), 0.9),
    .by = noise_sd) |>
  arrange(noise_sd)
print(nm_summary)

nm_skips <- d |>
  count(nm_skipped, nm_skip_reason)
print(nm_skips)

# NM vs GD contribution side by side (fraction of each stage's input RSS).
stage_summary <- d |>
  filter(profile_boundary == "interior") |>
  summarise(
    nm_frac_med = median(nm_rss_improvement_frac),
    nm_frac_q90 = quantile(nm_rss_improvement_frac, 0.9),
    gd_frac_med = median(rss_improvement_fraction, na.rm = TRUE),
    gd_frac_q90 = quantile(rss_improvement_fraction, 0.9, na.rm = TRUE),
    .by = noise_sd) |>
  arrange(noise_sd)
print(stage_summary)

## ---- boundary structure (context for the policies below) ----------------

boundary_tab <- with(d, table(profile_boundary, true_biphasic, noise_sd))
print(ftable(boundary_tab))

## ---- Q2: detection rules under honest boundary policies -----------------
# CI rule (final policy, "ci_lowA" in the exploratory analysis):
#   S2_upper pin (fit wants no rod phase)      -> not detected
#   S2_lower pin (fit at max steepness)        -> defer to AICc verdict
#   interior, CI machinery failed (NA)         -> not detected (fail-safe)
#   interior otherwise                         -> CI excludes zero
# AICc rule (final policy):
#   S2_upper pin                               -> not detected
#   otherwise                                  -> its own verdict (no override
#   of S2_lower: forcing pins to TRUE was shown to import pinned-null false
#   positives, 9-24% FPR rising with noise)

det <- d |> mutate(
  rule_ci_final = case_when(
    profile_boundary == "S2_upper" ~ FALSE,
    profile_boundary == "S2_lower" ~ classified_biphasic,
    is.na(S2_ci_excludes_zero)     ~ FALSE,
    .default = S2_ci_excludes_zero),
  rule_aicc_final = case_when(
    profile_boundary == "S2_upper" ~ FALSE,
    .default = classified_biphasic))

## ---- sensitivity ceilings (is 90% attainable at all?) -------------------

ceiling_final <- det |> filter(true_biphasic) |>
  summarise(p_ci = mean(rule_ci_final), p_aicc = mean(rule_aicc_final),
            .by = c(noise_sd, S2_real)) |>
  summarise(max_ci = max(p_ci), max_aicc = max(p_aicc), .by = noise_sd) |>
  arrange(noise_sd)
print(ceiling_final)

## ---- 90% detection thresholds via logistic (psychometric) fit -----------
# Thresholds are masked to NA where the empirical ceiling never reaches 0.9:
# there the logistic's forced asymptote at 1 manufactures a fictitious
# crossing, and the honest report is "not attained for |S2| <= 0.3".

inv90 <- function(m) unname((qlogis(0.9) - coef(m)[1]) / coef(m)[2])

thr_final <- det |> filter(true_biphasic, noise_sd > 0) |>
  group_by(noise_sd) |>
  group_modify(\(g, ...) tibble(
    S2_90_ci   = inv90(glm(rule_ci_final   ~ abs(S2_real), binomial, data = g)),
    S2_90_aicc = inv90(glm(rule_aicc_final ~ abs(S2_real), binomial, data = g)))) |>
  ungroup() |>
  left_join(ceiling_final, by = "noise_sd") |>
  mutate(S2_90_ci   = ifelse(max_ci   < 0.9, NA, S2_90_ci),
         S2_90_aicc = ifelse(max_aicc < 0.9, NA, S2_90_aicc))
print(thr_final)

## ---- false-positive rates (null-truth arm) ------------------------------

fpr_final <- det |> filter(!true_biphasic, noise_sd > 0) |>
  summarise(fpr_ci = mean(rule_ci_final), fpr_aicc = mean(rule_aicc_final),
            n = n(), .by = noise_sd) |>
  arrange(noise_sd)
print(fpr_final)

## ---- Q3: CI calibration (coverage) --------------------------------------
# Nominal 95% coverage expected for interior fits with ci_ok. The clinical
# question is whether S2 coverage holds while alpha coverage degrades with
# slow cone recovery (ridge entanglement of alpha with the cone tail).
# Compare this table across the four tau sets.

coverage <- d |>
  filter(profile_boundary == "interior", ci_ok, true_biphasic) |>
  summarise(
    n               = n(),
    S2_coverage     = mean(S2_ci_covers_real),
    alpha_coverage  = mean(alpha_ci_covers_real),
    S2_width_med    = median(S2_ci_width),
    alpha_width_med = median(alpha_ci_width),
    .by = noise_sd) |>
  arrange(noise_sd)
print(coverage)

## ---- detection surface figure -------------------------------------------

surf <- det |> filter(true_biphasic) |>
  summarise(ci = mean(rule_ci_final), aicc = mean(rule_aicc_final),
            n = n(), .by = c(S2_real, noise_sd))

p_surface <- surf |>
  pivot_longer(c(ci, aicc), names_to = "rule", values_to = "p_detect") |>
  ggplot(aes(abs(S2_real), p_detect,
             colour = factor(noise_sd), linetype = rule)) +
  geom_line() + geom_point(size = 1) +
  geom_hline(yintercept = 0.9, linetype = 3) +
  labs(x = "abs |S2| (log units / min)", y = "P(detect biphasic)",
       colour = "noise sd", linetype = "rule") +
  theme_minimal()
print(p_surface)
ggsave(file.path(res_dir, paste0("tau_", TAU, "_detection_surface.pdf")),
       p_surface, width = 7, height = 4.5)

## ---- ROC: is AICc at matched FPR equivalent to the CI rule? -------------
# delta_AICc > 0 is the published AICc rule; sweeping the threshold k in
# delta_AICc > k traces its ROC. The red point is the CI rule's operating
# point at that noise level. CI point above the curve = CI rule dominates;
# on the curve = same detector at different strictness.

roc_one <- function(dd) {
  ths <- quantile(dd$delta_AICc, seq(0, 1, 0.01), na.rm = TRUE)
  tibble(
    th  = ths,
    fpr = sapply(ths, \(k) mean(dd$delta_AICc[!dd$true_biphasic] > k, na.rm = TRUE)),
    tpr = sapply(ths, \(k) mean(dd$delta_AICc[dd$true_biphasic]  > k, na.rm = TRUE)))
}

roc_levels <- c(0.1, 0.15, 0.2, 0.3)
roc_df <- det |> filter(noise_sd %in% roc_levels) |>
  group_by(noise_sd) |> group_modify(\(g, ...) roc_one(g)) |> ungroup()

ci_points <- det |> filter(noise_sd %in% roc_levels) |>
  summarise(fpr = mean(rule_ci_final[!true_biphasic]),
            tpr = mean(rule_ci_final[true_biphasic]), .by = noise_sd)

p_roc <- ggplot(roc_df, aes(fpr, tpr)) +
  geom_line() +
  geom_point(data = ci_points, colour = "red", size = 3) +
  facet_wrap(~noise_sd, labeller = label_both) +
  coord_cartesian(xlim = c(0, 0.15)) +
  labs(x = "false-positive rate (null truth)",
       y = "sensitivity (biphasic truth)",
       caption = "curve: AICc threshold sweep; red point: CI rule") +
  theme_minimal()
print(p_roc)
ggsave(file.path(res_dir, paste0("tau_", TAU, "_roc_ci_vs_aicc.pdf")),
       p_roc, width = 8, height = 6)

## ---- one-glance result objects ------------------------------------------
# q1_summary     GD redundancy by noise level
# gd_status_tab  why GD stops (no_improving_step = stationarity evidence)
# nm_summary     NM refinement contribution over the raw grid
# nm_skips       refinement skip reasons
# stage_summary  NM vs GD contribution side by side
# ceiling_final  attainable sensitivity ceilings
# thr_final      90% detection thresholds, honestly masked
# fpr_final      false-positive rates under final policies
# coverage       CI calibration for S2 and alpha
# p_surface      detection surface (monograph central figure candidate)
# p_roc          rule dominance check

txtfile <- file.path(res_dir, paste0("tau_", TAU, "_tables.txt"))
sink(file = txtfile)
print(foi)
print("q1_summary")
print(q1_summary)
print("gd_convergence")
print(gd_convergence)
print("gd_status_tab")
print(gd_status_tab)
print("nm_summary")
print(nm_summary)
print("nm_skips")
print(nm_skips)
print("stage_summary")
print(stage_summary)
print("boundary_tab")
print(ftable(boundary_tab))
print("ceiling_final")
print(ceiling_final)
print("thr_final")
print(thr_final)
print("fpr_final")
print(fpr_final)
print("coverage")
print(coverage)
sink(file = NULL)
message("Tables written: ", txtfile)