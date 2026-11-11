# P4 — Grande carapace 3D approuvée au centre de Crossroads sur Android Low

**11 novembre 2026 — modification source, sans publication de Place.**

## Défaut visuel identifié

Le générateur serveur `ArenaVariants.Definitions.Crossroads.Platforms[1]`
crée une vraie plateforme physique **18×2×18 studs** au milieu de Crossroads.
`PremiumLargeDeckHullMeshKit` dispose déjà de la sculpture originale
approuvée **Model 125929150866282**, adaptée aux plateformes quasi carrées
de 16,3 à 20 studs. Pourtant, son entrée `Kit.install()` refusait
systématiquement le tier **Low**, laissant le carénage primitif à deux
`WedgeParts` (indice de plateforme 1 modulo 8).

## Correction mise en code

- Le kit partage désormais ses contrôles géométriques et de provenance
  entre la sélection Low et le montage existant Medium/High.
- **Une seule** plateforme réelle `PlatformN` de numéro 1 modulo 8,
  dans les 24 premiers decks, peut recevoir le grand carénage original
  sur Low. Elle doit être ancrée, collidable, physiquement stable,
  visible et compatible avec les dimensions de la source. La caméra
  doit être dans les limites de l'arène et à **moins de 125 studs**.
- Le modèle doit être approuvé avec attributs `OwnerVerified`,
  `Original3DAssetId=125929150866282`, `CosmeticOnly`,
  `OriginalLargeDeckHull3D` et contenir **exactement 7 MeshParts**
  pour que Low l'autorise ; autrement aucun montage Low n'est tenté.
- Le nouveau grand carénage et l'ancienne petite carapace Low
  **partagent l'unique emplacement 3D**, au lieu de s'additionner.
  Quand une grande plateforme éligible est sélectionnée, elle a priorité.
  Si son Model échoue au montage, le repli visuel natif est préservé.
- Le montage remplace la carapace native existante à deux wedges :
  au maximum **7 MeshParts à la place de 2 WedgeParts**, net **+5 Parts**
  pour ce propriétaire Low, déjà comptées dans
  `VisualBudgetRules.LocalFolders.ArenaPlatformIdentityLocal`.
- Le premier palier de pression `OptionalVfxPressure>=1` désactive
  ce remplacement ; le propriétaire se reconstruit via le même
  `scheduleRebuild` déjà branché au palier Low.
- `LocalOriginalLowHubHullCount` est **0 ou 1** et ne compte que
  les MeshParts d'un vrai montage Low réussi. Zéro au nettoyage.
  Il ne représente ni des images rendues ni des FPS.

## Non régressions visées

- Les contrôles Medium/High historiques (plateforme n°1..24,
  géométrie 16,3–20 studs, taille/échelle source, provenance)
  restent inchangés ; seuls les critères de stabilité
  supplémentaires s'appliquent **à Low**.
- Aucun nouvel upload Roblox, texture PBR, type de Part, lumière,
  RemoteEvent, boucle graphique ni changement de collision serveur.
- Les alertes `CollapsePhase`, les soudures `RouteTier` et le
  restaurateur `PlatformNativeTrimReplacementKit` existants
  continuent de gérer les visuels.

## Réception requise avant publication publique

1. Vérifier sur Crossroads Low, avec la caméra dans le hub,
   `LocalOriginalLowHubHullCount = 1` si le Model Approved 7 pièces
   est effectivement répliqué et complet.
2. Vérifier `LocalOriginalNearRouteCarapaceCount = 0` quand le grand
   hull est monté ; source absente ou incompatible = **retour natif**.
3. À pression Low 1/2, constater la restitution des deux wedges,
   aucun Model de grande carapace et les collisions inchangées.
4. Vérifier Medium/High et le `CollapsePhase` sur le SHA exact,
   puis mesurer FPS/p95 et stabilité mémoire sur appareil Android.

Les contrôles source ou GitHub Actions ne sont pas une preuve de
rendu réellement chargé dans Roblox Engine. **Pas de publication de
la Place dans ce changement.**
