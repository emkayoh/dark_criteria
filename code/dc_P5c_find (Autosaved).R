rm(list = ls())
# Find P5 using Rapida methodology
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_gradient_Descent_Functions.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_Huber_loss.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_Oldar.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_P3_find.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_findInitialParameters.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_findInitialParametersProfiled.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_P5cPredictionIntervals.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_Jacobian.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_simulateData.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_experiment_grid.R")
# starttime <- system.time({
# test data
test_df <- readRDS("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_test_df")
x <- test_df$time
# y <- test_df$thrs

# set.seed(1234)
plot <- TRUE

job <- experiment_grid[35932, ]

sim <- generateSimulationFromRow(job = job, time = x, ct = ct_fixed, cc = cc_fixed, tau = tau_fixed, analysis_version = "cd993fd")

sim$metadata
head(sim$data)

x <- sim$data$time
y <- sim$data$threshold_observed

# nobs <- length(y)
# y <- P5c(c(-2, 2, 0.7, -0.1, 3), x)
# y <- y + rnorm(nobs, 0, 0.5)


# Start parameters
# derived
# p0 <- findInitialParameters(x, y, GLOBAL_PARAM_GRID)
p0 <- findInitialParametersProfiled(x, y)
p02<- findInitialParametersProfiled(x, y, tau_range = seq(p0$best[3]/2, 2*p0$best[3], length.out = 40L), alpha_range = seq(p0$best[5]-1, p0$best[5]+1, length.out = 80L))


# Huber GD
p0h <- fitP5cPseudoHuber(p0$best, x, y)

# Scan for local minima
# Oldar
p0hO <- oldar(p0h, x, y) # now uses enhanced Huber 
# GD plain with inv
# return to ols, allow outliers to influence
ip0hO <- findParametersGDPlain(p0hO$params, P5c, x, y, TRUE)


# GDplain
# then finish with OLS to allow comparison with P3 process.
op0hO <- findParametersGDPlain(ip0hO$params, P5c, x, y, FALSE)
p5_rss <- sum((y - P5c(op0hO$params, x))^2)

# Inference
# Jacobian 
J <- P5cJacobianDiagnostics(op0hO$params, x)
J
# Ci intervals
ci0 <- P5cConfidenceIntervals(params = op0hO$params, x = x, y = y)




# Compare to P3
p3_result <- fitP3(x, y)
p3_result$rss
p3_result$params


p5_rss <- sum((y - P5c(op0hO$param, x))^2)
p3_rss <- sum((y - P3(p3_result$params, x))^2)

aic_p3 <- calculateAICc(rss = p3_rss, n = length(x), n_params = 3L)
aic_p5 <- calculateAICc(rss = p5_rss, n = length(x), n_params = 5L)


aic_p3
aic_p5
ci0


if (plot) {
	piv <- P5cPredictionIntervals(op0hO$params, x, y)
	par(las = 1, bty = "n")
	plot(x, y, ylim = c(-4.8, 0))

	lines(x, P5c(p0$best, x), col = 2) # profiled least squares
	lines(x, P5c(p02$best, x), col = 5) # profiled least squares, second
	lines(x, P5c(p0h$params, x), col = 2, lty = 2, lwd = 2) # after Huber loss function
	lines(x, P5c(ip0hO$params, x), col = 2, lty = 2, lwd = 2) # inverse square weighted
	lines(x, P5c(op0hO$params, x), col = 2, lty = 2, lwd = 2) # OLS to allow AICc comparisons

	lines(x, piv$lower, lty = 2)
	lines(x, piv$upper, lty = 2)


	lines(x, P3(p3_result$params, x), col = 3)
	lines(x, P3(p0$best, x), col = 4)
	lines(x, P5c(p0$best, x), col = 4)
}