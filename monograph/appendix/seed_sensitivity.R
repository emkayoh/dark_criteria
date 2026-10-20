## MWE: optimiser-seed sensitivity arm for the VarPro validation experiment.
##
## Base R equivalent of seed_sensitivity.py. Two differences worth knowing:
##
## 1. Base R has no SeedSequence. The equivalent is L'Ecuyer-CMRG with
##    parallel::nextRNGStream, which gives provably separated streams
##    (2^127 apart) rather than seeds that merely look different.
##    parallel ships with every R install.
##
## 2. optim() does not accept an initial simplex. It builds one deterministically
##    from par, so in R the randomness enters through the starting point instead.
##    NM is still deterministic once that point is fixed.

suppressPackageStartupMessages(library(parallel))

ROOT            <- 20260828L   # record with the environment capture
PURPOSE_DATA    <- 0L
PURPOSE_SIMPLEX <- 1L
PURPOSE_SUBSET  <- 2L
PURPOSE_GD      <- 3L          # reserved: separate stream if GD is stochastic

TAU_TRUE <- 1.8
N_REPS   <- 200L
FRAC     <- 0.20
K        <- 8L
N_POINTS <- 40L
SIGMA    <- 0.05

TOL_TAU <- 1e-6                # pre-stated, decided before looking

## ------------------------------------------------------------ RNG streams

.stream_cache <- new.env(parent = emptyenv())

stream_index <- function(rep_id, purpose, k = 0L) {
  ## compact and unique: keeps the number of stream advances small
  as.integer((rep_id * 4L + purpose) * K + k)
}

get_stream <- function(idx) {
  ## Deterministic: stream idx is idx jumps from the root. Any single unit is
  ## reconstructable from ROOT + rep_id + k, with no need to replay the run.
  key <- as.character(idx)
  if (!is.null(.stream_cache[[key]])) return(.stream_cache[[key]])
  have <- as.integer(ls(.stream_cache))
  start <- if (length(have)) max(have[have <= idx], -1L) else -1L
  if (start < 0L) {
    set.seed(ROOT, kind = "L'Ecuyer-CMRG")
    s <- .Random.seed
    .stream_cache[["0"]] <- s
    start <- 0L
  } else {
    s <- .stream_cache[[as.character(start)]]
  }
  while (start < idx) {
    s <- nextRNGStream(s)
    start <- start + 1L
    .stream_cache[[as.character(start)]] <- s
  }
  s
}

with_stream <- function(rep_id, purpose, k, expr) {
  ## Set the stream, evaluate, restore. Nothing leaks between units.
  old_kind <- RNGkind()
  old_seed <- if (exists(".Random.seed", .GlobalEnv)) get(".Random.seed", .GlobalEnv) else NULL
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (!is.null(old_seed)) assign(".Random.seed", old_seed, .GlobalEnv)
  }, add = TRUE)
  RNGkind("L'Ecuyer-CMRG")
  assign(".Random.seed", get_stream(stream_index(rep_id, purpose, k)), .GlobalEnv)
  force(expr)
}

## ------------------------------------------------------------ model

varpro_sse <- function(theta, t, y) {
  tau <- theta[1L]
  if (!is.finite(tau) || tau <= 1e-8) return(Inf)
  Phi <- cbind(exp(-t / tau), rep(1, length(t)))
  fit <- .lm.fit(Phi, y)            # linear coefficients profiled out
  sum(fit$residuals^2)
}

make_row <- function(rep_id) {
  t <- seq(0.05, 12.0, length.out = N_POINTS)
  eps <- with_stream(rep_id, PURPOSE_DATA, 0L, rnorm(N_POINTS, 0, SIGMA))
  list(t = t, y = 2 * exp(-t / TAU_TRUE) - 0.3 + eps) # model here is exponential decay 
}

fit_once <- function(row, rep_id, k, centre = 2.5, spread = 0.30) {
  start <- with_stream(rep_id, PURPOSE_SIMPLEX, k,
                       centre * exp(rnorm(1L, 0, spread)))
  ## 1-D NM warns in R; the real experiment has d > 1, so this is an MWE artefact
  res <- suppressWarnings(
    optim(par = start, fn = varpro_sse, t = row$t, y = row$y,
          method = "Nelder-Mead",
          control = list(reltol = 1e-12, maxit = 2000))
  )
  data.frame(rep_id = rep_id, k = k, tau0 = start,
             tau_hat = res$par[1L], sse = res$value,
             ok = res$convergence == 0L)
}

## ------------------------------------------------------------ run

select_subset <- function() {
  n <- round(FRAC * N_REPS)
  sort(with_stream(0L, PURPOSE_SUBSET, 0L,
                   sample.int(N_REPS, n, replace = FALSE)) - 1L)
}

main <- function() {
  subset <- select_subset()
  out <- do.call(rbind, lapply(subset, function(rep_id) {
    row <- make_row(rep_id)
    do.call(rbind, lapply(seq_len(K) - 1L,
                          function(k) fit_once(row, rep_id, k)))
  }))

  tau <- matrix(out$tau_hat, nrow = length(subset), ncol = K, byrow = TRUE)
  spread <- apply(tau, 1L, function(v) max(v) - min(v))
  across_reps <- rowMeans(tau)

  cat(sprintf("subset rows       : %d of %d at tau=%.2f\n",
              length(subset), N_REPS, TAU_TRUE))
  cat(sprintf("refits per row    : %d\n", K))
  cat(sprintf("all converged     : %s\n", all(out$ok)))
  cat(sprintf("max within-row range of tau across seeds : %.3e\n", max(spread)))
  cat(sprintf("median within-row range                  : %.3e\n", median(spread)))
  cat(sprintf("sd of tau across rows (sampling noise)   : %.3e\n", sd(across_reps)))
  cat(sprintf("pre-stated tolerance %.1e : %s\n", TOL_TAU,
              if (max(spread) < TOL_TAU) "PASS" else "FAIL"))
  invisible(out)
}

if (sys.nframe() == 0L) main()
