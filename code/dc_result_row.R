# make_result_row.R  (JMFK)
# Builds one results row per replication for the dark criteria experiment.
#
# Changes in this revision (2026-08-18), paired with the corrected
# findInitialParametersProfiled:
#   1. NM refinement contribution carried through: grid-stage RSS and
#      parameters, refined flag, nm_rss_improvement(_frac), nm_tau_shift,
#      nm_alpha_shift, nm_converged, refinement_skipped and its reason.
#   2. profile_boundary now taken from p0$S2_boundary (authoritative,
#      computed inside the fit) with grid_S2_boundary alongside, rather
#      than being inferred downstream. The profile_boundary argument is
#      retained for compatibility but p0 wins; a mismatch is flagged.
#   3. experiment_index bug fixed: the function previously ignored its
#      experiment_index argument and captured `ii` from the calling
#      environment; it now uses the argument.

make_result_row <- function(
    experiment_index,
    meta,
    p0,
    op0hO,
    J,
    ci0,
    p3_result,
    p3_p,
    aic_p3,
    aic_p5,
    profile_boundary,
    gdr_attempted,
    p5_profile_rss,
    p5_gdr_rss,
    rss_improvement,
    rss_improvement_fraction,
    jacobian_ok,
    ci_ok
) {

    # Extract components used repeatedly
    p_gdr <- unname(drop(op0hO$params))

    ci_S2    <- ci0[ci0$param == "S2", ]
    ci_alpha <- ci0[ci0$param == "alpha", ]

    true_biphasic       <- meta$S2_real != 0
    classified_biphasic <- aic_p5 < aic_p3

    # Authoritative boundary status from the fit itself; keep the passed
    # argument only as a cross-check.
    boundary_from_fit <- if (!is.null(p0$S2_boundary)) {
        p0$S2_boundary
    } else {
        profile_boundary
    }

    boundary_mismatch <-
        !is.null(p0$S2_boundary) &&
        !identical(as.character(p0$S2_boundary),
                   as.character(profile_boundary))

    data.frame(

        # --------------------------------------------------
        # Experimental conditions
        # --------------------------------------------------
        experiment_index = experiment_index,
        simulation_id = as.character(meta$simulation_id),
        seed           = meta$seed,
        git_commit = as.character(meta$analysis_version),

        ct_real    = meta$ct_real,
        cc_real    = meta$cc_real,
        tau_real   = meta$tau_real,
        S2_real    = meta$S2_real,
        alpha_real = meta$alpha_real,

        noise_sd       = meta$noise_sd,
        n_observations = meta$n_observations,


        # --------------------------------------------------
        # Profile results (post-refinement, as deployed)
        # --------------------------------------------------
        ct_profile    = unname(p0$best["ct"]),
        cc_profile    = unname(p0$best["cc"]),
        tau_profile   = unname(p0$best["tau"]),
        S2_profile    = unname(p0$best["S2"]),
        alpha_profile = unname(p0$best["alpha"]),

        S2_error_profile =
            unname(p0$best["S2"]) - meta$S2_real,

        alpha_error_profile =
            unname(p0$best["alpha"]) - meta$alpha_real,

        # Profile diagnostics
        profile_boundary = boundary_from_fit,
        profile_boundary_mismatch = boundary_mismatch,
        p5_profile_rss = p5_profile_rss,

        # --------------------------------------------------
        # Grid stage (pre-refinement) and NM contribution
        # --------------------------------------------------
        tau_grid    = unname(p0$grid_best["tau"]),
        alpha_grid  = unname(p0$grid_best["alpha"]),
        S2_grid     = unname(p0$grid_best["S2"]),
        grid_rss    = p0$grid_RSS,
        grid_S2_boundary = p0$grid_S2_boundary,

        nm_refined  = p0$refined,
        nm_skipped  = p0$refinement_skipped,
        nm_skip_reason = if (is.na(p0$refinement_reason)) {
            NA_character_
        } else {
            as.character(p0$refinement_reason)
        },
        nm_converged = p0$converged,

        nm_rss_improvement      = p0$nm_rss_improvement,
        nm_rss_improvement_frac = p0$nm_rss_improvement_frac,
        nm_tau_shift            = p0$nm_tau_shift,
        nm_alpha_shift          = p0$nm_alpha_shift,

        # --------------------------------------------------
        # OLS gradient-descent results
        # --------------------------------------------------
        ct_est_gdr    = p_gdr[1],
        cc_est_gdr    = p_gdr[2],
        tau_est_gdr   = p_gdr[3],
        S2_est_gdr    = p_gdr[4],
        alpha_est_gdr = p_gdr[5],

        S2_error_gdr =
            p_gdr[4] - meta$S2_real,

        alpha_error_gdr =
            p_gdr[5] - meta$alpha_real,

        mse_gdr   = as.numeric(op0hO$MSE),
        runs_gdr  = op0hO$runs,
        noise_gdr = op0hO$noise,

        # GD refinement
        gdr_attempted = gdr_attempted,
        gdr_converged = op0hO$converged,
        gdr_status = op0hO$status,

        p5_gdr_rss = p5_gdr_rss,

        rss_improvement = rss_improvement,

        rss_improvement_fraction =
            rss_improvement_fraction,

        # --------------------------------------------------
        # Jacobian / identifiability
        # --------------------------------------------------
        jacobian_ok = jacobian_ok,
        jac_min_sv_scaled =
            min(J$singular_values_scaled),

        jac_condition_scaled =
            J$condition_J_scaled,

        jac_any_zero_columns =
            any(J$zero_columns),

        # --------------------------------------------------
        # S2 inference
        # --------------------------------------------------
        ci_ok = ci_ok,
        S2_se       = ci_S2$se,
        S2_ci_lower = ci_S2$lower,
        S2_ci_upper = ci_S2$upper,

        S2_ci_width =
            ci_S2$upper - ci_S2$lower,

        S2_ci_covers_real =
            ci_S2$lower <= meta$S2_real &&
            ci_S2$upper >= meta$S2_real,

        S2_ci_excludes_zero =
            ci_S2$upper < 0 ||
            ci_S2$lower > 0,

        # --------------------------------------------------
        # Alpha inference
        # --------------------------------------------------
        alpha_se       = ci_alpha$se,
        alpha_ci_lower = ci_alpha$lower,
        alpha_ci_upper = ci_alpha$upper,

        alpha_ci_width =
            ci_alpha$upper - ci_alpha$lower,

        alpha_ci_covers_real =
            ci_alpha$lower <= meta$alpha_real &&
            ci_alpha$upper >= meta$alpha_real,

        alpha_ci_excludes_zero =
            ci_alpha$upper < 0 ||
            ci_alpha$lower > 0,

        # --------------------------------------------------
        # P3 model
        # --------------------------------------------------
        p3_RSS = p3_result$rss,

        p3_ct  = p3_p[1],
        p3_cc  = p3_p[2],
        p3_tau = p3_p[3],

        # --------------------------------------------------
        # Model comparison
        # --------------------------------------------------
        p3_AICc = aic_p3,
        p5_AICc = aic_p5,

        delta_AICc =
            aic_p3 - aic_p5,

        selected_model =
            if (aic_p3 < aic_p5) "P3" else "P5c",

        # --------------------------------------------------
        # Classification
        # --------------------------------------------------
        true_biphasic =
            true_biphasic,

        classified_biphasic =
            classified_biphasic,

        classification_correct =
            true_biphasic == classified_biphasic
    )
}