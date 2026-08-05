# result row

result_row <- data.frame(
    simulation_id = simulation_id,
    seed = seed,
    replicate = replicate,

    ct_real = ct_real,
    cc_real = cc_real,
    tau_real = tau_real,
    S2_real = S2_real,
    alpha_real = alpha_real,
    noise_sd = noise_sd,
    n_observations = length(x),

    ct_est = p5$params["ct"],
    cc_est = p5$params["cc"],
    tau_est = p5$params["tau"],
    S2_est = p5$params["S2"],
    alpha_est = p5$params["alpha"],

    S2_error = p5$params["S2"] - S2_real,
    alpha_error = p5$params["alpha"] - alpha_real,

    p5_converged = p5$converged,
    p5_RSS = p5$RSS,
    p5_MSE = p5$MSE,
    p5_huber_loss = p5$loss,

    S2_se = param_ci["S2", "SE"],
    S2_ci_lower = param_ci["S2", "lower"],
    S2_ci_upper = param_ci["S2", "upper"],
    S2_ci_width =
        param_ci["S2", "upper"] -
        param_ci["S2", "lower"],
    S2_ci_covers_real =
        param_ci["S2", "lower"] <= S2_real &&
        param_ci["S2", "upper"] >= S2_real,
    S2_ci_excludes_zero =
        param_ci["S2", "upper"] < 0 ||
        param_ci["S2", "lower"] > 0,

    alpha_se = param_ci["alpha", "SE"],
    alpha_ci_lower = param_ci["alpha", "lower"],
    alpha_ci_upper = param_ci["alpha", "upper"],

    hessian_valid = hessian_valid,
    hessian_positive_definite = hessian_positive_definite,

    p3_converged = p3_result$converged,
    p3_RSS = p3_result$RSS,

    p3_AICc = p3_AICc,
    p5_AICc = p5_AICc,
    delta_AICc = p3_AICc - p5_AICc,

    selected_model = if (
        p3_AICc < p5_AICc
    ) {
        "P3"
    } else {
        "P5c"
    },

    true_biphasic = S2_real != 0,
    classified_biphasic = p5_AICc < p3_AICc,
    classification_correct =
        (S2_real != 0) == (p5_AICc < p3_AICc),

    elapsed_seconds = elapsed_seconds,
    error_stage = NA_character_,
    error_message = NA_character_,

    check.names = FALSE
)