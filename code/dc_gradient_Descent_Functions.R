# Reference copy 17 June 2024
# Dr Jeremiah MF Kelly

# optim(p0, fn)


#' Step Function
#'
#' This function applies a logistic function to the input and rounds it to the nearest integer.
#'
#' @param x A numeric value.
#' @param t A threshold value.
#'
#' @return A numeric value that is either 0 or 1.
#'
#' @examples
#' H(0.5, 0.5)
#' H(1, 0.5)
#'
#' @export
H <- function(x, t) {
  round(1/(1 + exp(-40 * (x - t))), 0)
}


#' Exponential Model
#'
#' This function models an exponential decay.
#'
#' @param a A numeric vector of parameters.
#' @param x A numeric vector of independent variable values.
#'
#' @return A numeric vector representing the exponential model.
#'
#' @examples
#' a <- c(1, 2, 3)
#' x <- seq(0, 10, by = 0.1)
#' P3(a, x)
#'
#' @export
P3 <- function(a, x) {
	if(missing(x)){
		 return(list(Pn = 3L, Mod = "P3"))
	}
  a[1] + a[2] * exp(-x/a[3])
}

#' Abbreviated MLP Model
#'
#' This function models an abbreviated Mahroo Lamb Pugh model.
#'
#' @param a A numeric vector of parameters.
#' @param x A numeric vector of independent variable values.
#'
#' @return A numeric vector representing the abbreviated MLP model.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' P5c(a, x)
#'
#' @export
P5c <- function(a, x) {
	if(missing(x)){
		return(list(Pn = 5L, Mod = "P5c"))
	}
  a[1] + a[2] * exp(-x/a[3]) + a[4] * (x - a[5]) * H(x, a[5])
}

### Full MLP
P7c <- function(a, x) {
	a[1] + a[2] * exp(-x/a[3]) + a[4] * (x - a[5]) * H(x, a[5]) +
		a[6] * (x - a[7]) * H(x, a[7])
}

#' Residuals
#'
#' This function calculates the residuals of the model for a given set of parameters.
#'
#' @param a A numeric vector of parameters.
#' @param fn The model function.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#'
#' @return A numeric vector representing the residuals.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' Resid(a, P5c, x, y)
#'
#' @export
Resid <- function(a, fn, x, y) {
  y - fn(a, x)
}


#' Least Squares
#'
#' This function calculates the weighted least squares.
#'
#' @param a A numeric vector of parameters.
#' @param fn The model function.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#' @param inv A boolean indicating whether to use inverse weighting.
#'
#' @return A numeric value representing the weighted least squares.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' LeastSq(a, P5c, x, y)
#'
#' @export
LeastSq <- function(a, fn = P5c, x, y, inv = FALSE) {
  resid <- Resid(a, fn, x, y)
  if (inv) {
    wt <- 1/(1 + resid^2)
  } else {
    wt = 1
  }
  sum(wt * resid^2)
}

#' Partial Differential Equation for Parameter 1 (Cone threshold)
#'
#' This function calculates the partial differential equation (PDE) value for the first parameter in the MLP model for dark adaptation.
#'
#' @param a A numeric vector of parameters.
#' @param fn The model function.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#'
#' @return A numeric value representing the PDE value for the first parameter.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' pdf1(a, P5c, x, y)
#'
#' @export
pdf1 <- function(a, fn, x, y) {
  root <- x/x
  -2 * (root %*% Resid(a, fn, x, y))
}

#' Partial Differential Equation for Parameter 2 (Cone Coefficient or intercept)
#'
#' This function calculates the partial differential equation (PDE) value for the second parameter in the MLP model for dark adaptation.
#'
#' @param a A numeric vector of parameters.
#' @param fn The model function.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#'
#' @return A numeric value representing the PDE value for the second parameter.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' pdf2(a, P5c, x, y)
#'
#' @export
pdf2 <- function(a, fn, x, y) {
  root <- exp(-x/a[3])
  -2 * (root %*% Resid(a, fn, x, y))
}

#' Partial Differential Equation for Parameter 3 (Cone time constant or tau)
#'
#' This function calculates the partial differential equation (PDE) value for the third parameter in the MLP model for dark adaptation.
#'
#' @param a A numeric vector of parameters.
#' @param fn The model function.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#'
#' @return A numeric value representing the PDE value for the third parameter.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' pdf3(a, P5c, x, y)
#'
#' @export
pdf3 <- function(a, fn, x, y) {
  root <- exp(-x/a[3]) * a[2] * x/(a[3] * a[3])
  -2 * (root %*% Resid(a, fn, x, y))
}

#' Partial Differential Equation for Parameter 4 (Rod recovery rate or S2)
#'
#' This function calculates the partial differential equation (PDE) value for the fourth parameter in the MLP model for dark adaptation.
#'
#' @param a A numeric vector of parameters.
#' @param fn The model function.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#'
#' @return A numeric value representing the PDE value for the fourth parameter.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' pdf4(a, P5c, x, y)
#'
#' @export
pdf4 <- function(a, fn, x, y) {
  root <- (x - a[5])/(1 + exp(-200 * (x - a[5])))
  -2 * (root %*% Resid(a, fn, x, y))
}

#' Partial Differential Equation for Parameter 5 (Cone rod transition time or alpha)
#'
#' This function calculates the partial differential equation (PDE) value for the fifth parameter in the MLP model for dark adaptation.
#'
#' @param a A numeric vector of parameters.
#' @param fn The model function.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#'
#' @return A numeric value representing the PDE value for the fifth parameter.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' pdf5(a, P5c, x, y)
#'
#' @export
pdf5 <- function(a, fn, x, y) {
  k <- 20
  root = (a[4]/(1 + exp(-2 * k * (x - a[5]))) - a[4] * (x - a[5]) *
          (exp(-2 * k * (x - a[5])) * (-2 * k))/(1 + exp(-2 * k * (x -
                                                                    a[5])))^2)
  2 * (root %*% Resid(a, fn, x, y))
}


#' Gradient Vector
#'
#' This function calculates the gradient vector of the least squares function.
#'
#' @param a A numeric vector of parameters.
#' @param fn The model function.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#'
#' @return A numeric vector representing the gradient of the least squares function.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' Grad(a, P5c, x, y)
#'
#' @export
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
# progGrad(p0, P5c, x, y) this function is not used as of 17/06/24


#' Gradient Descent

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
# findParametersGDPlain(a, fn, x, y, 1)


#' Gradient Descent with Momentum
#'
#' This function performs parameter optimization using gradient descent with momentum for the given model and data.
#'
#' @param a A numeric vector of initial parameter values.
#' @param fn The model function, which takes parameters `a` and independent variable `x`.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#' @param inv A boolean indicating whether to use inverse weighting in the least squares calculation.
#'
#' @return A list containing the optimized parameters, the number of iterations, the noise standard deviation, and the mean squared error.
#'
#' @details This function iteratively updates the parameters using gradient descent with momentum to minimize the least squares error. The velocity term helps accelerate convergence and avoid local minima.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' result <- findParametersGDMomentum(a, P5c, x, y)
#' print(result)
#'
#' @export
findParametersGDMomentum <- function(a, fn, x, y, inv = FALSE) {
  val = list()
  tol <- 1e-06
  eta <- 1/c(1000, 1000, 1000, 10000, 100)
  LS0 <- 1e+07
  velocity = 0
  gamma = 0.9
  for (ii in 1:10000) {
    gradient <- Grad(a, fn, x, y)
    velocity = gamma * velocity + eta * gradient
    a <- a - velocity
    LS1 <- LeastSq(a, fn, x, y, inv)
    del = LS0 - LS1
    LS0 = LS1
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


#' Gradient Descent with Momentum and Boundaries
#'
#' This function performs parameter optimization using gradient descent with momentum and boundary conditions for the given model and data.
#'
#' @param a A numeric vector of initial parameter values.
#' @param fn The model function, which takes parameters `a` and independent variable `x`.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#' @param inv A boolean indicating whether to use inverse weighting in the least squares calculation.
#'
#' @return A list containing the optimized parameters, the number of iterations, the noise standard deviation, and the mean squared error.
#'
#' @details This function iteratively updates the parameters using gradient descent with momentum to minimize the least squares error. The boundary conditions ensure that certain parameters remain within specified limits during optimization.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' result <- findParametersGDMomentumBounded(a, P5c, x, y)
#' print(result)
#'
#' @export
findParametersGDMomentumBounded <- function(a, fn, x, y, inv = FALSE) {
  val = list()
  tol <- 1e-06
  eta <- 1/c(1000, 1000, 1000, 10000, 100)
  LS0 <- 1e+07
  velocity = 0
  gamma = 0.9
  for (ii in 1:10000) {
    gradient <- Grad(a, fn, x, y)
    velocity = gamma * velocity + eta * gradient
    a <- a - velocity
    if (a[5] < 0 | a[5] > max(x)) {
      a[5] <- 0
      a[4] <- 0
    }
    LS1 <- LeastSq(a, fn, x, y, inv)
    del = LS0 - LS1
    LS0 = LS1
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

#' Nesterov Accelerated Gradient Descent
#'
#' This function performs parameter optimization using Nesterov Accelerated Gradient Descent (NAG) for the given model and data.
#'
#' @param a A numeric vector of initial parameter values.
#' @param fn The model function, which takes parameters `a` and independent variable `x`.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#' @param inv A boolean indicating whether to use inverse weighting in the least squares calculation.
#'
#' @return A list containing the optimized parameters, the number of iterations, the noise standard deviation, and the mean squared error.
#'
#' @details This function iteratively updates the parameters using Nesterov Accelerated Gradient Descent to minimize the least squares error. The NAG method helps accelerate convergence by anticipating the future gradient direction.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' result <- findParametersGDNAG(a, P5c, x, y)
#' print(result)
#'
#' @export
findParametersGDNAG <- function(a, fn, x, y, inv = FALSE) {
  val = list()
  tol <- 1e-06
  eta <- 1/c(1000, 1000, 1000, 10000, 10)
  LS0 <- 1e+07
  velocity = 0
  gamma = 0.6
  for (ii in 1:10000) {
    gradient <- Grad(a - gamma * velocity, fn, x, y)
    velocity = gamma * velocity + eta * gradient
    a <- a - velocity
    LS1 <- LeastSq(a, fn, x, y, inv)
    del = LS0 - LS1
    LS0 = LS1
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

#' Compute the Hessian Matrix for the Least Squares Function
#'
#' This function calculates the Hessian matrix for the given model and data.
#' The Hessian matrix is a square matrix of second-order partial derivatives
#' of the function being minimized (the least squares function in this case).
#' It is used to understand the curvature of the function and is important in
#' optimization algorithms.
#'
#' @param a A numeric vector of parameters.
#' @param fn The model function, which takes parameters `a` and independent variable `x`.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#'
#' @return A numeric matrix representing the Hessian matrix of the least squares function
#' with respect to the parameters in `a`.
#'
#' @details The Hessian matrix provides information about the local curvature of the
#' least squares function. Each element in the Hessian matrix represents the second-order
#' partial derivative with respect to the parameters. The diagonal elements indicate
#' the curvature with respect to individual parameters, while the off-diagonal elements
#' show the interaction between different parameters. Smaller off-diagonal values indicate
#' less interaction between parameters. Positive diagonal elements suggest that the function
#' is locally convex in those directions. For the function to be convex at the parameters,
#' the Hessian matrix needs to be positive semi-definite.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' hessian_matrix <- Hessian(a, P5c, x, y)
#' print(hessian_matrix)
#'
#' @export
# Hessian of least squares loss via symbolic double differentiation
# k=20 for sigmoid smoothing — consistent with Grad
Hessian <- function(a, fn, x, y) {
  ct <- a[1]; cc <- a[2]; tau <- a[3]; S2 <- a[4]; alpha <- a[5]
  k <- 20
  L <- expression((y - (ct + cc * exp(-x/tau) + S2 *
        (x - alpha) / (1 + exp(-k * (x - alpha)))))^2)
  params <- c("ct", "cc", "tau", "S2", "alpha")

  Hess <- matrix(0, 5, 5)
  for (ii in 1:5) {
    for (jj in 1:5) {
      Hess[ii, jj] <- sum(eval(D(D(L, params[ii]), params[jj])), na.rm = TRUE)
    }
  }
  Hess
}


#' Assess the Convexity of the Hessian Matrix
#'
#' This function evaluates the convexity of the Hessian matrix by examining its eigenvalues.
#' It determines whether the matrix is positive definite, positive semi-definite, or indefinite.
#'
#' @param hess A numeric matrix representing the Hessian matrix.
#'
#' @return An integer indicating the convexity of the Hessian matrix:
#' \describe{
#'   \item{1}{The Hessian matrix is positive definite.}
#'   \item{0}{The Hessian matrix is positive semi-definite.}
#'   \item{-1}{The Hessian matrix is indefinite.}
#' }
#'
#' @details The function calculates the eigenvalues of the Hessian matrix and uses them to determine its convexity:
#' \itemize{
#'   \item If all eigenvalues are positive, the matrix is positive definite.
#'   \item If all eigenvalues are non-negative (zero or positive), the matrix is positive semi-definite.
#'   \item If any eigenvalue is negative, the matrix is indefinite.
#' }
#'
#' @examples
#' hessian_matrix <- matrix(c(2, -1, -1, 2), nrow = 2)
#' convexity(hessian_matrix)
#'
#' @export
convexity <- function(hess) {
  eigenvalues <- round(eigen(hess)$values, 5)
  is_positive_definite <- all(eigenvalues > 0)
  is_positive_semi_definite <- all(eigenvalues >= 0)
  is_indefinite <- any(eigenvalues < 0)

  if (is_positive_definite) {
    cat("The Hessian matrix is positive definite.\n")
    return(1)
  } else if (is_positive_semi_definite) {
    cat("The Hessian matrix is positive semi-definite.\n")
    return(0)
  } else if (is_indefinite) {
    cat("The Hessian matrix is indefinite.\n")
    return(-1)
  }
}


#' Leave-One-Out Validation for Model Fitting
#'
#' This function performs leave-one-out validation to identify the least informative data point for a given model.
#' It returns the model fit ignoring that point along with the Hessian matrix of the fit at the estimate.
#'
#' @param a A numeric vector of initial parameter values.
#' @param fn The model function, which takes parameters `a` and independent variable `x`.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#' @param inv A boolean indicating whether to use inverse weighting in the least squares calculation (default is `TRUE`).
#'
#' @return A list containing the model fit excluding the least informative point, the Hessian matrix of the fit, and the index of the least informative point.
#'
#' @details The function performs leave-one-out validation by fitting the model multiple times, each time leaving out one observation. It identifies the point whose exclusion results in the lowest noise in the model fit. The function then refits the model excluding this least informative point and computes the Hessian matrix for this fit.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' result <- LOO(a, P5c, x, y)
#' print(result)
#'
#' @export
LOO <- function(a, fn, x, y, inv = TRUE) {
  para <- NULL
  noise <- NULL
  nobs <- length(x)  # Assuming `time` should be `x`
  for(ii in 1:nobs) {
    fit <- findParametersGDPlain(a, fn, x[-ii], y[-ii], inv)
    para <- rbind(para, fit$params)
    noise <- c(noise, fit$noise)
  }

  idx <- which.min(noise)
  fit <- findParametersGDPlain(a, fn, x[-idx], y[-idx], inv = TRUE)
  hess <- Hessian(para[idx,], fn, x[-idx], y[-idx])
  fit$hessian <- hess
  fit$least_informative_point <- idx

  fit
}

#' Confidence Intervals and P-values for Model Parameter Estimates
#'
#' Computes confidence intervals and p-values for model parameters using the
#' Hessian of the least squares loss, evaluated at the final parameter estimates.
#'
#' @param a A numeric vector of final parameter estimates.
#' @param fn The model function, which takes parameters `a` and independent variable `x`.
#' @param x A numeric vector of independent variable values.
#' @param y A numeric vector of dependent variable values.
#' @param alpha Significance level for confidence intervals and p-values (default is \code{0.05}).
#'
#' @return A data frame containing the parameter names, estimates, standard errors,
#' lower and upper confidence interval bounds, two-tailed p-values, and a significance
#' indicator (\code{*} if the interval excludes zero, \code{-} if it includes zero).
#' The p-value for \code{tau} is \code{NA} — see Details.
#'
#' @details All confidence intervals and p-values are derived using the delta method,
#' linearising the nonlinear model around the final parameter estimates via inversion
#' of the Hessian of the least squares loss. This is valid when parameters have been
#' finalised using inverse least squares weighting.
#'
#'
#' If the Hessian is near-singular (e.g. due to parameter insensitivity in \code{a[3]}),
#' \code{MASS::ginv()} is used in place of \code{solve()} for stability.
#'
#' @examples
#' a <- c(1, 2, 3, 4, 5)
#' x <- seq(0, 10, by = 0.1)
#' y <- 3 + 2 * exp(-x / 3) + rnorm(length(x))
#' fit <- findParametersGDPlain(a, P5c, x, y, inv = TRUE)
#' param_ci(fit$params, P5c, x, y)
#'
#' @export
param_ci <- function(a, fn, x, y, alpha = 0.05) {
  a <- as.vector(a)
  H <- Hessian(a, fn, x, y)
  cov_mat <- tryCatch(
    solve(H),
    error = function(e) {
      warning("Hessian is near-singular, using generalised inverse")
      MASS::ginv(H)
    }
  )
  se <- sqrt(abs(diag(cov_mat)))
  t_crit <- qt(1 - alpha / 2, df = length(x) - 5)

  # Delta method CIs for all parameters
  lower <- a - t_crit * se
  upper <- a + t_crit * se

  # tau (a[3]) — CI computed in log space for valid positive bounds
  # SE(log(tau)) ≈ SE(tau) / tau via delta method
  log_tau_se <- se[3] / a[3]
  lower[3]   <- a[3] * exp(-t_crit * log_tau_se)
  upper[3]   <- a[3] * exp( t_crit * log_tau_se)


  data.frame(
    param    = c("ct", "cc", "tau", "S2", "alpha"),
    estimate = a,
    se       = se,
    lower    = lower,
    upper    = upper,
    sig      = ifelse(sign(lower) == sign(upper), "*", "-")
  )
}