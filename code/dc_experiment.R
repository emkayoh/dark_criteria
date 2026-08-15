rm(list = ls())
run_stamp <- format(Sys.time(), "%Y-%m-%d_%H%M")
results_file <- file.path(
    "~/Dropbox/Mumac_/CODE_1/dark_criteria/results",
    paste0("dc_experiment_results_", run_stamp, ".csv")
)

# Find P5c using the new profiling methodology

source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_gradient_Descent_Functions.R")
# Experimental parameters 
ct_fixed <- -1.7
cc_fixed <- 2
tau_fixed <- 0.6
analysis_version = 'cd993fd'
S2_values <- c(-0.01, -0.05, -0.10, -0.15,-0.20, -0.25, -0.30)
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
source('~/Dropbox/Mumac_/CODE_1/dark_criteria/code/run_experiment.R')
source('~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_save_results.R')

# initiation
test_df <- readRDS("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_test_df")
x <- test_df$time
for (ii in 1:36000){
	
result_row <- run_experiment(job <- experiment_grid[ii, ], x, ct_fixed, cc_fixed, tau_fixed, analysis_version)

append_result_row(result_row,results_file)
}