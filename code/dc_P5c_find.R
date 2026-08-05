# Find P5 using Rapida methodology
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_gradient_Descent_Functions.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_Huber_loss.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_Oldar.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_P3_find.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_findInitialParameters.R")
starttime <- system.time({
# test data
test_df <- readRDS("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_test_df")
x <- test_df$time
y <- test_df$thrs

# # x <- sim$data$time
# y <- sim$data$threshold_observed

# Start parameters
# derived
# p0 <- findInitialParameters(x, y, GLOBAL_PARAM_GRID)
p0 <- findInitialParametersProfiled(x,y)


# Huber GD
p0h <- fitP5cPseudoHuber(p0$best, x, y)

# Scan for local minima
# Oldar
p0hO <- oldar(p0h, x, y)
# GD plain with inv
# return to ols, allow outliers to influence
ip0hO <- findParametersGDPlain(p0hO$params, P5c, x, y, TRUE)


# GDplain
# then finish with OLS to allow comparison with P3 process.
op0hO <- findParametersGDPlain(ip0hO$params, P5c, x, y)


# Ci intervals
ci0 <- P5cConfidenceIntervals(
     params = op0hO$params,
     x = x,
     y = y
)
# hessian
hess_g <- P5cRSSHessian(op0hO$params, x)
hess_n <- P5cNumericalHessian(op0hO$params, x, y)
rss <- sum((y - P5c(op0hO$param, x))^2)

# Compare to P3
p3_result <- fitP3(x, y0)

p3_result$params
p3_result$RSS
p3_result$converged


aic_p3 <- calculateAICc(rss = p3_result$RSS, n = length(x), n_params = 3L)

aic_p5 <- calculateAICc(rss = rss, n = length(x), n_params = 5L)


aic_p3
aic_p5

})

starttime

par(las = 1, bty = "n")
plot(x, y, ylim = c(-4.8, 0))

lines(x, P5c(p0$best, x), col = 2)
lines(x, P5c(p0h$params, x), col = 2, lty = 2, lwd = 2)
lines(x, P5c(ip0hO$params, x), col = 2, lty = 2, lwd = 2)

lines(x, P5c(ci0[, 4], x))
lines(x, P5c(ci0[, 5], x))


lines(x, P3(p3_result$params, x), col = 3)
lines(x, P5c(p0$best, x), col = 4)