#' Simulate a dark-adaptation dataset from the P5c model
#'
#' Generates a synthetic dark-adaptation dataset using the five-parameter
#' P5c model:
#'
#' \deqn{
#' y(t) = ct + cc \exp(-t / tau)
#'        + S2 (t - alpha) H(t, alpha)
#' }
#'
#' Independent Gaussian noise is added to each generated threshold
#' measurement.
#'
#' Each simulation is assigned a short identifier. If the `uuid` package is
#' installed, the identifier is derived from a UUID. Otherwise, an identifier
#' is generated from the system clock, process ID and a random hexadecimal
#' component.
#'
#' @param time Numeric vector of measurement times.
#' @param ct Cone threshold asymptote.
#' @param cc Cone-component amplitude.
#' @param tau Positive cone time constant.
#' @param S2 Rod recovery slope.
#' @param alpha Rod-cone transition time.
#' @param noise_sd Non-negative standard deviation of the additive Gaussian
#'   noise.
#' @param replicate Positive integer identifying the replicate within a
#'   simulation condition.
#' @param simulation_number Optional positive integer identifying the
#'   simulation within the complete experiment.
#' @param simulation_id Optional character identifier. If `NULL`, an
#'   eight-character identifier is generated automatically.
#' @param seed Optional non-negative integer random-number seed. If `NULL`
#'   and `simulation_number` is supplied, the seed is calculated as
#'   `seed_offset + simulation_number`.
#' @param seed_offset Integer added to `simulation_number` when automatically
#'   constructing the random-number seed.
#' @param analysis_version Character string identifying the analysis-code
#'   version, such as a release number or Git commit hash.
#'
#' @return A list containing:
#'
#' \describe{
#'   \item{data}{Data frame containing time, noiseless threshold, added noise
#'     and observed threshold.}
#'   \item{params}{Named vector of the five generating P5c parameters.}
#'   \item{metadata}{One-row data frame describing the simulation.}
#' }
#'
#' @examples
#' x <- seq(0, 10, length.out = 64)
#'
#' simulated <- simulateData(
#'     time = x,
#'     ct = -1.25,
#'     cc = 1.40,
#'     tau = 2.50,
#'     S2 = -0.20,
#'     alpha = 7,
#'     noise_sd = 0.10,
#'     replicate = 1L,
#'     simulation_number = 1L,
#'     analysis_version = "0.1.0"
#' )
simulateData <- function(
    time,
    ct,
    cc,
    tau,
    S2,
    alpha,
    noise_sd,
    replicate = 1L,
    simulation_number = NA_integer_,
    simulation_id = NULL,
    seed = NULL,
    seed_offset = 100000L,
    analysis_version = NA_character_
) {
    make_simulation_id <- function(n_characters = 8L) {
        if (requireNamespace("uuid", quietly = TRUE)) {
            id <- gsub(
                pattern = "-",
                replacement = "",
                x = uuid::UUIDgenerate()
            )

            return(toupper(substr(id, 1L, n_characters)))
        }

        # Fallback requiring no additional package. Including the process ID
        # helps reduce collisions when simulations are run in parallel.
        timestamp <- format(
            Sys.time(),
            format = "%Y%m%d%H%M%OS6",
            tz = "UTC"
        )

        source_string <- paste0(
            timestamp,
            Sys.getpid(),
            sample.int(.Machine$integer.max, 1L)
        )

        # Convert the final integer component to hexadecimal.
        random_hex <- sprintf(
            "%08X",
            as.integer(abs(
                sum(utf8ToInt(source_string) *
                    seq_along(utf8ToInt(source_string)))
            ) %% .Machine$integer.max)
        )

        substr(random_hex, 1L, n_characters)
    }

    scalar_finite_numeric <- function(value) {
        is.numeric(value) &&
            length(value) == 1L &&
            is.finite(value)
    }

    if (
        !is.numeric(time) ||
        length(time) == 0L ||
        any(!is.finite(time))
    ) {
        stop("time must be a non-empty numeric vector of finite values.")
    }

    if (is.unsorted(time)) {
        stop("time must be ordered from earliest to latest.")
    }

    parameters <- c(
        ct = ct,
        cc = cc,
        tau = tau,
        S2 = S2,
        alpha = alpha
    )

    if (!all(vapply(
        list(ct, cc, tau, S2, alpha),
        scalar_finite_numeric,
        logical(1L)
    ))) {
        stop("Each P5c parameter must be a finite numeric scalar.")
    }

    if (tau <= 0) {
        stop("tau must be greater than zero.")
    }

    if (
        !scalar_finite_numeric(noise_sd) ||
        noise_sd < 0
    ) {
        stop("noise_sd must be a non-negative finite scalar.")
    }

    if (
        !scalar_finite_numeric(replicate) ||
        replicate < 1 ||
        replicate != as.integer(replicate)
    ) {
        stop("replicate must be a positive integer.")
    }

    replicate <- as.integer(replicate)

    simulation_number_missing <- (
        length(simulation_number) == 1L &&
        is.na(simulation_number)
    )

    if (!simulation_number_missing) {
        if (
            !scalar_finite_numeric(simulation_number) ||
            simulation_number < 1 ||
            simulation_number != as.integer(simulation_number)
        ) {
            stop(
                "simulation_number must be NA or a positive integer."
            )
        }

        simulation_number <- as.integer(simulation_number)
    } else {
        simulation_number <- NA_integer_
    }

    if (
        !is.numeric(seed_offset) ||
        length(seed_offset) != 1L ||
        !is.finite(seed_offset)
    ) {
        stop("seed_offset must be a finite numeric scalar.")
    }

    seed_offset <- as.integer(seed_offset)

    if (is.null(simulation_id)) {
        simulation_id <- make_simulation_id()
    } else if (
        !is.character(simulation_id) ||
        length(simulation_id) != 1L ||
        is.na(simulation_id) ||
        !nzchar(simulation_id)
    ) {
        stop(
            "simulation_id must be NULL or a non-empty character scalar."
        )
    }

    if (is.null(seed) && !is.na(simulation_number)) {
        seed <- seed_offset + simulation_number
    }

    if (!is.null(seed)) {
        if (
            !scalar_finite_numeric(seed) ||
            seed < 0 ||
            seed > .Machine$integer.max
        ) {
            stop(
                "seed must be NULL or a non-negative integer no greater ",
                "than .Machine$integer.max."
            )
        }

        seed <- as.integer(seed)
        set.seed(seed)
    }

    if (
        length(analysis_version) != 1L ||
        (!is.na(analysis_version) &&
            !is.character(analysis_version))
    ) {
        stop(
            "analysis_version must be NA or a character scalar."
        )
    }

    y_true <- P5c(
        a = parameters,
        x = time
    )

    noise <- if (noise_sd == 0) {
        numeric(length(time))
    } else {
        rnorm(
            n = length(time),
            mean = 0,
            sd = noise_sd
        )
    }

    y_observed <- y_true + noise

    simulation_data <- data.frame(
        observation = seq_along(time),
        time = time,
        threshold_true = y_true,
        noise = noise,
        threshold_observed = y_observed
    )

    metadata <- data.frame(
        simulation_id = simulation_id,
        simulation_number = simulation_number,
        seed = if (is.null(seed)) NA_integer_ else seed,
        replicate = replicate,
        created_utc = format(
            Sys.time(),
            format = "%Y-%m-%dT%H:%M:%OS3Z",
            tz = "UTC"
        ),
        analysis_version = analysis_version,
        ct_real = ct,
        cc_real = cc,
        tau_real = tau,
        S2_real = S2,
        alpha_real = alpha,
        noise_sd = noise_sd,
        n_observations = length(time),
        time_min = min(time),
        time_max = max(time),
        stringsAsFactors = FALSE
    )

    list(
        data = simulation_data,
        params = parameters,
        metadata = metadata
    )
}
