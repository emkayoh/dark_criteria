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



findParametersGDPlain <- function(a, fn, x, y, inv = FALSE) {
	val = list()
	tol <- 1e-06
	delta <- NULL
	eta <- 1/c(1000, 1000, 1000, 10000, 100)
	LS0 <- 1e+07
	for (ii in 1:20000) {
		gradient <- Grad(a, fn, x, y)
		a <- a - eta * gradient
		LS1 <- LeastSq(a, fn, x, y, inv)
		del = LS0 - LS1
		LS0 = LS1
		delta <- c(delta, del)
		if (abs(del) < tol)
			break
	}
	resV <- Resid(a, fn, x, y)
	val$params = a
	val$runs = ii
	val$noise = sd(resV)
	val$MSE = resV %*% resV/(length(x) - 5)
	return(val)
}


  # val = list()
  # tol <- 1e-06
  # eta <- 1/c(1000, 1000, 1000, 10000, 100)
  # LS0 <- 1e+07
  # velocity = 0
  # gamma = 0.9
  # for (ii in 1:10000) {
    # gradient <- Grad(a, fn, x, y)
    # velocity = gamma * velocity + eta * gradient
    # a <- a - velocity
    # LS1 <- LeastSq(a, fn, x, y, inv)
    # del = LS0 - LS1
    # LS0 = LS1
    # if (abs(del) < tol)
      # break
  # }
  # resV <- Resid(a, fn, x, y)
  # val$params = a
  # val$runs = ii
  # val$noise = sd(resV)
  # val$MSE = resV %*% resV/(length(x) - 5)
  # return(val)


  # val = list()
  # tol <- 1e-06
  # eta <- 1/c(1000, 1000, 1000, 10000, 100)
  # LS0 <- 1e+07
  # velocity = 0
  # gamma = 0.9
  # for (ii in 1:10000) {
    # gradient <- Grad(a, fn, x, y)
    # velocity = gamma * velocity + eta * gradient
    # a <- a - velocity
    # if (a[5] < 0 | a[5] > max(x)) {
      # a[5] <- 0
      # a[4] <- 0
    # }
    # LS1 <- LeastSq(a, fn, x, y, inv)
    # del = LS0 - LS1
    # LS0 = LS1
    # if (abs(del) < tol)
      # break
  # }
  # resV <- Resid(a, fn, x, y)
  # val$params = a
  # val$runs = ii
  # val$noise = sd(resV)
  # val$MSE = resV %*% resV/(length(x) - 5)
  # return(val)

  # val = list()
  # tol <- 1e-06
  # eta <- 1/c(1000, 1000, 1000, 10000, 10)
  # LS0 <- 1e+07
  # velocity = 0
  # gamma = 0.6
  # for (ii in 1:10000) {
    # gradient <- Grad(a - gamma * velocity, fn, x, y)
    # velocity = gamma * velocity + eta * gradient
    # a <- a - velocity
    # LS1 <- LeastSq(a, fn, x, y, inv)
    # del = LS0 - LS1
    # LS0 = LS1
    # if (abs(del) < tol)
      # break
  # }
  # resV <- Resid(a, fn, x, y)
  # val$params = a
  # val$runs = ii
  # val$noise = sd(resV)
  # val$MSE = resV %*% resV/(length(x) - 5)
  # return(val)


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



  # eigenvalues <- round(eigen(hess)$values, 5)
  # is_positive_definite <- all(eigenvalues > 0)
  # is_positive_semi_definite <- all(eigenvalues >= 0)
  # is_indefinite <- any(eigenvalues < 0)

  # if (is_positive_definite) {
    # cat("The Hessian matrix is positive definite.\n")
    # return(1)
  # } else if (is_positive_semi_definite) {
    # cat("The Hessian matrix is positive semi-definite.\n")
    # return(0)
  # } else if (is_indefinite) {
    # cat("The Hessian matrix is indefinite.\n")
    # return(-1)
  # }


  # para <- NULL
  # noise <- NULL
  # nobs <- length(x)  # Assuming `time` should be `x`
  # for(ii in 1:nobs) {
    # fit <- findParametersGDPlain(a, fn, x[-ii], y[-ii], inv)
    # para <- rbind(para, fit$params)
    # noise <- c(noise, fit$noise)
  # }

  # idx <- which.min(noise)
  # fit <- findParametersGDPlain(a, fn, x[-idx], y[-idx], inv = TRUE)
  # hess <- Hessian(para[idx,], fn, x[-idx], y[-idx])
  # fit$hessian <- hess
  # fit$least_informative_point <- idx

  # fit




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
