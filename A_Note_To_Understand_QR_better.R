rm(list = ls())
library(Dark)
# A note to better undertstand QR decomposition 
set.seed(123)
# We have twenty timestamped observations 

# a <- c(-1.967, 1.39, 1.609, -0.228, 8.704) what were seeking 

# 1. Create the time vector (20 observations)
t <- 1:20

# 2. Simulate the observed y values with a bit of random noise/error
y <- c(-1.301, -1.609, -1.695, -1.661, -1.967, -2.022, -1.963, -1.856,
       -1.921, -2.179, -2.269, -2.825, -2.865, -3.383, -3.286, -3.618,
       -3.829, -4.138, -4.187, -4.406)

rapiPA <- function(t, y, tau = 1, alpha = 3){
	step <- t>alpha

# 3. Construct the Design Matrix A using cbind()
##     step <- as.numeric(x >= alpha)

  # Column 1 = Intercept: a[1L] * 1 				+
  # Column 2 = a[2L] * exp(-x / tau) 	+
  # Column 3 = a[4L] * (x - alpha) * step

A <- cbind(1, exp(-t/tau), (t - alpha) * step)
    
# 4. Perform the QR decomposition
qr_res <- qr(A)
Q <- qr.Q(qr_res) # Dimension: 20 x 3
R <- qr.R(qr_res) # Dimension: 3 x 3

# 5. Transform the right-hand side: Q^T %*% y
transformed_y <- t(Q) %*% y # Dimension: 3 x 1

# 6. Solve for the 3 parameters via back substitution
est_P <- backsolve(R, transformed_y)

# 7. Print the results
# print("Estimated Parameters (ct, cc, S2):")
# print(est_P)	
est <- c(est_P[1], est_P[2], tau, est_P[3], alpha)
est	
}

par(mfrow=c(1,2))
plot(t, y)
ALP <-seq(7,10, by = 0.2)
RES <- numeric(length(ALP))
ii=1

for(a in ALP){
est <- rapiPA(t, y, tau = 1.7, alpha = a)
Y <- P5c(est, t)
RES[ii] <- sum((y-Y)^2)
ii = ii + 1
lines(t, Y)
}


plot(ALP, RES)
