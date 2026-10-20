# Publication Strategy

## Overview

During the development of the simulation framework for investigating model discrimination in dark adaptation, two distinct and publishable contributions emerged:

1. **A methodological contribution** describing an efficient optimisation strategy for fitting the P5c model.
2. **A scientific contribution** describing the conditions under which biphasic dark adaptation can be reliably distinguished from a simpler exponential recovery model.

Although these projects share the same underlying model and software, they address different research questions and are intended for different audiences.

---

# Paper 1 – Optimisation Methods

## Working title

**Profile Least-Squares Initialisation for Robust Fitting of a Biphasic Dark Adaptation Model**

(alternative)

**Efficient Optimisation of a Partially Linear Model of Human Dark Adaptation**

## Central question

How can the P5c model be fitted accurately, robustly and efficiently?

## Scientific contribution

The paper demonstrates that the P5c model is partially linear and that this mathematical structure can be exploited to substantially simplify parameter estimation.

The principal contributions are:

- Recognition that only **τ** and **α** are intrinsically nonlinear.
- Reformulation of the initialisation problem using profile least squares (variable projection).
- Analytical estimation of **ct**, **cc** and **S2** by ordinary least squares.
- Robust refinement using the pseudo-Huber objective.
- Final inverse-weighted least-squares refinement.
- Jacobian-based parameter uncertainty estimation.
- Performance comparison with earlier optimisation approaches.

## Comparison methods

- Original five-dimensional parameter grid.
- Oldar heuristic.
- Profile least-squares initialisation.
- Robust optimisation pipeline.

## Outcome measures

- Runtime.
- Convergence rate.
- Residual sum of squares.
- Parameter recovery.
- Numerical stability.
- Confidence interval behaviour.
- Computational complexity.

## Key message

The optimisation strategy exploits the mathematical structure of the model rather than relying on brute-force search, producing substantially faster and more robust parameter estimation.

---

# Paper 2 – Model Discrimination

## Working title

**The Limits of Detecting Biphasic Dark Adaptation**

(alternative)

**Model Discrimination in Human Dark Adaptation: Effects of Rod Slope, Transition Time and Measurement Noise**

## Central question

Under what conditions can a biphasic recovery model be distinguished from a simple exponential recovery?

## Scientific contribution

Using realistic simulated data, determine the boundary separating reliable and unreliable identification of rod recovery.

Primary variables:

- Rod slope (**S2**)
- Rod-cone transition (**α**)
- Measurement noise (**σ**)

Secondary analyses:

- Parameter recovery.
- Confidence interval coverage.
- AIC and AICc discrimination.
- Hessian behaviour.
- Parameter identifiability.
- Failure modes.

## Experimental design

Generate simulated datasets over a multidimensional parameter space.

Current design:

- S2 ∈ {-0.05, -0.10, -0.15, -0.20, -0.25, -0.30}
- α ∈ {3, 5, 7, 9}
- σ ∈ {0, 0.05, 0.10, 0.15, 0.20, 0.30}
- 250 replicates per condition

Potential extension:

Include **S2 = 0** to estimate false-positive classification rates.

## Principal outputs

- Probability of selecting P5c.
- Parameter recovery.
- Confidence interval width.
- Confidence interval coverage.
- Classification accuracy.
- Regions where P3 and P5c become statistically indistinguishable.

## Key message

The ability to identify biphasic recovery depends jointly on rod slope, transition time and measurement noise. These relationships define the practical limits of dark-adaptation testing.

---

# Relationship Between the Papers

The papers are complementary rather than sequential.

The optimisation paper develops the methodology required to perform efficient and robust parameter estimation.

The discrimination paper applies that methodology to answer a physiological and statistical question concerning the limits of detecting rod recovery.

Neither paper depends critically on the other for scientific completeness, but together they provide:

- an improved computational framework for model fitting; and
- an investigation of the limits of model discrimination.

---

# Proposed Publication Order

## Preferred

Complete both manuscripts in parallel.

Submit the optimisation paper first or submit both manuscripts within a short interval.

The discrimination paper can simply reference the optimisation procedure rather than describing its derivation in detail.

---

# Intellectual Property Considerations

Before public disclosure:

- Review the optimisation methodology with patent attorneys.
- Determine whether any aspect of the optimisation pipeline should be protected before publication.
- Decide whether publication, patent protection or trade-secret protection best serves the company's commercial strategy.

No public disclosure (journal submission, conference presentation, preprint or public repository) should occur until the IP position has been reviewed.

---

# Immediate Research Plan

1. Finalise the profile least-squares initialisation.
2. Validate the optimisation pipeline.
3. Complete the simulation framework.
4. Generate the discrimination dataset.
5. Benchmark optimisation methods.
6. Review the optimisation with patent attorneys.
7. Prepare both manuscripts in parallel.

---

# Long-Term Vision

Together these papers establish both the computational and scientific foundations of the RapiDA™ analysis framework.

The optimisation paper provides an efficient, mathematically principled fitting strategy for partially linear dark-adaptation models.

The discrimination paper establishes the conditions under which rod recovery can be identified reliably, thereby defining the practical limits of the measurement system and informing future clinical study design.