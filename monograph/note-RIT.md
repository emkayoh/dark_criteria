# Rod intercept time: derived, arbitrary, fragile, and confounded

<!-- JMFK. Merges "Notes on Rod Intercept Time" (19 May 2024) with the
     algebraic and simulation-based material developed August 2026.
     Supersedes note-RIT-derived-and-confounded (v1) and the earlier
     Tanaya/derived-quantity notes. Basis for TECH-NOTE-001 and the
     monograph discussion. Not a controlled document. -->

## The thesis

Rod intercept time is presented as a measure that avoids model fitting.
It does not. **RIT is a model fitting exercise with unstated overarching
assumptions**, and the number it returns depends on choices the analyst
makes and does not report.

Four independent lines of evidence support this, and they are worth
keeping distinct because they persuade different audiences:

1. **Algebraic** — RIT is a deterministic function of three fitted
   parameters and one arbitrary criterion.
2. **Empirical, from method choice** — the same dataset yields different
   RITs, with wildly different confidence intervals, depending on how the
   analyst samples it.
3. **Empirical, from fragility** — a single erroneous response can move
   RIT by a factor of nine.
4. **Physiological** — RIT moves with bleach intensity even when rod
   function does not.

---

## 1. The algebra: RIT is derived, not measured

Along the rod phase the threshold falls linearly from $ct$ at time
$\alpha$ with slope $S2$. Setting the threshold equal to the criterion
$\mathrm{crit}$:

$$
\mathrm{RIT} = \frac{\mathrm{crit} - ct}{S2} + \alpha,
\qquad
S2 = \frac{\mathrm{crit} - ct}{\mathrm{RIT} - \alpha}.
$$

RIT is determined entirely by $ct$, $S2$, $\alpha$ and the criterion. It
carries no information those three parameters do not, and its value
depends on a convention rather than on a property of the eye.

This reframes the comparison. It is not $S2$ versus RIT as rival
measurements; it is one parameter against a lossy collapse of three,
plus a chosen constant. It is also the honest answer to the reviewer
question "does $S2$ add anything beyond RIT?"

### The criterion is itself unstable — VERIFY BEFORE USE

Jackson & Edwards (2008) define the rod intercept as recovery to
$5\times10^{-4}$ cd/m² (3.3 log units). Owsley et al. (2016) define it as
recovery to $5.0\times10^{-3}$ scotopic cd/m² (2.3 log units of
attenuation of the stimulus), and that definition is in common use (e.g.
Higgins et al. 2021).

The arithmetic within each is self-consistent, but they differ by a
factor of ten. **Before making anything of this, rule out two innocent
explanations:** photopic versus scotopic units, and absolute stimulus
intensity versus attenuation relative to a reference. If neither
accounts for it, the criterion has genuinely moved and RIT values are not
comparable across eras — a strong point. If they do account for it, the
weaker but still fair point is that the criterion is stated
inconsistently enough that cross-study comparison needs care.

---

## 2. Method choice changes the answer

From the Pugh (1975) data as cited by Lamb & Pugh (2006), four defensible
methods give four answers:

| Method | RIT (min) | Bounds |
|---|---|---|
| First past the post (nRIT) | 13.15 | none available |
| Linear fit, $\mathrm{crit} \pm 0.3$ LU | 13.29 | 7.53 – 19.06 |
| Linear fit, $\mathrm{crit} \pm 0.6$ LU | 13.20 | 11.08 – 15.33 |
| Linear portion of fitted P5c, $\alpha$ to $\beta$ | 13.25 | 13.09 – 13.41 |

The point estimates agree to within a few percent. **The intervals do
not**: $\pm 5.8$ min, $\pm 2.1$ min, $\pm 0.16$ min, spanning a factor of
36, driven entirely by how much data the analyst chose to include.

As the 2024 notes put it: the arbitrary nature of the sample size means
there is no meaningful interpretation of the confidence interval found by
these methods. Moving-average methods fare no better — the estimate moves
with the aggregation window, and the method only works at all if data
exist in the sampling domain.

Every one of these is a model fit. First-past-the-post assumes the
crossing point of a noisy series estimates the crossing point of the
underlying function. The window methods assume local linearity over an
unstated span. Only the last states its assumptions and propagates its
uncertainties.

---

## 3. Fragility: one bad point, a ninefold error

Calibration data from a development device, containing a single spurious
response at ~1.5 min caused by a memory overflow since remedied:

- nRIT is **undefined**: no observation falls below the criterion.
- Sampling at $\mathrm{crit} \pm 0.3$ LU yields **one** data point.
- Sampling at $\mathrm{crit} \pm 0.6$ LU yields eight points including
  the outlier, and a linear fit crosses the criterion at
  **88.41 minutes**.
- With leave-one-out validation removing the outlier, the same method
  gives **9.53 min** (8.52 – 10.54).
- Using all data after $\alpha$: **9.51 min** (9.34 – 9.67).

A ninefold error from one bad response, on a measure the field prefers
*because* it is supposed to avoid the pitfalls of model fitting. This is
the strongest single exhibit available to us: real device data, an
undeniable failure, and ours to show.

Outlier handling under consideration: leave-one-out (implemented) and
inverse square weighting (in development). The general point stands
regardless of which is adopted — outlier handling is a modelling
decision, and RIT cannot avoid making one.

---

## 4. Physiology: RIT moves with the bleach

Lamb & Pugh (2006) show that the time mid-way through the S2 phase
depends on the intensity of the initial photobleach.

Tanaya et al. (2023) confirm it clinically: RIT measured before and after
cataract surgery **rose**, from 13.2 to 14.8 minutes, and rose most in
eyes with the densest cataracts, attributed to the bleaching light
reaching the retina more strongly once the media were clear.

Removing a cataract admits more light; RIT moved the other way. Nobody
needs persuading that this is the wrong direction. The explanation
follows from the algebra: bleach depth changed, $ct$ and $\alpha$ moved
with it, and RIT followed, while there is no reason to suppose the rod
recovery rate $S2$ changed at all.

**The testable prediction.** A stronger effective bleach should raise
$\alpha$, and possibly $ct$, while leaving $S2$ comparatively unchanged.
If the retrospective study shows $S2$ stable across a media change while
RIT moves, the proposition stops being a claim and becomes a
demonstration. Archival trials spanning a cataract surgery would be the
natural experiment.

It also bears on the $\alpha > 5$ min review flag: media opacity
attenuating the bleach is the same phenomenon from the other direction.

---

## Why RIT was adopted: a defence against parameter instability

A hypothesis worth taking seriously, because it changes what we claim.

RIT may have been chosen precisely *because* parameter fitting was
unreliable. From the position of 1999: the cone coefficient and time
constant can blow up together — see the $-398.54$ coefficient in McGwin
et al.'s own published fit for their 75-year-old subject, at
$r^2 = 0.99$ — the model comparison is unstable, but the time at which
the fitted curve crosses a criterion depends on the *curve*, not on any
individual parameter. Take the one number you can trust and discard the
ones you cannot. Jackson & Edwards say as much in their motivation:
"because ARM patients can exhibit several differently shaped dark
adaptation functions".

That is a sensible engineering decision given the methods of the day.
**The claim to make is not that the field chose a poor endpoint, but that
it chose a defensive one, and that the defence is no longer needed and no
longer sufficient.** That framing credits the choice, which matters when
the people who made it may review the work.

### The defence is partial, and that is the closing argument

RIT depends on $ct$, $S2$ and $\alpha$. It does **not** depend on $cc$ or
$\tau$.

- **Against cone-parameter degeneracy, RIT is robust.** The
  $cc \uparrow$, $\tau \downarrow$ blow-up leaves the fitted curve intact
  and RIT untouched. The defence works.
- **Against a shallow rod slope, RIT is defeated** (next section), and
  becomes least reliable exactly where early disease lives.
- **Against a single bad response, RIT is defenceless** (section 3
  above) — because avoiding an explicit model also means avoiding the
  outlier machinery a model brings with it.

RIT protects against the instability of 1999 and is defeated by the ones
that matter now.

**Testable from data already in hand.** The validation experiment
identifies degenerate fits directly ($\tau$ at the grid's lower bound,
$cc$ large): 15,271 of 191,996 replications, 8.0%. Compare RIT error for
degenerate and non-degenerate fits **matched on noise and on $|S2|$** —
the matching matters, since RIT error depends strongly on $|S2|$ and the
degenerate fits may not be evenly distributed across slopes. If RIT error
is comparable across the two groups while the cone parameters differ by
orders of magnitude, the robustness hypothesis is confirmed.

---

## The uncertainty in RIT as the slope shallows

$$
\frac{\partial \mathrm{RIT}}{\partial ct} = -\frac{1}{S2},
\qquad
\frac{\partial \mathrm{RIT}}{\partial S2} = -\frac{\mathrm{crit} - ct}{S2^{2}},
\qquad
\frac{\partial \mathrm{RIT}}{\partial \alpha} = 1
$$

$$
\operatorname{Var}(\mathrm{RIT}) =
\frac{\operatorname{Var}(ct)}{S2^{2}}
+ \frac{(\mathrm{crit} - ct)^{2}}{S2^{4}}\operatorname{Var}(S2)
+ \operatorname{Var}(\alpha)
+ \text{covariance terms}
$$

Fourth power in the **variance**, second power in the standard deviation:
halving the slope multiplies the variance contribution sixteenfold and the
interval width fourfold. State which is meant.

With $\mathrm{crit} = -3$, $ct = -1.7$, $\alpha = 5$, and
$\mathrm{SD}(S2) \approx 0.0105$ (dense sampling, noise 0.1):

| $S2$ | RIT (min) | $\partial\mathrm{RIT}/\partial S2$ | SD(RIT) from $S2$ | relative |
|---|---|---|---|---|
| −0.30 | 9.3 | 14 | 0.15 | 0.016 |
| −0.20 | 11.5 | 33 | 0.34 | 0.030 |
| −0.10 | 18.0 | 130 | 1.37 | 0.076 |
| −0.05 | 31.0 | 520 | 5.46 | 0.176 |
| −0.01 | 135.0 | 13000 | 136.5 | 1.011 |

**A refinement a reviewer will spot, so state it first.** The *relative*
uncertainty does not explode: for shallow slopes it converges to
$\mathrm{SD}(S2)/|S2|$, the relative uncertainty of the slope itself,
because RIT and its error both scale as $1/S2$. It is the **absolute**
uncertainty, in minutes, that blows up.

That is the clinically relevant one, because RIT is used absolutely
against fixed cut-offs in minutes. A measure with an error of 0.15 min at
a healthy slope and 5.5 min at a shallow one cannot support a fixed
threshold across that range.

**And censoring follows from the same algebra.** At $S2 = -0.05$ the
expected RIT is 31 minutes, beyond any practical test window, so the
value is censored rather than measured. Higgins et al. (2021) address
exactly this statistically, with time-to-event analysis, and report
substantial power gains. Their censoring is a consequence of the blow-up
above.

### The analysis to run — no new data required

For all 191,996 replications we have true parameters, fitted parameters,
and fitted covariances. So: compute true and fitted RIT; compute relative
error of RIT and of $S2$; plot both against $|S2|$ by noise level;
optionally propagate the covariance for an interval on RIT and compare
its relative width with that of the $S2$ interval. State $\mathrm{crit}$
explicitly.

Expected: two curves diverging sharply at the shallow slopes that matter
clinically. **If so, that single figure carries the argument.**

---

## How to present this

The difficulty has always been that the claim, stated directly, asks the
listener to accept a criticism before they have felt a problem. "RIT is a
scalar that discards information" lands as methodological fussiness to a
clinician who has used it successfully for a decade.

**Lead with a failure the listener already recognises.** Three are
available, in ascending order of ownership: the cataract result (theirs),
the 88-minute calibration trace (ours), and the error propagation figure
(ours, once run).

Three rules:

1. **Name the parts, with clinical meanings.** Not "five parameters" but
   four things a clinician can care about: how quickly the cones recover,
   how deep the bleach went, when the rods take over, and how quickly they
   recover once they do. RIT blends the last three and is contaminated by
   the first.
2. **Lead with the confound, not the information loss.** "RIT cannot
   distinguish a slow patient from a bright flash" is concrete.
3. **One figure that shows it.** The 88-minute trace beside its
   leave-one-out correction may be the most economical.

## Four senses of "superior", for reference

RIT is a time and $S2$ is a rate, so superiority must be defined against a
purpose:

- **as a measurement** — test-retest repeatability, each against its own
  between-subject spread. Achievable from the archive now.
- **as robust to nuisance** — the cataract case. Most rhetorically
  powerful.
- **as a diagnostic** — discrimination of AMD or graded severity in the
  same eyes; paired ROC with DeLong's test. Needs a graded cohort.
- **as an endpoint** — sensitivity to change, or sample size for a given
  effect. Needs longitudinal data.

The first two are within reach of existing data. Any comparison must be
paired within eyes, since RIT and $S2$ are correlated by construction.

---

## References

- Higgins BE, Montesano G, Binns AM, Crabb DP (2021). Optimising
  assessment of dark adaptation data using time to event analysis. *Sci
  Rep* 11:8323.
- Jackson GR, Edwards JG (2008). A short-duration dark adaptation protocol
  for assessment of age-related maculopathy. *J Ocul Biol Dis Infor*
  1(1):7–11.
- Lamb TD, Pugh EN (2006). Phototransduction, dark adaptation, and
  rhodopsin regeneration: the Proctor Lecture. *IOVS* 47(12):5138.
- McGwin G, Jackson GR, Owsley C (1999). Using nonlinear regression to
  estimate parameters of dark adaptation. *Behav Res Methods Instrum
  Comput* 31(4):712–717.
- Owsley C, McGwin G, Clark ME, et al. (2016). Delayed rod-mediated dark
  adaptation is a functional biomarker for incident early AMD.
  *Ophthalmology* 123(2):344–351.
- Pugh EN (1975). Rushton's paradox: rod dark adaptation after flash
  photolysis. *J Physiol* 248(2):413–431.
- Tanaya T, Swain TA, Clark ME, et al. (2023). Comparing rod-mediated dark
  adaptation in older adults before and after cataract surgery. *Curr Eye
  Res* 48(5):512–517.
