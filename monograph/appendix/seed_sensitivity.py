"""
MWE: optimiser-seed sensitivity arm for the VarPro validation experiment.

Question: does the fitted nonlinear parameter depend on the RNG seed that
sets the NM starting simplex, given the same data?

Design:
  - one root seed, recorded with the environment capture
  - independent substreams keyed by (rep_id, purpose, k), so data noise and
    optimiser initialisation are statistically independent but both replayable
  - a deterministic 20% subset of rows at one tau
  - K refits per row, each with a different optimiser substream
  - NM itself is deterministic once the simplex is fixed; the only randomness
    in the refinement is the simplex

Any single unit is reconstructable from ROOT, rep_id and k alone.
"""

import numpy as np
from scipy.optimize import minimize

ROOT = 20260828          # record alongside compiler and library versions
PURPOSE_DATA = 0         # noise realisation
PURPOSE_SIMPLEX = 1      # NM initial simplex
PURPOSE_SUBSET = 2       # subset selection
PURPOSE_GD = 3           # reserved: give GD its own stream if it is stochastic

TAU_TRUE = 1.8
N_REPS = 200
FRAC = 0.20
K = 8
N_POINTS = 40
SIGMA = 0.05

# Pre-stated tolerance. Decide this before looking at the output.
TOL_TAU = 1e-6           # absolute agreement in tau across optimiser seeds


def substream(rep_id, purpose, k=0):
    """Well-separated, replayable RNG stream. SeedSequence hashes the key,
    so adjacent indices do not give correlated streams."""
    ss = np.random.SeedSequence(entropy=ROOT, spawn_key=(rep_id, purpose, k))
    return np.random.default_rng(ss)


# ---------------------------------------------------------------- model

def varpro_sse(theta, t, y):
    """Separable model y = a*exp(-t/tau) + b. Linear coefficients are
    profiled out by least squares; NM sees only the nonlinear parameter."""
    tau = theta[0]
    if not np.isfinite(tau) or tau <= 1e-8:
        return np.inf
    Phi = np.column_stack([np.exp(-t / tau), np.ones_like(t)])
    coef, *_ = np.linalg.lstsq(Phi, y, rcond=None)
    resid = y - Phi @ coef
    return float(resid @ resid)


def make_row(rep_id):
    rng = substream(rep_id, PURPOSE_DATA)
    t = np.linspace(0.05, 6.0, N_POINTS)
    y = 1.2 * np.exp(-t / TAU_TRUE) + 0.3 + rng.normal(0.0, SIGMA, N_POINTS)
    return t, y


def random_simplex(rng, centre, spread=0.30):
    """d+1 vertices for d nonlinear parameters. This is the only place the
    refinement consumes randomness."""
    centre = np.atleast_1d(np.asarray(centre, float))
    d = centre.size
    verts = np.empty((d + 1, d))
    verts[0] = centre * np.exp(rng.normal(0.0, spread, d))
    for i in range(d):
        step = np.zeros(d)
        step[i] = spread * rng.uniform(0.5, 1.5)
        verts[i + 1] = verts[0] * np.exp(step)
    return verts


def fit(t, y, rep_id, k, centre=2.5):
    rng = substream(rep_id, PURPOSE_SIMPLEX, k)
    simplex = random_simplex(rng, [centre])
    res = minimize(varpro_sse, x0=simplex[0], args=(t, y),
                   method="Nelder-Mead",
                   options={"initial_simplex": simplex,
                            "xatol": 1e-10, "fatol": 1e-12, "maxiter": 2000})
    return {"rep_id": rep_id, "k": k, "tau0": float(simplex[0, 0]),
            "tau_hat": float(res.x[0]), "sse": float(res.fun),
            "nit": int(res.nit), "ok": bool(res.success)}


# ---------------------------------------------------------------- run

def select_subset():
    """Deterministic and recorded. 'a random 20% of rows' is not reproducible
    on its own, so the chosen ids go in the results file."""
    rng = substream(0, PURPOSE_SUBSET)
    n = int(round(FRAC * N_REPS))
    return np.sort(rng.choice(N_REPS, size=n, replace=False))


def main():
    subset = select_subset()
    rows = []
    for rep_id in subset:
        t, y = make_row(int(rep_id))
        for k in range(K):
            rows.append(fit(t, y, int(rep_id), k))

    tau = np.array([r["tau_hat"] for r in rows]).reshape(len(subset), K)
    spread = tau.max(axis=1) - tau.min(axis=1)
    across_reps = tau.mean(axis=1)

    print(f"subset rows       : {len(subset)} of {N_REPS} at tau={TAU_TRUE}")
    print(f"refits per row    : {K}")
    print(f"all converged     : {all(r['ok'] for r in rows)}")
    print(f"max within-row range of tau across seeds : {spread.max():.3e}")
    print(f"median within-row range                  : {np.median(spread):.3e}")
    print(f"sd of tau across rows (sampling noise)   : {across_reps.std(ddof=1):.3e}")
    print(f"pre-stated tolerance {TOL_TAU:.1e} : "
          f"{'PASS' if spread.max() < TOL_TAU else 'FAIL'}")
    print("\nThe last two numbers are the comparison that answers the reviewer:")
    print("optimiser-seed variability against noise-driven variability.")


if __name__ == "__main__":
    main()
