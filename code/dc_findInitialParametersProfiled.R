#' Find initial P5c parameters using profiled least squares
#'
#' Searches over tau and alpha while solving ct, cc and S2 exactly by
#' linear least squares at each candidate point. The best grid point is
#' optionally refined by bounded two-parameter optimisation.
#'
#' @param time Numeric vector of observation times.
#' @param threshold Numeric vector of observed thresholds.
#' @param tau_range Numeric vector of candidate tau values.
#' @param alpha_range Numeric vector of candidate alpha values.
#' @param refine Logical; refine the best grid result using optim().
#' @param tau_bounds Lower and upper bounds for tau during refinement.
#' @param alpha_bounds Lower and upper bounds for alpha during refinement.
#' @param S2_bounds Optional lower and upper bounds for S2. Candidate fits
#'   outside these bounds are rejected.
#'
#' @return A list containing the best parameter vector, RSS, MSE, the initial
#'   grid result, and optimisation diagnostics.
# dc_findInitialParametersProfiled.R  (JMFK)
# Profiled (variable projection) initial parameter search for the P5c model.
#
# Changes in this revision (2026-08-18):
#   1. BOUNDARY FIX. When the unconstrained S2 estimate falls outside
#      S2_bounds (or within S2_zero_tol of zero), the linear parameters are
#      now RE-SOLVED with S2 fixed at the bound, rather than clamping S2 and
#      retaining ct and cc from the unconstrained fit. For a single active
#      bound on a linear coefficient this refit is the exact constrained
#      least-squares solution, so boundary candidates now carry their true
#      RSS and compete fairly with interior cells.
#   2. NM CONTRIBUTION. The return value now reports the refinement stage's
#      contribution explicitly (nm_rss_improvement, nm_rss_improvement_frac,
#      nm_tau_shift, nm_alpha_shift) so the experiment parser can carry it
#      into the results columns.
#   3. S2_boundary status ("interior", "S2_lower", "S2_upper") is returned
#      directly rather than being inferred downstream from the S2 value.

findInitialParametersProfiled <- function(
    time,
    threshold,
    tau_range = seq(0.01, max(log(time)), length.out = 40L),
    alpha_range = seq(0.5, max(time), length.out = 80L),
    refine = TRUE,
    tau_bounds = range(tau_range),
    alpha_bounds = range(alpha_range),
    S2_bounds = c(-0.5, 0),
    S2_zero_tol = 1e-6
) {
    if (
        !is.numeric(time) ||
        !is.numeric(threshold) ||
        length(time) != length(threshold) ||
        length(time) < 5L
    ) {
        stop("time and threshold must be numeric vectors of equal length.")
    }

    if (
        any(!is.finite(time)) ||
        any(!is.finite(threshold))
    ) {
        stop("time and threshold must contain finite values.")
    }

    if (
        any(!is.finite(tau_range)) ||
        any(tau_range <= 0)
    ) {
        stop("tau_range must contain positive finite values.")
    }

    if (any(!is.finite(alpha_range))) {
        stop("alpha_range must contain finite values.")
    }

    fit_linear_parameters <- function(tau, alpha) {
        if (
            !is.finite(tau) ||
            !is.finite(alpha) ||
            tau <= 0
        ) {
            return(NULL)
        }

        exponential <- exp(-time / tau)
        rod_term <- (time - alpha) * as.numeric(time >= alpha)

        design <- cbind(
            ct = 1,
            cc = exponential,
            S2 = rod_term
        )

        qr_fit <- qr(design)

        if (qr_fit$rank < 3L) {
            return(NULL)
        }

        coefficients <- qr.coef(qr_fit, threshold)

        if (any(!is.finite(coefficients))) {
            return(NULL)
        }

        S2_est <- unname(coefficients["S2"])
        S2_boundary <- "interior"
        S2_fixed <- NA_real_

        # Decide whether a bound is active.
        if (abs(S2_est) <= S2_zero_tol || S2_est > S2_bounds[2L]) {
            S2_fixed <- S2_bounds[2L]        # upper bound (zero)
            S2_boundary <- "S2_upper"
        } else if (S2_est < S2_bounds[1L]) {
            S2_fixed <- S2_bounds[1L]        # lower bound (max steepness)
            S2_boundary <- "S2_lower"
        }

        if (is.na(S2_fixed)) {
            # Interior: unconstrained solution stands.
            fitted <- drop(design %*% coefficients)
        } else {
            # Active bound: re-solve ct and cc exactly, with S2 fixed.
            # Move the (now known) rod contribution to the offset.
            offset <- S2_fixed * rod_term
            design2 <- design[, c("ct", "cc"), drop = FALSE]

            qr_fit2 <- qr(design2)

            if (qr_fit2$rank < 2L) {
                return(NULL)
            }

            coef2 <- qr.coef(qr_fit2, threshold - offset)

            if (any(!is.finite(coef2))) {
                return(NULL)
            }

            coefficients <- c(coef2, S2 = S2_fixed)
            fitted <- drop(design2 %*% coef2) + offset
        }

        residuals <- threshold - fitted
        rss <- sum(residuals * residuals)

        if (!is.finite(rss)) {
            return(NULL)
        }

        list(
            params = c(
                ct = unname(coefficients["ct"]),
                cc = unname(coefficients["cc"]),
                tau = tau,
                S2 = unname(coefficients["S2"]),
                alpha = alpha
            ),
            RSS = rss,
            S2_boundary = S2_boundary
        )
    }

    best_grid <- NULL
    best_grid_rss <- Inf

    for (tau in tau_range) {
        for (alpha in alpha_range) {
            candidate <- fit_linear_parameters(
                tau = tau,
                alpha = alpha
            )

            if (
                !is.null(candidate) &&
                candidate$RSS < best_grid_rss
            ) {
                best_grid <- candidate
                best_grid_rss <- candidate$RSS
            }
        }
    }

    if (is.null(best_grid)) {
        stop("No valid P5c starting parameters were found.")
    }

    best <- best_grid
    optimisation <- NULL
    refinement_skipped <- FALSE
    refinement_reason <- NA_character_

    # When S2 sits on the zero bound, alpha is unidentified. Retain the grid
    # result rather than attempting continuous two-parameter refinement.
    if (
        isTRUE(refine) &&
        best_grid$S2_boundary == "S2_upper"
    ) {
        refinement_skipped <- TRUE
        refinement_reason <- "S2 on zero bound; alpha unidentified"
    } else if (isTRUE(refine)) {
        profile_objective <- function(z) {
            tau <- exp(z[1L])
            alpha <- z[2L]

            candidate <- fit_linear_parameters(
                tau = tau,
                alpha = alpha
            )

            if (is.null(candidate)) {
                return(1e100)
            }

            candidate$RSS
        }

        optimisation <- tryCatch(
            optim(
                par = c(
                    log(best_grid$params["tau"]),
                    best_grid$params["alpha"]
                ),
                fn = profile_objective,
                method = "Nelder-Mead",
                control = list(
                    maxit = 500L,
                    reltol = 1e-10
                )
            ),
            error = function(e) e
        )

        if (inherits(optimisation, "error")) {
            refinement_skipped <- TRUE
            refinement_reason <- conditionMessage(optimisation)
            optimisation <- NULL
        } else {
            tau_refined <- exp(optimisation$par[1L])
            alpha_refined <- optimisation$par[2L]

            # Enforce the permitted ranges after unconstrained Nelder-Mead.
            tau_refined <- min(
                max(tau_refined, tau_bounds[1L]),
                tau_bounds[2L]
            )

            alpha_refined <- min(
                max(alpha_refined, alpha_bounds[1L]),
                alpha_bounds[2L]
            )

            refined <- fit_linear_parameters(
                tau = tau_refined,
                alpha = alpha_refined
            )

            if (
                !is.null(refined) &&
                refined$RSS < best_grid$RSS
            ) {
                best <- refined
            }
        }
    }

    n <- length(threshold)

    list(
        best = best$params,
        performance = best$RSS / n,
        RSS = best$RSS,
        S2_boundary = best$S2_boundary,
        grid_best = best_grid$params,
        grid_RSS = best_grid$RSS,
        grid_S2_boundary = best_grid$S2_boundary,
        refined = !is.null(optimisation) &&
            best$RSS < best_grid$RSS,
        refinement_skipped = refinement_skipped,
        refinement_reason = refinement_reason,
        nm_rss_improvement = best_grid$RSS - best$RSS,
        nm_rss_improvement_frac = if (best_grid$RSS > 0) {
            (best_grid$RSS - best$RSS) / best_grid$RSS
        } else {
            0
        },
        nm_tau_shift = unname(best$params["tau"] - best_grid$params["tau"]),
        nm_alpha_shift = unname(best$params["alpha"] - best_grid$params["alpha"]),
        converged = if (is.null(optimisation)) {
            NA
        } else {
            optimisation$convergence == 0L
        },
        converged_nm = if (is.null(optimisation)) {
            NA
        } else {
            optimisation$convergence == 0L
        },
        optimisation = optimisation
    )
}