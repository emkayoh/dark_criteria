P5cJacobian <- function(a, x) {
	ct <- a[1L]
	cc <- a[2L]
	tau <- a[3L]
	S2 <- a[4L]
	alpha <- a[5L]

	step <- as.numeric(x >= alpha)
	exponential <- exp(-x/tau)

	cbind(ct = 1, cc = exponential, tau = cc * exponential * x/tau^2, S2 = (x - alpha) * step, alpha = -S2 * 
		step)
}

P5cRSSHessian <- function(a, x) {
	J <- P5cJacobian(a, x)
	2 * crossprod(J)
}

P5cNumericalHessian <- function(a, x, y) {
    objective <- function(params) {
        residuals <- y - P5c(params, x)
        sum(residuals^2)
    }

    numDeriv::hessian(
        func = objective,
        x = a
    )
}



P5cConfidenceIntervals <- function(params, x, y, level = 0.95) {
	params <- as.numeric(params)
	names(params) <- c("ct", "cc", "tau", "S2", "alpha")

	fitted <- P5c(params, x)
	residuals <- y - fitted

	n <- length(y)
	p <- length(params)
	residual_df <- n - p

	rss <- sum(residuals^2)
	sigma2 <- rss/residual_df

	J <- P5cJacobian(params, x)
	information <- crossprod(J)

	eigenvalues <- eigen(information, symmetric = TRUE, only.values = TRUE)$values

	condition_number <- kappa(information)

	covariance <- tryCatch(sigma2 * solve(information), error = function(e) {
		sigma2 * MASS::ginv(information)
	})

	se <- sqrt(diag(covariance))
	critical <- qt(1 - (1 - level)/2, df = residual_df)

	lower <- params - critical * se
	upper <- params + critical * se

	structure(data.frame(param = names(params), estimate = params, se = se, lower = lower, upper = upper, 
		covers_zero = lower <= 0 & upper >= 0, row.names = NULL), RSS = rss, sigma2 = sigma2, residual_df = residual_df, 
		condition_number = condition_number, information_eigenvalues = eigenvalues, covariance = covariance, 
		jacobian = J)
}


ci_check <- P5cConfidenceIntervals(params = op0hO$params, x = x, y = y)

ci_check

attr(ci_check, "condition_number")
attr(ci_check, "information_eigenvalues")

J <- P5cJacobian(op0hO$params, x)
information <- crossprod(J)

eigen(information, symmetric = TRUE)$values
kappa(information)

scaledJacobianCondition <- function(J) {
	column_norms <- sqrt(colSums(J^2))

	if (any(!is.finite(column_norms)) || any(column_norms == 0)) {
		return(Inf)
	}

	J_scaled <- sweep(J, MARGIN = 2L, STATS = column_norms, FUN = "/")

	kappa(crossprod(J_scaled))
}


scaled_condition_number <- scaledJacobianCondition(J)

scaled_condition_number