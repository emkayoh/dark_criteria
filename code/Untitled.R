fit_linear_parameters <- function(tau, alpha, x, y) {
	    time <- x,
    threshold <- y,
    tau_range = seq(0.01, max(log(time)), length.out = 40L),
    alpha_range = seq(0.5, max(time), length.out = 80L),
    refine = TRUE,
    tau_bounds = range(tau_range),
    alpha_bounds = range(alpha_range),
    S2_bounds = c(-0.5, 0),
    S2_zero_tol = 1e-6
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

fit_linear_parameters(1, 4)
