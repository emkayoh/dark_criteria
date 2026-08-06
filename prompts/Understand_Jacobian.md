I am analysing uncertainty and identifiability in a five-parameter dark-adaptation model:

\[
y = c_t + c_c e^{-x/\tau} + S_2(x-\alpha)H(x,\alpha).
\]

The model parameters are:

- \(c_t\): cone threshold;
- \(c_c\): cone offset/amplitude;
- \(\tau\): cone time constant;
- \(S_2\): rod recovery slope;
- \(\alpha\): rod-cone transition time.

I currently use the analytic Jacobian:

\[
\frac{\partial f}{\partial c_t}=1,
\]

\[
\frac{\partial f}{\partial c_c}=e^{-x/\tau},
\]

\[
\frac{\partial f}{\partial \tau}
=
c_c e^{-x/\tau}\frac{x}{\tau^2},
\]

\[
\frac{\partial f}{\partial S_2}
=
(x-\alpha)H(x,\alpha),
\]

\[
\frac{\partial f}{\partial \alpha}
=
-S_2H(x,\alpha),
\]

ignoring the undefined derivative of the Heaviside step exactly at \(x=\alpha\).

For an OLS fit, I currently calculate:

\[
\widehat{\mathrm{Cov}}(\hat\theta)
=
\hat\sigma^2(J^\mathsf{T}J)^{-1},
\qquad
\hat\sigma^2=\frac{RSS}{n-p}.
\]

This gives local Wald confidence intervals. I previously made the mistake of plotting parameter confidence intervals as though they formed a 95% prediction field. I now understand that I need to distinguish:

1. parameter confidence intervals;
2. a confidence band for the fitted mean curve;
3. a prediction band for future observations.

I need to revisit this carefully so that I understand the mathematics and implement it correctly.

Please help me:

- verify every Jacobian derivative;
- explain the relationship between \(J^\mathsf{T}J\), the Gauss–Newton Hessian, and the exact RSS Hessian;
- explain why raw and scaled condition numbers differ;
- calculate covariance and parameter correlations;
- identify the loss of identifiability of \(\alpha\) as \(S_2\to0\);
- implement local Wald parameter intervals;
- implement a confidence band for the mean fitted curve;
- implement a prediction band including residual noise;
- explain simultaneous versus pointwise bands;
- design parametric and residual bootstrap validation;
- decide which inference quantities should be calculated for all 36,000 simulations and which should be calculated only for a stratified subset;
- assess empirical 95% coverage using the known generating parameters.

The old symbolic Hessian routine differentiated a smoothed model that was not identical to the final stepped P5c model, so it should not be treated as the reference method.

Please proceed slowly and derive the equations before proposing revised R functions. Begin by asking me to paste the current `P5cJacobian()`, confidence interval, and plotting functions.