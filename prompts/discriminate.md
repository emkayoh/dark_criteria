I am building an R simulation study to determine when a biphasic P5c dark-adaptation curve can be distinguished from a simpler P3 exponential model.

The generating P5c model is:

\[
y = c_t + c_c e^{-x/\tau} + S_2(x-\alpha)H(x,\alpha).
\]

The main experimental array is:

- \(S_2 \in \{-0.05,-0.10,-0.15,-0.20,-0.25,-0.30\}\)
- \(\alpha \in \{3,5,7,9\}\) minutes
- \(\sigma \in \{0,0.05,0.10,0.15,0.20,0.30\}\) log units
- 250 replicates per condition

This gives 36,000 simulated datasets. I am also considering adding \(S_2=0\) as the null condition for estimating false-positive classification rates.

I already have a `simulateData()` function that returns:

- simulated observations;
- the true generating parameters;
- simulation metadata;
- a reproducible seed;
- a short simulation ID;
- simulation number and replicate.

I now need to finalise a wrapper called `fitOneSimSet()` that analyses one simulated dataset and returns exactly one result row suitable for binding into a large results table.

The wrapper should:

1. Extract `x` and `y` from the simulation object.
2. Fit P3.
3. Obtain a profile least-squares P5c initial estimate.
4. Perform robust pseudo-Huber refinement.
5. Perform final unweighted P5c OLS refinement.
6. Recompute P3 and P5c RSS directly.
7. Confirm that P5c can reproduce the P3 solution when \(S_2=0\).
8. Calculate AIC and AICc consistently.
9. Record the selected model and whether classification is correct.
10. Calculate parameter estimates, errors, convergence diagnostics, bounds, runtime, and inference diagnostics.
11. Return a row even when a fitting stage fails, recording the error stage and message.

Useful result columns include:

- identifiers and seeds;
- true parameters;
- estimated P5c parameters;
- P3 and P5c RSS, AIC and AICc;
- `delta_AICc = AICc_P3 - AICc_P5c`;
- selected model;
- true and classified biphasic status;
- classification correctness;
- convergence status;
- boundary status;
- Jacobian condition numbers and eigenvalues;
- CI coverage of the known true values;
- elapsed time;
- error and warning information.

Please help me design and implement `fitOneSimSet()` in modular R code. The final wrapper must be suitable for serial and parallel execution, must not write directly to a shared CSV from worker processes, and must be completely reproducible from the stored simulation seed.

Begin by asking me to paste the current versions of `simulateData()`, `fitP3()`, `findInitialParametersProfiled()`, the P5c refinement functions, and my current draft of `fitOneSimSet()`.