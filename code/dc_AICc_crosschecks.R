fitP5cOLS <- function(
    start,
    x,
    y,
    lower = c(-3, -2, 0.01, -0.5, min(x)),
    upper = c(0, 5, 6, 0, max(x))
) {
    objective <- function(a) {
        residuals <- y - P5c(a, x)
        sum(residuals * residuals)
    }

    fit <- optim(
        par = start,
        fn = objective,
        method = "L-BFGS-B",
        lower = lower,
        upper = upper,
        control = list(
            factr = 1e7,
            pgtol = 1e-8,
            maxit = 2000L
        )
    )

    params <- fit$par
    names(params) <- c("ct", "cc", "tau", "S2", "alpha")

    list(
        params = params,
        RSS = fit$value,
        converged = fit$convergence == 0L,
        convergence_code = fit$convergence,
        message = fit$message
    )
}

p5_ols_from_refined <- fitP5cOLS(
    start = op0hO$params,
    x = x,
    y = y
)

p5_ols_from_p3 <- fitP5cOLS(
    start = p5_from_p3,
    x = x,
    y = y
)

p5_ols <- if (
    p5_ols_from_refined$RSS <= p5_ols_from_p3$RSS
) {
    p5_ols_from_refined
} else {
    p5_ols_from_p3
}

c(
    P3_RSS = p3_rss,
    P5_current_RSS = p5_rss,
    P5_polished_RSS = p5_ols$RSS
)


aic_p3 <- calculateAIC(
    rss = p3_rss,
    n = length(y),
    n_params = 3L
)

aic_p5 <- calculateAIC(
    rss = p5_ols$RSS,
    n = length(y),
    n_params = 5L
)

aic_p3 
aic_p5 


p5_from_p3 <- c(
    ct = p3_result$params["ct"],
    cc = p3_result$params["cc"],
    tau = p3_result$params["tau"],
    S2 = 0,
    alpha = median(x)
)

p5_from_p3_rss <- sum(
    (y - P5c(p5_from_p3, x))^2
)

p5_fit_valid <- (
    abs(p5_from_p3_rss - p3_rss) < 1e-8 &&
    p5_rss <= p3_rss + 1e-8
)