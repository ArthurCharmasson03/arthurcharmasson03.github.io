# ONERA M6 wing — transonic validation (Ansys Fluent)

*Universidad Carlos III de Madrid, Computational Fluid Dynamics, 2024. Report: [`ONERA_M6_Validation_Report.pdf`](ONERA_M6_Validation_Report.pdf) (English).*

## Case
NASA Turbulence Modeling Resource validation case 2308: M = 0.84, α = 3.06°, Re = 14.6 × 10⁶ (root chord), T = 300 K.
Spalart-Allmaras turbulence model, density-based implicit solver (Roe-FDS, second order, then third-order MUSCL).

## Approach
- Half-sphere domain with a symmetry plane. Diameters of 9.6 m, 48 m and 96 m tested, plus one structured outer shell.
- Density-based and pressure-based solvers compared.
- Final run: a 48 m domain, a rebuilt surface mesh of about 500,000 cells, then Fluent's pressure-error adaptation up to the student licence limit of 1 M cells.

## Results (final run vs. NASA)

| | C_L | C_D |
|---|---|---|
| This work, Fluent, 1 M cells | 0.2742 | 0.01933 |
| NASA FUN3D, 1.2 M cells (same size) | 0.2632 | 0.01833 |
| NASA CFL3D, 69 M cells (finest) | 0.2693 | 0.01695 |

The C_p distributions at η = 0.2 and η = 0.9 match the NASA grids. The λ-shock is captured, slightly upstream and more smeared at η = 0.9. On the portfolio page, these two sections are redrawn from the report figures (digitised, about ±0.01 on C_p).

## Limits
- First cell at y⁺ ≈ 100, so the model uses wall functions where the references resolve the boundary layer.
- Trailing edge and wake are not refined enough. Together with the wall functions, this explains the drag gap.

---

### En bref (FR)
Validation du cas NASA de l'aile ONERA M6 sous Fluent, avec une licence étudiante limitée à 1 M de mailles. C_L est à +1,8 % du maillage NASA le plus fin, C_D à +5,5 % du calcul NASA de même taille. Les écarts restants s'expliquent par les lois de paroi (y⁺ ≈ 100) et le manque de raffinement dans le sillage.
