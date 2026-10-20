# Note: rod intercept time — derived, confounded, and unstable where it matters

<!-- JMFK, 22 August 2026. Consolidates the earlier Tanaya material and the
     derived-quantity note. Basis for TECH-NOTE-001 and for the
     monograph's discussion. Not a controlled document. -->

## The relationship

$$
S2 = \frac{\mathrm{crit} - ct}{\mathrm{RIT} - \alpha},
\qquad
\mathrm{RIT} = \frac{\mathrm{crit} - ct}{S2} + \alpha
$$

where $\mathrm{crit}$ is the criterion threshold at which rod intercept
time is declared.

**RIT is not an independent measurement.** It is a deterministic function
of three fitted parameters ($ct$, $S2$, $\alpha$) and one arbitrary
constant ($\mathrm{crit}$).

This reframes the comparison. It is not $S2$ versus RIT as rival
measurements; it is one parameter against a lossy collapse of three
parameters plus a chosen criterion. We are not proposing a competitor to
RIT — we are observing that RIT is a projection of quantities we already
estimate. It is also the honest answer to the reviewer question "does
$S2$ add anything beyond RIT?": RIT contains no information that $S2$,
$ct$ and $\alpha$ do not.

---

## Consequence 1: RIT cannot separate three distinct effects

Equation above contains three parameters with different physiological
meanings. A change in RIT is consistent with a change in any of them:

- a slower rod recovery rate (smaller $|S2|$) raises RIT;
- a later rod--cone break (larger $\alpha$ — a deeper bleach, or less
  attenuation before the retina) raises RIT;
- a higher cone threshold (larger $ct$ ) raises RIT.

### The cataract evidence

Tanaya et al., ARVO Annual Meeting abstract, Denver, May 2022.
**Conference abstract, $n = 16$; cite as preliminary.**

Sixteen adults aged 60+, one eye each, RMDA measured with the AdaptDx
before and 2--3 weeks after cataract surgery, LOCS II grading by a masked
grader. Visual acuity improved (20/25 to 20/20). Mean RIT **rose** from
13.2 to 14.8 minutes ($p = 0.03$), within test--retest limits overall, but
eyes with more severe cataract (LOCS II $\geq 4$) showed a significantly
greater increase ($p = 0.006$). The authors attribute this to the
bleaching light being more intense once the cataract is removed.

**Why this is the strongest single exhibit we have.** Removing a cataract
lets more light reach the retina; RIT moved the other way. Nobody needs
persuading that this is the wrong direction. The measurement gave an
answer that cannot be right, and the explanation then follows from the
algebra rather than from interpretation: the bleach depth changed, $ct$
and $\alpha$ moved with it, and RIT followed, while there is no reason to
suppose the rod recovery rate $S2$ changed at all.

A measurement that moves when the stimulus changes, in a direction
opposite to clinical expectation, is reporting a property of the test as
much as of the patient.

### The testable prediction

Our parameterisation should separate exactly these effects: a stronger
effective bleach should raise $\alpha$, and possibly $cc$, while leaving
$S2$ comparatively unchanged.

**If the retrospective study shows $S2$ stable across a media change while
RIT moves, the proposition stops being a claim and becomes a
demonstration.** That may be the single most valuable output of that
study, more so than the fitting comparison itself. Archival trials
spanning a cataract surgery would be the natural experiment; they may
already be in the database.

### It also bears on the $\alpha > 5$ rule

The rule already distinguishes an inadequate bleach from delayed rod
recovery. Media opacity attenuating the bleach is the same phenomenon
from the other direction.

---

## Why RIT was probably adopted: a defence against parameter instability

A hypothesis worth taking seriously, because it changes what we are
claiming.

RIT may have been chosen precisely *because* parameter fitting was
unreliable. The reasoning, from the position of 1999, would run: the cone
coefficient and time constant can blow up together (see the
$-398.54$ coefficient in McGwin et al.'s own published fit for their
75-year-old subject, at $r^2 = 0.99$); the model comparison is unstable;
but the time at which the fitted curve crosses a criterion depends on the
*curve*, not on any individual parameter, and is therefore robust to all
of it. Take the one number you can trust and discard the ones you cannot.

That is a sensible engineering decision given the fitting methods
available at the time, and it is a much better characterisation of the
field's choice than naivety. **The claim to make is not that the field
chose a poor endpoint, but that it chose a defensive one, appropriate to
the methods of the day, and that the defence is no longer needed.** That
framing credits the choice rather than criticising it, which matters when
the people who made it may review the work.

### The defence is partial, and that is the closing argument

RIT depends on $ct$, $S2$ and $\alpha$. It does **not** depend on $cc$ or
$\tau$. So:

- **Against cone-parameter degeneracy, RIT is robust.** The $cc \uparrow$,
  $\tau \downarrow$ blow-up leaves the fitted curve intact and leaves RIT
  untouched. The defence works.
- **Against a shallow rod slope, RIT is defeated.** The $S2^{-4}$ term
  below takes over, and RIT becomes least reliable exactly where early
  disease lives. The defence does not work where it now matters most.

RIT protects against the instability of 1999 and is defeated by the one
that matters clinically. If that holds up, it is the most elegant version
of the argument available to us.

### Testable now, from data already in hand

The validation experiment identifies the degenerate fits directly: those
with $\tau$ at the grid's lower bound and $cc$ running to large values,
58 per set at noise 0.3 in the coarse runs. The test is:

1. compute RIT error for the degenerate fits and for the non-degenerate
   fits at matched noise and matched $|S2|$;
2. if RIT error is comparable across the two groups while the cone
   parameters differ by orders of magnitude, the robustness hypothesis is
   confirmed;
3. contrast that with RIT error as a function of $|S2|$, where the
   $S2^{-4}$ amplification should dominate.

That converts a historical conjecture into a demonstrated property, and it
requires no new simulation.

---

## Consequence 2: the uncertainty in RIT is unbounded as the slope shallows

Differentiating:

$$
\frac{\partial \mathrm{RIT}}{\partial ct} = -\frac{1}{S2},
\qquad
\frac{\partial \mathrm{RIT}}{\partial S2} = -\frac{\mathrm{crit} - ct}{S2^{2}},
\qquad
\frac{\partial \mathrm{RIT}}{\partial \alpha} = 1
$$

so that

$$
\operatorname{Var}(\mathrm{RIT}) =
\frac{\operatorname{Var}(ct)}{S2^{2}}
+ \frac{(\mathrm{crit} - ct)^{2}}{S2^{4}}\operatorname{Var}(S2)
+ \operatorname{Var}(\alpha)
+ \text{covariance terms}.
$$

**The fourth power is the crux.** Halving the slope multiplies the $S2$
contribution sixteenfold. The rod slope is shallowest in early disease,
which is precisely where a functional biomarker is most wanted, so RIT
becomes least reliable in the regime it is most needed. $S2$ itself
suffers no such amplification.

### The analysis to run — no new data required

For every one of the 192,000 replications we have true parameters, fitted
parameters, and fitted covariances. So:

1. compute true and fitted RIT from the formula;
2. compute relative error of RIT and of $S2$ against their true values;
3. plot both against $|S2|$, coloured or faceted by noise level;
4. optionally propagate the fitted covariance to obtain an interval for
   RIT, and compare its relative width with that of the $S2$ interval.

Expected result: the two curves diverge sharply at exactly the shallow
slopes that matter clinically. **If so, that single figure carries the
whole argument** — it shows the incumbent measure becoming unstable where
early detection lives, without asking the reader to accept any prior claim
about single scalars discarding information.

State $\mathrm{crit}$ explicitly and choose it to match the convention of
the literature being compared against; RIT is only defined relative to it.

---

## How to present this

The difficulty has always been that the claim, stated directly, asks the
listener to accept a criticism before they have felt a problem. "RIT is a
scalar that discards information" lands as methodological fussiness to a
clinician who has used it successfully for a decade.

**Lead with a failure the listener already recognises; supply the
explanation second.** The cataract result is one such failure. The error
propagation figure will be another, and it will be ours rather than
borrowed.

Three rules that follow:

1. **Name the parts, with clinical meanings.** Not "five parameters" but
   four things a clinician can care about: how quickly the cones recover,
   how deep the bleach went, when the rods take over, and how quickly they
   recover once they do. RIT blends the last three and is contaminated by
   the first.
2. **Lead with the confound, not the information loss.** "RIT cannot
   distinguish a slow patient from a bright flash" is concrete. "RIT
   discards information" is abstract and easy to nod past.
3. **Build one figure that shows it.** Two curves with visibly different
   shapes and near-identical RIT; or the same eye under two bleach
   intensities with $S2$ unchanged while RIT shifts.

## Four senses of "superior", for reference

RIT is a time and $S2$ is a rate, so superiority must be defined against a
purpose:

- **as a measurement** — test--retest repeatability, each against its own
  between-subject spread. Achievable from the archive now.
- **as robust to nuisance** — the cataract case above. The most
  rhetorically powerful.
- **as a diagnostic** — discrimination of AMD or of graded severity in the
  same eyes; paired ROC with DeLong's test. Needs a graded cohort.
- **as an endpoint** — sensitivity to change, or sample size required to
  detect a given effect. Needs longitudinal data.

The first two are within reach of existing data and together make a strong
methods paper. Any comparison must be paired within eyes, since RIT and
$S2$ are correlated by construction.
