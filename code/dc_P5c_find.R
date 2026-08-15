rm(list = ls())

# Find P5c using the new profiling methodology

source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_gradient_Descent_Functions.R")
# Experimental parameters 
ct_fixed <- -1.7
cc_fixed <- 2
tau_fixed <- 0.6
S2_values <- c(-0.05, -0.10, -0.15,-0.20, -0.25, -0.30)
alpha_values <- c(3, 5, 7, 9)
noise_values <- c(0, 0.05, 0.10, 0.15, 0.20, 0.30)
n_replicates <- 250L
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_experiment_grid.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_simulateData.R")
# methods under test
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_findInitialParametersProfiled.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_Jacobian.R")
source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_P3_find.R")
# storage
source('~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_result_row.R')

# initiation
test_df <- readRDS("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_test_df")
x <- test_df$time

noexs <- length(experiment_grid[,1])
ii <- 1
# Experimental loop for ii in length experiment_grid
job <- experiment_grid[ii, ]

sim <- generateSimulationFromRow(job = job, time = x, ct = ct_fixed, cc = cc_fixed, tau = tau_fixed, analysis_version = "cd993fd")

meta <- sim$metadata


x <- sim$data$time
y <- sim$data$threshold_observed

# Start parameters
p0 <- findInitialParametersProfiled(x, y)
ip0hO <- findParametersGDPlain(p0$best, P5c, x, y, TRUE)
op0hO <- findParametersGDPlain(ip0hO$params, P5c, x, y, FALSE)

p5_rss <- sum((y - P5c(op0hO$params, x))^2)
J <- P5cJacobianDiagnostics(op0hO$params, x)
ci0 <- P5cConfidenceIntervals(params = op0hO$params, x = x, y = y)

p3_result <- fitP3(x, y)
p3_p <- drop(p3_result$params)

p3_rss <- sum((y - P3(p3_result$params, x))^2)

aic_p3 <- calculateAICc(rss = p3_rss, n = length(x), n_params = 3L)
aic_p5 <- calculateAICc(rss = p5_rss, n = length(x), n_params = 5L)

result_row <- make_result_row(
    meta      = meta,
    p0        = p0,
    op0hO     = op0hO,
    J         = J,
    ci0       = ci0,
    p3_result = p3_result,
    p3_p      = p3_p,
    aic_p3    = aic_p3,
    aic_p5    = aic_p5
)

result_row