> **Actualisation du 11 novembre 2026 — code source P4 :** la base `InlaidStationBase` bénéficie maintenant d'un véritable insert approuvé (`ApprovedPerimeterStationDeckInlayMeshKit`) par réutilisation de l'asset 3D du sol. La couverture statique potentielle des stations passe de **16/23 (69,57 %)** à **17/23 (73,91 %)**. Les six voyants/repères lumineux restent volontairement natifs. Ce ratio ne reflète pas les modèles réellement rendus en jeu et les chiffres ci-dessous décrivent l'audit historique du 9 novembre. Détails : [lot de socles 3D](P4_APPROVED_STATION_DECK_INLAYS_2026-11-11.md).

# Inventaire précis de couverture 3D — stations périphériques

**9 novembre 2026 — audit statique du code de src/server/MapBuilder.lua, fonction addPerimeterStations.**

## Méthode et dénominateur

Chaque vraie station possède exactement **23 pièces natives cosmétiques** : base incrustée (1), piliers (2), capots (2), lumières de piliers (2), traverse (1), boîtier central (1), lentille (1), repère de navigation (1), compresseurs (2), turbines d'admission (2), ailes mécaniques (2), rails de données (2), rotor supérieur (1), blindage (1) et **deux éléments propres à la variante (2)**. Il y a quatre stations par variante et cinq variantes.

## Couverture des remplacements d'assets originaux

| Kit 3D effectivement branché dans le code source | Pièces natives ciblées par station |
| --- | ---: |
| ApprovedPerimeterButtressMeshKit | 2 |
| ApprovedPerimeterMachineryMeshKit | 3 |
| ApprovedPerimeterRotorMeshKit | 3 |
| ApprovedPerimeterArmorMeshKit | 4 |
| ApprovedPerimeterStructuresMeshKit | 2 |
| ApprovedPerimeterVariantApexMeshKit | 2 |
| **Total source avec véritable modèle 3D approuvé** | **16** |
| **Pièces encore natives sans substitution 3D** | **7** |

**16 / 23 = 69,57 %** de pièces source potentiellement convertibles en vraie géométrie MeshPart et **7 / 23 = 30,43 %** restant nativement géométriques dans une station. Le calcul précédent était 14 / 23 = 60,87 % : soit **+8,70 points**. Cinq variantes × quatre stations donnent 460 pièces natives dans les définitions, dont 320 potentiellement remplaçables et 140 qui n'ont pas de mesh de substitution.

Les sept éléments restant sans remplacement sont : InlaidStationBase (1), LeftLightNotch et RightLightNotch (2), CoreLens (1), WayfindingInset (1), PodDataRailL et PodDataRailR (2). Une partie est volontairement conservée pour assurer la lecture du danger et des objectifs ; une transformation en asset 3D n'est pas systématiquement justifiée.

## Les cinq silhouettes de sommet

Towers remplace ServiceMast + SignalCrown par perimeter_towers_apex (Model 131413152501235). Orbital remplace ReceiverDish + ReceiverAntenna par perimeter_orbital_apex (131188899020391). Crossroads remplace ExchangeBeam + SwitchyardMarker par perimeter_crossroads_apex (134533469777794). Classic et Harbor remplacent RelaySpire + RelayCrown par perimeter_relay_apex (110237986522853). Ces quatre vrais assets ont reçu Moderation Approved dans GitHub Actions #42699542702 et sont montés localement sur les deux pièces natives avec fallback.

## Limites d'interprétation obligatoires

Ce **69,57 % ne concerne PAS l'ensemble de Chaos Survival**. Les plateformes, bâtiments, éléments d'environnement, lobby, effets, skybox et autres props ne font pas partie du dénominateur de 23. Ce n'est **pas non plus le pourcentage d'objets qui apparaissent réellement en 3D MeshPart à l'écran** : le tier Low conserve les 23 pièces natives dans cette famille, les tiers Medium/High sélectionnent seulement des stations proches, le streaming peut être partiel et le chargement/contrôle de géométrie d'un Model peut échouer. La limite High Android est deux stations, High PC trois, et une pression VFX élevée peut rendre les quatre stations entièrement natives.

**Aucun test Roblox Engine, audit de FPS Android ou nouvelle publication Roblox Place n'a été accompli sur ce commit.** Pour l'audit global, prévoir un recensement de tous les générateurs d'instances du jeu et un instantané de plusieurs arènes actives en conditions réelles. Dernière publication publique attestée : P2 (ae4ae044e991ef4ca28a991991f2e11b9df49c84).
