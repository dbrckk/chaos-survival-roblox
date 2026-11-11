# P4 — Finition 2K des vraies stations périphériques

11 novembre 2026. Ce lot vise le système de finition visuelle partagée de
Chaos Survival, à partir du commit `5590cdcc73a4bf264f847778c33cf1f98d3620ce` déjà publié publiquement.

## Diagnostic source

Les modules périmétriques ont déjà de **véritables sculptures
créateur-approuvées** : apex propre à la variante, plaques d'armure,
poutrelles forgées, rotors, boîtiers mécaniques et supports. Ils utilisent
les mêmes sept sous-meshes et matériaux d'origine que les autres familles
P4, mais n'étaient pas encore éligibles à
`PremiumNearfieldPbrKit`.

Autre limite observée dans le code : le quota PBR classait les modèles
par `Model:GetPivot().Position`. Or les propriétaires des modèles
positionnent les sept MeshParts une par une en modifiant
`MeshPart.CFrame`. Le pivot d'export peut être décalé de la géométrie
effective et exclure un objet visuellement proche.

## Changements

- **Neuf entrées d'IDs approuvés par carte**, soit 45 lignes de
  sélection sur cinq arènes. Il ne s'agit pas de 45 assets uniques :
  plusieurs IDs sont réutilisés, et une seule arène est active.
- Les six propriétaires existants des MeshParts de périmètre sont
  autorisés explicitement. Chaque modèle doit toujours présenter
  exactement sept MeshParts non physiques, un ID Roblox approuvé,
  un dossier local autorisé et `CosmeticOnly=true`.
- Le calcul de proximité utilise désormais le centre du véritable
  `Model:GetBoundingBox()`, basé sur les MeshParts placées en jeu.
- **Budget PBR inchangé** : Low zéro ; Medium Android deux modèles ;
  High Android quatre modèles, diminués sous pression et
  désactivables par le joueur. Portée Medium 175 et High 245 studs.
  Aucun objet 3D supplémentaire n'est créé par ce changement.
- Les 16 images 2K existantes sont partagées entre les candidats.
  Les sous-meshes `SIGNAL`, `CARBON`, `GRIP` et `GLASS`
  ne reçoivent jamais de surcouche afin de préserver les signaux
  d'avertissement et la lisibilité des dangers.
- Mise à jour du contrat de régression source
  `tools/verify_premium_nearfield_pbr.py` : chaque propriétaire et
  ID enregistré est vérifié contre le registre Approved, et
  l'utilisation de la géométrie réelle est exigée.

## Limites

La finition peut ne pas apparaître sur un modèle si l'asset est
indisponible, trop loin, hors quota, ou si ses UVs sont inadaptés.
Les contrôles GitHub ne mesurent ni les FPS ni les pixels du moteur
Roblox sur un Android réel. Aucun déclenchement de publication
Roblox n'est inclus dans le lot.
