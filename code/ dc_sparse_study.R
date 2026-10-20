# dc_sparse_study.R  (JMFK)
# Sampling density study.
#
# Question: how much of the fitting performance reported for this method
# depends on the density of the threshold data, as distinct from the
# fitting method itself?
#
# Motivation. De Silva et al. (2022) report rod intercept time prediction
# errors of 19.1 +/- 18.6 minutes for a classical five-parameter fit, on
# AdaptDx data sampled at roughly one threshold per minute with staircase
# quantisation. Our protocol samples about four per minute from a
# continuous ramp. Their comparator's poor showing therefore confounds
# method with sampling density, and the confound cannot be separated from
# their published results.
#
# Design. Simulate at our density, then thin the same simulated curve to
# lower densities and refit. Because the underlying curve and its noise
# are identical across densities within a replication, the comparison
# isolates sampling density exactly.
#
# Thinning is by TIME, not by index, so retained points span the curve
# evenly. Several offsets are used per curve so that a single unlucky
# draw cannot drive the result.
#
# This is the simulation arm. The real-data arm (thinning archival RapiDA
# curves and refitting old paradigm vs VarPro) is a separate study.

rm(list = ls())

RNGversion("4.3.3") # matched to the main experiment

library(dplyr)
library(tidyr)
library(ggplot2)

## ---- paths and sources ---------------------------------------------------

project_root <- Sys.getenv("DC_ROOT", unset = path.expand("~/dark_criteria"))
code_dir <- file.path(project_root, "code")
results_dir <- file.path(project_root, "results")

source(file.path(code_dir, "dc_gradient_Descent_Functions.R"))
source(file.path(code_dir, "dc_findInitialParametersProfiled.R"))
source(file.path(code_dir, "dc_Jacobian.R"))
source(file.path(code_dir, "dc_P3_find.R"))

## ---- experiment configuration -------------------------------------------

ct_fixed <- -1.7
cc_fixed <- 2
tau_fixed <- 1.2 # single cone regime; loop outside for others
S2_values <- c(0, -0.01, -0.05, -0.1, -0.15, -0.2, -0.25, -0.3)
alpha_values <- c(3, 5, 7, 9)
noise_values <- c(0.05, 0.1, 0.15, 0.2, 0.3)
n_replicates <- 100L # lower than the main experiment; raise if needed


# Sampling regimes, expressed as the interval between retained thresholds.
# 0.25 min  = 4 per minute  = our continuous ramp protocol
# 0.50 min  = 2 per minute
# 1.00 min  = 1 per minute  = AdaptDx-like
# 2.00 min  = 1 per two minutes
thin_intervals <- c(0.25, 0.5, 1, 2)

# Offsets within each interval, so the retained grid is not always
# anchored at t = 0.
n_offsets <- 3L

test_duration <- 15 # minutes

## ---- model ---------------------------------------------------------------

p5c <- function(t, ct, cc, tau, S2, alpha) {
	ct + cc * exp(-t/tau) + S2 * pmax(t - alpha, 0)
}

## ---- thinning ------------------------------------------------------------
# Retain the observation nearest each target time. Thinning by time rather
# than by index keeps the retained points evenly spread even if the dense
# grid is irregular.

thin_by_time <- function(t_dense, interval, offset = 0) {
	targets <- seq(offset, max(t_dense), by = interval)
	idx <- vapply(targets, function(tt) which.min(abs(t_dense - tt)), integer(1))
	sort(unique(idx))
}

## ---- one replication at one density -------------------------------------

fit_once <- function(t_obs, y_obs, truth) {

	out <- list(n_obs = length(t_obs), ct = NA_real_, cc = NA_real_, tau = NA_real_, S2 = NA_real_, alpha = NA_real_, rss = NA_real_, boundary = NA_character_, S2_ci_excludes_zero = NA, 
		S2_se = NA_real_, alpha_ci_covers = NA, S2_ci_covers = NA, rit_fitted = NA_real_, converged = NA)

	p0 <- tryCatch(findInitialParametersProfiled(t_obs, y_obs), error = function(e) NULL)
	if (is.null(p0)) 
		return(out)

	b <- p0$best
	out$ct <- unname(b["ct"])
	out$cc <- unname(b["cc"])
	out$tau <- unname(b["tau"])
	out$S2 <- unname(b["S2"])
	out$alpha <- unname(b["alpha"])
	out$rss <- p0$RSS
	out$boundary <- p0$S2_boundary
	out$converged <- isTRUE(p0$converged)

	# Fitted rod intercept time, for comparison with the literature.
	# crit is the criterion threshold; set to match the convention being
# compared against and state it explicitly in any write-up.
crit <- -3
	if (is.finite(out$S2) && out$S2 < 0) {
		out$rit_fitted <- (crit - out$ct)/out$S2 + out$alpha
	}

	# Delta-method interval for S2, where the fit is interior.
	if (identical(out$boundary, "interior")) {
		J <- tryCatch(P5cJacobian(c(out$ct, out$cc, out$tau, out$S2, out$alpha), t_obs), error = function(e) NULL)
		if (!is.null(J)) {
			n <- length(y_obs)
			p <- 5L
			if (n > p) {
				s2hat <- out$rss/(n - p)
				V <- tryCatch(s2hat * solve(crossprod(J)), error = function(e) NULL)
				if (!is.null(V) && all(is.finite(diag(V))) && all(diag(V) >= 0)) {
					se <- sqrt(diag(V))
					tq <- qt(0.975, df = n - p)
					lo <- c(out$ct, out$cc, out$tau, out$S2, out$alpha) - tq * se
					hi <- c(out$ct, out$cc, out$tau, out$S2, out$alpha) + tq * se
					out$S2_se <- se[4]
					out$S2_ci_excludes_zero <- (hi[4] < 0) || (lo[4] > 0)
					out$S2_ci_covers <- lo[4] <= truth["S2"] && hi[4] >= truth["S2"]
					out$alpha_ci_covers <- lo[5] <= truth["alpha"] && hi[5] >= truth["alpha"]
				}
			}
		}
	}

	out
}

## ---- main loop -----------------------------------------------------------

t_dense <- seq(0, test_duration, by = 0.25) # 4 per minute

grid <- expand.grid(S2_real = S2_values, alpha_real = alpha_values, noise_sd = noise_values, rep = seq_len(n_replicates), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)

message("Conditions: ", nrow(grid), "   densities: ", length(thin_intervals), "   offsets: ", n_offsets, "   total fits: ", nrow(grid) * length(thin_intervals) * n_offsets)

rows <- vector("list", nrow(grid) * length(thin_intervals) * n_offsets)
k <- 0L

for (i in seq_len(nrow(grid))) {

	g <- grid[i, ]
	truth <- c(ct = ct_fixed, cc = cc_fixed, tau = tau_fixed, S2 = g$S2_real, alpha = g$alpha_real)

	# Seed derived from the condition and replicate, never from loop
	# position, so results are independent of execution order.
seed <- as.integer(1e+06 + which(S2_values == g$S2_real) * 1e+05 + which(alpha_values == g$alpha_real) * 10000 + which(noise_values == g$noise_sd) * 1000 + g$rep)
	set.seed(seed)

	y_dense <- p5c(t_dense, ct_fixed, cc_fixed, tau_fixed, g$S2_real, g$alpha_real) + rnorm(length(t_dense), sd = g$noise_sd)

	for (iv in thin_intervals) {
		offs <- if (iv == min(thin_intervals)) 
			0
		else seq(0, iv, length.out = n_offsets + 1L)[seq_len(n_offsets)]

		for (off in offs) {
			idx <- thin_by_time(t_dense, iv, off)
			if (length(idx) < 6L) 
				next

			f <- fit_once(t_dense[idx], y_dense[idx], truth)

			k <- k + 1L
			rows[[k]] <- data.frame(seed = seed, rep = g$rep, S2_real = g$S2_real, alpha_real = g$alpha_real, noise_sd = g$noise_sd, interval = iv, offset = off, per_minute = 1/iv, 
				as.data.frame(f, stringsAsFactors = FALSE), stringsAsFactors = FALSE)
		}
	}

	if (i%%200L == 0L) 
		message("  ", i, " / ", nrow(grid))
}

res <- as_tibble(bind_rows(rows[seq_len(k)]))

## ---- true RIT for comparison --------------------------------------------

crit <- -3
res <- mutate(res, rit_true = ifelse(S2_real < 0, (crit - ct_fixed)/S2_real + alpha_real, NA_real_))

## ---- summaries -----------------------------------------------------------

# Parameter recovery by sampling density.
recovery <- arrange(summarise(filter(res, S2_real < 0, boundary == "interior"), n = n(), S2_bias = median(S2 - S2_real), S2_mad = median(abs(S2 - S2_real)), alpha_mad = median(abs(alpha - 
	alpha_real)), tau_mad = median(abs(tau - tau_fixed)), rit_mad = median(abs(rit_fitted - rit_true), na.rm = TRUE), rit_p90 = quantile(abs(rit_fitted - rit_true), 0.9, na.rm = TRUE), 
	.by = c(per_minute, noise_sd)), desc(per_minute), noise_sd)
print(recovery, n = 40)

# Detection by sampling density: sensitivity on true biphasic, false
# positives on the null arm. Same policy as the main analysis.
det <- mutate(res, detected = case_when(boundary == "S2_upper" ~ FALSE, is.na(S2_ci_excludes_zero) ~ FALSE, .default = S2_ci_excludes_zero), true_biphasic = S2_real < 0)

detection <- arrange(summarise(det, rate = mean(detected), n = n(), .by = c(per_minute, noise_sd, true_biphasic)), true_biphasic, desc(per_minute), noise_sd)
print(detection, n = 60)

# 90% detection thresholds by density, masked where unattainable.
inv90 <- function(m) unname((qlogis(0.9) - coef(m)[1])/coef(m)[2])

ceilings <- summarise(summarise(filter(det, true_biphasic), p = mean(detected), .by = c(per_minute, noise_sd, S2_real)), ceiling = max(p), .by = c(per_minute, noise_sd))

thresholds <- arrange(mutate(left_join(ungroup(group_modify(group_by(filter(det, true_biphasic), per_minute, noise_sd), function(g, ...) tibble(S2_90 = tryCatch(inv90(glm(detected ~ 
	abs(S2_real), binomial, data = g)), error = function(e) NA_real_)))), ceilings, by = c("per_minute", "noise_sd")), S2_90 = ifelse(ceiling < 0.9, NA_real_, S2_90)), desc(per_minute), 
	noise_sd)
print(thresholds, n = 40)

## ---- figures -------------------------------------------------------------

p_thresh <- ggplot(thresholds, aes(noise_sd, S2_90, colour = factor(per_minute))) + geom_line() + geom_point() + labs(x = "threshold noise (log units)", y = expression(paste("|S2| detected on 90% of occasions")), 
	colour = "thresholds\nper minute") + theme_minimal()
print(p_thresh)

p_rit <- ggplot(recovery, aes(noise_sd, rit_mad, colour = factor(per_minute))) + geom_line() + geom_point() + labs(x = "threshold noise (log units)", y = "median |RIT error| (min)", 
	colour = "thresholds\nper minute") + theme_minimal()
print(p_rit)

ggsave(file.path(results_dir, sprintf("sparse_thresholds_tau%s.pdf", format(tau_fixed))), p_thresh, width = 7, height = 4.5)
ggsave(file.path(results_dir, sprintf("sparse_rit_error_tau%s.pdf", format(tau_fixed))), p_rit, width = 7, height = 4.5)

saveRDS(res, file.path(results_dir, sprintf("sparse_study_tau%s_%s.rds", format(tau_fixed), format(Sys.time(), "%Y-%m-%d_%H%M%S"))))

## ---- what to look for ----------------------------------------------------
# 1. How far do detection thresholds degrade from 4/min to 1/min? That is
#    the size of the sampling contribution, method held constant.
# 2. Does RIT error at 1/min approach the 19.1 +/- 18.6 min reported by
#    De Silva? If it does, their comparator's failure is substantially a
#    sampling effect and should be described as such. If our RIT error
#    stays far below theirs at matched density, the difference is
#    attributable to the fitting method after all.
# 3. Does the boundary/degenerate fit rate rise as density falls? Sparse
#    data during the cone phase is the mechanism De Silva propose for
#    cone-parameter instability.