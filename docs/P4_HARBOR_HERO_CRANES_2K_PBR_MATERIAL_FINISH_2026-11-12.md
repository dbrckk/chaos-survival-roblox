# P4 — Finition PBR 2K sur la station et les grues 3D Harbor

**12 novembre 2026.** Modification du moteur client de rendu cosmétique, **sans nouveau téléchargement de textures, sans nouvelle source Roblox et sans publication du jeu**.

## Audit réel

Le moteur existant `PremiumNearfieldPbrKit.lua` applique les quatre
`SurfaceAppearance` 2K déjà sérialisées et approuvées dans
`default.project.json` : **BrushedTitanium**, **OxidizedSteel**,
**DiamondArmor**, **ReactorCeramic** (16 images couleur / normales /
rugosité / métal). Les couches sont temporaires et limitées à des
modèles `MeshPart` créateur authentifiés et proches de la caméra.

Or les deux nouvelles familles de modèles Harbor n'étaient pas dans
`SOURCES.Harbor` :
- Station de contrôle originale (`73237902371094`, 7 MeshParts),
  intégrée via `HarborHeroStationMeshKit.lua`.
- Grue conteneurs (`75684193304551`) et grue câble (`98809955094422`),
  chacune avec 7 MeshParts, intégrées via `HarborGantryKineticMeshKit.lua`.

Les grandes pièces statiques continuaient donc à utiliser uniquement
les facteurs de matériaux issus de l'import glTF, même à faible distance.

## Changement

1. Autoriser uniquement ces **trois modèles Roblox déjà approuvés** dans
   les dossiers locaux authentiques
   `OriginalHarborHeroStationLocal` et
   `OriginalHarborKineticGantryLocal`, en plus des sources existantes.
2. Sur les surfaces manufacturées **statiques** `ARMOR`, `BRUSHED`,
   `ALLOY` et `CERAMIC`, appliquer conditionnellement les matériaux
   2K existants, avec leurs **vraies cartes de normales, rugosité et
   métal**, seulement si le modèle original est résident et visible à
   proximité.
3. Exclure explicitement les groupes mobiles par leurs attributs
   `OriginalHarborHeroMotionRole` et
   `OriginalHarborGantryKineticRole` (`Radar`, `Cable`,
   `Weight`, `Trolley`, `Load`). **Ils conservent leurs finitions
   d'origine et leurs animations inchangées.**
4. Ne pas couvrir les groupes `SIGNAL`, `CARBON`, `GRIP` et
   `GLASS`, déjà exclus afin de conserver le contraste des balises
   et la distinction des matières.

## Budget GPU et repli

- **Android Low : zéro couche PBR 2K supplémentaire.** Les modèles
  source 3D Low préexistants restent visibles selon leur propre LOD.
- **Medium :** quota partagé existant (au plus 2 modèles sur Android
  sans pression) ; **High :** quota existant (jusqu'à 4 modèles
  Android / 6 PC). Aucune augmentation.
- Une pression graphique de niveau 2, l'option
  `PbrMaterialsDisabled`, une perte de source/modèle ou un
  changement de variante retire les couches via
  `release(model)` et restitue les `SurfaceAppearance` initiales.
- Aucun changement de collision, de navigation, de physique,
  de boucle de rendu, d'import serveur, de fichier image ou
  d'identifiant Roblox.
- Les 3 modèles **entrent en concurrence avec les autres sculptures** :
  cet ajout n'implique pas que les 3 seront simultanément texturés.

## Vérification

Le vérificateur source existant
`tools/verify_premium_nearfield_pbr.py` contrôle les trois IDs
approuvés, les dossiers et les vrais kits propriétaires, les exclusions
des pièces mobiles, et la compatibilité avec les limites précédentes.
Le workflow `original-nearfield-pbr-source.yml` exécute cette
vérification sur PR/push.

**À contrôler en moteur avant qualification visuelle :** Harbor,
Medium/High, station et grue à portée de caméra, nombre de couches
`OriginalNearfieldPbr2K`, cartes normales/roughness/metal réellement
affichées et animations radar/câble/charge intactes. Simuler une
pression GPU niveau 2 et la disparition d'un modèle ; vérifier le
retour des couches originales. Captures Android et FPS p95 nécessaires.

**Limite :** les tests source ne démontrent ni qualité AAA réelle,
ni rendu sur Android, ni gain FPS, ni publication Roblox.
