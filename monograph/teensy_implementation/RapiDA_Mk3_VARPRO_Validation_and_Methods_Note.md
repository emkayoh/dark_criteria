# RapiDA Mk3 VARPRO Validation and Methods Note

*Simulation-based implementation sign-off*

| **Implementation status** | **Accepted for RapiDA Mk3 simulation integration**                 |
|---------------------------|--------------------------------------------------------------------|
| Reference comparator      | Full global VARPRO (“Look-for”)                                    |
| Scope                     | Embedded numerical/operational validation; not clinical validation |

# 1. Executive summary

The real-time dark-adaptation analysis used in the RapiDA Mk3 prototype
was changed from iterative five-parameter gradient descent to a
variable-projection (VARPRO) method. The implementation profiles the
linear parameters at fixed nonlinear parameters and uses a full global
search only for initialisation or explicit reference checking.
Subsequent response-by-response analyses use a directed coarse
reconnaissance followed by two-dimensional Nelder–Mead refinement.

Across five end-of-test comparisons covering normal-human, slow-rod and
long-alpha simulations, the fast directed refinement reproduced the full
global VARPRO solution to numerical precision. Analysis time fell from
174–247 ms for the global search to 6–13 ms for refinement, a mean
speed-up of 22.0×. Profile evaluations were reduced by a mean factor of
20.7×.

The implementation also incorporates two safeguards discovered during
testing: a minimum post-alpha support rule (at least five observations
and at least one minute of data after alpha), and an S2 detectability
diagnostic based on \|S2\| \>= 0.55 × RMSE. The detectability rule is
reported as interpretation metadata and does not alter the fitted
parameters.

This note signs off the embedded algorithm for the Mk3 development path.
The current RapiDA generation is left unchanged. A later RStudio report
can use the same test logs as an appendix to the paper on VARPRO applied
to dark-adaptation data.

# 2. Scope and intended use

The objective was to determine whether a profiled least-squares method
could provide numerically reliable on-the-fly dark-adaptation estimates
without blocking the Teensy stimulus-control loop for clinically
relevant periods. The work therefore assessed both numerical agreement
with a deliberately expensive global reference search and execution time
on the embedded target.

The tests reported here are simulated-human engineering tests. They
establish implementation behaviour, numerical agreement and timing. They
do not constitute clinical validation, population validation, or a
formal statistical study of parameter recoverability.

# 3. Embedded VARPRO method

## 3.1 Model

The five-parameter dark-adaptation model used by the embedded analysis
is

$y(t) = ct + cc\exp(-t/\tau) + S2(t-\alpha)H(t-\alpha)$

For fixed tau and alpha, ct, cc and S2 are linear parameters. VARPRO
therefore removes these three terms from the nonlinear search by solving
the conditional linear least-squares problem directly.

## 3.2 Profiled linear solve and S2 bounds

For each candidate (tau, alpha), the embedded implementation accumulates
the required cross-products in one pass through the observations and
solves a fixed 3×3 system. No observation-length design matrix or
heap-allocated vector object is required. S2 is constrained to the
configured interval \[-0.5, 0\]. If either S2 bound is active, ct and cc
are re-solved with S2 fixed rather than merely clipping the
unconstrained estimate.

The C++ implementation uses small fixed linear systems rather than the
QR machinery used in the R numerical-development code. The simulation
comparisons in this note assess the complete embedded method against its
own full global VARPRO reference path; they are not a formal
R-versus-C++ equivalence experiment.

## 3.3 Global fit

The full reference fit searches 40 tau values and 80 alpha values (3,200
profiled fits), retains the lowest-RSS candidate, and optionally refines
the nonlinear pair with Nelder–Mead in (log(tau), alpha) space. The
embedded tau upper bound used for these tests was 3.0 minutes. The upper
alpha search limit is further restricted by the post-alpha support rule
described below.

## 3.4 Directed sequential refinement

After a valid full-model result has been obtained, the next response set
is not re-searched globally. The previous tau and alpha are retained as
a warm start. A directed 8×8 reconnaissance is then evaluated before
Nelder–Mead refinement. In the final tested version, the alpha
reconnaissance used six local points spanning approximately alpha − 1.0
to alpha + 2.0, together with one backward scout at alpha − 2.0 and one
longer forward scout at alpha + 3.5, all clipped to admissible bounds.
The tau reconnaissance used seven logarithmically spaced points from
tau/2 to 2×tau and one wider scout at 3×tau.

This design emerged from testing: pure local warm-start refinement could
remain in an early alpha basin, whereas a small directed grid retained
millisecond timing while allowing the solution to move between basins as
new rod data became available.

## 3.5 Support rule for alpha

A candidate alpha is admissible only when the data contain both (i) at
least five observations strictly after alpha and (ii) at least one
minute of observed time after alpha. A sample exactly at alpha is not
counted because its rod term is zero and it therefore provides no
information about the rod slope. This rule prevents spurious late breaks
from being created by fitting a steep line to only the final few
observations.

## 3.6 Early cone-only regime

From four observations onward, if the full P5c model is not yet
supportable, varproFit() returns the identifiable cone exponential fit
(ct, cc, tau) and reports S2 and alpha as NaN, with full_model = false.
This preserves a single public analysis interface while distinguishing
parameters that have not yet become estimable. The downstream parser
still requires a later protocol update before the preliminary NaN values
are used by the production display.

## 3.7 S2 detectability diagnostic

The application reports an interpretation diagnostic based on prior
numerical work:

$|S2|_{detect} \approx 0.55\,RMSE, \quad RMSE = \sqrt{RSS/n}$

The diagnostic is intentionally separate from the optimiser. The fitted
S2 and alpha values are left untouched; the output simply states whether
the magnitude of the fitted rod slope is above or below the approximate
detection threshold. This allows the downstream software to use the flag
later without changing the numerical fit.

# 4. Engineering validation approach

The main acceptance test was end-of-test agreement between the fast
on-the-fly result and the explicit full global “Look-for” fit on the
same captured observations. The comparison was made after stopping the
simulation so that both algorithms saw exactly the same dataset.

The following simulation modes were exercised: normal-human P5c
behaviour, reduced/slow rod behaviour, and long-alpha behaviour.
Slow-rod simulations are deliberately challenging because alpha becomes
poorly identified when the rod slope is small. Long-alpha simulations
challenge the ability of the sequential search to follow a genuine late
break without confusing it with an unsupported endpoint artefact.

The engineering acceptance criteria used here were: (1) no material
increase in RSS relative to the full global reference, (2) effectively
identical fitted parameters when S2 is identifiable, (3) analysis
latency comfortably below the full-grid blocking times observed in the
original prototype, and (4) correct rejection of unsupported endpoint
breaks.

# 5. Results

## 5.1 Full-global timing baseline

Before directed refinement was introduced, a normal-human simulation
using the full global VARPRO search on every new response required 173
ms and 3,264 profile evaluations at n = 77. That blocking interval was
considered long enough to threaten the timing of the stimulus
flicker/ramp loop. This baseline motivated the sequential refinement
path.

## 5.2 Direct refine-versus-global comparisons

| **Test**       | **n** | **Refine ms** | **Global ms** | **Speed-up** | **Refine evals** | **Global evals** |
|----------------|-------|---------------|---------------|--------------|------------------|------------------|
| Normal human 2 | 77    | 6             | 174           | 29.0×        | 126              | 3266             |
| Slow rods 6    | 77    | 9             | 191           | 21.2×        | 171              | 3296             |
| Slow rods 7    | 82    | 10            | 203           | 20.3×        | 168              | 3287             |
| Long alpha 1   | 100   | 13            | 247           | 19.0×        | 178              | 3308             |
| Long alpha 2   | 100   | 12            | 246           | 20.5×        | 164              | 3301             |

Across these five direct comparisons, refinement was 19.0× to 29.0×
faster than the full global search (mean 22.0×).

| **Test**       | **RSS refine** | **RSS global** | **\|ΔRSS\|** | **Max \|parameter Δ\|** | **S2 criterion** |
|----------------|----------------|----------------|--------------|-------------------------|------------------|
| Normal human 2 | 0.1828806735   | 0.1828806735   | 0.00e+00     | 7.34e-06                | Detected         |
| Slow rods 6    | 0.7426327839   | 0.7426327838   | 1.00e-10     | 3.08e-06                | Detected         |
| Slow rods 7    | 0.9668864325   | 0.9668864326   | 1.00e-10     | 7.24e-06                | Below threshold  |
| Long alpha 1   | 1.0864014929   | 1.0864014929   | 0.00e+00     | 5.17e-06                | Detected         |
| Long alpha 2   | 1.4509838085   | 1.4509838070   | 1.50e-09     | 9.03e-06                | Detected         |

The largest absolute difference among ct, cc, tau, S2 and alpha in any
of the five comparisons was below 1×10^-5. RSS differences were at
floating-point/reporting precision.

## 5.3 End-point parameter agreement

| Test | ct (R / G) | cc (R / G) | tau (R / G) | S2 (R / G) | alpha (R / G) | RSS (R / G) |
|---|---|---|---|---|---|---|
| Normal human 2 | -1.4792743 / -1.4792734 | 1.4238563 / 1.4238566 | 0.5670445 / 0.5670430 | -0.2289364 / -0.2289361 | 3.0574888 / 3.0574815 | 0.1828807 / 0.1828807 |
| Slow rods 6 | -1.5264547 / -1.5264550 | 1.4120528 / 1.4120513 | 0.6881310 / 0.6881326 | -0.1617139 / -0.1617142 | 6.3150297 / 6.3150327 | 0.7426328 / 0.7426328 |
| Slow rods 7 | -1.5334326 / -1.5334337 | 1.3695489 / 1.3695436 | 0.7463784 / 0.7463857 | -0.0324521 / -0.0324515 | 4.9561833 / 4.9561833 | 0.9668864 / 0.9668864 |
| Long alpha 1 | -1.4972364 / -1.4972358 | 1.4071538 / 1.4071590 | 0.6267271 / 0.6267224 | -0.2253761 / -0.2253764 | 6.1287833 / 6.1287833 | 1.0864015 / 1.0864015 |
| Long alpha 2 | -1.5473934 / -1.5473943 | 1.5927688 / 1.5927598 | 0.6156596 / 0.6156667 | -0.2404072 / -0.2404067 | 6.5135337 / 6.5135333 | 1.4509838 / 1.4509838 |

*R/G = directed refinement / full global Look-for.*

## 5.4 Interpretation by simulation mode

Normal human. The direct normal-human comparison reached exactly the
same reported RSS in 6 ms versus 174 ms. The five fitted parameters
differed by at most about 7×10^-6. This provides the cleanest
demonstration that the fast sequential path can reproduce the global
optimum when the rod component is well expressed.

Slow rods. Slow-rods run 6 again matched the global optimum to numerical
precision, with S2 clearly above the approximate detectability
threshold. In slow-rods run 7 the refine and global algorithms also
agreed essentially exactly, but \|S2\| was below 0.55×RMSE. The reported
alpha should therefore be treated as a numerical fit rather than a
well-identified physiological break. This distinction is an
identifiability issue, not an optimisation disagreement.

Long alpha. Both long-alpha tests produced essentially identical refine
and global results, including alpha values of about 6.13 and 6.51
minutes respectively. The fitted S2 values were well above the
detectability threshold. These runs are important because they show that
the directed search can follow a genuinely late break while the
alpha-support rule prevents unsupported endpoint minima.

## 5.5 S2 detectability values

| **Test**       | **RMSE** | **0.55×RMSE** | **\|S2\|** | **\|S2\| / limit** |
|----------------|----------|---------------|------------|--------------------|
| Normal human 2 | 0.0487   | 0.0268        | 0.2289     | 8.54               |
| Slow rods 6    | 0.0982   | 0.0540        | 0.1617     | 2.99               |
| Slow rods 7    | 0.1086   | 0.0597        | 0.0325     | 0.54               |
| Long alpha 1   | 0.1042   | 0.0573        | 0.2254     | 3.93               |
| Long alpha 2   | 0.1205   | 0.0663        | 0.2404     | 3.63               |

# 6. Development findings and safeguards

Several failure modes were deliberately retained in the engineering
record because they motivated the final algorithm rather than being
hidden by the final result.

- **Early full-model failure:** The original R-derived tau upper bound
  depended on log(max(time)); during an accumulating test this became
  invalid before one minute. The embedded implementation instead uses a
  fixed tau maximum of 3.0 minutes.

- **Pure warm-start trapping:** Local refinement alone could remain in
  an early alpha = 0.5 basin even after a better distant basin emerged.
  The directed 8×8 reconnaissance was introduced to permit basin changes
  while preserving millisecond execution.

- **Late endpoint artefact:** An unrestricted global search produced a
  late alpha near the end of the record with S2 on its -0.5 boundary and
  only a small RSS advantage. Requiring at least five post-alpha
  observations and one minute of post-alpha duration removed this
  unsupported edge fit.

- **Weak-rod alpha instability:** When \|S2\| is below its approximate
  detection threshold, alpha can move substantially with negligible
  change in RSS. The final implementation leaves the fitted values
  unchanged and reports an explicit detectability criterion instead of
  forcing alpha to a preferred basin.

# 7. Mk3 implementation sign-off

Decision: the current embedded VARPRO implementation is accepted as the
Mk3 development implementation for continued integration and testing.

- Full global VARPRO remains available through Look-for as an
  independent reference check.

- Directed refinement reproduces the global solution to numerical
  precision in the direct comparison set.

- End-of-test refine latency was 6–13 ms in the recorded comparisons,
  versus 174–247 ms for the global reference.

- Alpha candidates require at least five post-alpha observations and at
  least one minute of post-alpha data.

- S2 detectability is reported separately from the optimiser using the
  0.55×RMSE criterion.

- Early cone-only VARPRO uses the same public result type, with S2 and
  alpha reported as NaN until the full model is supportable.

- The existing RapiDA generation remains unchanged; the new method is
  reserved for Mk3.

Remaining integration work: update the downstream parser/display to
recognise the early cone-only NaN fields and, if useful, consume the S2
detection criterion. This is intentionally separate from the numerical
sign-off above.

# 8. Manuscript-ready methods / appendix draft

The following text is written in a paper-oriented style so that it can
be adapted directly into the planned RStudio appendix. Numerical tables
and figures can subsequently be regenerated from the raw simulation logs
in R.

## 8.1 Embedded sequential VARPRO analysis

A variable-projection implementation was developed for real-time
analysis of dark-adaptation measurements on the RapiDA Mk3 embedded
controller. The five-parameter model comprised a cone exponential and a
delayed linear rod component. For each fixed pair of nonlinear
parameters, tau and alpha, the linear parameters ct, cc and S2 were
estimated by least squares. The rod slope was constrained to the
interval -0.5 \<= S2 \<= 0; when a bound was active, ct and cc were
re-estimated with S2 fixed at the boundary. The nonlinear objective was
the residual sum of squares after profiling the linear parameters.

The first supportable five-parameter fit used a 40×80 grid over tau and
alpha followed by Nelder–Mead refinement in log(tau) and alpha.
Thereafter, each new observation was analysed using the previous
nonlinear solution as a warm start. To avoid local-basin trapping, the
warm start was supplemented by a directed 8×8 reconnaissance grid
spanning a local and asymmetric neighbourhood in alpha together with
wider scout points, and a logarithmic neighbourhood in tau. Nelder–Mead
refinement was then applied from the best reconnaissance candidate.

To prevent endpoint artefacts, alpha was considered admissible only when
at least five observations occurred strictly after the candidate break
and at least one minute of data followed the break. Before these
conditions were met, the implementation returned the identifiable
cone-only exponential parameters and marked S2 and alpha as unavailable.
A separate diagnostic classified S2 as detected when \|S2\| was at least
0.55 times the residual RMSE; this criterion was not used to modify the
fitted parameter values.

## 8.2 Embedded validation against the global reference

The sequential implementation was compared with an explicit full global
VARPRO search performed after each simulation had been stopped. Five
direct end-point comparisons included a normal-human simulation, two
slow-rod simulations and two long-alpha simulations. Across these tests,
the residual sums of squares from the sequential and global solutions
agreed to reporting precision and the maximum absolute difference among
the five fitted parameters was below 1×10^-5. The sequential analysis
required 6–13 ms compared with 174–247 ms for the global search,
corresponding to a 19–29-fold reduction in execution time.

The slow-rod simulations also illustrated the distinction between
optimiser agreement and parameter identifiability. In one run the fitted
rod slope was below the approximate 0.55×RMSE detection threshold; the
sequential and global algorithms nevertheless returned essentially
identical fits. In this regime, variability in alpha should be
interpreted as a consequence of weak rod information rather than failure
of the optimisation method. Conversely, two long-alpha simulations
produced well-detected rod slopes and sequential estimates of alpha that
were numerically indistinguishable from the full global reference.

## 8.3 Suggested RStudio appendix outputs

- A table reproducing the end-point refine/global parameter pairs and
  their differences.

- A timing/evaluation table and simple plot showing the reduction from
  full global search to directed refinement.

- Plots of the profiled objective surface or alpha/S2 behaviour for
  representative normal, slow-rod and long-alpha datasets.

- A plot or table showing \|S2\| relative to 0.55×RMSE, highlighting the
  weak-rod case where alpha is poorly identified.

- A short development note illustrating the endpoint artefact removed by
  the five-point/one-minute alpha-support rule.

# Appendix A. Recorded end-point comparisons

## Normal human 2

**Directed refine:** ct=-1.4792742783, cc=1.4238563320,
tau=0.5670444591, S2=-0.2289363708, alpha=3.0574887978,
RSS=0.1828806735, time=6 ms, evaluations=126, n=77.

**Full global:** ct=-1.4792733509, cc=1.4238565521, tau=0.5670429893,
S2=-0.2289361058, alpha=3.0574814543, RSS=0.1828806735, time=174 ms,
evaluations=3266, n=77.

## Slow rods 6

**Directed refine:** ct=-1.5264547112, cc=1.4120527694,
tau=0.6881309772, S2=-0.1617138757, alpha=6.3150296534,
RSS=0.7426327839, time=9 ms, evaluations=171, n=77.

**Full global:** ct=-1.5264549528, cc=1.4120512997, tau=0.6881326330,
S2=-0.1617142223, alpha=6.3150327345, RSS=0.7426327838, time=191 ms,
evaluations=3296, n=77.

## Slow rods 7

**Directed refine:** ct=-1.5334326172, cc=1.3695488598,
tau=0.7463784197, S2=-0.0324520889, alpha=4.9561833374,
RSS=0.9668864325, time=10 ms, evaluations=168, n=82.

**Full global:** ct=-1.5334337233, cc=1.3695435628, tau=0.7463856562,
S2=-0.0324515363, alpha=4.9561833200, RSS=0.9668864326, time=203 ms,
evaluations=3287, n=82.

## Long alpha 1

**Directed refine:** ct=-1.4972363565, cc=1.4071538435,
tau=0.6267271154, S2=-0.2253761470, alpha=6.1287833341,
RSS=1.0864014929, time=13 ms, evaluations=178, n=100.

**Full global:** ct=-1.4972358187, cc=1.4071590085, tau=0.6267223888,
S2=-0.2253763784, alpha=6.1287833326, RSS=1.0864014929, time=247 ms,
evaluations=3308, n=100.

## Long alpha 2

**Directed refine:** ct=-1.5473934057, cc=1.5927687905,
tau=0.6156596389, S2=-0.2404071876, alpha=6.5135336511,
RSS=1.4509838085, time=12 ms, evaluations=164, n=100.

**Full global:** ct=-1.5473942511, cc=1.5927597615, tau=0.6156666522,
S2=-0.2404067420, alpha=6.5135333400, RSS=1.4509838070, time=246 ms,
evaluations=3301, n=100.
