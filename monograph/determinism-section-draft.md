# Determinism and cross-platform reproducibility

<!-- Replacement for the "Determinism across platforms" section of
     DISC-IP-003-appendix-A.Rmd. Revised 22 August 2026 against the
     complete macOS/RISC-V comparison (both platforms ran the full
     experiment; the earlier truncated run is superseded). Numbers below
     are final. -->

The method is deterministic by construction: a fixed grid, a closed-form
solve at each cell, and a stated tie-break. On a single platform,
identical data yield bit-identical parameters. Across platforms, exact
agreement additionally depends on the floating-point summation order
inside the linear algebra library, which differs between builds. This
section reports a direct measurement of that agreement.

## Design of the comparison

The complete validation experiment was executed on two machines under the
same repository commit, verified identical by `git diff`, with the
pseudo-random number generator version pinned so that both platforms
simulate identical data:

| | Development platform | Independent platform |
|---|---|---|
| Architecture | arm64 (Apple silicon) | riscv64 (UltraRISC UR-DP1000) |
| Operating system | macOS | Ubuntu |
| R version | 4.5.2 | 4.3.3 |
| BLAS | Accelerate / vecLib | reference BLAS |

The two builds therefore differ in instruction set architecture, operating
system, R version, and linear algebra implementation: close to a worst
case for exact agreement.

**Inputs are bit-identical.** Under the pinned generator, the same seed
produces the same pseudo-random draws on both machines, verified to the
last bit by comparing the exact hexadecimal representation of the values
(`sprintf("%a", ...)`). Every simulated recovery curve is therefore
identical on the two platforms, and any difference in the fitted
parameters is attributable to the fitting arithmetic alone.

The comparison covers 191,996 replications: the four cone-time-constant
sets in full, on both platforms.

## Results

Fits at the lower bound of the $\tau$ grid are excluded from the
parameter comparison and reported separately: there the cone exponential
collapses over the sampled interval and the cone coefficient is
unidentified, taking values of order $10^{13}$ on both platforms. These
accounted for 15,271 replications, 8.0% of the total. Both platforms
reached the same degenerate solution in every such case, agreeing to
seven significant figures.

Over the remaining 176,725 identified fits:

| Cone time constant $\tau$ | 0.6 | 1.2 | 1.8 | 2.4 |
|---|---|---|---|---|
| Identified fits compared | 44,165 | 43,995 | 43,913 | 44,652 |
| Residual sum of squares bit-identical | 76.5% | 76.0% | 75.7% | 75.8% |
| RSS difference, 99th percentile | $1.0\times10^{-14}$ | $1.0\times10^{-14}$ | $1.0\times10^{-14}$ | $1.0\times10^{-14}$ |
| RSS difference, 99.9th percentile | $1.1\times10^{-14}$ | $1.1\times10^{-14}$ | $1.1\times10^{-14}$ | $1.7\times10^{-6}$ |
| Largest RSS difference | $2.2\times10^{-4}$ | $1.2\times10^{-5}$ | $7.1\times10^{-4}$ | $8.0\times10^{-4}$ |
| Break times differing by more than $10^{-6}$ min | 2 | 1 | 4 | 60 |
| Boundary classification disagreements | 0 | 0 | 1 | 0 |

Roughly three quarters of all fits are bit-identical across the two
architectures, and the residual sum of squares agrees to
$1\times10^{-14}$ in 99% of cases in every cone regime. Classification of
the fitted slope as interior or at a bound agreed in 191,995 of 191,996
comparisons: a single disagreement in the whole experiment.

## The source and size of the exceptions

Where the two platforms differ, the difference arises at one specific
point in the pipeline, and not in the exhaustive search. In every case
examined the two platforms selected the same winning grid cell, with
identical grid parameters and grid residual. The divergence occurs in the
subsequent continuous refinement, at the test that decides whether the
refined solution is accepted:

$$\text{accept if } \mathrm{RSS}_{\text{refined}} < \mathrm{RSS}_{\text{grid}}.$$

When the refinement improves the residual only at the level of
floating-point rounding, this strict comparison can fall either way, and
the two platforms then report the two endpoints of a step that made no
material difference to the fit. Across the four sets this occurred in 1,
1, 1, and 53 replications respectively.

**The exceptions concentrate in the ill-conditioned regime.** Both the
count of accept-test disagreements (1, 1, 1, 53) and the count of
materially differing break times (2, 1, 4, 60) rise by more than an order
of magnitude at the longest cone time constant, while the other three
regimes remain at one to four. This is expected from the geometry of the
problem. When $\tau$ is long relative to the test window, the cone
exponential approaches an affine function of time and the error surface
develops a ridge along which the parameters trade off; refinement gains
along such a ridge are small, so the accept test is more often decided by
rounding. The same regime is the only one in which the 99.9th percentile
of the residual difference leaves rounding territory at all.

The practical size of the exceptions is negligible. The largest
disagreement in break time anywhere in the comparison was 0.43 minutes,
in a replication with no true rod phase where both platforms returned a
fitted slope of about $-0.001$; the remaining worst cases differ by 0.05
to 0.38 minutes, that is, three to twenty-three seconds, against
confidence intervals for the break time that are 1.5 to 4 minutes wide.
In these replications the residual sums of squares agree to four
significant figures or better: the two platforms have found fits of
indistinguishable quality and differ only in which of two near-equivalent
parameter sets they report.

## Statement

Identical inputs, verified bit-identical across architectures, produce
fits that are bit-identical in roughly three quarters of cases and agree
to $1\times10^{-14}$ in residual sum of squares in 99% of cases, despite
differences in instruction set, operating system, R version, and linear
algebra implementation. The exhaustive profiled search itself agreed
exactly in every case examined, and the classification of the fitted
slope agreed in all but one of 191,996 comparisons. The rare exceptions
arise from the accept test of the optional refinement stage when its
improvement is at the level of rounding, concentrate in the
ill-conditioned cone regime, and are immaterial by any clinical or
statistical measure.

If bit-level cross-platform identity were ever required, two routes are
available: omitting the refinement stage, which the validation experiment
shows contributes a median residual improvement of well under one per cent
and parameter shifts of a fraction of a grid step; or replacing the
accept test with a tolerance, so that a refinement is accepted only when
it improves the residual by more than a stated margin.
