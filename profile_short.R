profileP5cRSS <- function(tau, alpha, x, y) {

    H <- as.numeric(x >= alpha)

    X <- cbind(
        ct = 1,
        cc = exp(-x / tau),
        S2 = (x - alpha) * H
    )

    beta <- qr.solve(X, y)

    fitted <- as.vector(X %*% beta)
    rss <- sum((y - fitted)^2)

    list(
        rss = rss,
        params = c(
            ct = beta["ct"],
            cc = beta["cc"],
            tau = tau,
            S2 = beta["S2"],
            alpha = alpha
        )
    )
}

profileObjective <- function(z, x, y) {

    tau <- exp(z[1])
    alpha <- z[2]

    profileP5cRSS(
        tau = tau,
        alpha = alpha,
        x = x,
        y = y
    )$rss
}

opt <- optim(
    par = c(
        log_tau = log(best_tau_2),
        alpha = best_alpha_2
    ),
    fn = profileObjective,
    x = x,
    y = y,
    method = "L-BFGS-B",
    lower = c(
        log(tau_lower),
        alpha_lower
    ),
    upper = c(
        log(tau_upper),
        alpha_upper
    ),
    control = list(
        factr = 1e7,
        pgtol = 1e-10,
        maxit = 500L
    )
)


tau_final <- exp(opt$par["log_tau"])
alpha_final <- opt$par["alpha"]

final <- profileP5cRSS(
    tau = tau_final,
    alpha = alpha_final,
    x = x,
    y = y
)

final$params
final$rss

