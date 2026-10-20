# Note: McGwin, Jackson & Owsley (1999) — the structure was seen and set aside

<!-- JMFK, 22 August 2026. Working note. This paper is the documentary
     evidence for the monograph's opening argument. Not a controlled
     document. -->

## The citation

McGwin G, Jackson GR, Owsley C. *Using nonlinear regression to estimate
parameters of dark adaptation.* Behavior Research Methods, Instruments, &
Computers 1999;31(4):712--717. doi:10.3758/BF03200752

Note the authorship. This is the same group that went on to develop the
AdaptDx and to publish Jackson et al. (2014) on its diagnostic sensitivity
and Owsley et al. (2016) on delayed dark adaptation as a biomarker for
incident AMD. This is not an obscure paper: it is the methods foundation
of the field's dominant commercial instrument, written by its creators.

## What the published code actually does

The appendix gives SAS code in two parts.

**The initialization block** constructs hinge basis functions at fixed
knots and fits them by ordinary linear regression:

```sas
xx_1 = max(x - 1.0, 0);
xx_2 = max(x - 10.0, 0);
xx_3 = max(x - 20.0, 0);
...
proc reg noprint data=one outest=reg_est; model y = x xx_1 xx_2 xx_3;
```

This is the recognition, in 1999, that **with the knots held fixed the
model is linear in its remaining parameters and can be solved in closed
form.** The hinge is handled by `max(x - knot, 0)`, exactly as in our own
design matrix.

**The nonlinear block** then discards that structure. All parameters,
including the knots, are handed to `proc nlin` with `method=dud`,
`maxiter=300`, and hand-picked starting values:

```sas
proc nlin noprint maxiter = 300 method = dud data=one outest=nlin_est;
  parms a=20 b=-20 c=0.90 d=2.10 e=0.40 knot1=10 knot2=23;
  xx1 = max(x-knot1,0);
  xx2 = max(x-knot2,0);
  model y = ((a + b*exp(-c*x)) + (d*(xx1)) + (e*(xx2));
```

**To check against the original:** in the excerpt, the linear-pass
coefficients are captured into macro variables (`&b0` … `&b4`) but the
`parms` statement uses hardcoded literals rather than those macro
variables. If that is faithful to the published appendix, the linear fit
is computed and then not even used as a starting value. Worth confirming
against the paper before saying so in print, since the excerpt may be
imperfect.

## Why this matters

**The separability was half-seen twenty-seven years ago and not
exploited.** The step not taken is precisely the one we take: keep the
linear solve at the centre of the method rather than at its periphery,
put only the nonlinear parameters in the outer search, and solve the
linear parameters in closed form at *every* candidate rather than once at
the start.

**The practice persisted.** De Silva et al. (2022), from the National Eye
Institute, fit the same five-parameter model with a trust-region solver
and empirically chosen starting values, and report rod intercept time
prediction errors of 19.1 ± 18.6 minutes for that classical fit. Twenty-
three years separate the two papers and the fitting strategy is
essentially unchanged.

**This converts an assertion into documentation.** The monograph's opening
argument — that the field has treated fragility as something to overcome
with computation, when it was largely an artefact of ignoring structure
the model already had — can now be made by exhibiting published code
rather than by characterising the literature. That is a far stronger
opening, and it is not a criticism of anyone: the ingredients were
available and the combination simply was not made.

## For the disclosure

Add to the prior-art list in Section 6 of DISC-IP-003, with a one-line
statement of what it does and does not do. It supports the position
rather than threatening it: it shows that the linear structure of the
model was recognised in the literature and that the method nonetheless
proceeded by full nonlinear search. That is close to the textbook shape
of a non-obviousness argument.

Alongside Lerman (1980) on fitting segmented regression by grid search,
the honest picture is that both halves of the approach existed
separately in the literature — closed-form linear solution with fixed
knots, and grid search over a breakpoint — and were not combined and
applied to this measurement. That is the claim to make, and it is one
that can be defended.
