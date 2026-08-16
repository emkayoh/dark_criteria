#' Fit a three-parameter exponential (P3) by separable least squares
#'
#' Fits `y = a1 + a2 * exp(-x / a3)` by profiling the single nonlinear
#' parameter. For any fixed `a3` the model is linear in `a1` and `a2`,
#' so those are solved exactly by QR at each candidate. The profile
#' residual sum of squares is evaluated on a log-spaced grid of `a3`,
#' then refined by `optimize` on the bracket around the grid minimum.
#'
#' No start values are required and the result is deterministic, which
#' makes this safe to run unattended over many replicates where `nls`
#' would need starts and could fail on noisy records.
#'
#' @param x Numeric vector of times. Must be finite, and `range(x)` must
#'   be non-degenerate.
#' @param y Numeric vector of observed values, same length as `x`.
#'
#' @return A list with components:
#'   \describe{
#'     \item{params}{Numeric vector `c(a1, a2, a3)`: intercept,
#'       amplitude, and time constant, in the argument order used by
#'       `P3`.}
#'     \item{rss}{Residual sum of squares at the fitted parameters.}
#'   }
#'
#' @details The grid spans `diff(range(x))/1000` to `diff(range(x))*10`.
#'   A fitted `a3` at either end means the profile has no interior
#'   minimum, so the fit has degenerated towards a step or a straight
#'   line. Worth checking if the data are noisy.
#'
#' @examples
#' fit <- fitP3(sim$data$time, sim$data$threshold_observed)
#' fit$params
#'
#' @export


fitP3 <- function(x, y) {

    f <- function(tau) {
        X <- cbind(1, exp(-x / tau))
        sum(qr.resid(qr(X), y)^2)
    }

    g <- exp(
        seq(
            log(diff(range(x)) / 1000),
            log(diff(range(x)) * 10),
            length.out = 400
        )
    )

    fv <- vapply(g, f, numeric(1))
    i <- which.min(fv)

    interval <- c(
        g[max(1, i - 1)],
        g[min(length(g), i + 1)]
    )

    opt <- optimize(
        f,
        interval = interval,
        tol = 1e-12
    )

    tau <- opt$minimum

    X <- cbind(1, exp(-x / tau))
    cf <- qr.solve(X, y)

    residuals <- y - drop(X %*% cf)

    list(
        params = c(cf[1], cf[2], tau),
        rss = sum(residuals^2)
    )
}

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


