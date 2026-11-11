# P4 — Priorité face caméra pour les finitions 2K approuvées

**11 novembre 2026. Source uniquement ; pas de nouvelle publication Place.**

## Problème

Le gestionnaire `PremiumNearfieldPbrKit` sélectionnait les sculptures
d'acier, de céramique et de stations authentiques **uniquement par distance**
pour les quelques créneaux SurfaceAppearance PBR 2K disponibles.
Une sculpture cachée derrière la caméra pouvait occuper un créneau GPU
pendant qu'un modèle approuvé, effectivement visible, conservait sa finition
d'import par défaut.

## Correction

- La même boucle LOD transmet son vecteur `cameraLook` déjà calculé.
- `SceneryLodRules.sceneryViewScore` est partagé entre les trois familles
  de skyline et les finitions proches ; son bonus est plafonné à **60**
  studs virtuels en skyline et **28** dans le nearfield.
- Une finition **déjà installée** conserve un avantage de 12 studs virtuels
  pour limiter le remplacement fréquent de plusieurs overlays 2K lors des
  rotations de caméra. Il ne s'agit pas d'une augmentation de quota GPU.
- Rayon d'éligibilité réel 175 Medium / 245 High **inchangé**.
  Sur Low et en pression GPU sévère : **zéro** finition ajoutée.
  Les budgets existants sont respectés pour tactile et PC.
- Les 16 images originales approuvées, la validation de provenance des
  sept MeshParts, l'exclusion SIGNAL/CARBON/GRIP/GLASS et la restitution
  des apparences d'origine restent inchangées.
- Aucun AssetId ajouté, aucune nouvelle lumière, boucle, collision,
  raycast ou requête AssetService.

## Limites et recette

Contrôle de source de la signature de `reconcile`, de son appel unique,
du tri, des quotas et des restrictions de matériaux ; comportement
arithmétique face/arrière/latéral vérifiable. Pas de test moteur revendiqué.

**Avant publication :** exécuter Build Validation et le test Roblox Engine
sur le SHA exact, puis comparer captures et cadence sur un vrai Android
Medium/High. Une sélection plus pertinente ne certifie ni l'apparence
effective des textures ni l'absence de saccades de GPU.
