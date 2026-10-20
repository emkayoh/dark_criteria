## Start-point sensitivity, hinge model. Base R, no RNG in the fit.
##
##   y = c1*exp(-t/tau) + c2*pmax(0, t - alpha) + c3 + noise
##
## tau is a scale parameter, alpha is a breakpoint (a location on the t axis).
## They are not interchangeable and must not be treated the same way.
##
## Why this differs from the two-exponential case:
##   - the hinge is non-differentiable in alpha at t = alpha
##   - the profiled SSE is piecewise smooth with a kink wherever alpha crosses
##     an observed t_i, so it has up to n pieces and can be genuinely multimodal
##   - alpha > max(t) makes the hinge column identically zero, so the linear
##     projection is rank deficient; alpha < min(t) makes it collinear with
##     the intercept plus a linear trend
##
## Variants:
##   guard : Inf outside the domain, plus an explicit rank check
##   none  : no guard, no rank check (what a silent .lm.fit does)
##   trans : log(tau), and alpha mapped through a logit onto the observed
##           time range, so both are unconstrained and the domain holds
##           by construction

suppressPackageStartupMessages(library(parallel))

ROOT <- 20260828L
PURPOSE_DATA <- 0L
PURPOSE_SUBSET <- 2L

TAU_TRUE <- 1.8
ALPHA_TRUE <- 3 # breakpoint, inside the observation window
C_TRUE <- c(1.5,-0.24, -1.5)
# design order: exp, hinge, 1 = cone amp, rod slope, intercept

N_REPS <- 200L
FRAC <- 0.2
N_POINTS <- 60L
SIGMA <- 0.01
T_MIN <- 0.05
T_MAX <- 12

REF_START <- c(tau = 2.5, alpha = 2)
SPAN_TAU <- 3 # multiplicative, tau is a scale
GRID_N <- 9L
SSE_TOL <- 1e-06

## ------------------------------------------------------------ RNG (data only)

.stream_cache <- new.env(parent = emptyenv())
get_stream <- function(idx) {
	key <- as.character(idx)
	if (!is.null(.stream_cache[[key]])) 
		return(.stream_cache[[key]])
	have <- as.integer(ls(.stream_cache))
	start <- if (length(have)) 
		max(c(-1L, have[have <= idx]))
	else -1L
	if (start < 0L) {
		set.seed(ROOT, kind = "L'Ecuyer-CMRG")
		.stream_cache[["0"]] <- .Random.seed
		start <- 0L
	}
	s <- .stream_cache[[as.character(start)]]
	while (start < idx) {
		s <- nextRNGStream(s)
		start <- start + 1L
		.stream_cache[[as.character(start)]] <- s
	}
	s
}
with_stream <- function(rep_id, purpose, expr) {
	old_kind <- RNGkind()
	old_seed <- if (exists(".Random.seed", .GlobalEnv)) 
		get(".Random.seed", .GlobalEnv)
	else NULL
	on.exit({
		do.call(RNGkind, as.list(old_kind))
		if (!is.null(old_seed)) assign(".Random.seed", old_seed, .GlobalEnv)
	}, add = TRUE)
	RNGkind("L'Ecuyer-CMRG")
	assign(".Random.seed", get_stream(rep_id * 4L + purpose), .GlobalEnv)
	force(expr)
}

## ------------------------------------------------------------ objective

design <- function(tau, alpha, t) cbind(exp(-t/tau), pmax(0, t - alpha), rep(1, length(t)))

sse_core <- function(tau, alpha, t, y, rank_check = TRUE) {
	Phi <- design(tau, alpha, t)
	if (any(!is.finite(Phi))) 
		return(NaN)
	if (rank_check) {
		q <- qr(Phi)
		if (q$rank < ncol(Phi)) 
			return(NaN) # hinge column dead or collinear
	}
	sum(.lm.fit(Phi, y)$residuals^2)
}

obj_guard <- function(th, t, y) {
	if (any(!is.finite(th))) 
		return(Inf)
	if (th[1L] <= 1e-08) 
		return(Inf)
	if (th[2L] <= T_MIN || th[2L] >= T_MAX) 
		return(Inf)
	v <- sse_core(th[1L], th[2L], t, y, TRUE)
	if (is.nan(v)) 
		Inf
	else v
}

obj_none <- function(th, t, y) sse_core(th[1L], th[2L], t, y, FALSE)

logit <- function(p) log(p/(1 - p))
expit <- function(x) 1/(1 + exp(-x))
to_nat <- function(z) c(exp(z[1L]), T_MIN + (T_MAX - T_MIN) * expit(z[2L]))
to_trn <- function(p) c(log(p[1L]), logit((p[2L] - T_MIN)/(T_MAX - T_MIN)))

obj_trans <- function(z, t, y) {
	if (any(!is.finite(z))) 
		return(Inf)
	p <- to_nat(z)
	v <- sse_core(p[1L], p[2L], t, y, TRUE)
	if (is.nan(v)) 
		Inf
	else v
}

## ------------------------------------------------------------ data

make_row <- function(rep_id) {
	t <- seq(T_MIN, T_MAX, length.out = N_POINTS)
	eps <- with_stream(rep_id, PURPOSE_DATA, rnorm(N_POINTS, 0, SIGMA))
	mu <- C_TRUE[1L] * exp(-t/TAU_TRUE) + C_TRUE[2L] * pmax(0, t - ALPHA_TRUE) + C_TRUE[3L]
	list(t = t, y = mu + eps)
}

## ------------------------------------------------------------ fitting

fit_from <- function(row, start, variant) {
	fn <- switch(variant, guard = obj_guard, none = obj_none, trans = obj_trans)
	par0 <- if (variant == "trans") 
		to_trn(start)
	else start
	if (any(!is.finite(par0))) 
		return(data.frame(tau = NA_real_, alpha = NA_real_, sse = NA_real_, ok = FALSE, failed = TRUE))
	res <- tryCatch(suppressWarnings(optim(par0, fn, t = row$t, y = row$y, method = "Nelder-Mead", control = list(reltol = 1e-12, 
		maxit = 4000))), error = function(e) NULL)
	if (is.null(res)) 
		return(data.frame(tau = NA_real_, alpha = NA_real_, sse = NA_real_, ok = FALSE, failed = TRUE))
	p <- if (variant == "trans") 
		to_nat(res$par)
	else res$par
	data.frame(tau = p[1L], alpha = p[2L], sse = res$value, ok = res$convergence == 0L && is.finite(res$value), failed = FALSE)
}

grid_starts <- function() {
	ftau <- exp(seq(-log(SPAN_TAU), log(SPAN_TAU), length.out = GRID_N))
	## alpha is a location: scan it across the observation window, not by ratio
	aa <- seq(T_MIN + 0.05 * (T_MAX - T_MIN), T_MAX - 0.05 * (T_MAX - T_MIN), length.out = GRID_N)
	as.matrix(expand.grid(tau = REF_START[["tau"]] * ftau, alpha = aa))
}

## ------------------------------------------------------------ run

select_subset <- function() {
	n <- round(FRAC * N_REPS)
	sort(with_stream(0L, PURPOSE_SUBSET, sample.int(N_REPS, n, replace = FALSE)) - 1L)
}

scan_variant <- function(subset, starts, variant) {
	do.call(rbind, lapply(subset, function(rep_id) {
		row <- make_row(rep_id)
		ref <- fit_from(row, REF_START, variant)
		fits <- do.call(rbind, lapply(seq_len(nrow(starts)), function(j) fit_from(row, starts[j, ], variant)))
		best <- suppressWarnings(min(fits$sse[fits$ok]))
		if (!is.finite(best)) 
			best <- NA_real_
		at <- fits$ok & is.finite(best) & (fits$sse - best) <= SSE_TOL * max(best, .Machine$double.eps)
		## distinct local optima found, by rounded SSE among converged starts
		nmodes <- length(unique(signif(fits$sse[fits$ok], 8)))
		data.frame(rep_id = rep_id, n_starts = nrow(fits), n_failed = sum(fits$failed), n_ok = sum(fits$ok), n_at_best = sum(at), 
			n_modes = nmodes, alpha_err_at_best = if (any(at)) 
				max(abs(fits$alpha[at] - ALPHA_TRUE))
			else NA_real_, ref_at_best = isTRUE(ref$ok) && is.finite(best) && (ref$sse - best) <= SSE_TOL * max(best, .Machine$double.eps), 
			ref_alpha = ref$alpha)
	}))
}

main <- function() {
	subset <- select_subset()
	starts <- grid_starts()
	cat(sprintf("rows: %d | starts per row: %d | true (tau, alpha) = (%.2f, %.2f)\n", length(subset), nrow(starts), TAU_TRUE, ALPHA_TRUE))
	cat(sprintf("reference start = (%.2f, %.2f), alpha scanned across [%.2f, %.2f]\n\n", REF_START[["tau"]], REF_START[["alpha"]], 
		T_MIN, T_MAX))
	cat(sprintf("%-7s %8s %8s %10s %9s %12s %9s\n", "variant", "failed", "conv%", "at-best%", "modes", "max a-err", "ref ok%"))
	for (v in c("guard", "none", "trans")) {
		s <- scan_variant(subset, starts, v)
		tot <- sum(s$n_starts)
		cat(sprintf("%-7s %8d %7.1f%% %9.1f%% %9.2f %12.2e %8.1f%%\n", v, sum(s$n_failed), 100 * sum(s$n_ok)/tot, 100 * sum(s$n_at_best)/tot, 
			mean(s$n_modes), max(s$alpha_err_at_best, na.rm = TRUE), 100 * mean(s$ref_at_best)))
	}
	cat("\nmodes = mean number of distinct converged SSE values per row.\n")
	cat("A value above 1 means the objective is multimodal in the scanned region.\n")
}

if (sys.nframe() == 0L) 
	main()