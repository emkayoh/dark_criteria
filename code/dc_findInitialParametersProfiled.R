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

findInitialParametersProfiled <- function(
    time,
    threshold,
    tau_range = seq(0.01, max(time), length.out = 40L),
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

        # Treat very small positive or negative estimates as zero.
        if (abs(S2_est) <= S2_zero_tol) {
            S2_est <- 0
        }

        # Clamp the starting estimate rather than rejecting the candidate.
        S2_est <- min(
            max(S2_est, S2_bounds[1L]),
            S2_bounds[2L]
        )

        coefficients["S2"] <- S2_est

        fitted <- drop(design %*% coefficients)
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
                S2 = S2_est,
                alpha = alpha
            ),
            RSS = rss
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

    # When S2 is effectively zero, alpha is unidentified. Retain the grid
    # result rather than attempting continuous two-parameter refinement.
    if (
        isTRUE(refine) &&
        abs(best_grid$params["S2"]) <= S2_zero_tol
    ) {
        refinement_skipped <- TRUE
        refinement_reason <- "S2 effectively zero; alpha unidentified"
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
        grid_best = best_grid$params,
        grid_RSS = best_grid$RSS,
        refined = !is.null(optimisation) &&
            best$RSS < best_grid$RSS,
        refinement_skipped = refinement_skipped,
        refinement_reason = refinement_reason,
        converged = if (is.null(optimisation)) {
            NA
        } else {
            optimisation$convergence == 0L
        },
        optimisation = optimisation
    )
}


