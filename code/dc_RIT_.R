# Calculated RIT using simulated data

rm(list = ls())

library(dplyr)

dir_mac   <- "~/Dropbox/Mumac_/CODE_1/dark_criteria/results/Mac_dark_criteria_results/"

mac_f <- c(
    "dc_experiment_results_tau0.6_2026-08-20_113721_pid3341.csv",
    "dc_experiment_results_tau1.2_2026-08-20_113721_pid3342.csv",
    "dc_experiment_results_tau1.8_2026-08-20_113721_pid3343.csv",
    "dc_experiment_results_tau2.4_2026-08-20_113721_pid3344.csv"
)

CRIT <- -3.0
MAXTIME <- 11.87802 

RITc <- function( alpha, s2, ct, crit=-3){

	alpha + (crit - ct)/s2
	}



dat <- read.csv(file.path(path.expand(dir_mac),  mac_f[4]),   sep = ",")
vars <- c("experiment_index" ,"ct_real","cc_real","tau_real","S2_real","alpha_real","noise_sd","ct_profile", "cc_profile", "tau_profile", "S2_profile", "alpha_profile","p5_profile_rss")

S2s <- c( -0.01, -0.05, -0.1, -0.15, -0.2, -0.25, -0.3)

sel <- sapply(vars, \(v) dat[[v]])

idx0 <- sel[,"noise_sd"]!=0 # excluded the zero noise data

rit_t <- RITc(sel[idx0,"alpha_real"], sel[idx0,"S2_real"], sel[idx0,"ct_real"])
rit_p <- RITc(sel[idx0,"alpha_profile"], sel[idx0,"S2_profile"], sel[idx0,"ct_profile"])

idx <- (sel[idx0,"tau_profile"] <= 0.101 | sel[idx0,"cc_profile"] > 4) & rit_t < 100
sum(idx)

degen_t <- rit_t[idx]
degen_p <- rit_p[idx]
degen_s2 <- as.integer(as.factor(sel[idx0,"S2_real"][idx]))
degen_noise <- as.integer(as.factor(sel[idx0,"noise_sd"][idx]))

par(mfrow= c(2,2))

plot(degen_t,degen_p , col = degen_s2, pch = 15+ degen_noise)
mod <- lm(degen_p~degen_t)
summary(mod)
abline(0,1)
abline(mod, col = 2)
abline(v = MAXTIME, lty =2)

legend('bottomright', legend=c("-0.3","-0.25","-0.2","-0.15","-0.1"),pch = 16, col =1:5, bty = 'n')



idxg <- rit_t < 20 
sum(idxg)

delt <- abs(rit_t[idxg] - rit_p[idxg])

boxplot(delt[nine]~sel[idx0 , "alpha_real"][idxg][nine], xlb ="Real alpha (min)", ylab= expression(abs(Delta~RIT)))


tmp <- NULL

S2s <- c( -0.01, -0.05, -0.1, -0.15, -0.2, -0.25, -0.3)
for(ii in S2s){
idx2 <- idx <- rit_t >0 & rit_t < 14000 & rit_p >0 & rit_p < 140000 & sel[idx0,"S2_real"]== ii

No <- sum(idx2)
del <- abs((rit_t - rit_p)[idx2])
foo <- quantile(del, c(50, 90, 99, 99.9)/100)
bar <- c(ii, No, foo)
tmp <- rbind(tmp, bar)
}

colnames(tmp) <- c("S2", "Count",  "50%", "90%","99%", "99.9%")
rownames(tmp) <- NULL

tmp

S2s <- c(0.01,0.05,0.10,0.15,0.20,0.25,0.30)
med <- tmp[,"50%"]
fit <- lm(log(med) ~ log(S2s))
coef(fit)

rel_med <- tmp[,"50%"] / ((CRIT - (-1.7))/S2s)   # median error / true RIT magnitude
plot(S2s, rel_med)