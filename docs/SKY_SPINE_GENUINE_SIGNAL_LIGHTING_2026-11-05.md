# VIS-048 — éclairage réellement motivé des modèles 3D Sky Spine

**5 novembre 2026 — code source non publié.** Base de travail `6387290b344145229ddde6add42cec0770d6a6ba`. Le dernier jeu public confirmé est toujours `968a49d`.

## Défaut observé dans le code

Les quatre grands portiques Sky Spine des cinq arènes disposent d'un véritable modèle original UV approuvé par Roblox (`OriginalSkySpineCrown` **71492051540032**), monté sur les vraies plateformes `SkySpineStep=2/5/6/9`. Les PBR 2K récents améliorent la matière, mais aucun photon n'émanait de ses optiques `SIGNAL`. Les anciens spots focaux éclairent surtout les surfaces de l'arène, pas les joints métalliques et les grands portiques vus de près.

## Implémentation de la famille

- `SkySpineCrownMeshKit` crée un véritable **`PointLight` sur un `MeshPart` de matériau `SIGNAL`**, uniquement sous le `Model` original vérifié et placé sur un véritable collider de route. Si le morceau approuvé manque, **pas de lampe ni de partie 3D factice**. Toutes les surfaces de marche, garde-corps, panneaux d'alerte et collisions restent ceux du serveur.
- **Maximum de sources lumineuses simultanées réellement actives** : Low = **0**, Medium = **1**, High tactile/Android = **1**, High desktop = **2**. Dès que `OptionalVfxPressure >= 1` : **0**. La caméra existante choisit les portiques les plus proches. Pas de boucle indépendante, d'import, de RemoteEvent ni de nouvel objet physique.
- Photométrie neutre et confinée, `Color=(212,230,238)`, `Brightness=0.31`, `Range=17`, `Shadows=false`. Ces valeurs n'affirment aucune certification de contraste en conditions réelles ; elles sont une première calibration originale destinée à être évaluée sur Android/PC.
- **Extinction immédiatement sur `Darkness`, même en deuxième catastrophe Double Chaos** : le `juice.client.lua` préexistant met à jour `LocalDarknessLightGuard`. `scenery-lod.client.lua` réutilise ce vrai attribut et une seule connexion `GetAttributeChangedSignal` pour éteindre les lampes sans attendre le tick LOD. Jusqu'à la première information de cet owner, la lampe reste éteinte.
- La présence d'un `CollapsePhase=Warning/Gone`, d'un `BridgeShutterPhase` actif, de la perte de collision, d'un shrink, du retrait du Model, d'un changement de carte ou de la pression GPU éteint puis nettoie les lampes par les mêmes événements que la sécurité du pont et que le masque PBR.
- Une `PointLight` est comptée par `VisualBudgetRules.isLight` dans `OriginalSkySpineCrownLocal` déjà enregistré. Budgets mondiaux du projet conservés : 32/48/64 lumières Low/Medium/High, pas de sous-compteur parallèle hors contrôle. `LocalOriginalSkySpineSignalLightCount` mesure uniquement le nombre d'instances **activées**, pas les FPS ni les lumens réels.
- Régression **Roblox engine** ajoutée à `tests/engine/mapbuilder-advanced.spec.luau` : vrais `MeshPart`, `PointLight`, couleur et limites, Medium/High/Low, extinction instantanée Darkness et Warning, pression et nettoyage du Model.

## Critères d'acceptation avant publication

1. Exécution du build et des sept suites moteur sur le **SHA final**, avec le contrôle statique d'authenticité `SIGNAL` et du guard Darkness. Publication **désactivée** pour ce lot.
2. En Roblox Studio puis Android, captures des quatre portiques par carte de jour et de nuit, test des matériaux PBR à faible distance, arrivée d'un avertissement `Warning`, secondaire Darkness et pression VFX mobile.
3. Vérifier que le budget Lights n'est pas atteint en Double Chaos, que les chemins restent lisibles, et qu'aucune lampe ne reste quand son vrai modèle disparaît. Surveiller FPS/mémoire en séance réelle ; aucun résultat appareil n'est inventé ici.

**Encore à faire :** raccords volumétriques bâtiments/ponts, calibration nocturne et contrôle Android réel.
