# dc_run_experiment_driver.R  (JMFK)
# needs a tau as argument and is run from CLI with 
# Rscript dc_run_experiment_driver.R 0.6 > tau_0.6.log 2>&1 &
#   Rscript dc_run_experiment_driver.R 1.2 > tau_1.2.log 2>&1 & 
#.  Rscript dc_run_experiment_driver.R 1.8 > tau_1.8.log 2>&1 & 
#   Rscript dc_run_experiment_driver.R 2.4 > tau_2.4.log 2>&1 & 
#   wait echo "all four sets done"

# Driver for one dark criteria experiment set.
# Revised 2026-08-18: self-describing output filenames (tau tag, seconds,
# PID), collision guard, and analysis_version derived from git rather than
# hardcoded.

rm(list = ls())

# -------------------------------------------------- 
# RNG configuration # -------------------------------------------------- 
# Pinned so that simulated data are identical across machines and R 
# versions (Mac 4.5.2, Titan 4.3.3). Verified bit-identical by comparing 
# sprintf("%a", rnorm(5)) on both platforms, 19 August 2026. 

RNGversion("4.3.3")

# --------------------------------------------------
# Paths
# --------------------------------------------------
# Project root differs by machine; set DC_ROOT in the environment to
# override. Mac: ~/Dropbox/Mumac_/CODE_1/dark_criteria
# Titan: ~/dark_criteria
project_root <- Sys.getenv("DC_ROOT", unset = path.expand("~/dark_criteria"))

code_dir    <- file.path(project_root, "code")
results_dir <- file.path(project_root, "results")

if (!dir.exists(code_dir)) {
    stop("code_dir not found: ", code_dir,
         " (set DC_ROOT to the project root)")
}
if (!dir.exists(results_dir)) {
    dir.create(results_dir, recursive = TRUE)
}

# --------------------------------------------------
# Source code
# --------------------------------------------------

source(file.path(code_dir, "dc_gradient_Descent_Functions.R"))

source(file.path(code_dir, "dc_simulateData.R"))

source(file.path(code_dir, "dc_findInitialParametersProfiled.R"))

source(file.path(code_dir, "dc_Jacobian.R"))

source(file.path(code_dir, "dc_P3_find.R"))

source(file.path(code_dir, "dc_result_row.R"))

source(file.path(code_dir, "run_experiment.R"))

source(file.path(code_dir, "dc_save_results.R"))


# --------------------------------------------------
# Experimental parameters
# --------------------------------------------------

ct_fixed <- -1.7
cc_fixed <- 2

# tau comes from the command line, not from an edit to this file, so
# running a different set requires no commit and all sets carry the same
# code hash:   Rscript dc_run_experiment_driver.R 1.2
# When sourced interactively, define TAU_ARG before source(); otherwise
# the default below applies.
args <- commandArgs(trailingOnly = TRUE)
tau_fixed <- if (length(args) >= 1L) {
	as.numeric(args[1L])
} else if (exists("TAU_ARG")) {
	as.numeric(TAU_ARG)
} else {
	1.2
}
stopifnot(is.finite(tau_fixed), tau_fixed > 0)

# Analysis version from the repository itself, so results always carry the
# hash of the code that produced them. Falls back loudly rather than
# silently if git is unavailable.
analysis_version <- tryCatch(system2("git", c("-C", shQuote(path.expand(code_dir)), "rev-parse", "--short", "HEAD"), stdout = TRUE, 
	stderr = TRUE), error = function(e) NA_character_)

if (length(analysis_version) != 1L || is.na(analysis_version) || !grepl("^[0-9a-f]{7,}$", analysis_version)) {
	stop("Could not determine analysis_version from git; refusing to run ", "with an unattributed code version.")
}

dirty <- length(system2("git", c("-C", shQuote(path.expand(code_dir)), "status", "--porcelain"), stdout = TRUE)) > 0L

if (dirty) {
	stop("Repository has uncommitted changes; commit before running so ", "analysis_version (", analysis_version, ") matches the code.")
}

S2_values <- c(0, -0.01, -0.05, -0.1, -0.15, -0.2, -0.25, -0.3)

alpha_values <- c(3, 5, 7, 9)

noise_values <- c(0, 0.05, 0.1, 0.15, 0.2, 0.3)

n_replicates <- 250L

# S2_values <- c(-0.10)
# alpha_values <- c(5)
# noise_values <- c(0.1)
# n_replicates <- 1L


# --------------------------------------------------
# Run identification / output
# --------------------------------------------------
# Filename carries the tau set, a seconds-resolution stamp, and the PID:
# concurrent launches can never share a file, and a file's identity is
# legible from ls alone.

run_stamp <- format(Sys.time(), "%Y-%m-%d_%H%M%S")

results_file <- file.path(results_dir, sprintf("dc_experiment_results_tau%s_%s_pid%d.csv", paste(format(tau_fixed), collapse = "-"), 
	run_stamp, Sys.getpid()))
	
source(file.path(code_dir, "dc_envCap.R"))
envCap(dir = results_dir, code_dir = code_dir,
       notes = sprintf("tau = %s", format(tau_fixed)))

# Should never trigger with seconds + PID in the name; if it ever does,
# something is wrong that you want to know about.
if (file.exists(results_file)) {
	stop("Results file already exists: ", results_file)
}

message("Writing results to: ", results_file)
message("Analysis version:   ", analysis_version)


# --------------------------------------------------
# Build experimental grid
# --------------------------------------------------

source(file.path(code_dir, "dc_experiment_grid.R"))


# --------------------------------------------------
# Time vector
# --------------------------------------------------

test_df <- readRDS(file.path(code_dir, "dc_test_df"))

x <- test_df$time


# --------------------------------------------------
# Run experiments
# --------------------------------------------------

n_experiments <- nrow(experiment_grid)

for (ii in seq_len(n_experiments)) {

	job <- experiment_grid[ii, ]

	result_row <- run_experiment(job = job, experiment_index = ii, x = x, ct_fixed = ct_fixed, cc_fixed = cc_fixed, tau_fixed = tau_fixed, 
		analysis_version = analysis_version)

	append_result_row(result_row, results_file)
}

message("Done: ", n_experiments, " experiments written to ", basename(results_file))