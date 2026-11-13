# P0 — vraie carapace 3D approuvée sur les plateformes paires de Crossroads en Android Low

**Dépôt :** `dbrckk/chaos-survival-roblox` / `main`. **Date :** 13 novembre 2026.

## Régression réelle constatée dans le code

- `MapBuilder.addPlatformDecor` crée, pour **chaque** `PlatformN`, **quatre `PlatformBevelN_K`** WedgeParts non physiques (`OriginalStructuralBevel=true`) et un `PlatformUnderFrameN` non physique (`PremiumArchitecturalSurface=true`). Ils constituent les **fallbacks natifs** ; le collider `PlatformN` appartient toujours au serveur.
- `PremiumPlatformSideMeshKit.selectCarapaceDecks()` limite Android Low sain à **un** modèle approuvé de **sept MeshParts**, dans les **125 studs** de la caméra, à pression 0. Auparavant, il excluait arbitrairement toutes les plateformes ne vérifiant pas `index % 8 == 1`. La méthode `carapace()` exigeait **le même filtre**, empêchant le montage même après sélection.
- La vraie géométrie des quatre accès principaux de **Crossroads** `Platform2,4,6,8` est `14×2×12` ou `12×2×14` studs. Ces quatre plateformes rectangulaires **correspondent aux dimensions du vrai asset** `deck_carapace_crossroads` (asset approuvé `116452624086023`, fabriqué par `tools/generate_original_platform_carapaces.py`) et non à une variante imaginaire. **Les quatre étaient auparavant exclues en Low** malgré leurs cinq formes natives existantes.

## Amélioration intégrée

1. La caméra peut sélectionner la plus proche de ces vraies plateformes de Crossroads **quel que soit son indice**. Aucune création de primitive supplémentaire pour une plateforme non retenue.
2. `PremiumPlatformSideMeshKit.carapace()` peut désormais monter **un** modèle original sur l'indice pair choisi ; toutes les validations de source, de dimension, de distance, d'ancrage, de phase, de collision et de pression graphique restent actives.
3. `arena-platform-identity.client.lua` laisse passer le **même vrai MeshPart sélectionné sur un indice pair**, tout en conservant la **moitié de la peinture native Low** et les signaux de gameplay inchangés.
4. `PlatformNativeTrimReplacementKit` masque **uniquement** les quatre bordures et le sous-cadre natifs après vérification des MeshParts réellement assemblés et de leurs Welds vers le collider serveur. Toute catastrophe `CollapsePhase`, un changement de source ou la perte du dernier MeshPart rétablit le fallback natif ; la collision du plancher ne change jamais.
5. `PremiumPlatformSideAssets.lua` charge désormais **le modèle de l'arène réellement active en premier**, après la même attente initiale de 74 secondes, puis le modèle de girder partagé, ensuite les autres modèles. Six imports maximum comme avant, séquentiels, via `GlobalApprovedImportGate` (maximum deux appels globaux concurrents). Les modèles restent ceux du registre modéré existant.

## Impact exact sur l'inventaire des cinq cartes

- **Quatre plateformes paires Crossroads nouvellement éligibles**, couvrant un maximum de **4 × (4 bordures + 1 sous-cadre) = 20 cibles natives distinctes** dans l'inventaire de source.
- **Une seule** de ces plateformes peut être remplacée visuellement **à la fois sur Android Low**, soit **cinq natives masquées par sept MeshParts authentiques** au maximum pour cette famille, et seulement lorsque le modèle est effectivement importé/validé et dans le champ d'action de la caméra.
- Les **2 080 bordures** et **520 sous-cadres** dans le recensement des cinq arènes **restent le stock initial serveur** : cette livraison modifie la résidence client conditionnelle, pas les colliders ni le nombre créé dans `MapBuilder`.

## Vérifications

- `tools/verify_platform_trim_mesh_ownership.py` protège la limite Low, la caméra, la présence des quatre vraies bordures, le contournement correct du filtre pair et la priorité d'import source. Workflow `platform-trim-streaming-regression.yml` déclenché sur les propriétaires et sur le chargeur.
- `tests/engine/native-premium-fallback.spec.luau` : vraie carte Crossroads construite par `MapBuilder.buildArena`, vraie `Platform2` de **14×2×12** et quatre `WedgePart` natives, un modèle de **sept MeshParts de fixture de test** avec les proportions du modèle approuvé. Le moteur vérifie sélection à pression 0, non-sélection à pression 1, montage en indice pair, restitution sous `CollapsePhase=Warning`, remontage sûr et fallback à la disparition de la source.
- **Statut de la campagne principale :** GitHub Actions `Roblox Open Cloud Engine Tests` `43404300904`, code `e84528a972d1bc579407b1a3012ec780005c1417`. Résultat à confirmer. Build Validation `43404243574` réussi. Contrôles statiques du chargeur et de la sélection à suivre sur la dernière révision.

Cette progression ne mesure pas les FPS/p95, les draw calls, la fidélité des pixels sur Android réel, ni une publication publique Roblox. Seule une session client peut certifier la résidence effective lorsque le modèle approuvé a fini de charger.
