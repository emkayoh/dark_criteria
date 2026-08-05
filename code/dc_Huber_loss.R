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

#' Robust gradient-descent optimisation of the P5c model
#'
#' Fits the smoothed five-parameter dark-adaptation model (`P5cSmooth`) by
#' minimising the pseudo-Huber objective function using gradient descent with
#' parameter-specific learning rates. The pseudo-Huber loss provides a smooth,
#' differentiable approximation to the Huber loss, giving robustness to
#' outlying observations while retaining stable optimisation.
#'
#' The optimiser is intended as a robust initial estimation procedure for the
#' P5c model. The resulting parameter estimates may subsequently be refined
#' using ordinary or inverse-weighted least squares before statistical
#' inference (e.g. Hessian estimation, confidence intervals or AIC
#' calculations).
#'
#' Convergence is declared when one of the following criteria is satisfied:
#'
#' \itemize{
#'   \item the Euclidean norm of the gradient falls below
#'         \code{grad_tol};
#'   \item the proposed parameter update is sufficiently small
#'         (\code{step_tol});
#'   \item the relative improvement in pseudo-Huber loss remains below
#'         \code{relative_loss_tol} for \code{plateau_runs} consecutive
#'         accepted iterations;
#'   \item the learning rate falls below \code{min_eta}.
#' }
#'
#' Candidate parameter updates that increase the objective function are
#' rejected and the learning rates are halved before another iteration is
#' attempted. The best parameter vector encountered during optimisation is
#' returned.
#'
#' @param a Numeric vector of initial parameter estimates in the order
#'   \code{ct}, \code{cc}, \code{tau}, \code{S2} and \code{alpha}.
#'
#' @param fn Model function. Currently this must be \code{P5cSmooth}, since
#'   the analytic gradient is derived specifically for this model.
#'
#' @param x Numeric vector of measurement times.
#'
#' @param y Numeric vector of observed threshold measurements.
#'
#' @param opt Positive pseudo-Huber transition parameter (\eqn{\delta}).
#'   Smaller values produce greater robustness to outliers; larger values
#'   approach ordinary least-squares behaviour.
#'
#' @param k Logistic smoothing parameter used to approximate the Heaviside
#'   step in the P5c model. Larger values more closely approximate the
#'   discontinuous model but may reduce numerical stability.
#'
#' @param eta Scalar or vector of learning rates. If a scalar is supplied it
#'   is recycled for all parameters.
#'
#' @param loss_tol Absolute tolerance for successive changes in pseudo-Huber
#'   loss.
#'
#' @param relative_loss_tol Relative tolerance for successive changes in
#'   pseudo-Huber loss.
#'
#' @param grad_tol Tolerance on the Euclidean norm of the gradient.
#'
#' @param step_tol Relative tolerance on the proposed parameter update.
#'
#' @param plateau_runs Number of consecutive accepted iterations satisfying
#'   the loss tolerance before convergence is declared.
#'
#' @param max_runs Maximum number of gradient-descent iterations.
#'
#' @param min_eta Minimum permitted learning rate before optimisation is
#'   terminated.
#'
#' @return A list containing:
#'
#' \describe{
#'   \item{params}{Named vector of fitted parameter estimates.}
#'   \item{runs}{Number of optimisation iterations performed.}
#'   \item{converged}{Logical indicating whether a convergence criterion was
#'     satisfied.}
#'   \item{convergence_reason}{Character string describing the criterion that
#'     terminated optimisation.}
#'   \item{loss}{Final pseudo-Huber objective value.}
#'   \item{loss_change}{Change in loss during the final accepted iteration.}
#'   \item{absolute_loss_change}{Absolute change in loss.}
#'   \item{relative_loss_change}{Relative change in loss.}
#'   \item{gradient_norm}{Euclidean norm of the final gradient.}
#'   \item{step_norm}{Euclidean norm of the final parameter update.}
#'   \item{plateau_count}{Number of consecutive plateau iterations at
#'     termination.}
#'   \item{rejected_steps}{Number of proposed updates rejected because they
#'     increased the objective function.}
#'   \item{eta_final}{Learning rates at termination.}
#'   \item{noise}{Residual standard deviation.}
#'   \item{RSS}{Residual sum of squares.}
#'   \item{MSE}{Residual mean square.}
#'   \item{residual_df}{Residual degrees of freedom.}
#'   \item{delta}{Pseudo-Huber transition parameter used.}
#'   \item{smoothing_k}{Logistic smoothing parameter used.}
#' }
#'
#' @details
#' This routine is intended to provide robust parameter estimates in the
#' presence of intrinsic and extrinsic measurement noise. The pseudo-Huber
#' objective reduces the influence of observations with large residuals while
#' remaining continuously differentiable, allowing efficient gradient-based
#' optimisation.
#'
#' The returned parameters are suitable as starting values for subsequent
#' optimisation using ordinary least squares or inverse-weighted least squares,
#' from which Hessian matrices, confidence intervals and model-selection
#' statistics (e.g. AIC or AICc) may be calculated.
#'
#' @seealso
#' \code{\link{PseudoHuberLoss}},
#' \code{\link{P5cPseudoHuberGrad}},
#' \code{\link{P5cSmooth}}
findParametersGDPlainHuber <- function(
    a,
    fn = P5cSmooth,
    x,
    y,
    opt = 1.35,
    k = 20,
    eta = 1 / c(1000, 1000, 1000, 10000, 100),
    loss_tol = 1e-7,
    relative_loss_tol = 1e-5,
    grad_tol = 1e-6,
    step_tol = 1e-8,
    plateau_runs = 10L,
    max_runs = 20000L,
    min_eta = 1e-12
) {
    if (!identical(fn, P5cSmooth)) {
        stop(
            "The analytic gradient is specific to P5cSmooth; ",
            "fn must be P5cSmooth."
        )
    }

    if (
        !is.numeric(a) ||
        length(a) != 5L ||
        any(!is.finite(a))
    ) {
        stop("a must contain five finite P5c parameters.")
    }

    if (
        !is.numeric(x) ||
        !is.numeric(y) ||
        length(x) != length(y)
    ) {
        stop("x and y must be numeric vectors of equal length.")
    }

    if (
        length(x) == 0L ||
        any(!is.finite(x)) ||
        any(!is.finite(y))
    ) {
        stop("x and y must contain finite observations.")
    }

    if (
        !is.numeric(opt) ||
        length(opt) != 1L ||
        !is.finite(opt) ||
        opt <= 0
    ) {
        stop("opt must be a positive finite scalar.")
    }

    if (
        !is.numeric(k) ||
        length(k) != 1L ||
        !is.finite(k) ||
        k <= 0
    ) {
        stop("k must be a positive finite scalar.")
    }

    if (
        !is.numeric(loss_tol) ||
        length(loss_tol) != 1L ||
        !is.finite(loss_tol) ||
        loss_tol < 0
    ) {
        stop("loss_tol must be a non-negative finite scalar.")
    }

    if (
        !is.numeric(relative_loss_tol) ||
        length(relative_loss_tol) != 1L ||
        !is.finite(relative_loss_tol) ||
        relative_loss_tol < 0
    ) {
        stop(
            "relative_loss_tol must be a non-negative finite scalar."
        )
    }

    if (
        !is.numeric(grad_tol) ||
        length(grad_tol) != 1L ||
        !is.finite(grad_tol) ||
        grad_tol < 0
    ) {
        stop("grad_tol must be a non-negative finite scalar.")
    }

    if (
        !is.numeric(step_tol) ||
        length(step_tol) != 1L ||
        !is.finite(step_tol) ||
        step_tol < 0
    ) {
        stop("step_tol must be a non-negative finite scalar.")
    }

    if (
        length(plateau_runs) != 1L ||
        !is.finite(plateau_runs) ||
        plateau_runs < 1
    ) {
        stop("plateau_runs must be a positive integer.")
    }

    if (
        length(max_runs) != 1L ||
        !is.finite(max_runs) ||
        max_runs < 1
    ) {
        stop("max_runs must be a positive integer.")
    }

    plateau_runs <- as.integer(plateau_runs)
    max_runs <- as.integer(max_runs)

    eta <- rep_len(eta, length(a))

    if (
        any(!is.finite(eta)) ||
        any(eta <= 0)
    ) {
        stop("eta must contain positive finite values.")
    }

    if (
        !is.numeric(min_eta) ||
        length(min_eta) != 1L ||
        !is.finite(min_eta) ||
        min_eta <= 0
    ) {
        stop("min_eta must be a positive finite scalar.")
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
    convergence_reason <- "maximum iterations reached"

    loss_change <- NA_real_
    absolute_loss_change <- NA_real_
    relative_loss_change <- NA_real_
    gradient_norm <- NA_real_
    step_norm <- NA_real_
    plateau_count <- 0L
    rejected_steps <- 0L

    for (ii in seq_len(max_runs)) {
        gradient <- P5cPseudoHuberGrad(
            a = a,
            x = x,
            y = y,
            delta = opt,
            k = k
        )

        if (
            length(gradient) != length(a) ||
            any(!is.finite(gradient))
        ) {
            convergence_reason <- "non-finite gradient"
            break
        }

        gradient_norm <- sqrt(sum(gradient^2))

        if (gradient_norm <= grad_tol) {
            converged <- TRUE
            convergence_reason <- "gradient tolerance reached"
            break
        }

        step <- eta * gradient
        step_norm <- sqrt(sum(step^2))

        parameter_scale <- 1 + sqrt(sum(a^2))

        if (step_norm <= step_tol * parameter_scale) {
            converged <- TRUE
            convergence_reason <- "parameter-step tolerance reached"
            break
        }

        candidate <- a - step

        candidate_loss <- PseudoHuberLoss(
            a = candidate,
            fn = fn,
            x = x,
            y = y,
            delta = opt,
            k = k
        )

        if (!is.finite(candidate_loss)) {
            eta <- eta / 2
            plateau_count <- 0L
            rejected_steps <- rejected_steps + 1L

            if (max(eta) <= min_eta) {
                convergence_reason <- "minimum learning rate reached"
                break
            }

            next
        }

        loss_change <- current_loss - candidate_loss
        absolute_loss_change <- abs(loss_change)

        relative_loss_change <- absolute_loss_change /
            max(
                abs(current_loss),
                abs(candidate_loss),
                .Machine$double.eps
            )

        loss_is_stable <- (
            absolute_loss_change <= loss_tol ||
            relative_loss_change <= relative_loss_tol
        )

        if (candidate_loss > current_loss) {
            eta <- eta / 2
            plateau_count <- 0L
            rejected_steps <- rejected_steps + 1L

            if (max(eta) <= min_eta) {
                convergence_reason <- "minimum learning rate reached"
                break
            }

            next
        }

        # Accept the improving or numerically equivalent step.
        a <- candidate
        current_loss <- candidate_loss

        if (current_loss < best_loss) {
            best_loss <- current_loss
            best_params <- a
        }

        if (loss_is_stable) {
            plateau_count <- plateau_count + 1L
        } else {
            plateau_count <- 0L
        }

        if (plateau_count >= plateau_runs) {
            converged <- TRUE
            convergence_reason <- "sustained loss plateau"
            break
        }
    }

    # Ensure that the most recent accepted result is retained.
    if (current_loss <= best_loss) {
        best_loss <- current_loss
        best_params <- a
    }

    residuals <- y - fn(
        a = best_params,
        x = x,
        k = k
    )

    residual_df <- length(y) - length(best_params)
    rss <- sum(residuals^2)

    params <- best_params
    names(params) <- c("ct", "cc", "tau", "S2", "alpha")

    list(
        params = params,
        runs = ii,
        converged = converged,
        convergence_reason = convergence_reason,
        loss = best_loss,
        loss_change = loss_change,
        absolute_loss_change = absolute_loss_change,
        relative_loss_change = relative_loss_change,
        gradient_norm = gradient_norm,
        step_norm = step_norm,
        plateau_count = plateau_count,
        rejected_steps = rejected_steps,
        eta_final = eta,
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


fitP5cPseudoHuber <- function(
    a,
    x,
    y,
    delta = 1.35,
    k = 20,
    lower = c(-3, -2, 0.01, -0.5, 0.5),
    upper = c(0, 3, 5, 0, max(x))
) {
    objective <- function(par) {
        PseudoHuberLoss(
            a = par,
            fn = P5cSmooth,
            x = x,
            y = y,
            delta = delta,
            k = k
        )
    }

    gradient <- function(par) {
        P5cPseudoHuberGrad(
            a = par,
            x = x,
            y = y,
            delta = delta,
            k = k
        )
    }

    fit <- optim(
        par = a,
        fn = objective,
        gr = gradient,
        method = "L-BFGS-B",
        lower = lower,
        upper = upper,
        control = list(
            factr = 1e8,
            pgtol = 1e-6,
            maxit = 2000
        ),
        hessian = FALSE
    )

    residuals <- y - P5cSmooth(fit$par, x, k = k)
    rss <- sum(residuals^2)
    residual_df <- length(y) - length(fit$par)

    params <- fit$par
    names(params) <- c("ct", "cc", "tau", "S2", "alpha")

    list(
        params = params,
        runs = fit$counts[["function"]],
        converged = fit$convergence == 0L,
        convergence_code = fit$convergence,
        convergence_message = fit$message,
        loss = fit$value,
        noise = sd(residuals),
        RSS = rss,
        MSE = rss / residual_df,
        residual_df = residual_df,
        delta = delta,
        smoothing_k = k
    )
}


refineP5cStarts <- function(
    obj,
    x,
    y,
    alpha_values = seq(
        from = 0.5,
        to = max(x, na.rm = TRUE),
        length.out = 10L
    ),
    tau_values = 10^seq(
        from = log10(0.01),
        to = log10(2),
        length.out = 10L
    ),
    delta = 1.35,
    k = 20
) {
    if (!is.null(obj$params)) {
        start_params <- obj$params
    } else if (!is.null(obj$param)) {
        start_params <- obj$param
    } else if (!is.null(obj$best)) {
        start_params <- obj$best
    } else {
        stop("obj must contain 'params', 'param', or 'best'.")
    }

    fit_candidate <- function(params) {
        tryCatch(
            fitP5cPseudoHuber(
                a = params,
                x = x,
                y = y,
                delta = delta,
                k = k
            ),
            error = function(e) NULL
        )
    }

    select_best <- function(start, index, values) {
        fits <- lapply(
            values,
            function(value) {
                candidate <- start
                candidate[index] <- value
                fit_candidate(candidate)
            }
        )

        valid <- vapply(
            fits,
            function(fit) {
                !is.null(fit) &&
                    isTRUE(fit$converged) &&
                    is.finite(fit$loss)
            },
            logical(1L)
        )

        if (!any(valid)) {
            return(NULL)
        }

        fits <- fits[valid]

        losses <- vapply(
            fits,
            `[[`,
            numeric(1L),
            "loss"
        )

        fits[[which.min(losses)]]
    }

    alpha_fit <- select_best(
        start = start_params,
        index = 5L,
        values = alpha_values
    )

    if (is.null(alpha_fit)) {
        stop("No valid fit was obtained from the alpha starts.")
    }

    tau_fit <- select_best(
        start = alpha_fit$params,
        index = 3L,
        values = tau_values
    )

    if (is.null(tau_fit)) {
        stop("No valid fit was obtained from the tau starts.")
    }

    tau_fit
}

makeP5cStarts <- function(
    initial,
    alpha_values = c(4, 7, 10),
    tau_values = c(1, 2.5)
) {
    grid <- expand.grid(
        tau = tau_values,
        alpha = alpha_values
    )

    lapply(
        seq_len(nrow(grid)),
        function(i) {
            candidate <- initial
            candidate[3L] <- grid$tau[i]
            candidate[5L] <- grid$alpha[i]
            candidate
        }
    )
}


fitP5cMultistart <- function(
    initial,
    x,
    y,
    alpha_values = c(4, 7, 10),
    tau_values = c(1, 2.5),
    delta = 1.35,
    k = 20
) {
    starts <- makeP5cStarts(
        initial = initial,
        alpha_values = alpha_values,
        tau_values = tau_values
    )

    fits <- lapply(
        starts,
        function(start) {
            tryCatch(
                fitP5cPseudoHuber(
                    a = start,
                    x = x,
                    y = y,
                    delta = delta,
                    k = k
                ),
                error = function(e) NULL
            )
        }
    )

    valid <- vapply(
        fits,
        function(fit) {
            !is.null(fit) &&
                is.finite(fit$loss)
        },
        logical(1L)
    )

    if (!any(valid)) {
        stop("All P5c optimisation attempts failed.")
    }

    fits <- fits[valid]

    losses <- vapply(
        fits,
        `[[`,
        numeric(1L),
        "loss"
    )

    fits[[which.min(losses)]]
}
