# P0 — supports 3D authentiques : correction du plafond de sélection Medium

Date : 2026-11-13. Dépôt : `dbrckk/chaos-survival-roblox`.

## Défaut mesuré dans les sources

Le client `arena-platform-identity.client.lua` alloue déjà **8 modules** de supports approuvés en Medium, **16** en High et **1** en Low lorsque la pression graphique le permet. `PremiumLargeStructureMeshKit.supports()` ne monte qu'un support par plateforme en Medium/Low, et jusqu'à deux par plateforme en High. Mais `selectNearRouteStructures()` sélectionnait **4 plateformes** au maximum en Medium, ce qui rendait structurellement impossible l'utilisation des quatre autres modules sur quatre propriétaires distincts, même avec assez de vrais supports natifs éligibles.

## Correction

- `supportLimit` passe de **4 à 8 propriétaires** en Medium, pas de 8 à 16 modules. La limite globale **8 Medium / 16 High / 1 Low** reste inchangée, comme le nombre de modèles originaux importés et la limite de concurrence AssetService.
- La sélection reste fondée sur des plateformes `PlatformN` réellement collidables et des `PlatformSupportN_K` natifs réellement présents dans le dossier `Decor`. Classement caméra + distribution spatiale, pas de nouveau suivi `RenderStepped`.
- Les `MeshPart` de chaque colonne restent **sept pièces source**, non collidantes, soudées au support serveur et automatiquement restaurées en fallback natif lors des changements de streaming, d'effondrement et de pression. Aucune suppression des `800` supports primitifs serveur.
- Le nombre de plateformes éligibles réellement visibles dépend de la carte, des dimensions de supports et du streaming. **8 est un maximum, pas une garantie de huit modèles montés**.

## Vérification

- Contrôle de source `tools/verify_original_3d_budget_census.py` : succès sur `af8555e7` ([GitHub Actions 43415880948](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43415880948)).
- `tests/engine/native-premium-fallback.spec.luau` : ajout d'un contrôle avec la vraie carte Crossroads produite par `MapBuilder`, les vrais `PlatformN` et les vrais `PlatformSupportN_K` ; vérifie huit propriétaires Medium distincts et les colliders natifs conservés. **Campagne moteur en attente au moment de cette rédaction**.
- Un test de source et un build réussi ne constituent pas une mesure des FPS ni une preuve de publication Roblox.
