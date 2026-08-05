


coneThreshold_range <- seq(-3, 3, length.out = 10)
coneOffset_range <- seq(1, 5, length.out = 10)
coneTimeConstant_range <- seq(0.5, 2, length.out = 10)
rodS2_range <- seq(-0.5, 0, length.out = 10)
rodAlpha_range <- seq(0, 10, length.out = 10)

GLOBAL_PARAM_GRID <- as.matrix(expand.grid(coneThreshold_range, coneOffset_range, coneTimeConstant_range, 
	rodS2_range, rodAlpha_range))

# Optional: Save it so you don't even have to generate it in future sessions saveRDS(GLOBAL_PARAM_GRID, "global_param_grid.rds")


#' Find the best initial P5c parameter vector
#'
#' Evaluates a grid of candidate P5c parameter vectors and returns the
#' candidate with the smallest residual mean square.
#'
#' Candidates are evaluated in chunks to reduce R function-call overhead
#' without allocating the full candidate-by-observation prediction matrix.
#'
#' @param time Numeric vector of measurement times.
#' @param threshold Numeric vector of observed thresholds.
#' @param param_grid Numeric matrix with five columns ordered as:
#'   ct, cc, tau, S2 and alpha.
#' @param chunk_size Number of candidate rows evaluated simultaneously.
#'
#' @return A list containing:
#' \describe{
#'   \item{best}{The best candidate parameter vector.}
#'   \item{performance}{Residual mean square for the best candidate.}
#'   \item{index}{Row number of the best candidate in `param_grid`.}
#' }
findInitialParameters <- function(
    time,
    threshold,
    param_grid,
    chunk_size = 2500L
) {
    if (
        !is.numeric(time) ||
        !is.numeric(threshold) ||
        length(time) != length(threshold) ||
        length(time) == 0L
    ) {
        stop("time and threshold must be non-empty numeric vectors of equal length.")
    }

    if (
        !is.matrix(param_grid) ||
        !is.numeric(param_grid) ||
        ncol(param_grid) != 5L
    ) {
        stop("param_grid must be a numeric matrix with five columns.")
    }

    if (
        any(!is.finite(time)) ||
        any(!is.finite(threshold)) ||
        any(!is.finite(param_grid))
    ) {
        stop("All inputs must contain finite values.")
    }

    chunk_size <- as.integer(chunk_size)

    if (length(chunk_size) != 1L || is.na(chunk_size) || chunk_size < 1L) {
        stop("chunk_size must be a positive integer.")
    }

    n_candidates <- nrow(param_grid)
    n_observations <- length(time)

    best_rss <- Inf
    best_index <- NA_integer_

    chunk_starts <- seq.int(
        from = 1L,
        to = n_candidates,
        by = chunk_size
    )

    for (start in chunk_starts) {
        end <- min(start + chunk_size - 1L, n_candidates)
        rows <- start:end
        candidates <- param_grid[rows, , drop = FALSE]

        ct <- candidates[, 1L]
        cc <- candidates[, 2L]
        tau <- candidates[, 3L]
        S2 <- candidates[, 4L]
        alpha <- candidates[, 5L]

        # Each resulting matrix has:
        #   rows    = candidate parameter vectors
        #   columns = observation times
        exponential <- exp(-outer(1 / tau, time, `*`))

        time_from_alpha <- outer(
            alpha,
            time,
            function(a, t) t - a
        )

        rod_component <- time_from_alpha *
            (time_from_alpha >= 0)

        predictions <-
            ct +
            cc * exponential +
            S2 * rod_component

        residuals <- sweep(
            predictions,
            MARGIN = 2L,
            STATS = threshold,
            FUN = "-"
        )

        rss <- rowSums(residuals * residuals)
        local_index <- which.min(rss)

        if (rss[local_index] < best_rss) {
            best_rss <- rss[local_index]
            best_index <- rows[local_index]
        }
    }

    best <- param_grid[best_index, ]
    names(best) <- c("ct", "cc", "tau", "S2", "alpha")

    list(
        best = best,
        performance = best_rss / n_observations,
        index = best_index
    )
}



# # for (size in c(1000L, 2500L, 5000L, 10000L, 25000L)) {
    # timing <- system.time({
        # result <- findInitialParameters(
            # time = x,
            # threshold = y,
            # param_grid = GLOBAL_PARAM_GRID,
            # chunk_size = size
        # )
    # })

    # cat(
        # "chunk:", size,
        # " elapsed:", timing[["elapsed"]],
        # " MSE:", result$performance,
        # "\n"
    # )
# }