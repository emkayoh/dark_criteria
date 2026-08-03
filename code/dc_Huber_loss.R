# Oldar

#' Smoothed five-parameter dark-adaptation model
#'
#' Uses a logistic approximation to the Heaviside step in P5c. This version
#' is intended for gradient-based optimisation, where a differentiable
#' approximation around alpha is required.
#'
#' @param a Numeric parameter vector in the order ct, cc, tau, S2, alpha.
#' @param x Numeric vector of times.
#' @param k Positive smoothing constant. Larger values approximate a sharper
#'   step but can cause numerical instability.
#'
#' @return Numeric vector of predicted sensitivities.
P5cSmooth <- function(a, x, k = 20) {
    ct <- a[1L]
    cc <- a[2L]
    tau <- a[3L]
    S2 <- a[4L]
    alpha <- a[5L]

    step <- plogis(2 * k * (x - alpha))

    ct +
        cc * exp(-x / tau) +
        S2 * (x - alpha) * step
}


#' Pseudo-Huber objective
#'
#' Calculates the summed pseudo-Huber loss for a model fit. The loss behaves
#' approximately quadratically for small residuals and approximately linearly
#' for large residuals.
#'
#' @param a Numeric parameter vector.
#' @param fn Model function accepting arguments `a` and `x`.
#' @param x Numeric predictor values.
#' @param y Numeric observed values.
#' @param delta Positive transition parameter controlling where the loss
#'   changes from approximately quadratic to approximately linear.
#' @param ... Additional arguments passed to `fn`.
#'
#' @return A non-negative scalar loss.
PseudoHuberLoss <- function(
    a,
    fn = P5cSmooth,
    x,
    y,
    delta = 1.35,
    ...
) {
    if (!is.numeric(delta) || length(delta) != 1L ||
        !is.finite(delta) || delta <= 0) {
        stop("delta must be a positive finite scalar.")
    }

    residuals <- y - fn(a, x, ...)

    if (any(!is.finite(residuals))) {
        return(Inf)
    }

    sum(
        delta^2 * (sqrt(1 + (residuals / delta)^2) - 1)
    )
}

#' Gradient of the P5c pseudo-Huber objective
#'
#' Computes the analytic gradient of the pseudo-Huber loss for the smoothed
#' P5c model.
#'
#' @param a Numeric parameter vector in the order ct, cc, tau, S2, alpha.
#' @param x Numeric vector of times.
#' @param y Numeric vector of observed sensitivities.
#' @param delta Positive pseudo-Huber transition parameter.
#' @param k Positive smoothing constant used by P5cSmooth.
#'
#' @return Numeric gradient vector of length five.
P5cPseudoHuberGrad <- function(
    a,
    x,
    y,
    delta = 1.35,
    k = 20
) {
    if (length(a) != 5L || any(!is.finite(a))) {
        stop("a must contain five finite P5c parameters.")
    }

    if (!is.finite(delta) || delta <= 0) {
        stop("delta must be positive and finite.")
    }

    if (!is.finite(k) || k <= 0) {
        stop("k must be positive and finite.")
    }

    ct <- a[1L]
    cc <- a[2L]
    tau <- a[3L]
    S2 <- a[4L]
    alpha <- a[5L]

    if (tau <= 0) {
        return(rep(NA_real_, 5L))
    }

    z <- 2 * k * (x - alpha)
    step <- plogis(z)
    step_derivative <- 2 * k * step * (1 - step)

    exponential <- exp(-x / tau)

    fitted <- ct +
        cc * exponential +
        S2 * (x - alpha) * step

    residuals <- y - fitted

    # Derivative of pseudo-Huber loss with respect to each residual.
    psi <- residuals / sqrt(1 + (residuals / delta)^2)

    # Derivatives of the fitted model with respect to its parameters.
    df_dct <- rep(1, length(x))
    df_dcc <- exponential
    df_dtau <- cc * exponential * x / tau^2
    df_dS2 <- (x - alpha) * step

    # d/dalpha [(x-alpha) * step]
    df_dalpha <- S2 * (
        -step -
        (x - alpha) * step_derivative
    )

    # residual = y - fitted, hence the leading minus sign.
    -c(
        sum(psi * df_dct),
        sum(psi * df_dcc),
        sum(psi * df_dtau),
        sum(psi * df_dS2),
        sum(psi * df_dalpha)
    )
}

#' Fit P5c using pseudo-Huber gradient descent
#'
#' Fits the smoothed P5c model by minimising the pseudo-Huber objective.
#' Parameter-specific learning rates are used because the five P5c parameters
#' operate on substantially different numerical scales.
#'
#' @param a Initial parameter vector in the order ct, cc, tau, S2, alpha.
#' @param fn Model function. The gradient implemented here is specific to
#'   `P5cSmooth`; supplying another function is not supported.
#' @param x Numeric vector of measurement times.
#' @param y Numeric vector of observed sensitivities.
#' @param opt Positive pseudo-Huber transition parameter.
#' @param k Positive logistic smoothing constant.
#' @param eta Numeric scalar or vector of five learning rates.
#' @param tol Convergence tolerance applied to the absolute change in loss.
#' @param max_runs Maximum number of gradient-descent iterations.
#' @param min_eta Smallest permitted learning rate during step reduction.
#'
#' @return A list containing fitted parameters, final loss, convergence
#'   information and residual diagnostics.
findParametersGDPlainHuber <- function(
    a,
    fn = P5cSmooth,
    x,
    y,
    opt = 1.35,
    k = 20,
    eta = 1 / c(1000, 1000, 1000, 10000, 100),
    tol = 1e-6,
    max_runs = 20000L,
    min_eta = 1e-12
) {
    if (!identical(fn, P5cSmooth)) {
        stop(
            "The analytic gradient is specific to P5cSmooth; ",
            "fn must be P5cSmooth."
        )
    }

    if (!is.numeric(a) || length(a) != 5L || any(!is.finite(a))) {
        stop("a must contain five finite P5c parameters.")
    }

    if (!is.numeric(x) || !is.numeric(y) || length(x) != length(y)) {
        stop("x and y must be numeric vectors of equal length.")
    }

    if (!length(x) || any(!is.finite(x)) || any(!is.finite(y))) {
        stop("x and y must contain finite observations.")
    }

    if (!is.numeric(opt) || length(opt) != 1L ||
        !is.finite(opt) || opt <= 0) {
        stop("opt must be a positive finite scalar.")
    }

    eta <- rep_len(eta, 5L)

    if (any(!is.finite(eta)) || any(eta <= 0)) {
        stop("eta must contain positive finite values.")
    }

    current_loss <- PseudoHuberLoss(
        a = a,
        fn = fn,
        x = x,
        y = y,
        delta = opt,
        k = k
    )

    if (!is.finite(current_loss)) {
        stop("The initial parameter vector produces a non-finite loss.")
    }

    best_params <- a
    best_loss <- current_loss
    converged <- FALSE
    loss_change <- NA_real_

    for (ii in seq_len(max_runs)) {
        gradient <- P5cPseudoHuberGrad(
            a = a,
            x = x,
            y = y,
            delta = opt,
            k = k
        )

        if (
            length(gradient) != 5L ||
            any(!is.finite(gradient))
        ) {
            break
        }

        candidate <- a - eta * gradient

        candidate_loss <- PseudoHuberLoss(
            a = candidate,
            fn = fn,
            x = x,
            y = y,
            delta = opt,
            k = k
        )

        # Reduce the step when the proposed update worsens the objective.
        if (!is.finite(candidate_loss) || candidate_loss > current_loss) {
            eta <- eta / 2

            if (all(eta < min_eta)) {
                break
            }

            next
        }

        loss_change <- current_loss - candidate_loss

        a <- candidate
        current_loss <- candidate_loss

        if (current_loss < best_loss) {
            best_loss <- current_loss
            best_params <- a
        }

        if (abs(loss_change) < tol) {
            converged <- TRUE
            break
        }
    }

    residuals <- y - fn(best_params, x, k = k)
    residual_df <- length(y) - length(best_params)
    rss <- sum(residuals^2)

    list(
        params = best_params,
        runs = ii,
        converged = converged,
        loss = best_loss,
        loss_change = loss_change,
        noise = sd(residuals),
        RSS = rss,
        MSE = if (residual_df > 0L) {
            rss / residual_df
        } else {
            NA_real_
        },
        residual_df = residual_df,
        delta = opt,
        smoothing_k = k
    )
}

checkP5cPseudoHuberGradient <- function(
    a,
    x,
    y,
    delta = 1.35,
    k = 20,
    epsilon = 1e-6
) {
    analytic <- P5cPseudoHuberGrad(
        a = a,
        x = x,
        y = y,
        delta = delta,
        k = k
    )

    numerical <- vapply(
        seq_along(a),
        function(j) {
            a_plus <- a
            a_minus <- a

            a_plus[j] <- a_plus[j] + epsilon
            a_minus[j] <- a_minus[j] - epsilon

            loss_plus <- PseudoHuberLoss(
                a_plus,
                P5cSmooth,
                x,
                y,
                delta,
                k = k
            )

            loss_minus <- PseudoHuberLoss(
                a_minus,
                P5cSmooth,
                x,
                y,
                delta,
                k = k
            )

            (loss_plus - loss_minus) / (2 * epsilon)
        },
        numeric(1L)
    )

    data.frame(
        parameter = c("ct", "cc", "tau", "S2", "alpha"),
        analytic = analytic,
        numerical = numerical,
        difference = analytic - numerical
    )
}
