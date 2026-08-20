# Results

<!-- DRAFT, JMFK, 19 August 2026.
     Numerical values in this section come from the coarse-grid experiment
     (tau grid 40 points, alpha grid 80 points; four tau sets, 192,000
     replications). Values marked [COARSE: x] are to be replaced by the
     fine-grid figures when available; the accompanying prose is expected
     to stand unchanged, since the findings are stable across four cone
     regimes and across a correction to the fitting code. -->

## Design

Recovery curves were simulated from the P5c model with fixed cone
threshold (ct = -1.7) and cone coefficient (cc = 2), and with the cone
time constant held at one of four values, tau = 0.6, 1.2, 1.8, and 2.4
minutes, in four otherwise identical experiment sets. Within each set,
the rod slope S2 took eight values (0, -0.01, -0.05, -0.10, -0.15, -0.20,
-0.25, -0.30 log units per minute), the rod-cone break alpha took four
values (3, 5, 7, 9 minutes), and Gaussian threshold noise took six levels
(sd = 0, 0.05, 0.10, 0.15, 0.20, 0.30 log units). Each condition was
replicated 250 times with distinct seeds, giving 48,000 replications per
set and 192,000 in total. The S2 = 0 conditions constitute a null arm
against which false-positive rates are measured.

Every replication was fitted three ways: by the profiled (variable
projection) search over a grid of (tau, alpha) with the linear parameters
solved in closed form; by continuous Nelder-Mead refinement of the same
profiled objective, initialised at the grid optimum; and by full
five-parameter gradient descent initialised at the refined solution. A
three-parameter cone-only model (P3) was also fitted, and the two models
compared by AICc. Each result row records the seed and the repository
commit of the code that produced it.

## The profiled search leaves nothing for gradient descent to find

Gradient descent, applied to the converged profiled solution, produced no
useful improvement in any of the four cone regimes at any noise level.
The median reduction in residual sum of squares was zero at every
realistic noise level in all four sets, with 90th percentiles of order
[COARSE: 1e-11] for tau = 0.6 to 1.8. Parameter estimates moved by a
median of [COARSE: 1e-8 to 1e-4] minutes in alpha, between four and seven
orders of magnitude below the grid resolution.

Where gradient descent did move estimates, it moved them away from the
truth as often as toward it. Across sets and noise levels, alpha
estimates were closer to the truth after descent in
[COARSE: 0.38 to 0.47] of replications and further from it in
[COARSE: 0.38 to 0.44]; S2 estimates were improved in
[COARSE: 0.33 to 0.40] and degraded in [COARSE: 0.39 to 0.47]. Descent
therefore degraded the rod slope estimate more often than it improved it.

The optimiser's own status reports explain this directly. Between
[COARSE: 21% and 53%] of descent runs terminated with the status
"no improving step", rising with noise, and reaching
[COARSE: 61% to 79%] in the noiseless condition. Genuine iteration-limit
exhaustion was rare and confined to the slowest cone regime
([COARSE: 74 cases] at tau = 2.4, noise 0.3). The profiled solution is
stationary to numerical tolerance in all five directions: the closed-form
linear solve enforces stationarity exactly in the three linear
parameters, and the refinement stage achieves it in the remaining two.
Descent is being asked to improve a point at which no improving step
exists.

The exception is instructive. In the slowest cone regime (tau = 2.4),
descent produced 90th-percentile residual reductions of up to
[COARSE: 0.9%] while still degrading S2 more often than improving it.
This is movement along the ridge in the error surface that arises when
the cone exponential approaches an affine function of time over the test
window, so that ct, cc, and tau trade off against one another. Descent
travels along this ridge among near-equivalent solutions without
improving parameter recovery.

## The refinement stage contributes a small, bounded polish

Separating the two profiled stages shows where the small remaining gain
lies. Continuous refinement of the grid optimum reduced residual sum of
squares by a median of [COARSE: 0.013% to 0.43%], decreasing with noise
and with tau, and shifted tau by a median of [COARSE: 0.008 to 0.021]
minutes and alpha by [COARSE: 0.027 to 0.040] minutes: fractions of the
respective grid steps. In the noiseless condition the refinement removes
essentially the whole residual, which is grid quantisation error and
nothing else. Refinement never failed numerically
([COARSE: 0 failures in 192,000]), and was skipped by design in the
[COARSE: 7,132] replications whose fitted slope lay on the zero bound,
where alpha is unidentified.

The three-stage accounting is therefore: the grid locates the optimum;
refinement polishes it by well under one per cent of residual; full
gradient descent contributes nothing measurable.

## Boundary behaviour

Fits in which the unconstrained slope estimate fell outside the
physiological bounds (-0.5 to 0 log units per minute) were re-solved with
the slope fixed at the active bound, giving the exact constrained
least-squares solution. Such fits fall into two classes with distinct
meanings. A fit pinned at zero is the model reporting no detectable rod
phase; these accounted for [COARSE: 2.2% to 5.1%] of replications,
concentrated in the null arm and at shallow slopes. A fit pinned at
maximum steepness indicates an estimate beyond the physiological range;
these accounted for [COARSE: 1.6% to 5.6%], rising with noise.

Pinned fits occurred in the null arm at rates far above chance
([COARSE: 74%] of null replications at noise 0.05 were interior, that is,
the search located some negative slope somewhere in the (tau, alpha)
plane), which quantifies the multiplicity pressure that any detection
rule applied to this search must resist.

## Detection thresholds

Two detection rules were compared. The model-comparison rule declares a
rod phase when AICc favours P5c over P3. The interval rule declares a
rod phase when the confidence interval for S2 excludes zero, with fits
pinned at zero treated as non-detections, fits pinned at maximum
steepness referred to the model comparison, and interval failures
treated conservatively as non-detections.

For each set and noise level, the slope detected on 90% of occasions was
estimated by logistic regression of detection on |S2| and inversion at
p = 0.9. Where the empirical detection probability did not reach 0.9 at
any tested slope, no threshold is reported, since the logistic
asymptote would manufacture a crossing outside the tested range.

<!-- TABLE 1 here: S2_90 by noise level and tau set, both rules, with
     ceilings. Values from thr_final and ceiling_final across the four
     sets. -->

Under the interval rule, thresholds were [COARSE: 0.016 to 0.025] log
units per minute at noise 0.05, rising to [COARSE: 0.163 to 0.175] at
noise 0.30, and varied little across the fourfold range of cone time
constants. Expressed relative to the threshold noise, the detectable
slope was approximately [COARSE: 0.5 to 0.6] times the noise standard
deviation per minute for all noise levels at or above 0.10, in every
cone regime. Detection thresholds are therefore governed by the
signal-to-noise ratio of the rod branch and are largely independent of
cone recovery speed.

False-positive rates under the interval rule were [COARSE: 1.2% to 6.2%]
and, notably, did not rise systematically with noise: the interval widens
as the data degrade, so the rule self-calibrates its specificity.

## The model-comparison rule fails where the interval rule does not

The two rules behave very differently as cone recovery slows. At the
fastest cone regime the model comparison is the more sensitive rule,
attaining thresholds of [COARSE: 0.0125] against [COARSE: 0.022] at noise
0.05, though at a higher false-positive rate. As tau increases, its
maximum attainable sensitivity falls monotonically: at noise 0.30 the
ceiling was [COARSE: 0.958, 0.887, 0.779, 0.698] for tau = 0.6, 1.2, 1.8,
and 2.4 respectively, and failures appear within the physiological range
from tau = 1.8 upward. The interval rule's ceiling never fell below
[COARSE: 0.988] in any of the 24 set-by-noise cells.

The mechanism is model competition rather than estimation failure. When
the cone time constant is long, the cone exponential of the P3 model
extends through the region of the rod-cone break and absorbs part of the
rod branch's curvature, so the evidence difference between the models
shrinks even where the rod slope itself remains well estimated. This
matters clinically because slowed cone recovery is itself a feature of
early disease: the model-comparison rule loses sensitivity precisely in
the population for which the test is intended.

<!-- FIGURE 1 here: detection surfaces, four panels by tau set, both
     rules, P(detect) against |S2| with noise as colour. -->

<!-- FIGURE 2 here: ROC panels, AICc threshold sweep with the interval
     rule's operating point marked, by noise level, for the extreme tau
     sets. -->

## Interval calibration

Confidence intervals for the rod slope covered the true value in
[COARSE: 0.911 to 0.938] of interior fits, close to but slightly below
the nominal 95%, consistently across all four cone regimes and all
noise levels. Intervals for the break time were less well calibrated,
covering the true value in [COARSE: 0.803 to 0.905] of replications, and
degrading as the cone time constant increased.

This asymmetry follows from the same ridge geometry that produces the
model-comparison failure: the position of the break entangles with the
cone tail, whereas the slope of the rod branch does not. The
clinically consequential parameter is the one whose inference remains
sound.

(Coverage is not reported for the noiseless condition, where intervals
are numerically degenerate.)

## Robustness of these results

The experiment was repeated in full after a correction to the treatment
of fits at the slope bounds, in which the linear parameters had
previously been retained from the unconstrained solution rather than
re-solved under the active constraint. The correction changed boundary
classification counts by single figures per condition and altered no
reported quantity by more than [COARSE: 0.004]. All results reported
here are from the corrected code; every result row carries the commit
hash of the code that produced it.
