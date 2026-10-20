source("hinge_lifelike.R")   # model, grid, streams (C_TRUE in design order)

## RIT: time at which the fitted curve crosses a fixed sensitivity criterion K
## on the rod limb, read off the full fitted curve. K is parametrization-
## specific: it must lie BELOW the break-point value or there is no post-break
## crossing. For C_TRUE = c(1.5, -0.24, -1.5) the rod limb runs roughly
## [-1.2, -5.6], so a criterion around -2.0 is sensible. Set your real one.

K_CRIT <- -3.0

fitted_curve <- function(t, tau, alpha, cc)
  cc[1]*exp(-t/tau) + cc[2]*pmax(0, t - alpha) + cc[3]

coefs_at <- function(tau, alpha, t, y) {
  Phi <- design(tau, alpha, t)
  if (any(!is.finite(Phi)) || qr(Phi)$rank < ncol(Phi)) return(rep(NA_real_, 3))
  as.numeric(.lm.fit(Phi, y)$coefficients)
}

## guarded root finder: returns NA when the criterion is not crossed in range,
## rather than erroring. Used for both the fitted RIT and the true RIT.
solve_rit <- function(f, lo, hi = 20) {
  flo <- f(lo); fhi <- f(hi)
  if (!is.finite(flo) || !is.finite(fhi) || flo * fhi > 0) return(NA_real_)
  uniroot(f, c(lo, hi), tol = 1e-8)$root
}

rit_of <- function(tau, alpha, cc, K, hi = 20) {
  if (any(is.na(cc))) return(NA_real_)
  solve_rit(function(t) fitted_curve(t, tau, alpha, cc) - K, alpha + 1e-6, hi)
}

rit_true <- function(atrue, hi = 20) {
  ## C_TRUE is already in design order, so it doubles as the coefficient vector
  solve_rit(function(t) fitted_curve(t, TAU_TRUE, atrue, C_TRUE) - K_CRIT, atrue + 1e-6, hi)
}

best_fit <- function(row, starts) {
  f <- do.call(rbind, lapply(seq_len(nrow(starts)),
        function(j) fit_from(row, starts[j,], "trans")))
  ok <- f$ok; b <- which.min(ifelse(ok, f$sse, Inf))
  list(tau=f$tau[b], alpha=f$alpha[b], sse=f$sse[b],
       at_best_frac = mean(ok & (f$sse - f$sse[b]) <= 1e-6*max(f$sse[b],1e-12)),
       modes = length(unique(signif(f$sse[ok], 8))))
}

run <- function(atrue, densities) {
  assign("ALPHA_TRUE", atrue, envir = globalenv())
  rt <- rit_true(atrue)
  starts <- grid_starts()
  cat(sprintf("\nalpha_true = %.1f   RIT_true = %s   (recording ends at %.1f)\n",
              atrue, if (is.na(rt)) "NA (criterion not reached in range)" else sprintf("%.3f", rt), T_MAX))
  if (is.na(rt)) { cat("  -> pick a K_CRIT below the break-point value; see range check.\n"); return(invisible()) }
  cat(sprintf("%6s %10s %10s %9s %8s\n", "Npts", "RIT bias", "RIT sd", "modes", "atbest%"))
  for (N in densities) {
    assign("N_POINTS", as.integer(N), envir = globalenv())
    subset <- select_subset()
    rits <- c(); modes <- c(); atb <- c()
    for (r in subset) {
      row <- make_row(r); bf <- best_fit(row, starts)
      cc <- coefs_at(bf$tau, bf$alpha, row$t, row$y)
      rits <- c(rits, rit_of(bf$tau, bf$alpha, cc, K_CRIT))
      modes <- c(modes, bf$modes); atb <- c(atb, bf$at_best_frac)
    }
    ok <- is.finite(rits)
    cat(sprintf("%6d %10.4f %10.4f %9.2f %7.1f%%   [RIT resolved %d/%d]\n",
                N, mean(rits[ok]) - rt, sd(rits[ok]), mean(modes),
                100*mean(atb), sum(ok), length(ok)))
  }
}

run(3.0, c(20, 40, 60, 100, 160))   # early, well-sampled break
run(6.0, c(20, 40, 60, 100, 160))   # late break, AMD-relevant
run(9.0, c(20, 40, 60, 100, 160))   # late break, AMD-relevant