
startP3 <- function(x, y) {

    n <- length(y)
    n_tail <- max(3L, ceiling(0.1 * n))
    n_head <- max(3L, ceiling(0.05 * n))

    ct_start <- median(tail(y, n_tail))
    y0_start <- median(head(y, n_head))
    cc_start <- y0_start - ct_start

    tau_start <- max(diff(range(x)) / 5, 0.1)

    c(
        ct = ct_start,
        cc = cc_start,
        tau = tau_start
    )
}


data <- data.frame(x = x, y = y)

p3_start <- startP3(x, y)

startP3Grid <- function(
    x,
    y,
    tau_values = 10^seq(
        log10(0.01),
        log10(max(2, max(x))),
        length.out = 50L
    )
) {
    if (
        !is.numeric(x) ||
        !is.numeric(y) ||
        length(x) != length(y) ||
        length(x) < 4L
    ) {
        stop("x and y must be numeric vectors of equal length.")
    }

    valid <- is.finite(x) & is.finite(y)
    x <- x[valid]
    y <- y[valid]

    best_rss <- Inf
    best_start <- NULL

    for (tau in tau_values) {
        exponential <- exp(-x / tau)

        design <- cbind(
            ct = 1,
            cc = exponential
        )

        qr_design <- qr(design)

        if (qr_design$rank < 2L) {
            next
        }

        coefficients <- qr.coef(qr_design, y)
        fitted <- drop(design %*% coefficients)
        rss <- sum((y - fitted)^2)

        if (is.finite(rss) && rss < best_rss) {
            best_rss <- rss
            best_start <- c(
                ct = coefficients["ct"],
                cc = coefficients["cc"],
                tau = tau
            )
        }
    }

    if (is.null(best_start)) {
        stop("Unable to obtain valid P3 starting values.")
    }

    unname_structure <- unname(best_start)
    names(unname_structure) <- c("ct", "cc", "tau")
    unname_structure
}

#' Fit the three-parameter exponential dark-adaptation model
#'
#' Fits
#'
#'   y = ct + cc * exp(-x / tau)
#'
#' using bounded nonlinear least squares. Residuals and RSS are recalculated
#' explicitly from the fitted coefficients rather than relying solely on the
#' residuals method for the nls object.
#'
#' @param x Numeric vector of observation times.
#' @param y Numeric vector of observed thresholds.
#'
#' @return A list containing fitted parameters, predictions, residuals,
#'   residual statistics and convergence information.
fitP3 <- function(x, y) {
    valid <- is.finite(x) & is.finite(y)
    x_fit <- x[valid]
    y_fit <- y[valid]

    if (length(x_fit) < 4L) {
        stop("At least four finite observations are required.")
    }

    start <- startP3(
        x = x_fit,
        y = y_fit
    )

    required_names <- c("ct", "cc", "tau")

    if (
        !is.numeric(start) ||
        !all(required_names %in% names(start)) ||
        any(!is.finite(start[required_names]))
    ) {
        stop(
            "startP3() must return finite named values for ct, cc and tau."
        )
    }

    fit <- tryCatch(
        nls(
            y_fit ~ ct + cc * exp(-x_fit / tau),
            start = as.list(start[required_names]),
            algorithm = "port",
            lower = c(
                ct = -Inf,
                cc = -Inf,
                tau = 0.001
            ),
            control = nls.control(
                maxiter = 500L,
                tol = 1e-8,
                minFactor = 1 / 4096,
                warnOnly = TRUE
            )
        ),
        error = function(e) e
    )

    if (inherits(fit, "error")) {
        return(list(
            model = "P3",
            converged = FALSE,
            error = conditionMessage(fit),
            start = start
        ))
    }

    params <- coef(fit)[required_names]

    # Recalculate predictions directly from the fitted parameters.
    fitted_values <- (
        params["ct"] +
        params["cc"] * exp(-x_fit / params["tau"])
    )

    residual_values <- y_fit - fitted_values

    rss <- sum(residual_values * residual_values)
    n <- length(y_fit)
    p <- length(params)
    residual_df <- n - p

    # Independent checks against the nls object.
    nls_residuals <- stats::residuals(fit)
    nls_rss <- sum(nls_residuals * nls_residuals)
    nls_deviance <- stats::deviance(fit)

    rss_consistent <- (
        isTRUE(all.equal(rss, nls_rss, tolerance = 1e-10)) &&
        isTRUE(all.equal(rss, nls_deviance, tolerance = 1e-10))
    )

    convergence <- fit$convInfo

    list(
        model = "P3",
        params = params,
        start = start,
        fitted = fitted_values,
        residuals = residual_values,
        RSS = rss,
        MSE = if (residual_df > 0L) {
            rss / residual_df
        } else {
            NA_real_
        },
        noise = stats::sd(residual_values),
        residual_df = residual_df,
        converged = isTRUE(convergence$isConv),
        convergence = convergence,
        RSS_nls = nls_rss,
        deviance_nls = nls_deviance,
        RSS_consistent = rss_consistent,
        x = x_fit,
        y = y_fit,
        fit = fit
    )
}

p3_result <- fitP3(x, y0)

p3_result$params
p3_result$RSS
p3_result$converged


calculateAIC <- function(rss, n, n_params) {
    if (!is.finite(rss) || rss <= 0) {
        stop("rss must be positive and finite.")
    }

    if (n <= n_params) {
        stop("n must exceed the number of fitted parameters.")
    }

    k <- n_params + 1L  # model parameters plus residual variance

    minus_2_loglik <- n * (
        log(2 * pi) +
        1 +
        log(rss / n)
    )

    minus_2_loglik + 2 * k
}

calculateAICc <- function(rss, n, n_params) {
    k <- n_params + 1L

    if (n <= k + 1L) {
        return(Inf)
    }

    aic <- calculateAIC(
        rss = rss,
        n = n,
        n_params = n_params
    )

    aic + (2 * k * (k + 1)) / (n - k - 1)
}


