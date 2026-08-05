test_df <- readRDS("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_test_df")
x <- test_df$time
y <- test_df$thrs



P3 <- function(a, x) {
    a[1] + a[2] * exp(-x / a[3])
}
y0 <- P3(c(-2, 2, 1), x) + rnorm(length(x), 0, 0.1)
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


#' Fit the three-parameter exponential model
#'
#' Fits:
#'
#'   y = ct + cc * exp(-x / tau)
#'
#' using grid-derived starting values followed by bounded nonlinear
#' least-squares optimisation.
#'
#' @param x Numeric vector of measurement times.
#' @param y Numeric vector of observed sensitivities.
#' @param tau_values Positive candidate tau values used to derive starting
#'   values.
#'
#' @return A list containing the fitted parameters, residual diagnostics,
#'   convergence information and the underlying nls object.
fitP3 <- function(
    x,
    y,
    tau_values = 10^seq(
        log10(0.01),
        log10(max(2, max(x, na.rm = TRUE))),
        length.out = 50L
    )
) {
    valid <- is.finite(x) & is.finite(y)
    x <- x[valid]
    y <- y[valid]

    if (length(x) < 4L) {
        stop("At least four finite observations are required.")
    }

    start <- startP3(
        x = x,
        y = y
        )

    fit <- tryCatch(
        nls(
            y ~ ct + cc * exp(-x / tau),
            data = data.frame(x = x, y = y),
            start = as.list(start),
            algorithm = "port",
            lower = c(
                ct = -Inf,
                cc = -Inf,
                tau = 0.001
            ),
            control = nls.control(
                maxiter = 500,
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

    residuals <- residuals(fit)
    rss <- sum(residuals^2)
    n <- length(y)
    p <- 3L

    convergence <- fit$convInfo

    list(
        model = "P3",
        params = coef(fit)[c("ct", "cc", "tau")],
        start = start,
        fitted = fitted(fit),
        residuals = residuals,
        RSS = rss,
        MSE = rss / (n - p),
        noise = sd(residuals),
        converged = isTRUE(convergence$isConv),
        convergence = convergence,
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


