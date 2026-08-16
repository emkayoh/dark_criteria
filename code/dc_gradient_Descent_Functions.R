# Reference copy 15 Aug 2026
# For a numerical experiment
# Dr Jeremiah MF Kelly

H <- function(x, t) {
  # round(1/(1 + exp(-40 * (x - t))), 0)
  as.numeric(x >= alpha)
}


P3 <- function(a, x) {
	if(missing(x)){
		 return(list(Pn = 3L, Mod = "P3"))
	}
  a[1] + a[2] * exp(-x/a[3])
}

	# if(missing(x)){
		# return(list(Pn = 5L, Mod = "P5c"))
	# }
  # a[1] + a[2] * exp(-x/a[3]) + a[4] * (x - a[5]) * H(x, a[5])

P5c <- function(a, x) {
    if (missing(x)) {
        return(list(
            Pn = 5L,
            Mod = "P5c"
        ))
    }

    step <- as.numeric(x >= a[5L])

    a[1L] +
        a[2L] * exp(-x / a[3L]) +
        a[4L] * (x - a[5L]) * step
}


P7c <- function(a, x) {
	a[1] + a[2] * exp(-x/a[3]) + a[4] * (x - a[5]) * H(x, a[5]) +
		a[6] * (x - a[7]) * H(x, a[7])
}

Resid <- function(a, fn, x, y) {
  y - fn(a, x)
}


LeastSq <- function(a, fn = P5c, x, y, inv = FALSE) {
  resid <- Resid(a, fn, x, y)
  if (inv) {
    wt <- 1/(1 + resid^2)
  } else {
    wt = 1
  }
  sum(wt * resid^2)
}

pdf1 <- function(a, fn, x, y) {
  root <- x/x
  -2 * (root %*% Resid(a, fn, x, y))
}

pdf2 <- function(a, fn, x, y) {
  root <- exp(-x/a[3])
  -2 * (root %*% Resid(a, fn, x, y))
}

pdf3 <- function(a, fn, x, y) {
  root <- exp(-x/a[3]) * a[2] * x/(a[3] * a[3])
  -2 * (root %*% Resid(a, fn, x, y))
}

pdf4 <- function(a, fn, x, y) {
  root <- (x - a[5])/(1 + exp(-200 * (x - a[5])))
  -2 * (root %*% Resid(a, fn, x, y))
}

pdf5 <- function(a, fn, x, y) {
  k <- 20
  root = (a[4]/(1 + exp(-2 * k * (x - a[5]))) - a[4] * (x - a[5]) *
          (exp(-2 * k * (x - a[5])) * (-2 * k))/(1 + exp(-2 * k * (x -
                                                                    a[5])))^2)
  2 * (root %*% Resid(a, fn, x, y))
}


Grad <- function(a, fn, x, y) {
  ct <- a[1]
  cc <- a[2]
  tau <- a[3]
  S2 <- a[4]
  alpha <- a[5]
  k = 20
  L <- expression((y - (ct + cc * exp(-x/tau) + S2 * (x - alpha)/(1 +
    exp(-2 * k * (x - alpha)))))^2)
  Params <- c("ct", "cc", "tau", "S2", "alpha")
  pGrad <- c()
  for (ii in 1:5) {
    pGrad <- cbind(pGrad, sum(eval(D(L, Params[ii])), na.rm = TRUE))
  }
  pGrad
}


progGrad <- function(p0, fn = P5c, x, y) {
	ct <- p0[1]
	cc <- p0[2]
	tau <- p0[3]
	S2 <- p0[4]
	alpha <- p0[5]
	k = 10

	L <- expression((y - (ct + cc * exp(-x/tau) + S2 * (x - alpha)/(1 +
		exp(-2 * k * (x - alpha)))))^2)


	Params <- c("ct", "cc", "tau", "S2", "alpha")

	pGrad <- c()
	for (ii in 1:5) {
		pGrad <- cbind(pGrad, (eval(D(L, Params[ii]))))

	}
	idx <- is.na(pGrad)
	pGrad[idx] <- 0

	GradMat <- t(pGrad) %*% pGrad
	GradMat
}



findParametersGDPlain <- function(
    a,
    fn,
    x,
    y,
    inv = FALSE,
    tol = 1e-6,
    max_iter = 20000L,
    max_backtrack = 30L
) {

    eta <- 1 / c(
        1000,
        1000,
        1000,
        10000,
        100
    )

    # Current objective
    LS0 <- LeastSq(
        a,
        fn,
        x,
        y,
        inv
    )

    if (!is.finite(LS0)) {
        stop("Initial least-squares value is non-finite")
    }

    converged <- FALSE
    status <- "max_iterations"

    for (ii in seq_len(max_iter)) {

        gradient <- Grad(
            a,
            fn,
            x,
            y
        )

        if (any(!is.finite(gradient))) {
            status <- "non_finite_gradient"
            break
        }

        # ----------------------------------------------
        # Backtracking step
        # ----------------------------------------------

        step_scale <- 1
        accepted <- FALSE

        for (jj in seq_len(max_backtrack)) {

            a_new <- a -
                step_scale * eta * gradient

            # tau must remain positive
            valid_params <-
                all(is.finite(a_new)) &&
                a_new[3] > 0

            if (valid_params) {

                LS1 <- LeastSq(
                    a_new,
                    fn,
                    x,
                    y,
                    inv
                )

            } else {

                LS1 <- Inf
            }

            # Accept only a finite, improving step
            if (
                is.finite(LS1) &&
                LS1 <= LS0
            ) {
                accepted <- TRUE
                break
            }

            step_scale <- step_scale / 2
        }

        # No acceptable step found:
        # retain the last valid parameter vector
        if (!accepted) {
            status <- "no_improving_step"
            break
        }

        # ----------------------------------------------
        # Accept step
        # ----------------------------------------------

        del <- LS0 - LS1

        a <- a_new
        LS0 <- LS1

        if (abs(del) < tol) {
            converged <- TRUE
            status <- "converged"
            break
        }
    }

    # ----------------------------------------------
    # Final residual diagnostics
    # ----------------------------------------------

    resV <- Resid(
        a,
        fn,
        x,
        y
    )

    list(
        params = a,
        runs = ii,
        noise = sd(resV),
        MSE = as.numeric(
            resV %*% resV /
                (length(x) - 5)
        ),
        converged = converged,
        status = status
    )
}


P5cJacobian <- function(a, x) {
    if (
        !is.numeric(a) ||
        length(a) != 5L ||
        any(!is.finite(a))
    ) {
        stop("a must contain five finite P5c parameters.")
    }

    if (
        !is.numeric(x) ||
        length(x) == 0L ||
        any(!is.finite(x))
    ) {
        stop("x must be a non-empty vector of finite values.")
    }

    cc <- a[2L]
    tau <- a[3L]
    S2 <- a[4L]
    alpha <- a[5L]

    if (tau <= 0) {
        stop("tau must be greater than zero.")
    }

    exponential <- exp(-x / tau)
    step <- as.numeric(x >= alpha)

    cbind(
        ct = rep(1, length(x)),
        cc = exponential,
        tau = cc * exponential * x / tau^2,
        S2 = (x - alpha) * step,
        alpha = -S2 * step
    )
}

P5cRSSHessian <- function(a, x) {
    J <- P5cJacobian(a, x)
    2 * crossprod(J)
}







P5cConfidenceIntervals <- function(
    params,
    x,
    y,
    level = 0.95
) {
    if (
        !is.numeric(y) ||
        length(y) != length(x) ||
        any(!is.finite(y))
    ) {
        stop("y must be finite and have the same length as x.")
    }

    params <- as.numeric(params)
    names(params) <- c("ct", "cc", "tau", "S2", "alpha")

    residuals <- y - P5c(params, x)

    n <- length(y)
    p <- length(params)
    residual_df <- n - p

    if (residual_df <= 0L) {
        stop("Residual degrees of freedom must be positive.")
    }

    rss <- sum(residuals^2)
    sigma2 <- rss / residual_df

    J <- P5cJacobian(params, x)
    information <- crossprod(J)

    eigenvalues <- eigen(
        information,
        symmetric = TRUE,
        only.values = TRUE
    )$values

    covariance <- tryCatch(
        sigma2 * solve(information),
        error = function(e) {
            matrix(NA_real_, p, p)
        }
    )

    if (any(!is.finite(covariance))) {
        se <- rep(NA_real_, p)
    } else {
        se <- sqrt(pmax(diag(covariance), 0))
    }

    critical <- qt(
        1 - (1 - level) / 2,
        df = residual_df
    )

    lower <- params - critical * se
    upper <- params + critical * se

    output <- data.frame(
        param = names(params),
        estimate = params,
        se = se,
        lower = lower,
        upper = upper,
        covers_zero = lower <= 0 & upper >= 0,
        row.names = NULL
    )

    attr(output, "RSS") <- rss
    attr(output, "sigma2") <- sigma2
    attr(output, "residual_df") <- residual_df
    attr(output, "condition_number") <- kappa(information)
    attr(output, "information_eigenvalues") <- eigenvalues
    attr(output, "covariance") <- covariance
    attr(output, "jacobian") <- J

    output
}
