# Note: Dimitrov et al. (2008) — a third strategy, and the limit of our claim

<!-- JMFK, 22 August 2026. Working note for the monograph discussion.
     Not a controlled document. -->

## The citation

Dimitrov PN, Guymer RH, Zele AJ, Anderson AJ, Vingrys AJ. *Measuring rod
and cone dynamics in age-related maculopathy.* Invest Ophthalmol Vis Sci
2008;49(1):55--65. doi:10.1167/iovs.06-1048

## What they do

They avoid the breakpoint entirely. Instead of an exponential phase and a
linear phase joined at a transition time, they model each of the cone and
rod components with a single decaying function and let the observed curve
be whichever mechanism is currently more sensitive. As printed (the
pasted text is OCR-damaged; check the appendix derivation for the exact
form) the model reads

$$
T(t) = \log_{10}\!\left(10^{\,T_i - Rt} + 10^{\,T_f}\right),
$$

with $T_i$ the initial threshold, $T_f$ the asymptotic threshold, and $R$
the rate of decay in decades per minute, applied separately to cone and
rod mechanisms (subscripts $c$ and $r$).

The form is a soft minimum. In linear units the decaying component and
the floor simply add, so in log units the curve falls at rate $R$ and then
bends smoothly onto $T_f$. That is physiologically well motivated: the
observer detects whichever mechanism is more sensitive at that moment,
and a sum in linear units is the natural smooth version of a minimum.

Fitting is by minimising the sum of squares in the Excel Solver module.

## Three observations

**1. The transition is not a parameter.** Where our model has $\alpha$ as
an explicit estimated quantity, Dimitrov's transition *emerges* from where
the two mechanisms cross. This is the same move as RIT, one level down:
the quantity of clinical interest becomes derived rather than estimated.
A consequence is that no confidence interval for the rod--cone break is
available, because the break is not in the model.

**2. The breakpoint decision returns by the back door.** Fitting cone and
rod components separately requires deciding first which observations
belong to which phase. That decision is exactly the segmentation
judgement the parameterisation avoided making explicit — but it is now
made by the analyst rather than the algorithm, and it is not recorded in
the parameters. The model looks cleaner than it is.

**3. Excel Solver.** Generic GRG minimisation of a sum of squares: no
starting-value discipline, no confidence intervals, no convergence record,
and results dependent on the state of the spreadsheet. As evidence for
the fragility argument this is the strongest of the three exhibits —
McGwin (1999, SAS `proc nlin`), Dimitrov (2008, Excel Solver), De Silva
(2022, trust-region least squares). Three eras, three off-the-shelf
optimisers, and in the middle case one whose results cannot be
reproduced from the paper.

## The important caveat: this bounds our claim

**Dimitrov's parameterisation is not separable.** The expression
$\log_{10}(10^{T_i - Rt} + 10^{T_f})$ is nonlinear in every parameter;
there is no linear coefficient to project out. Variable projection does
not apply to it.

It follows that the structural insight is a property of **the P5c
parameterisation**, not of dark adaptation as a phenomenon. The honest
statement is that this model form admits a closed-form inner solve, and
that other published forms of the same curve do not.

This should be said plainly in the discussion rather than left for a
reviewer to raise. Anyone who knows the Dimitrov work will ask precisely
this question, and the answer is a good one:

- the separable form is not a restriction imposed for computational
  convenience but the standard clinical parameterisation, whose
  parameters ($ct$, $cc$, $\tau$, $S2$, $\alpha$) carry the physiological
  meanings the field already uses;
- within that parameterisation the linear structure is available and has
  not been exploited;
- a model that dispenses with the explicit breakpoint gains smoothness
  but loses the ability to estimate, and place an interval on, the
  rod--cone break — which is one of the four quantities we argue a
  clinician should have.

## For the monograph

Use all three papers as the documentary basis of the opening argument,
and use Dimitrov again in the discussion to bound the claim. Introducing
the limitation ourselves is stronger than defending it later.
