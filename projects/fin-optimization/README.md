# Fin optimisation for an experimental rocket (MATLAB)

*ESTACA Space Odyssey, CHIRON rocket. File: [`OPTI_AILERONS_ESO.m`](OPTI_AILERONS_ESO.m). Comments and interface are in French.*

## What it does
It finds the trapezoidal fin geometry with the **smallest area**, hence the lightest and lowest-drag fins, that meets the C'Space stability requirements for experimental rockets (Fusex) or mini-rockets.

Design variables (mm): tip chord `n`, span `e`, root chord `m`, leading-edge sweep `p`.

Constraints (19, nonlinear), checked for both full and empty motor:
- static margin between 2 and 6 calibres (Fusex) or 1.5 and 6 (mini-rocket);
- fin normal-force coefficient C_n between 15 and 40 (Fusex) or 15 and 30;
- product MS × C_n above 40 (Fusex) or 30;
- bending safety factor ≥ 2 in both directions, from a tapered Euler-Bernoulli beam FE model (100 elements, von Mises stress);
- limited tip deflection.

Aerodynamics: Barrowman equations for C_n and centre of pressure. Solver: `fmincon`, SQP algorithm.

## How to run
Run the script. A window opens. Enter the rocket data, or import them from the team's StabTraj Excel sheet (sheet `Controle`). Pick a material and press **OPTIMISER**.
Requires the **Optimization Toolbox**. The graphical interface was built with the help of an AI assistant; the model and the optimisation algorithm are my own work.

## Example run
Inputs: 83 mm body, 116 cm length, 403 m/s, 17.4 g, four 4 mm aluminium fins, mini-rocket requirements selected.
Result after 15 SQP iterations: span 178 mm, root chord 55.3 mm, tip chord 20 mm, sweep 17.6 mm, 67 cm² per fin, 289.5 g in total.
Static margin is 3.03 calibres with a full motor and 3.63 when empty. C_n = 15.0, so the minimum-lift constraint is active.


## Known limits / next steps
- One point to check: the fin centre of pressure uses `TAILLE_FUSEX - m` while the fin centre of gravity uses `position_bas`. They should refer to the same fin position.
- Supersonic correction not implemented yet (`Beta = 1`), and no flutter criterion.
- Planned: supersonic and transonic analysis, 2D/3D plate finite element analysis.

---

### En bref (FR)
Optimisation SQP de la surface des ailerons sous les contraintes de stabilité du C'Space (Barrowman) et de tenue mécanique (poutre éléments finis). Interface graphique MATLAB avec import StabTraj.
