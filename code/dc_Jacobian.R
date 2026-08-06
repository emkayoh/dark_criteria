P5cJacobianDiagnostics <- function(params, x, tolerance = 1e-12) {
    J <- P5cJacobian(params, x)

    column_norms <- sqrt(colSums(J^2))

    zero_columns <- (
        !is.finite(column_norms) |
        column_norms <= tolerance
    )

    J_scaled <- J

    nonzero <- !zero_columns

    J_scaled[, nonzero] <- sweep(
        J[, nonzero, drop = FALSE],
        MARGIN = 2L,
        STATS = column_norms[nonzero],
        FUN = "/"
    )

    singular_raw <- svd(
        J,
        nu = 0L,
        nv = 0L
    )$d

    singular_scaled <- svd(
        J_scaled[, nonzero, drop = FALSE],
        nu = 0L,
        nv = 0L
    )$d

    condition_raw <- if (min(singular_raw) > tolerance) {
        max(singular_raw) / min(singular_raw)
    } else {
        Inf
    }

    condition_scaled <- if (
        length(singular_scaled) > 0L &&
        min(singular_scaled) > tolerance
    ) {
        max(singular_scaled) / min(singular_scaled)
    } else {
        Inf
    }

    list(
        column_norms = column_norms,
        zero_columns = zero_columns,
        singular_values_raw = singular_raw,
        singular_values_scaled = singular_scaled,
        condition_J_raw = condition_raw,
        condition_J_scaled = condition_scaled,
        condition_JtJ_raw = condition_raw^2,
        condition_JtJ_scaled = condition_scaled^2
    )
}


# # I would not use a single universal cutoff to declare failure, but as a practical guide for the scaled Jacobian:
	# •	below roughly 10: usually comfortable;
	# •	10–100: meaningful correlation;
	# •	100–1000: weak identifiability or strong trade-offs;
	# •	above 1000: inference likely unstable;
	# •	Inf: rank deficiency.
# Those are diagnostic ranges, not formal statistical thresholds.

