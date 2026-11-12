# P4 — Deux grandes silhouettes authentiques supplémentaires sur Android Low

**12 novembre 2026. Statut : code source GitHub. Aucun test Roblox Engine ni déploiement de la Place effectué.**

## Audit des deux arènes

Deux kits déjà déployés sur les profils Medium/High étaient totalement
désactivés sur les appareils Android Low, par **deux gardes indépendantes**
(`Low=0` et branche tactile retombant sur `or 0`).

| Arène | Formes primitives serveur | Sculptures approuvées existantes | Coût Low autorisé |
| --- | --- | --- | --- |
| **Towers** | 4 tours `TowerMachinery` de **24 studs** chacune, chapeau animé `TowerMachineryCap`, antenne indépendante | `72143366927826`, sculpture originelle **7 MeshParts**, enveloppe 7,36 × 24,9 × 7,36 studs | **1 tour / 7 MeshParts** à ≤**205 studs** |
| **Orbital** | 8 groupes de sphères `OrbitalReactorNode` de 4,4 studs et leurs contreforts rectangulaires `OrbitalReactorStrut` de 8,5 studs | `104654294187035` (**7 MeshParts**) + `138666009076890` (**7 MeshParts**) | **1 groupe / 14 MeshParts** à ≤**210 studs** |

Les trois modèles sont déjà approuvés dans
`assets/source/roblox-asset-registry.json`, importés/sanitisés
côté serveur, et soumis aux gardes `OwnerVerified`,
`CosmeticOnly`, `Original3DAssetId` strict,
`OriginalTowersMachinery3D` ou
`OriginalOrbitalReactorLandmark3D`. Aucun nouvel asset ou
import client n'est requis.

## Modifications

- Sur Towers, `ApprovedVariantTowersLandmarkMeshKit` autorise **un
  seul** modèle original proche sur Low (`CAP.Low=1`,
  `RANGE.Low=205`). Le code tactile ne neutralise plus ce
  quota. Medium conserve 2 modèles à 290 studs ; High, 4 à 410.
  Les plafonds Medium et High tactiles restent 1 et 2.
- Sur Orbital, `ApprovedOrbitalReactorLandmarkMeshKit` autorise
  **un seul groupe complet original** sur Low
  (`LIMITS.Low=1`, `RANGE.Low=210`). Il est formé de
  **deux** modèles de sept MeshParts, toujours installés en
  totalité **avant** tout masquage des deux pièces natives.
  Medium conserve 3 groupes à 340 studs ; High, 6 à 460.
  Les plafonds tactiles Medium/High restent 1/3.
- **Les deux arènes ne peuvent pas être actives simultanément**.
  Les quotas Low présentés ci-dessus ne s'ajoutent donc pas
  sur une même carte. Les dossiers déjà déclarés dans
  `VisualBudgetRules.LocalFolders` restent inclus dans le
  budget partagé de 440 Parts Android Low.
- Sur Low, `OptionalVfxPressure=1` fait tomber
  `math.floor(1×0,5)` à zéro et restaure le rendu natif.
  Sous pression 2, la géométrie facultative demeure désactivée.
  Les marges de résidence historiques restent 24 studs Towers
  et 26 studs Orbital.
- Une écoute `bucket.ChildRemoved` sur chaque propriétaire
  restaure **immédiatement** les natives si le gestionnaire
  budgétaire supprime un modèle entre deux échantillons LOD.
  L'entrée de montage est retirée avant la destruction du clone,
  évitant les callbacks récursifs.
- **Animations conservées** : Towers cache le chapeau
  `TowerMachineryCap` seulement via
  `SceneryLodHidden` et `LocalTransparencyModifier`,
  sans changer ses valeurs live de `Transparency` ni `CFrame`.
  L'antenne `TowerAntenna` reste intacte. Orbital conserve
  également l'animation réelle de sa sphère
  `OrbitalReactorNode` et ses attributs de masquage natifs.
  Lors du retrait du clone, leurs valeurs LOD sont restaurées.
- Les modèles d'origine sont non physiques, sans toucher,
  requête de collision ni ombre. Aucune modification des dangers,
  bots, mouvements, plateformes jouables, lumières,
  `RenderStepped`, `Heartbeat` ou `RemoteEvent`.

## Recette moteur et Android

1. Jouer sur Towers avec qualité **Low**, pression zéro et
   source originale chargée. Se placer à moins de **205 studs**
   de `TowerMachinery1..4`. Vérifier **une** silhouette 3D
   de sept MeshParts à la place d'une grande colonne et de
   son chapeau animé, sans disparition de l'antenne.
2. Sur Orbital, se placer à moins de **210 studs** d'un
   `OrbitalReactorNode1..8`. Vérifier **exactement sept
   MeshParts de nœud et sept de support**, et **deux** natives
   masquées **seulement** après double montage réussi.
3. Vérifier les attributs `LocalTowersLandmarkMeshCount≤1`
   et `LocalOrbitalReactorSculptPairCount≤1` sur Low.
4. Tester les huit directions Orbital, la pulsation du chapeau
   Towers, les mouvements du nœud Orbital et la réduction
   progressive de l'arène. Les positions sont calculées
   sur `OriginalSizeX/OriginalSizeZ`, pas le plancher rétréci.
5. Tester un asset manquant, un import incomplet, un
   `StreamingEnabled` intermittent, `OptionalVfxPressure=1/2`
   et le retrait manuel du modèle local : les formes primitives
   reviennent **sans attendre** le prochain sampler.
6. Comparer FPS, p95, mémoire et captures avec et sans ces
   sculptures sur un appareil Android Low réel. Déterminer
   le coût cumulé avec les autres décors visibles avant
   toute augmentation supplémentaire.

Les régressions GitHub des sources originales,
du mouvement des deux arènes, du budget 3D Android
et de la traduction Lua contrôlent les contrats statiques.
**Elles ne remplacent pas la validation de rendu dans Roblox Engine.**
