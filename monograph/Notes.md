# Profile Least Squares Initialisation for the P5c Model

## Key observation

The P5c model is **partially linear**. Rather than treating parameter estimation as a five-dimensional nonlinear optimisation problem, it can be reformulated as a **two-dimensional nonlinear optimisation** wrapped around a **three-dimensional linear least-squares problem**.

The model is

$$ y = c_t + c_c e^{-x/\tau} + S_2 (x-\alpha) H(x,\alpha). $$

If the nonlinear parameters \(\tau\) and \(\alpha\) are held fixed, the model becomes

\[
y =
c_t
\underbrace{1}_{\text{basis}}
+
c_c
\underbrace{e^{-x/\tau}}_{\text{basis}}
+
S_2
\underbrace{(x-\alpha)H(x,\alpha)}_{\text{basis}}.
\]

This can be written in matrix form as

\[
\mathbf{y} = \mathbf{X}\boldsymbol{\beta},
\]

where

- \(\mathbf{X}\) is the design matrix,

\[
\mathbf{X}=
\begin{bmatrix}
1 &
e^{-x_1/\tau} &
(x_1-\alpha)H(x_1,\alpha)\\
1 &
e^{-x_2/\tau} &
(x_2-\alpha)H(x_2,\alpha)\\
\vdots &
\vdots &
\vdots\\
1 &
e^{-x_n/\tau} &
(x_n-\alpha)H(x_n,\alpha)
\end{bmatrix},
\]

and

\[
\boldsymbol{\beta}
=
\begin{bmatrix}
c_t\\
c_c\\
S_2
\end{bmatrix}.
\]

Thus, for every candidate pair \((\tau,\alpha)\), the remaining parameters
\((c_t,c_c,S_2)\) have an **exact ordinary least-squares solution**.

---

# Why this is important

The original initialisation searched all five parameters simultaneously:

```
ct × cc × tau × S2 × alpha
```

Using ten grid points for each parameter gives

```
10 × 10 × 10 × 10 × 10 = 100,000
```

candidate parameter combinations.

After recognising the partially linear structure, the search is performed only over the nonlinear parameters:

```
tau × alpha
```

For example,

```
40 × 80 = 3,200
```

candidate combinations.

At each grid point, the remaining three parameters are obtained analytically by ordinary least squares.

Consequently, the nonlinear search dimension has been reduced from **five parameters to two**, providing a substantial improvement in both computational efficiency and the quality of the starting estimates.

---

# Statistical background

This approach is known as **profile least squares**, or more generally **variable projection**.

The method was introduced by

> Golub, G. H., & Pereyra, V. (1973). *The differentiation of pseudo-inverses and nonlinear least squares problems whose variables separate*. SIAM Journal on Numerical Analysis, 10(2), 413–432.

It is widely used whenever a nonlinear model contains a subset of parameters that enter linearly.

Rather than performing an exhaustive search over every parameter, the optimisation exploits the mathematical structure of the model, solving the linear parameters exactly while searching only the genuinely nonlinear parameter space.

---

# Suggested Methods description

> The P5c model is nonlinear only with respect to the parameters \(\tau\) and \(\alpha\). For fixed values of these parameters, the remaining parameters (\(c_t\), \(c_c\), and \(S_2\)) enter the model linearly and were estimated by ordinary least squares. Initial parameter estimation therefore employed a profiled least-squares (variable projection) approach, reducing the nonlinear optimisation from a five-dimensional parameter search to a two-dimensional search over \((\tau,\alpha)\). This substantially reduced computational cost while producing improved initial parameter estimates for subsequent robust optimisation.


OLDAR 

The profile least-squares initialisation can be viewed as a principled generalisation of the earlier "Oldar" strategy. The Oldar algorithm recognised that the optimisation was primarily sensitive to the nonlinear parameters τ and α, and therefore searched these explicitly while repeatedly invoking a local optimiser. The profiled approach reaches the same conclusion from the mathematical structure of the model: only τ and α require nonlinear optimisation, while the remaining parameters have closed-form least-squares solutions. Consequently, the repeated local optimisation steps of Oldar are replaced by exact linear estimation, yielding both greater computational efficiency and a more rigorous optimisation strategy.


"We show that the P5c dark-adaptation model admits a profile least-squares formulation in which only the rod-cone transition time and cone time constant require nonlinear optimisation. Exploiting this structure substantially reduces computational cost while preserving estimation accuracy."


One observation, though, may be worth checking before writing the methods paper. Earlier we discussed the profile least-squares approach in the context of your P5c model. Before presenting it as a contribution, I'd spend half an hour searching the literature specifically for combinations like:

"dark adaptation variable projection"
"dark adaptation profile least squares"
"biphasic exponential profile likelihood"
"rod cone break nonlinear least squares"

Variable projection itself is well established, but it's entirely possible that nobody has applied it to dark-adaptation modelling in this way. If that's the case, you can confidently position the paper as the application of a known optimisation principle to a clinically relevant model, which is a solid and publishable methodological contribution.

Scientific
Formulated the discrimination study.
Recognised that the work naturally separates into two papers.
Identified the null (S
2
	​

=0) condition as an important part of the experimental design.
Mathematical
Recognised that P5c is partially linear.
Reduced the nonlinear search from five dimensions to two.
Replaced an exhaustive five-dimensional initial search with profile least-squares estimation.
Explained why Oldar worked—it was an intuitive precursor to the profiled method.
Computational
Reduced runtime from around 3.6 s to approximately 0.17 s per simulation.
Built the simulation framework.
Started constructing a reproducible experimental pipeline.
Software engineering
Left the repository in a clean, tagged state.
Created a natural migration path to Django and the Teensy firmware.

One last thought before you disappear.

At the beginning of today you were trying to answer a physiological question:

When does a biphasic recovery become distinguishable from a simple exponential?

By the end of the day you've uncovered a second, independent research contribution:

How should a partially linear dark-adaptation model be fitted?

Those are genuinely different questions with different audiences. I think that's why the idea of two papers emerged so naturally—it wasn't forced; the work itself divided into two coherent stories.



18/8/26

Gradient-descent refinement presented an inherently circular tuning problem: appropriate step sizes depended on the local curvature of the objective surface, but this curvature could only be characterised reliably near the unknown optimum. The problem was exacerbated by substantial anisotropy, particularly the very shallow curvature associated with τ. Consequently, failure of GD to improve the objective could not readily be distinguished from inadequate tuning. Variable projection removes this difficulty by eliminating the linear parameters analytically and reducing the nonlinear optimisation to (α,τ).




After VARPRO plus optimisation of (α,τ), GD is being started at a point where:

∂(ct,cc,S2)
----------- ≈0
   ∂RSS

because the linear parameters have already been solved optimally, and

∂(α,τ)
------ ≈0
∂RSS

because those two nonlinear parameters have already been optimised.

So plain GD is being asked to improve a solution that is already stationary in all five directions, to numerical tolerance.


Following variable projection and optimisation of the remaining nonlinear parameters, the subsequent gradient-descent stage begins very close to a stationary point of the full five-parameter least-squares problem. Consequently, any residual improvement available to GD is necessarily very small. This task is further complicated by the strongly anisotropic local curvature, particularly the shallow dependence on τ, making step-size selection difficult: steps large enough to produce meaningful movement in shallow directions may be excessive in steeper directions, whereas conservative steps yield changes approaching numerical tolerance. The very small gains observed with GD are therefore consistent with the VARPRO solution already lying effectively at the full least-squares optimum.


In nonlinear optimisation, many results become obvious only after they have been established. Once the relevant structure is exposed, the behaviour can appear inevitable; beforehand, that same behaviour is often not safely predictable.

treat healthy S2 as a population distribution conditional on age and measurement uncertainty, then ask whether a new subject is improbable under that distribution.


a normative model: learn the distribution of a measurement in healthy people as a function of age, then quantify how unusual an individual is relative to that reference population. Normative modelling is specifically designed to make individual-level statements relative to population variation rather than merely comparing group averages
Marquand AF, Rezek I, Buitelaar J, Beckmann CF. Understanding Heterogeneity in Clinical Cohorts Using Normative Models: Beyond Case-Control Studies. Biol Psychiatry. 2016 Oct 1;80(7):552-61. doi: 10.1016/j.biopsych.2015.12.023. Epub 2016 Jan 6. PMID: 26927419; PMCID: PMC5023321.


Rapida answers the question 
“How probable is this dark-adaptation response for a healthy person of this age?”

