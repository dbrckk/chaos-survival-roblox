# P4 — Remplacement 3D atmosphérique : sélection des formes montables

**Date :** 11 novembre 2026. Ce lot part du commit de la Place publique
`7c1f89efabc4a6142cc46c21a9e645e27333dd6f`.

## Défaut constaté dans le code

`ApprovedAtmosphereColumnsMeshKit.sync()` classait les huit cibles
(4 piliers et 4 silhouettes) par distance caméra, puis réservait
directement les premiers `cap` éléments. Pourtant,
`mount()` refusait ensuite des sculptures pourtant sélectionnées
quand elles étaient trop élargies après mise à l'échelle :
échelle hors [0,54 ; 1,75], ou largeur supérieure à
`max(2.4, largeur_native * 2.1)`.

Sur la carte Towers notamment, les pylônes hauts et fins peuvent
échouer au contrôle de largeur alors qu'une silhouette plus éloignée
aurait pu recevoir l'asset sculpté sans problème. Avec un cap Low
de **1**, un seul candidat impossible suffisait à laisser
l'intégralité des formes primitives visibles.

## Modification

- Centralisation de la vérification dimensionnelle dans
  `candidateFit(sourceSize, kind, variant, height)`, fondée sur
  les dimensions de l'asset approuvé et le corps natif exact.
- Les candidats **non montables** sont exclus **avant** le classement
  et la consommation du budget Low/Medium/High.
- `mount()` réutilise la même vérification **avant le clonage** :
  réduit les clones inutiles et limite les invalidations visuelles.
- Le `GetBoundingBox()` du clone garde le **contrôle final strict**
  après mise à l'échelle ; la prévalidation tolère seulement 0,08
  stud pour ne pas refuser de géométrie arrondie par Roblox.
- Aucun asset importé, aucune nouvelle texture, aucune boucle, aucun
  changement de collision ou de gameplay. Même quota
  (Low 1, Medium 2, High Android 3 / PC 4), même portée,
  même source propriétaire et même repli natif sous pression.

## Validation et limite

Le script préexistant de régression Harbor est enrichi pour
vérifier que l'éligibilité de la sculpture est contrôlée au
moment du classement et à celui du montage. Ce **contrat source**
ne mesure ni les FPS ni la visibilité des vrais modèles dans
Roblox Engine. La présence de l'asset et la position de la
caméra peuvent toujours conduire à zéro remplacements réels.

La nouvelle version reste **dans GitHub** après fusion ;
une nouvelle Build Validation et les tests Engine sur le SHA
exact sont requis avant de remplacer la Place publique.
