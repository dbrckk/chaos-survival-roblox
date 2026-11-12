# P4 — Achever les 13/13 primitives du monument sud Towers sur Android Low

**12 novembre 2026.** Changement GitHub ; validation Roblox Engine et publication
de la Place publique non effectuées.

## Constat confirmé dans les sources

Le `SouthHorizonMonument` Towers contient exactement **13 éléments de
décor non physiques**, couverts par trois véritables modèles créateur
qui se répartissent les cibles **sans aucun chevauchement** :

| Kit | Cibles natives | Source 3D approuvée | Portée Low |
| --- | --- | --- | --- |
| `ApprovedSouthTowersSkytransferMeshKit` | Pont `SkyTransfer`, cabine `UnderslungLift` (2) | `120959181274080` | 290 studs |
| `ApprovedSouthTowersLiftTwinsMeshKit` | Ascenseurs Ouest/Est, deux couronnes (4) | `114886409893890` | 152 studs |
| **`ApprovedSouthTowersFinishingMeshKit`** | Fondation, plancher incrusté, deux rails, deux suspensions, signal `TransferSignal` (7) | **`79666240429608`** | **106 studs** |

Les deux premiers kits fonctionnaient déjà sur Low. Le dernier était
encore désactivé avec `QUALITIES.Low = 0`, laissant sept formes basiques
dominantes, notamment un signal `WedgePart`.

## Modification

- Activation **`QUALITIES.Low = 1`** dans le kit de finition original.
  Aucun nouvel import : le serveur dispose déjà du modèle de sept vrais
  MeshParts `ApprovedSouthTowersFinishingTemplates.ForgedFinishing`.
- Portée conservatrice de **106 studs**, avec 26 studs de rétention
  uniquement pour un modèle déjà monté. Les portées Medium 420 et
  High 580 studs et toutes leurs règles restent inchangées.
- Jusqu'à **trois modèles originaux distincts de sept MeshParts**
  peuvent coexister à proximité immédiate (21 MeshParts Low au
  maximum pour le monument sud Towers), sous la pression globale
  `VisualBudgetRules` (440 parties pour Low). Le seuil de proximité
  évite de charger le troisième modèle loin de la caméra.
- `OptionalVfxPressure >= 1` interdit tout nouveau montage Low et
  **restaure automatiquement les primitives natives** des trois kits.
- Les garanties existantes restent appliquées : modèle source
  `OwnerVerified`, `CosmeticOnly`, `Original3DAssetId` exact,
  sans scripts, sept vrais MeshParts, volumes et rotations vérifiés,
  absence de collisions, de toucher, de requête et d'ombres.
- Les sept formes serveur sont masquées **uniquement après montage
  complet** dans leur dossier `ApprovedSouthTowersFinishingLocal`.
  La perte de l'asset, le streaming partiel, le retrait d'une
  MeshPart ou la modification de la carte restaure le décor natif.
- L'owner continue d'être appelé par `scenery-lod.client.lua`,
  sans boucle graphique supplémentaire, texture, lumière ni
  modification physique serveur.

## Test d'acceptation dans Roblox Engine

1. Choisir Towers sur un appareil Android Low sain, en pression 0.
   Avec la caméra à moins de 106 studs du sud, constater la
   disparition des 13 primitives de décor au profit des **trois
   modèles originaux de sept MeshParts** — et non de modèles de
   démonstration ou d'un simple changement de couleur.
2. Contrôler `LocalApprovedSouthTowersSkytransferCount`,
   `LocalApprovedSouthTowersLiftTwinsCount`,
   `LocalApprovedSouthTowersFinishingCount` (chacun 0 ou 1).
   Les compteurs natifs doivent être **2 / 4 / 7** lorsque les
   trois modèles ont effectivement été montés.
3. Faire reculer la caméra au-delà des seuils +26 studs de
   rétention, puis forcer `OptionalVfxPressure=1` et 2 :
   tous les éléments serveur doivent redevenir visibles.
4. Vérifier un chargement partiel des sources, un retrait d'une
   MeshPart, la transition d'arène, Darkness et les catastrophes.
   Les plateformes jouables, trajectoires bots, lumières et
   marqueurs de danger doivent rester inchangés.
5. Mesurer FPS p95, mémoire et temps de chargement sur vrai
   smartphone Android Low, et comparer les captures avant/après.

`tools/verify_south_towers_mesh_fallback.py` contrôle désormais
les limites Low des trois kits et leurs **13 cibles non redondantes**.
Les résultats GitHub sont des **vérifications du code source** ;
ils ne remplacent pas un test Roblox Studio ou un déploiement réel.
