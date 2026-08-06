ct_fixed <- -1.7
cc_fixed <- 1.90
tau_fixed <- 0.60



S2_values <- c(
    -0.05, -0.10, -0.15,
    -0.20, -0.25, -0.30
)

alpha_values <- c(3, 5, 7, 9)

noise_values <- c(
    0, 0.05, 0.10,
    0.15, 0.20, 0.30
)

n_replicates <- 250L

experiment_grid <- expand.grid(
    S2_real = S2_values,
    alpha_real = alpha_values,
    noise_sd = noise_values,
    replicate = seq_len(n_replicates),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
)

experiment_grid$simulation_number <- seq_len(nrow(experiment_grid))

experiment_grid$seed <- (
    100000L +
    experiment_grid$simulation_number
)

nrow(experiment_grid)
# 36000
condition_grid <- expand.grid(
    S2_real = S2_values,
    alpha_real = alpha_values,
    noise_sd = noise_values,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
)

condition_grid$condition_id <- seq_len(nrow(condition_grid))

experiment_grid <- merge(
    experiment_grid,
    condition_grid,
    by = c("S2_real", "alpha_real", "noise_sd"),
    sort = FALSE
)

experiment_grid <- experiment_grid[
    order(experiment_grid$simulation_number),
]

row.names(experiment_grid) <- NULL


nrow(condition_grid)
# 144


generateSimulationFromRow <- function(
    job,
    time,
    ct,
    cc,
    tau,
    analysis_version = NA_character_
) {
    simulateData(
        time = time,
        ct = ct,
        cc = cc,
        tau = tau,
        S2 = job$S2_real,
        alpha = job$alpha_real,
        noise_sd = job$noise_sd,
        replicate = job$replicate,
        simulation_number = job$simulation_number,
        seed = job$seed,
        analysis_version = analysis_version
    )
}






