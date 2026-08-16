run_experiment <- function(
    job,
    experiment_index,
    x,
    ct_fixed,
    cc_fixed,
    tau_fixed,
    analysis_version,
    S2_limits = c(-0.5, 0),
    boundary_tol = 1e-8
) {

    # --------------------------------------------------
    # Simulation
    # --------------------------------------------------

    sim <- generateSimulationFromRow(
        job = job,
        time = x,
        ct = ct_fixed,
        cc = cc_fixed,
        tau = tau_fixed,
        analysis_version = analysis_version
    )

    meta <- sim$metadata

    x_sim <- sim$data$time
    y_sim <- sim$data$threshold_observed


    # --------------------------------------------------
    # P5c profile estimate
    # --------------------------------------------------

    p0 <- findInitialParametersProfiled(
        x_sim,
        y_sim
    )

    p_profile <- p0$best[
        c("ct", "cc", "tau", "S2", "alpha")
    ]

    p5_profile_rss <- sum(
        (y_sim - P5c(p_profile, x_sim))^2
    )


    # --------------------------------------------------
    # Is the S2 profile estimate on a boundary?
    # --------------------------------------------------

    if (
        abs(p_profile["S2"] - S2_limits[1]) <
        boundary_tol
    ) {

        profile_boundary <- "S2_lower"

    } else if (
        abs(p_profile["S2"] - S2_limits[2]) <
        boundary_tol
    ) {

        profile_boundary <- "S2_upper"

    } else {

        profile_boundary <- "interior"
    }


    # --------------------------------------------------
    # Optional GD refinement
    #
    # GD is now diagnostic only.
    # Do not refine S2 boundary solutions.
    # --------------------------------------------------

    gdr_attempted <- profile_boundary == "interior"

    if (gdr_attempted) {

        gd_fit <- tryCatch({

            ip0hO <- findParametersGDPlain(
                p_profile,
                P5c,
                x_sim,
                y_sim,
                TRUE
            )

            findParametersGDPlain(
                ip0hO$params,
                P5c,
                x_sim,
                y_sim,
                FALSE
            )

        }, error = function(e) {

            message(
                "GD failed for experiment ",
                experiment_index,
                ": ",
                conditionMessage(e)
            )

            list(
                params = matrix(
                    NA_real_,
                    nrow = 1,
                    ncol = 5
                ),
                runs = NA_integer_,
                noise = NA_real_,
                MSE = NA_real_,
                converged = FALSE,
                status = "error"
            )
        })

    } else {

        gd_fit <- list(
            params = matrix(
                NA_real_,
                nrow = 1,
                ncol = 5
            ),
            runs = 0L,
            noise = NA_real_,
            MSE = NA_real_,
            converged = NA,
            status = "skipped_profile_boundary"
        )
    }


    # --------------------------------------------------
    # Quantify GD improvement
    # --------------------------------------------------

    if (
        gdr_attempted &&
        all(is.finite(gd_fit$params))
    ) {

        p5_gdr_rss <- sum(
            (
                y_sim -
                P5c(gd_fit$params, x_sim)
            )^2
        )

        rss_improvement <-
            p5_profile_rss - p5_gdr_rss

        rss_improvement_fraction <-
            rss_improvement / p5_profile_rss

    } else {

        p5_gdr_rss <- NA_real_
        rss_improvement <- NA_real_
        rss_improvement_fraction <- NA_real_
    }


    # --------------------------------------------------
    # Inference on the PROFILE estimate
    # --------------------------------------------------

    jacobian_ok <- TRUE

    J <- tryCatch(
        P5cJacobianDiagnostics(
            p_profile,
            x_sim
        ),

        error = function(e) {

            jacobian_ok <<- FALSE

            message(
                "Jacobian failed for experiment ",
                experiment_index,
                ": ",
                conditionMessage(e)
            )

            list(
                singular_values_scaled = NA_real_,
                condition_J_scaled = NA_real_,
                zero_columns = NA
            )
        }
    )


   ci_result <- tryCatch({
        ci <- P5cConfidenceIntervals(
            params = p_profile,
            x = x_sim,
            y = y_sim
        )

        list(
            ci = ci,
            ok = TRUE
        )
    },
	error = function(e) {

        message(
            "CI calculation failed for experiment ",
            experiment_index,
            ": ",
            conditionMessage(e)
        )

        list(
            ci = data.frame(
                param = c(
                    "ct",
                    "cc",
                    "tau",
                    "S2",
                    "alpha"
                ),
                estimate = drop(p_profile),
                se = NA_real_,
                lower = NA_real_,
                upper = NA_real_,
                covers_zero = NA
            ),
            ok = FALSE
        )
    }
)

	ci0 <- ci_result$ci
	ci_ok <- ci_result$ok &&
    all(is.finite(ci0$se)) &&
    all(is.finite(ci0$lower)) &&
    all(is.finite(ci0$upper))

    # --------------------------------------------------
    # P3
    # --------------------------------------------------

    p3_result <- fitP3(
        x_sim,
        y_sim
    )

    p3_p <- drop(
        p3_result$params
    )

    p3_rss <- sum(
        (
            y_sim -
            P3(p3_result$params, x_sim)
        )^2
    )


    # --------------------------------------------------
    # Model comparison
    #
    # P5 AICc is now based on the PROFILE estimate
    # --------------------------------------------------

    aic_p3 <- calculateAICc(
        rss = p3_rss,
        n = length(x_sim),
        n_params = 3L
    )

    aic_p5 <- calculateAICc(
        rss = p5_profile_rss,
        n = length(x_sim),
        n_params = 5L
    )


    # --------------------------------------------------
    # Result
    # --------------------------------------------------

    make_result_row(
        experiment_index = experiment_index,
        meta = meta,
        p0 = p0,
        op0hO = gd_fit,
        J = J,
        ci0 = ci0,
        p3_result = p3_result,
        p3_p = p3_p,
        aic_p3 = aic_p3,
        aic_p5 = aic_p5,

        profile_boundary = profile_boundary,
        gdr_attempted = gdr_attempted,

        p5_profile_rss = p5_profile_rss,
        p5_gdr_rss = p5_gdr_rss,
        rss_improvement = rss_improvement,
        rss_improvement_fraction =
            rss_improvement_fraction,

        jacobian_ok = jacobian_ok,
        ci_ok = ci_ok
    )
}