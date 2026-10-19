# CHIRON trajectory and airbrakes (MATLAB)

*ESTACA Space Odyssey, aerodynamics team of the supersonic rocket CHIRON. File: [`Trajectoire_Aerofreins_v3.m`](Trajectoire_Aerofreins_v3.m). Comments are in French.*

## Purpose
C'Space caps apogee at 3,000 m, so CHIRON carries airbrakes. This script predicts the trajectory and apogee with and without airbrakes, and the descent with and without parachute.

## Model
- 2D point mass, state `[x, y, vx, vy, γ]`, gravity turn `dγ/dt = −(g/V) cos γ`.
- Drag coefficient interpolated in Mach from `Drag.csv` and `Mach.csv`. ISA temperature and density lapse.
- Powered phase: tabulated thrust curve (peak 1,286 N, burn 4.68 s, 1.795 kg of propellant) and decreasing mass.
- Airbrakes: four brakes with a Mach-tabulated force, deployment ramp `Tsortie = 0.5 s`.
- `ode45` events: deployment altitude, apogee (`vy = 0`), touchdown.

## Result
Without airbrakes the apogee reaches about 3,850 m; with airbrakes it drops to about 2,700 m, under the 3,000 m ceiling. Values are read from the MATLAB figure; the portfolio chart is redrawn from it by digitisation, rounded to 50 m.

## How to run
`Drag.csv` and `Mach.csv` (the team's drag-versus-Mach tables) must be in the same folder; they are not included here. Run the script to get the trajectory plot and the apogee and range table.
Post-burnout initial conditions (`H_sortie`, `V_sortie`, …) come from the team's StabTraj sheet. Update them if the design changes.

## Known limits
- The airbrake force is tabulated in newtons versus Mach at fixed density, so braking is overestimated at altitude.
- No launch rail: γ starts changing as soon as V > 1 m/s.
- The coast phase restarts from StabTraj values instead of chaining from the computed powered phase.

---

### En bref (FR)
Simulation 2D de la trajectoire de CHIRON (ode45, Cx(Mach), atmosphère standard, poussée tabulée) pour prédire l'apogée avec et sans aérofreins, sous le plafond de 3000 m du C'Space.
