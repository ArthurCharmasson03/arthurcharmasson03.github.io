# 2D lid-driven cavity — vorticity / streamfunction solver (MATLAB)

*Universidad Carlos III de Madrid, Computational Fluid Dynamics, 2024. Report: [`Lid_Driven_Cavity_Report.pdf`](Lid_Driven_Cavity_Report.pdf) (English).*

## Files
| File | What it is |
|---|---|
| `CFDPROJECT.m` | Version used for the report's results (N = 500). Vectorised explicit vorticity transport, Poisson equation solved by SOR (loops). **Unmodified.** |
| `cfdlid2.m` | Later version. The same transport, with the Poisson equation solved directly by a 2D sine transform (DST-I). Much faster. |

## Method
- Incompressible 2D Navier-Stokes in ω-ψ form, pseudo-transient marching to steady state.
- Explicit, conservative centred differences for vorticity transport. Stability limit Δt = min(2/Re, Re(Δx²+Δy²)/2).
- Second-order wall vorticity (Jensen-type formula) on all four walls.

## Validation (Re = 1000, against Botella & Peyret, *Computers & Fluids* 27(4), 1998)

| N | ψ_max | deviation | CPU time (s) |
|---|---|---|---|
| 24 | 0.1000045 | −15.92 % | 0.3 |
| 96 | 0.1173174 | −1.36 % | 9.9 |
| 201 | 0.1186187 | −0.27 % | 158.4 |
| 500 | 0.1188672 | −0.06 % | 6510.3 |
| reference | 0.1189366 | | |

At N = 500, the vortex centre (0.4700, 0.5660) sits within 0.001 of the reference (0.4692, 0.5652). Moving-wall vorticity matches within 0.5 % except next to the corner.

## How to run
Open either script in MATLAB and run it. Parameters are at the top: `Re`, `H`, wall velocities `Un, Us, Ve, Vw`, grid size `Ng`.
`cfdlid2.m` assumes a square cavity (`H = 1`), because the spectral Poisson solver uses kπ wavenumbers in both directions.


---

### En bref (FR)
Solveur Navier-Stokes 2D écrit de zéro (vorticité-fonction de courant, différences finies explicites). À Re = 1000 et N = 500, ψ_max est à −0,06 % de la référence spectrale de Botella et Peyret. `CFDPROJECT.m` est la version SOR utilisée pour le rapport ; `cfdlid2.m`, la version accélérée par transformée en sinus.
