# P4 — Chargement fiable des véritables MeshParts après streaming

**11 novembre 2026 — changement source, sans publication Roblox.**

## Problème constaté

Les propriétaires de visuels des plateformes surveillaient l'apparition des
Models approuvés `ApprovedFloorReliefTemplates`,
`ApprovedPlatformSideTemplates`, `ApprovedLargeDeckHullTemplates`
et `ApprovedLargeStructureTemplates`. Si le Model était répliqué avant
`OwnerVerified`, `Original3DAssetId`, `CosmeticOnly` ou son marqueur
d'origine, la vérification refusait à juste titre le Model ; aucun événement
ne relançait toutefois le montage une fois les attributs arrivés.
La plateforme pouvait rester sur ses Parts/WedgeParts natives jusque
la prochaine carte ou le prochain changement significatif de caméra.

Les trois observateurs de `RouteTier` et `HarborSpokeRoute/Step`
utilisaient également `task.defer(rebuild)` directement. Une vague
d'attributs arrivant sur 16 plateformes Harbor pouvait provoquer plusieurs
destructions/remontages complets du même propriétaire cosmétique.

## Modifications

- Écouter **uniquement les attributs de provenance** de chaque Model
  déjà approuvé dans ces quatre dossiers et `OwnerVerified` du dossier.
  Aucune validation ne devient permissive : les kits continuent à contrôler
  l'ID exact, les MeshParts et leurs dimensions avant installation.
- Chaque changement valide **programme** la reconstruction existante via
  `scheduleRebuild` (batch de 0,12 s), à la place des trois chemins
  `task.defer(rebuild)` non regroupés.
- Nettoyer les abonnements à chaque remplacement de dossier, ignorer les
  changements d'un Model sorti du dossier, traiter les modèles qui étaient
  présents avant la création de l'observateur.
- Conserver les quotas Android, les sources Approved, les colliders serveur,
  les avertissements et les replis natifs. Aucun import AssetService, Part
  supplémentaire, RenderStepped, RemoteEvent ni boucle de polling.

## Vérification attendue

1. Sur une vraie carte, charger un Model avant ses attributs : les formes
   natives restent visibles tant que la provenance est incomplète.
2. Après réception de la provenance correcte : le même propriétaire
   reconstruit les MeshParts à quota constant, sans changer de carte.
3. Sous source absente/invalide ou pendant le streaming-out : les replis
   natifs restent intacts ; aucune collision de plateforme ne change.
4. Faire arriver `RouteTier` et les attributs Harbor en rafale : une
   fenêtre de 0,12 s coalesce les demandes de reconstruction.

**Non validé à ce stade :** exécution Roblox Engine sur le commit exact,
rendu Android réel, cadence FPS/mémoire et publication de la Place.
