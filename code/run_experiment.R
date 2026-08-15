run_experiment <- function(job, x, ct_fixed, cc_fixed, tau_fixed, analysis_version) {

	sim <- generateSimulationFromRow(job = job, time = x, ct = ct_fixed, cc = cc_fixed, tau = tau_fixed, analysis_version = analysis_version)

	meta <- sim$metadata

	x <- sim$data$time
	y <- sim$data$threshold_observed

	# P5c
	p0 <- findInitialParametersProfiled(x, y)

	ip0hO <- findParametersGDPlain(p0$best, P5c, x, y, TRUE)

	op0hO <- findParametersGDPlain(ip0hO$params, P5c, x, y, FALSE)

	p5_rss <- sum((y - P5c(op0hO$params, x))^2)

	# Inference
	J <- tryCatch(P5cJacobianDiagnostics(op0hO$params, x), error = function(e) {

		message("Jacobian failed: ", conditionMessage(e))

		list(singular_values_scaled = NA_real_, condition_J_scaled = NA_real_, zero_columns = NA)
	})

	ci0 <- tryCatch(P5cConfidenceIntervals(params = op0hO$params, x = x, y = y), error = function(e) {

		message("CI calculation failed: ", conditionMessage(e))

		data.frame(param = c("ct", "cc", "tau", "S2", "alpha"), estimate = drop(op0hO$params), se = NA_real_, lower = NA_real_, upper = NA_real_, 
			covers_zero = NA)
	})

	# P3
	p3_result <- fitP3(x, y)
	p3_p <- drop(p3_result$params)

	p3_rss <- sum((y - P3(p3_result$params, x))^2)

	# Model comparison
	aic_p3 <- calculateAICc(rss = p3_rss, n = length(x), n_params = 3L)

	aic_p5 <- calculateAICc(rss = p5_rss, n = length(x), n_params = 5L)

	# One-row result
	make_result_row(ii, meta = meta, p0 = p0, op0hO = op0hO, J = J, ci0 = ci0, p3_result = p3_result, p3_p = p3_p, aic_p3 = aic_p3, 
		aic_p5 = aic_p5)
}