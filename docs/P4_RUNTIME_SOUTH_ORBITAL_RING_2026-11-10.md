# P4 — Runtime du véritable anneau d'observation Orbital de l'horizon sud

**10 novembre 2026 — code source de la prochaine mise à jour, pas de Place publiée.**

## Asset vérifiable
Le nouveau tore 3D original est produit par `tools/generate_original_south_orbital_observation_ring.py`, vérifié par [Actions #42821753995](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42821753995) : **7 048 triangles, sept sous-meshes et matériaux PBR, 14,84 × 14,84 × 1,19565 studs source**, normales, UV et tangentes glTF. L'authentique Roblox Model `124474310430876` est **Approved**.

## Séparation stricte nord/sud
L'anneau **nord** a un autre Model (`125070862497818`, 16 `ReactorArc`, `ArenaSignatureMegastructure`). Le kit `ApprovedSouthOrbitalObservationRingMeshKit.lua` ne cherche que `SouthHorizonMonument` de la vraie carte `GeneratedMap/Arena` Orbital et **14** `ObservationArc` dont taille, orientation, position et attributs physiques sont confirmés. Il impose `SuspendedOrb` sphérique 6,4, `OrbClamp` 9,5×0,8×2,4 ainsi que les deux `RingSupport` à 23 studs, qui restent visibles et intacts.

## Animation, LOD, restauration
Le serveur `PremiumSouthOrbitalObservationRingAssets.lua` charge **tardivement et sans bloquer** seulement le Model approuvé, le sanitize puis valide ses sept MeshParts et dimensions originales. Le client dimensionne le tore **uniformément** à environ 34,55 studs sur le cercle natif de rayon 17 et fixe les sept MeshParts à `Anchored=true`, `CanCollide/CanTouch/CanQuery=false`, `Massless=true`, `CastShadow=false`. Les 14 Part natives ne sont masquées **qu'après** installation complète dans `ApprovedSouthOrbitalObservationTorusLocal`. L'orbe et ses supports conservent leur comportement et visibilité.

Le kit ne crée aucune boucle de rendu ni aucun RemoteEvent ; il réutilise `scenery-lod.client.lua` et `VisualBudgetRules.lua`. Low : pas de mesh. Medium/High : au plus un Model sud, distance max 420/580 studs et rétention 26, sous réserve de pression GPU. Les 14 formes originales sont restaurées lors d'une absence d'asset, streaming incomplet, suppression du Model, changement de carte, rétrécissement du socle ou baisse qualité. Les compteurs client `LocalApprovedSouthOrbitalRingCount` et `LocalSouthOrbitalObservationArcsReplaced` mesurent des montages visibles effectifs, pas une estimation.

**Limites de preuve :** compilation Luau Engine, rendu Roblox Studio, tests Android, FPS, gameplay in situ et publication publique de cette mise à jour non attestés.
