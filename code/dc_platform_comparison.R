# dc_platform_compare.R  (JMFK)
# Cross-platform comparison of the dark criteria experiment: macOS (arm64,
# Accelerate/vecLib BLAS) against Titan (riscv64, reference BLAS), same
# commit, same pinned RNG version, same seeds.
#
# Titan runs were truncated at ~80% by an unplanned shutdown, so both
# frames are trimmed to the shorter file and one further row is dropped in
# case the final line was partially written.
#
# Produces:
#   summary_tbl  one row per tau set: agreement rates and disagreement counts
#   worst_rows   the single most divergent row from each set, for inspection

rm(list = ls())

library(dplyr)

## ---- paths ---------------------------------------------------------------

dir_titan <- "~/Dropbox/Mumac_/CODE_1/dark_criteria/results/Titan_rerun/"
dir_mac   <- "~/Dropbox/Mumac_/CODE_1/dark_criteria/results/Mac_dark_criteria_results/"

mac_f <- c(
    "dc_experiment_results_tau0.6_2026-08-20_113721_pid3341.csv",
    "dc_experiment_results_tau1.2_2026-08-20_113721_pid3342.csv",
    "dc_experiment_results_tau1.8_2026-08-20_113721_pid3343.csv",
    "dc_experiment_results_tau2.4_2026-08-20_113721_pid3344.csv"
)


titan_f <- c('dc_experiment_results_tau0.6_2026-08-21_073918_pid3933.csv',
'dc_experiment_results_tau1.2_2026-08-21_073918_pid3934.csv',
'dc_experiment_results_tau1.8_2026-08-21_184622_pid78402.csv',
'dc_experiment_results_tau2.4_2026-08-21_184622_pid78403.csv')

stopifnot(length(mac_f) == length(titan_f))

vars <- c("ct_profile", "cc_profile", "tau_profile", "S2_profile",
          "alpha_profile", "p5_profile_rss")

## ---- comparison for one pair --------------------------------------------

compare_pair <- function(f_mac, f_titan, verbose = TRUE) {

    tmpM <- read.csv(file.path(path.expand(dir_mac),   f_mac),   sep = ",")
    tmpT <- read.csv(file.path(path.expand(dir_titan), f_titan), sep = ",")

    # Trim to the shorter file, then drop one further row in case the last
    # line of the truncated file was partially written.
    n   <- min(nrow(tmpM), nrow(tmpT)) - 1L
    idx <- seq_len(n)
    mac   <- tmpM[idx, ]
    titan <- tmpT[idx, ]

    # Guards: same experiment, same simulated data, same code.
    stopifnot(
        identical(mac$experiment_index, titan$experiment_index),
        all(mac$seed == titan$seed),
        length(unique(c(mac$tau_real, titan$tau_real))) == 1L,
        all(mac$S2_real == titan$S2_real),
        all(mac$alpha_real == titan$alpha_real),
        all(mac$noise_sd == titan$noise_sd)
    )

    tau_set <- unique(mac$tau_real)

    # Identified fits only: exclude the tau lower bound, where the cone
    # exponential collapses and cc is unidentified (values to 1e13, agreeing
    # between platforms to 7 significant figures but absurd in absolute terms).
    ok <- titan$tau_profile > 0.0101 & mac$profile_boundary == "interior"

    dif <- sapply(vars, \(v) abs(mac[[v]] - titan[[v]]))

    d_rss   <- dif[, "p5_profile_rss"][ok]
    d_alpha <- dif[, "alpha_profile"][ok]

    out <- tibble(
        tau              = tau_set,
        n_rows           = n,
        n_identified     = sum(ok),
        n_excluded       = sum(!ok),
        frac_bit_ident   = mean(d_rss == 0),
        rss_q99          = unname(quantile(d_rss, 0.99)),
        rss_q999         = unname(quantile(d_rss, 0.999)),
        rss_max          = max(d_rss),
        alpha_gt_1e6     = sum(d_alpha > 1e-6),
        boundary_disagree = sum(mac$profile_boundary != titan$profile_boundary),
        nm_refined_disagree = sum(mac$nm_refined != titan$nm_refined, na.rm = TRUE),
        nm_conv_na_disagree = sum(is.na(mac$nm_converged) != is.na(titan$nm_converged))
    )

    # Maxima over identified fits, per parameter.
    maxima <- sapply(vars, \(v) max(dif[, v][ok], na.rm = TRUE))

    # The single most divergent row, for inspection.
    w <- which(ok)[which.max(d_alpha)]
    worst <- tibble(
        tau              = tau_set,
        noise_sd         = mac$noise_sd[w],
        S2_real          = mac$S2_real[w],
        alpha_real       = mac$alpha_real[w],
        tau_mac          = mac$tau_profile[w],
        tau_titan        = titan$tau_profile[w],
        alpha_mac        = mac$alpha_profile[w],
        alpha_titan      = titan$alpha_profile[w],
        S2_mac           = mac$S2_profile[w],
        S2_titan         = titan$S2_profile[w],
        rss_mac          = mac$p5_profile_rss[w],
        rss_titan        = titan$p5_profile_rss[w],
        nm_refined_mac   = mac$nm_refined[w],
        nm_refined_titan = titan$nm_refined[w]
    )

    if (verbose) {
        cat("\n--- tau =", tau_set, "-------------------------------------\n")
        cat("rows compared:", n, "  identified:", sum(ok),
            "  excluded (tau bound / boundary):", sum(!ok), "\n")
        cat("bit-identical RSS:", sprintf("%.4f", mean(d_rss == 0)), "\n")
        cat("max abs difference, identified fits:\n")
        print(signif(maxima, 4))
        cat("boundary class disagreements:", out$boundary_disagree,
            "   nm_refined disagreements:", out$nm_refined_disagree, "\n")
    }

    list(summary = out, maxima = maxima, worst = worst)
}

## ---- run over all four sets ---------------------------------------------

res <- Map(compare_pair, mac_f, titan_f)

summary_tbl <- bind_rows(lapply(res, `[[`, "summary"))
worst_rows  <- bind_rows(lapply(res, `[[`, "worst"))
maxima_tbl  <- as.data.frame(t(sapply(res, `[[`, "maxima")))
maxima_tbl$tau <- summary_tbl$tau

cat("\n\n===== SUMMARY ACROSS TAU SETS =====\n")
print(as.data.frame(summary_tbl))

cat("\n===== MAX ABS DIFFERENCE, IDENTIFIED FITS =====\n")
print(maxima_tbl)

cat("\n===== MOST DIVERGENT ROW PER SET =====\n")
print(as.data.frame(worst_rows))

## ---- optional: write the tables for the write-up ------------------------

out_dir <- path.expand(dir_mac)
 write.csv(summary_tbl, file.path(out_dir, "platform_comparison_summary.csv"),
           row.names = FALSE)
 write.csv(worst_rows,  file.path(out_dir, "platform_comparison_worst.csv"),
           row.names = FALSE)