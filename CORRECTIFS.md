# Correctifs appliqués aux codes (version portfolio)

Règle suivie : **aucune refonte**. Seules les erreurs qui empêchent un code de tourner ou qui faussent un résultat ont été corrigées.
Chaque ligne modifiée est balisée `[CORRECTIF portfolio]` dans le fichier, avec la ligne d'origine conservée en commentaire.
Les rapports PDF n'ont pas été modifiés.

| Fichier | Problème | Effet avant correction | Correction |
|---|---|---|---|
| `projects/airbrake-trajectory/Trajectoire_Aerofreins_v3.m` | `F_a_mach0=[Mach_a,F_a]; F_a_mach0(2,:)=0;` : matrice 24×2 non transposée, la ligne annulée est une ligne de Mach | Trajectoire en `NaN` dès qu'on choisit une altitude de déploiement `H ≠ H_sortie` | `F_a_mach0=[Mach_a,zeros(size(F_a))]';` |
| `projects/fin-optimization/OPTI_AILERONS_ESO.m` | Contraintes de marge max `c(3)`…`c(6)` de signe inversé | Marge statique max (6 calibres) jamais imposée | `c = -Stab - MS_max*D` |
| `projects/fin-optimization/OPTI_AILERONS_ESO.m` | Limite élastique passée en MPa au solveur MEF qui calcule en Pa (affichage uniquement) | FS longitudinal / transverse affichés 10⁶ fois trop petits | `material.sigma` au lieu de `material.sigma/1e6` |
| `projects/fin-optimization/OPTI_AILERONS_ESO.m` | Flèche : `U(end)` est la rotation du dernier nœud, pas son déplacement | Contrainte de flèche `c(19)` mélangeant rad et m | `U(end-1)` |
| `projects/fin-optimization/OPTI_AILERONS_ESO.m` | Export : `results.marge_stab` n'existe pas | Bouton Export en erreur (Excel et texte) | Export des marges moteur plein et moteur vide |
| `projects/lid-driven-cavity/cfdlid2.m` | `dstn` / `idstn` absentes de MATLAB de base | `Undefined function 'dstn'` au premier pas | Paire DST-I ajoutée en fonctions locales (vérifiée : erreur ~1e-15) |

`projects/lid-driven-cavity/CFDPROJECT.m` : aucune modification.

## Points relevés mais volontairement non modifiés

Ils relèvent de choix de modélisation ou demandent ton arbitrage :

- **Ailerons** : le CP des ailerons est placé avec `TAILLE_FUSEX - m`, alors que leur CG utilise `position_bas`. Avec les valeurs par défaut (80 cm contre 120 cm), les deux positions diffèrent de 40 cm. **À vérifier selon la convention de la feuille StabTraj.**
- **Ailerons** : `Beta = 1`, donc les contraintes « SS » dupliquent les contraintes subsoniques. Le CP de l'ogive est pris à L/2 ; les coefficients 0,02 et 0,1 des efforts ne sont pas justifiés ; il n'y a pas de critère de flottement (flutter).
- **Trajectoire** : `acc/m` agit seulement à t = 0 ; `disp` dans l'ODE ; la force des aérofreins est tabulée à densité constante ; pas de rampe de lancement ; `Drag.csv` et `Mach.csv` ne sont pas fournis.
- **cfdlid2.m** : le Poisson spectral suppose `H = 1` (`ky = kπ`) ; il reste du code mort de la version SOR.
