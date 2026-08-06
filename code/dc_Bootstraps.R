bootstrapP5cParametric <- function(
    params,
    x,
    sigma,
    fit_function,
    B = 500L,
    seed = NULL
) {
    if (!is.null(seed)) {
        set.seed(seed)
    }

    y_hat <- P5c(params, x)

    estimates <- matrix(
        NA_real_,
        nrow = B,
        ncol = 5L,
        dimnames = list(
            NULL,
            c("ct", "cc", "tau", "S2", "alpha")
        )
    )

    converged <- logical(B)

    for (b in seq_len(B)) {
        y_boot <- y_hat + rnorm(
            length(x),
            mean = 0,
            sd = sigma
        )

        fit <- tryCatch(
            fit_function(x = x, y = y_boot),
            error = function(e) NULL
        )

        if (!is.null(fit) && all(is.finite(fit$params))) {
            estimates[b, ] <- fit$params
            converged[b] <- TRUE
        }
    }

    valid <- estimates[converged, , drop = FALSE]

    intervals <- t(apply(
        valid,
        2L,
        quantile,
        probs = c(0.025, 0.5, 0.975),
        na.rm = TRUE,
        names = FALSE
    ))

    colnames(intervals) <- c("lower", "median", "upper")

    list(
        estimates = estimates,
        intervals = intervals,
        converged = converged,
        convergence_rate = mean(converged)
    )
}



# # Pseudocode for bootstrapping px data 
# residuals_centred <- residuals - mean(residuals)

# y_boot <- fitted_values +
    # sample(
        # residuals_centred,
        # size = length(residuals_centred),
        # replace = TRUE
    # )