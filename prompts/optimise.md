I am developing an R fitting pipeline for the five-parameter dark-adaptation model:

\[
y = c_t + c_c e^{-x/\tau} + S_2(x-\alpha)H(x,\alpha).
\]

The current workflow includes:

1. Profile least-squares initialisation, exploiting the fact that \(c_t\), \(c_c\), and \(S_2\) are linear when \(\tau\) and \(\alpha\) are fixed.
2. Pseudo-Huber robust refinement using `optim()` and an analytic gradient.
3. A final unweighted ordinary least-squares refinement so that P5c can be compared fairly with the nested P3 model using AIC/AICc.
4. A P3 fit:
   \[
   y = c_t + c_c e^{-x/\tau}.
   \]

Earlier implementations used a five-dimensional parameter grid, gradient descent, momentum/NAG, and an `oldar()` routine that scanned \(\alpha\) and \(\tau\). The profile least-squares approach may replace much of this older machinery.

The original runtime was about 3.6 seconds per dataset. Profiling and optimisation reduced this to approximately 0.17–0.24 seconds.

Please help me:

- review the complete optimisation pipeline;
- identify unnecessary or duplicated stages;
- compare profile least squares, pseudo-Huber refinement, and final OLS refinement;
- verify that the P5c OLS fit always satisfies the nested-model condition:
  \[
  RSS_{P5c} \le RSS_{P3};
  \]
- design numerical regression tests;
- improve naming, documentation, bounds, convergence reporting, and error handling;
- assess which parts could later be ported to a Django application and an incremental Teensy implementation.

Important implementation details:

- Avoid relying on global `x` and `y`.
- Use exact list names such as `$params`, not partial matching such as `$param`.
- P3 and P5c AIC/AICc must be calculated from directly recomputed, unweighted RSS values.
- Test or example data must not be loaded automatically when an R file is sourced.
- The R implementation is the reference implementation for later Django and Teensy ports.

Begin by asking me to paste the current versions of the relevant functions or files.