rm(list = ls())


# --------------------------------------------------
# Run identification / output
# --------------------------------------------------

run_stamp <- format(Sys.time(), "%Y-%m-%d_%H%M")

results_file <- file.path("~/Dropbox/Mumac_/CODE_1/dark_criteria/results", paste0("dc_experiment_results_", run_stamp, ".csv"))

# Writer side: make the output name unique per process and self-describing
out_name <- sprintf("dc_experiment_results_tau%s_%s_pid%d.csv",
                    paste(TAU_SET, collapse = "-"),
                    format(Sys.time(), "%Y-%m-%d_%H%M%S"),
                    Sys.getpid())

# --------------------------------------------------
# Source code
# --------------------------------------------------

source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_gradient_Descent_Functions.R")

source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_simulateData.R")

source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_findInitialParametersProfiled.R")

source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_Jacobian.R")

source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_P3_find.R")

source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_result_row.R")

source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/run_experiment.R")

source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_save_results.R")


# --------------------------------------------------
# Experimental parameters
# --------------------------------------------------

ct_fixed <- -1.7
cc_fixed <- 2
tau_fixed <- 1.2 # fourth of three experiments varying tau

analysis_version <- "5bb3cf4"

S2_values <- c(0, -0.01, -0.05, -0.10, -0.15, -0.2, -0.25, -0.3)

alpha_values <- c(3, 5, 7, 9)

noise_values <- c(0, 0.05, 0.1, 0.15, 0.2, 0.3)

n_replicates <- 250L

# S2_values <- c(-0.10)
# alpha_values <- c(5)
# noise_values <- c(0.1)
# n_replicates <- 1L


# --------------------------------------------------
# Build experimental grid
# --------------------------------------------------

source("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_experiment_grid.R")


# --------------------------------------------------
# Time vector
# --------------------------------------------------

test_df <- readRDS("~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_test_df")

x <- test_df$time


# --------------------------------------------------
# Run experiments
# --------------------------------------------------

n_experiments <-  nrow(experiment_grid)

for (ii in seq_len(nrow(experiment_grid))) {

	job <- experiment_grid[ii, ]

	result_row <- run_experiment(job = job, experiment_index = ii, x = x, ct_fixed = ct_fixed, cc_fixed = cc_fixed, tau_fixed = tau_fixed, 
		analysis_version = analysis_version)

	append_result_row(result_row, results_file)
}