P5cPredictionIntervals <- function(
    params,
    x,
    y,
    level = 0.95
) {
    fitted <- P5c(params, x)
    residuals <- y - fitted

    n <- length(y)
    p <- length(params)
    df <- n - p

    sigma2 <- sum(residuals^2) / df

    J <- P5cJacobian(params, x)
    covariance <- sigma2 * solve(crossprod(J))

    mean_variance <- rowSums((J %*% covariance) * J)
    prediction_se <- sqrt(mean_variance + sigma2)

    critical <- qt(
        1 - (1 - level) / 2,
        df = df
    )

    data.frame(
        x = x,
        fitted = fitted,
        lower = fitted - critical * prediction_se,
        upper = fitted + critical * prediction_se
    )
}
