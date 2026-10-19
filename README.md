# Portfolio — Arthur Charmasson

Site statique (HTML/CSS/JS, aucune dépendance) pour GitHub Pages. Il est bilingue français/anglais, suit le thème clair ou sombre du visiteur et s'affiche correctement sur mobile.

## Mise en ligne (10 minutes)

1. Sur GitHub, crée un dépôt **public** nommé exactement `<ton-pseudo>.github.io`.
2. Dépose **tout le contenu de ce dossier** à la racine du dépôt. Inclus le fichier caché `.nojekyll` : il empêche GitHub de retraiter le site.
   - Par l'interface : *Add file → Upload files*, puis glisse les fichiers et dossiers.
   - En ligne de commande :
     ```bash
     git init && git add . && git commit -m "Portfolio"
     git branch -M main
     git remote add origin https://github.com/<ton-pseudo>/<ton-pseudo>.github.io.git
     git push -u origin main
     ```
3. Dans *Settings → Pages*, choisis la source **Deploy from a branch**, branche `main`, dossier `/ (root)`.
4. Après une à deux minutes, le site est en ligne à l'adresse `https://<ton-pseudo>.github.io`.

Si tu nommes le dépôt autrement (par exemple `portfolio`), le site sera à l'adresse `https://<ton-pseudo>.github.io/portfolio/`. Les liens vers le code s'adaptent tout seuls dans les deux cas.

## À compléter avant de publier

Dans `index.html` :

- **LinkedIn** : remplace `https://www.linkedin.com/in/VOTRE-PROFIL`, puis supprime l'attribut `hidden` du bouton.
- **CV** : dépose `assets/CV_Arthur_Charmasson.pdf`, puis supprime l'attribut `hidden` du bouton.
- **E-mail** : l'adresse ESTACA est celle de l'en-tête de ton code. Remplace-la par une adresse durable si elle doit expirer après le diplôme (trois occurrences).
- **Rapports PDF** : ils contiennent ton numéro étudiant UC3M en page de titre. Tu peux le retirer dans les sources LaTeX et recompiler avant de publier.

## Prévisualiser en local

```bash
python -m http.server 8000
# puis ouvrir http://localhost:8000
```

## Modifier le contenu

- Chaque texte existe en deux versions : `<span data-lang="fr">…</span><span data-lang="en">…</span>`. Modifie les deux.
- Les graphiques sont des SVG intégrés à `index.html`. Leurs données viennent des rapports (tableaux NASA et Botella & Peyret) et de la courbe de poussée de `Trajectoire_Aerofreins_v3.m`.
- Les courbes de C<sub>p</sub> (η = 0,2 et 0,9) ont été numérisées depuis les figures 9 et 10 du rapport M6, avec une précision d'environ ±0,01. Si tu retrouves les exports Fluent (.csv ou .xy), remplace-les par les vraies données : les valeurs se trouvent dans le bloc `<script id="cp-data">` et dans les `polyline` des deux graphiques.
- Couleurs et typographie : variables CSS en tête de `assets/css/style.css`, en thème clair et en thème sombre.

## Structure

```
index.html                  page unique
assets/css/style.css        styles (thèmes clair et sombre)
assets/js/main.js           bascule FR/EN, infobulles, liens GitHub
assets/img/                 figures extraites des rapports
projects/onera-m6-wing/     rapport PDF + README
projects/lid-driven-cavity/ rapport PDF + CFDPROJECT.m (SOR) + cfdlid2.m (DST) + README
projects/fin-optimization/  OPTI_AILERONS_ESO.m + README
projects/airbrake-trajectory/ Trajectoire_Aerofreins_v3.m + README
CORRECTIFS.md               les seules modifications apportées à tes codes, ligne par ligne
```
