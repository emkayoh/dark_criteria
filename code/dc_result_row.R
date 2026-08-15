make_result_row <- function(
	ii,
    meta,
    p0,
    op0hO,
    J,
    ci0,
    p3_result,
    p3_p,
    aic_p3,
    aic_p5
) {

    # Extract components used repeatedly
    p_ols <- drop(op0hO$params)

    ci_S2    <- ci0[ci0$param == "S2", ]
    ci_alpha <- ci0[ci0$param == "alpha", ]

    true_biphasic       <- meta$S2_real != 0
    classified_biphasic <- aic_p5 < aic_p3

    data.frame(

        # --------------------------------------------------
        # Experimental conditions
        # --------------------------------------------------
        experiment_index = ii,
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
        # Profile results
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

        # --------------------------------------------------
        # OLS gradient-descent results
        # --------------------------------------------------
        ct_est_ols    = p_ols[1],
        cc_est_ols    = p_ols[2],
        tau_est_ols   = p_ols[3],
        S2_est_ols    = p_ols[4],
        alpha_est_ols = p_ols[5],

        S2_error_ols =
            p_ols[4] - meta$S2_real,

        alpha_error_ols =
            p_ols[5] - meta$alpha_real,

        mse_ols   = as.numeric(op0hO$MSE),
        runs_ols  = op0hO$runs,
        noise_ols = op0hO$noise,

        # --------------------------------------------------
        # Jacobian / identifiability
        # --------------------------------------------------
        jac_min_sv_scaled =
            min(J$singular_values_scaled),

        jac_condition_scaled =
            J$condition_J_scaled,

        jac_any_zero_columns =
            any(J$zero_columns),

        # --------------------------------------------------
        # S2 inference
        # --------------------------------------------------
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
