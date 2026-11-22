# Detection threshold for the rod recovery slope
## Appendix B to DISC-IP-003: derivation, operating point and implementation

Dr Jeremiah MF Kelly
11 October 2026, revised 17 November 2026

---

## Purpose

Section 6 of DISC-IP-003 reports that the shallowest rod slope the method
reliably identifies is about 0.5 to 0.6 times the threshold noise per minute,
consistently across a fourfold range of cone time constants. The RapiDA
application uses a single coefficient derived from that result to decide
whether a rod-cone break is reported. Until 17 November 2026 the same
coefficient decided only whether a fitted rod slope carried a caveat.

This appendix records which coefficient was chosen and why, states the units
in which it applies, sets out the rule the instrument actually implements as
distinct from the rule used to measure the limit, and identifies where the
value is held in the software. It adds no new result: the evidence is the
detection threshold experiment summarised in Section 6 and carried out under
the `dark_criteria` project.

---

## 1. The measured limit

The experiment simulated recovery curves with known rod slopes at a range of
threshold noise levels, and recorded how often the method correctly reported
a rod phase. Simulation design was informed by observed recordings, and are discussed further in section 6. 

Two quantities characterise the limit:

- the **detection threshold**, the shallowest slope identified on 90% of
  occasions;
- the **false-positive rate**, how often a rod phase is reported in simulated
  data containing none.

The detection threshold was 0.016 to 0.025 log units per minute at a
threshold noise of 0.05 log units, rising to 0.163 to 0.175 at a noise of
0.30. False positives occurred in 1.2% to 6.2% of null cases and did not rise
systematically with noise, because the confidence interval widens as the data
degrade and the decision rule becomes correspondingly more cautious.

Expressed as a ratio, the detection threshold was consistently about 0.5 to
0.6 times the threshold noise per minute across all four cone time constant
sets.

**Supporting work.** `dark_criteria`, commit a611bf3, held at https://github.com/emkayoh/dark_criteria. The
simulation design, the number of replications per condition and the
derivation of the 90% criterion are recorded there. This appendix summarises
rather than reproduces that work, as Appendix A does for the cross-platform
validation experiment.

---

## 2. Choice of operating point

The measured result is a range, 0.5 to 0.6, not a single value. The
implementation uses

    k = 0.55

the midpoint of that range.

The midpoint was chosen rather than either endpoint because the variation
across the four cone regimes is small and shows no systematic trend with the
cone time constant. There is therefore no regime for which 0.5 or 0.6 is the
correct value and the other is wrong; the spread reflects simulation
variability rather than a dependence on cone recovery. A midpoint treats the
four regimes alike, which is consistent with the engineering claim that the
relationship holds regardless of how quickly the patient's cones recover.

Two alternatives were considered and rejected:

- **The conservative endpoint, 0.6.** This would widen the range of slopes
  withheld, at the cost of withholding rod phases the experiment shows are
  detectable in three of the four regimes. Appropriate if the rule were a
  clinical decision rule; it is not. It decides what a recording can support
  being reported.
- **A coefficient varying with the fitted cone time constant.** Rejected as
  unsupported: the experiment found no systematic dependence, so a varying
  coefficient would encode simulation noise as if it were structure.

This choice is an engineering decision, not a measured result, and is
recorded here so that it is visible as such.

---

## 3. Units

**The coefficient is a ratio and is therefore dimensionless.** It relates a
slope to a noise level, and applies in any consistent set of units provided
both quantities are expressed in the same ones.

This matters because the experiment and the instrument work in different
units:

| | Experiment | Instrument |
|---|---|---|
| Threshold | log units | decibels (10 x log units) |
| Rod slope | log units per minute | dB per minute |
| Noise | log units | dB |

Both the slope and the noise are scaled by the same factor of ten between the
two, so the ratio is unchanged and `k` carries across without modification.

**This is a property of the ratio, not a coincidence to be relied on
silently.** Any reimplementation, including the on-device fit planned for the
Mk3, must apply the coefficient to a slope and a noise expressed in the same
units. Applying it to a slope in dB per minute and a noise in log units, or
the reverse, is wrong by a factor of ten in either direction and would either
suppress the caveat entirely or attach it to every result.

**Sign.** The fitted slope is negative in the model of Appendix A, where
thresholds fall during recovery, and is stored positive by the instrument.
The comparison is made on the magnitude of the slope.

---

## 4. The rule the instrument implements

The experiment measured the detection limit using a rule that declares a rod
phase when the confidence interval for the slope excludes zero. The
instrument does not implement that rule. It compares the fitted slope against
the coefficient times the residual standard deviation of the full-model fit:

    no rod-cone break reported if |S2| < k * s,   s = sqrt(SS / (n - 5))

The noise was named RMSE in this line until the revision of 17 November 2026.
RMSE conventionally divides by n, and s by n - 5; the two differ by
sqrt(n / (n - 5)), 1.10 at 30 observations and 1.63 at 8, so the name invited
the wrong estimator, and an implementation briefly used it.

**Consequence.** Where no break is detected the result is reported as a single
exponential: the rod slope, the break time, their uncertainties and the rod
intercept time are not reported. A single exponential names the model and not
the photoreceptors; after a weak bleach, a mixed rod and cone recovery can take
that shape. Until 17 November 2026 the slope was reported with a caveat.

These are related but not identical tests, and the difference should be
stated rather than left to be discovered.

**What the instrument's rule claims.** That the fitted slope lies below the
level at which the experiment showed slopes to be reliably distinguishable
from zero, for a recording of this noise. It is a statement about what this
recording could have resolved.

**What it does not claim.** That this particular slope is not statistically
distinguishable from zero. That is the confidence-interval test, and the
instrument already holds the information to perform it, since the half-width
`S2HW95` is computed and stored. The two tests will usually agree and will sometimes
differ, particularly where the number of observations is small and the
interval is wide for reasons unrelated to the noise level.

**Consequence for report wording.** The statement must describe the limit of
the recording, not the status of the finding. Wording of the form "a rod slope
below X cannot be distinguished from zero in a recording of this noise" is
supported, and is what the report states where no break is detected. Wording
of the form "this slope is not distinguishable from zero" is not, unless the
rule is changed to the confidence-interval test.

**Open point.** Whether the instrument should adopt the confidence-interval
rule, which would align it with the experiment, or retain the noise-ratio
rule, which is simpler and depends on one estimated quantity rather than two.
To be settled before the Mk3 implementation. Either way, the rule and the
coefficient are versioned together (Section 5).

**Which noise estimate.** The instrument uses the residual standard deviation
of the full-model fit, `Report.noise`, not the leave-one-out refit. The leave-one-out value
reflects the influence of a single point rather than the noise level of the
recording, and is therefore the wrong estimator for this purpose. The
experiment's "threshold noise" is the noise of the simulated measurements;
the full-model residual standard deviation is the instrument's estimate of
the same quantity for a real recording.

**The firmware differs.** Its in-test criterion compares |S2| with
0.55 x sqrt(RSS / n), the conventional RMSE, and so declares breaks the
application's rule does not, by the factor above. The in-test estimate is not
the result of record. The difference is recorded in RAP-DCR-001 and is to be
removed at a firmware release made for another reason.

---

## 5. Implementation and versioning

The coefficient is held once, in `datapoint/constants.py`:

    DETECTION_THRESHOLD_K = 0.55

and the comparison is made once, by `rod_break_detected` in
`datapoint/analysis/gradient.py`, which the fit, the on-screen report and the
PDF all call.

Each analysed result records the rule that produced its classification in
`Report.result_class_rule`. That identifier names this appendix, not
DISC-IP-004: the threshold is a property of the fit and its noise, and
DISC-IP-004 cites it as an input to the quality classification rather than
owning it.

**A change to `k`, or to the rule in Section 4, makes results produced before
and after the change incomparable.** The rule identifier exists so that
affected records can be selected and, if required, reclassified. Any such
change requires a new identifier, a revision of this appendix, and an entry
in the design change record.

**The change of 17 November 2026** alters the rule's consequence, from a
caveat to withholding the rod phase, and not `k` or the comparison. It is
recorded in RAP-DCR-001 §4.37. `Report.result_class_rule` is not yet written,
the classification rule being unimplemented, so it cannot select the records
affected. `Report.fit_model` does: it is blank on every report written before
the change and `P3` or `P5c` on every fitted report after it. The identifier
for the rule as revised is to be assigned when `result_class_rule` is first
written, and is to name this revision.

---

## 6. Limitations

- The coefficient is derived from simulation under the model of Appendix A.
  It inherits that model's assumptions, including a single rod-cone break and
  a constant rod slope thereafter.
- The 0.5 to 0.6 relationship was established across four cone time constant
  sets; it has not been tested outside that range.
- The relationship was established across simulated threshold noise from 0.05
  to 0.30 log units. That range was chosen to span the noise levels observed
  in real recordings, so the evidence covers the instrument's working range
  rather than a hypothetical one. Recordings noisier than the upper end
  remain outside the evidence.
- The instrument estimates noise from the residuals of a single fit. For a
  recording with few observations that estimate is itself imprecise, and the
  caveat inherits that imprecision.

---

## References

- DISC-IP-003, Section 6, detection thresholds.
- Appendix A to DISC-IP-003, variable projection fitting of dark adaptation
  recovery curves.
- `dark_criteria`, detection threshold simulation experiment,
  https://github.com/emkayoh/dark_criteria, commit a611bf3.
- RAP-DCR-001, design change record, for the removal of the earlier
  rules-based classification this rule replaces, and §4.37 for the revision
  of 17 November 2026.
- RAP-MOD-001, §4 and §4.1, for the single exponential and the mapping of the
  firmware's criterion.

---

## Revision

| Date | Change |
|---|---|
| 11 October 2026 | First issue. |
| 17 November 2026 | The rule's consequence changed from a caveat to reporting a single exponential with no rod values or rod intercept time, RAP-DCR-001 §4.37. The noise in the rule's formula named as the residual standard deviation with its denominator, having been called RMSE. The firmware's different denominator recorded. The comparison stated as made once, and `fit_model` stated as the selector of records before and after the change. `S2CI` renamed `S2HW95`, as the field now is. The `dark_criteria` reference completed from §1. |
