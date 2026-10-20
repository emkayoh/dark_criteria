# Note: how the field has fitted the dark adaptation curve, 1999–2022

<!-- JMFK, 22 August 2026. Consolidates the earlier separate notes on
     McGwin (1999), Dimitrov (2008) and De Silva (2022). Basis for the
     monograph's introduction and for the prior-art list in DISC-IP-003
     Section 6. Not a controlled document. -->

## The argument this supports

The field has treated the fragility of curve fitting as something to be
overcome with computation, when the model's own structure made much of
that computation unnecessary.

This can be shown from published methods and published output rather than
by characterising anyone's practice. Three papers span twenty-three years
and three eras of software.

**A caution about tone, and about accuracy.** These are not careless
papers. McGwin et al. recognised the conditional linearity and used it,
and compared five nonlinear methods before choosing one. Dimitrov et al.
sampled densely. De Silva et al. diagnosed the weak point correctly and
addressed it with the tools of their era. An earlier draft of this note
mischaracterised the 1999 paper on the basis of an OCR excerpt, and was
wrong. The claim to make is not that these groups were careless but that
a particular step went untaken for twenty-seven years — including by us,
over a decade of work on the same problem. That is also the more
defensible claim, and the one a reviewer from any of these groups could
read without objection.

---

## 1999 — McGwin, Jackson & Owsley: the structure recognised, and used once

McGwin G, Jackson GR, Owsley C. *Using nonlinear regression to estimate
parameters of dark adaptation.* Behav Res Methods Instrum Comput
1999;31(4):712--717. doi:10.3758/BF03200752

**Who.** The same group that went on to develop the AdaptDx and to publish
Jackson et al. (2014) on its diagnostic sensitivity and Owsley et al.
(2016) on delayed dark adaptation as a biomarker for incident AMD. This is
the methods foundation of the field's dominant commercial instrument,
written by its creators. It is a careful paper and should be described as
one.

### What they do, in their own account

The program has two stages. A **preliminary linear regression** fits the
dark adaptation data using four linear components delimited by transition
points the user supplies; those points are fixed for this stage and not
solved. Its purpose is stated explicitly: to supply subject-specific
starting values for the nonlinear stage. They set out the alternative they
rejected and why — fixed initial values would not cope with the individual
variability between normal and diseased eyes — and note the benefit as
fewer iterations to convergence.

The **nonlinear stage** takes those values into the `PARMS` statement of
`PROC NLIN` and solves all parameters, knots included; the user's
transition times are preliminary, not fixed. They compared the method of
false position (DUD) against Gauss-Newton, Marquardt, steepest descent and
Newton, **found the results equivalent**, and selected DUD because it
needed slightly fewer iterations. Convergence is at a change in sum of
squared errors of $10^{-8}$, with a 200-iteration cap. Two model forms are
fitted per subject and compared by a $z$ test: a two-exponential model
(Hecht; Barlow) and the one-exponential, two-linear-component form (after
Lamb et al. 1998; Leibrock et al. 1998) that is the ancestor of P5c.

This is considered comparative methods work, not a default reached for.
Any account that suggests otherwise is wrong, and an earlier draft of this
note was wrong on exactly that point.

### What they did not do

They recognised the conditional linearity and used it **as far as it goes
for initialisation**: one linear pass, at user-supplied fixed transition
points, to seed a seven-parameter nonlinear fit.

The step not taken — and not taken by anyone for twenty-seven years — is
to recognise that the same linear solve, run at *every* candidate rather
than once at the start, removes those parameters from the search
altogether rather than merely starting them well. Their linear regression
is an initialisation device; in the profiled method it is the fitting
method, and the transition times become the only quantities searched.

That is a short conceptual distance and a large practical one. It is also
easy to see why it went unnoticed: once the linear regression is framed as
a way to start the search, its role is settled and there is no reason to
ask what else it might do. The framing closed the question.

**Their own optimiser comparison points the same way.** They found that
the choice among nonlinear methods made no material difference to the
answer. Our validation experiment, with 192,000 replications, finds that
adding a nonlinear method to a profiled solve makes no difference either.
Both results say the optimiser was never where the difficulty lay.

### Two findings visible in their published output

These need no characterisation of anyone's practice. They are printed in
the paper.

**1. An unidentified cone fit, reported at $r^2 = 0.99$.** For the
75-year-old subject the one-exponential, two-linear-component fit is
given as

$$
y = 14.65 - 398.54\,e^{-1.77x} + 1.54\max(x - 14.21, 0) - 1.28\max(x - 31.4, 0),
$$

with $r^2 = 0.99$. A cone coefficient of $-398.54$ with a rate of $1.77$
is the degeneracy our validation experiment characterises: as the
exponential term collapses towards the bound, the coefficient grows
without limit to compensate, and the fitted *curve* remains excellent
while the cone *parameters* become meaningless. Compare their own
25-year-old fit, $-19.86$ at rate $0.91$, which is well behaved.

The goodness-of-fit statistic cannot see this. That is the argument for
parameter-level diagnostics — a boundary flag on the cone time constant,
as we now apply — made from the field's own published output rather than
from any claim of ours.

It also corroborates De Silva et al. (2022) independently: they identify
cone-parameter instability as the classical fit's weak point and
attribute it to sparse data during the cone phase. Here is the same
signature in 1999, and our simulation locates the mechanism in the
flattening exponential rather than in sparsity as such. Note that
Dimitrov et al. sampled densely and the problem is not confined to sparse
protocols.

**And this may be why the field adopted rod intercept time.** If the cone
parameters cannot be trusted, a quantity that depends on the fitted curve
rather than on individual parameters is a rational defence. RIT depends on
$ct$, $S2$ and $\alpha$ and not at all on $cc$ or $\tau$, so it is
untouched by exactly this degeneracy. That reading makes the field's
choice of endpoint a considered response to a real problem rather than a
naive one — and makes our argument that the defence is no longer needed,
and no longer sufficient, rather than that the choice was wrong. See the
companion note on RIT.

**2. Rates of recovery are derived, not estimated.** In their words: "To
obtain rates of sensitivity recovery, simple mathematical calculations are
performed on the parameter estimates." The clinically meaningful quantity
is computed after the fit, from parameters whose uncertainty is not
propagated into it.

That is the rod intercept time argument one level down, and it is present
in the methods paper that established how the field fits these curves. The
practice of reporting a derived scalar without its interval has propagated
from there.

---

## 2008 — Dimitrov et al.: the breakpoint avoided, and Excel Solver

Dimitrov PN, Guymer RH, Zele AJ, Anderson AJ, Vingrys AJ. *Measuring rod
and cone dynamics in age-related maculopathy.* Invest Ophthalmol Vis Sci
2008;49(1):55--65. doi:10.1167/iovs.06-1048

**What they do.** They dispense with an explicit transition. Each of the
cone and rod mechanisms is modelled by a single decaying function, and
the observed curve follows whichever mechanism is currently more
sensitive. In R, as implemented:

```r
Thrs <- function(t) log10(10^((Tf + Ti) - R*t) + 10^Tf)
```

that is,

$$
T(t) = \log_{10}\!\left(10^{\,(T_f + T_i) - Rt} + 10^{\,T_f}\right)
    \;=\; T_f + \log_{10}\!\left(10^{\,T_i - Rt} + 1\right),
$$

with $T_f$ the asymptotic threshold, $T_i$ the elevation above that
asymptote at $t = 0$, and $R$ the rate of decay in decades per minute,
applied separately to cone and rod mechanisms. The factored form on the
right makes the structure plain: a pure additive floor, plus a softplus
term that falls away.

### It is not a reparameterisation of the P5c cone phase

The parameter roles correspond so neatly that it is natural to assume the
two models are the same thing written differently: $T_f$ is a plateau like
$ct$, $T_i$ is an elevation above it like $cc$, and $R$ is a rate like
$1/\tau$. They are not.

**The difference is where the decaying term is added.** The P5c cone phase
adds it in log units,
$$
T(t) = ct + cc\,e^{-t/\tau},
$$
whereas Dimitrov adds it in *linear* units and then takes the logarithm.
Their decay is exponential in linear intensity, which on a semi-log plot
is a **straight line of slope $-R$**, not a curve.

The consequence is a qualitative difference at early times and agreement
only in the tail:

- **Early** ($10^{T_i - Rt} \gg 1$): $\log_{10}(1+x) \approx \log_{10} x$,
  so $T(t) \approx T_f + T_i - Rt$. A straight descent at $R$ log units
  per minute. The P5c cone phase has no such regime; it is curved from
  $t = 0$.
- **Late** ($10^{T_i - Rt} \ll 1$): $\log_{10}(1+x) \approx x/\ln 10$, so
  $T - T_f \approx 10^{T_i - Rt}/\ln 10$, an exponential approach to the
  asymptote in log units with time constant $1/(R \ln 10)$.

So the models share their limiting behaviour but not their functional
form. **The parameters correspond in role, and only asymptotically.** For
$R = 1.04$ decades per minute the equivalent time constant is
$1/(1.04 \ln 10) = 0.42$ minutes — which is why comparing $R$ directly
against a P5c $\tau$ makes no sense and no value of $R$ will make the two
shapes agree. Matched at $t=0$, at the same asymptote and the same tail
rate, the two curves still differ by more than 1.2 log units at
$t = 1$~min.

**This is a real modelling question with an empirical answer, and the
comparison is a fair one.** Which form better describes cone recovery is
testable, and the two differ most in the first two minutes: by more than
a log unit at $t = 1$ min when matched at $t = 0$, at the same asymptote
and the same tail rate. Because Dimitrov sample at 17.5-second intervals,
close to our own density, both datasets resolve that window. Two
consequences follow:

- their 2008 data could in principle have distinguished the two forms,
  and they report only that a single decaying function "adequately
  defined" each component;
- fitting both forms to our archival curves is a like-for-like test, not
  one confounded by sampling.

Worth settling before the monograph commits to P5c. If the softplus fits
our dense curves better through the cone phase, we should know it; if the
exponential-plus-hinge wins, a live alternative is retired.

### Dense sampling, generic optimiser

**Their sampling is dense.** Thresholds are measured every 17.5 seconds,
about 3.4 per minute: essentially our own density, and roughly three
times that of the AdaptDx staircase. This is easy to overlook and matters
twice over.

First, it removes any suggestion that the methodological weakness of the
older literature is explained by sparse data. Here is a 2008 study with
data as good as ours, fitted by minimising a sum of squares in the
**Excel Solver module**: generic GRG minimisation, no starting-value
discipline, no confidence intervals, no convergence record, and results
dependent on the state of the spreadsheet. Of the three exhibits this is
the one whose results cannot be reproduced from the paper at all. The
pattern across the three is three eras of off-the-shelf optimisers, not
three eras of poor data.

Second, it means their curves resolve the first two minutes, which is
exactly where their functional form and ours diverge, as above.

**Two further observations.** First, the transition is not a parameter, so no
interval for the rod--cone break is available — the same move as RIT, one
level down, with the clinical quantity derived rather than estimated.
Second, fitting the two components separately requires deciding first
which observations belong to which phase; the segmentation judgement
returns by the back door, made by the analyst rather than the algorithm,
and is not recorded in the parameters.

**This paper also bounds our claim — see the final section below.**

---

## 2022 — De Silva et al.: fragility accepted, and a smoother interposed

De Silva T, Hess K, Grisso P, Thavikulwat AT, Wiley H, Keenan TDL, Chew
EY, Jeffrey BG, Cukras CA. *Deep learning-based modeling of the dark
adaptation curve for robust parameter estimation.* Transl Vis Sci Technol
2022;11(10):40. doi:10.1167/tvst.11.10.40. National Eye Institute
intramural programme.

**What they do.** Fit a long-short-term memory autoencoder to dark
adaptation curves and compare against classical nonlinear regression on
954 tests. The classical comparator is a five-parameter model of the same
structure as P5c, fitted by trust-region least squares with empirically
chosen starting values (break time set to half the test duration, plateau
to the midpoint of the intensity range, the rest derived arithmetically),
tolerances of $10^{-5}$, and caps of 600 function evaluations and 400
iterations. Data are AdaptDx: roughly one threshold per minute, quantised
to 0.3 and 0.1 log unit staircase steps.

**What they find.** Comparable goodness of fit (RMSE 0.11 LU classical,
0.13 LU deep learning). The deep learning method is superior on
repeatability under perturbation and on repeat testing, **especially for
cone-related parameters**, and markedly better at predicting the later
curve from early data: RIT prediction error of 3.1 ± 3.1 minutes against
**19.1 ± 18.6 minutes** for the classical fit.

**Why it matters to us.**

- *Independent evidence for our problem statement.* Their comparator is
  precisely the fragility described in Section 4 of DISC-IP-003. A
  prediction error whose standard deviation nearly equals its mean, on a
  quantity bounded by a 20-minute test, is not imprecision but failure.
  Cite as corroboration, not as a rival.
- *Their diagnosis matches ours from the opposite direction.* They locate
  the instability in the cone parameters and attribute it to sparse data
  during the cone phase. That is the same pathology we observe as
  $\tau$-boundary degeneracies with $cc$ running to $10^{13}$, and as the
  ridge in the error surface when the cone exponential becomes affine over
  the test window.
- *The approaches diverge instructively.* They accept the fragility and
  interpose a learned smoother; we remove it by exploiting structure.
  Their route needs a training corpus and yields a model that cannot be
  audited parameter by parameter. Ours needs no training data and is
  exactly reproducible. For a regulated instrument that distinction is
  material — state it plainly, without disparagement.
- *They cite us.* Reference 19 is Murray IJ, Rodrigo-Diaz E, Kelly JMF, et
  al., Prog Retin Eye Res 2021;88:101015, on faster implementations with
  error bounds. This group is aware of MuMac's work.

**Caveat to state, not to hide.** Their protocol samples roughly one
threshold per minute with staircase quantisation; ours samples about four
per minute from a continuous ramp. Some of the classical method's poor
showing is attributable to data density rather than to the fitting
method, and the two cannot be separated from their published results. We
must not claim our method would outperform their deep learning approach
on their data: we have simulation results and a different protocol. The
defensible claim is that the failure mode motivating their work is one our
method addresses at source.

**Partial remedy available.** The planned subsampling study — thinning our
own curves to AdaptDx-like density and refitting both ways — gives a 2×2
of method by sampling density on identical underlying measurements. Thin
by time rather than index, and use several offsets per curve.

---

## The limit of our claim

**Dimitrov's parameterisation offers almost nothing to project out.**
Written in factored form, $T(t) = T_f + \log_{10}(10^{T_i - Rt} + 1)$,
the asymptote $T_f$ enters purely additively and is therefore linear: for
fixed $T_i$ and $R$ its least-squares value is just the mean residual. But
$T_i$ and $R$ are both nonlinear. Projecting out the one linear parameter
reduces a three-parameter search to a two-parameter search, which is no
material advantage.

Compare P5c, where three of five parameters are linear and come free,
leaving only two to search. The separability argument is therefore not a
binary property of models but a question of how much structure is
available to exploit, and this parameterisation has very little.

It follows that the structural insight is a property of **the P5c
parameterisation**, not of dark adaptation as a phenomenon. Say so
plainly in the discussion rather than leaving a reviewer to raise it. The
answer is a good one:

- the separable form is not a restriction adopted for computational
  convenience but the standard clinical parameterisation, whose
  parameters ($ct$, $cc$, $\tau$, $S2$, $\alpha$) carry the physiological
  meanings the field already uses;
- within that parameterisation the linear structure is available and has
  not been exploited;
- a model that dispenses with the explicit breakpoint gains smoothness but
  loses the ability to estimate, and place an interval on, the rod--cone
  break — one of the four quantities we argue a clinician should have.

Two further items belong in the prior-art picture, and both support the
position rather than threatening it, since they show the ingredients
existed separately and were not combined:

- **Lerman PM (1980),** *Fitting segmented regression models by grid
  search*, Appl Statist 29:77--84 — grid search over a breakpoint.
- **McGwin et al. (1999)** above — closed-form linear solution with the
  transition points held fixed, used to initialise a nonlinear search.
