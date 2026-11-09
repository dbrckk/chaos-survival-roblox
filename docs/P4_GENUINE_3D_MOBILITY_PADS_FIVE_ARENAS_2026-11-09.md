# P4 — pads de mobilité : vrai carénage 3D approuvé et signalétique au sol

**9 novembre 2026 — source uniquement.** Base `main@839593a96ee1c9d5bc0cdc2a0773b7affa689cbf`. Aucun nouvel asset inconnu, publication, build ou test moteur n'a été exécuté pour ce lot. La dernière publication attestée reste [P2 sur `ae4ae044...`, GitHub Actions #42650986552](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42650986552). P3 est intégré sur GitHub, non publié/certifié ; P4 suit la même règle d'itération sans exécuter de tests, sans présenter de résultats fictifs.

## Défaut visuel inspecté

Dans les cinq mondes, `ArenaMechanics.createPad` produit des surfaces physiques de **6,5 × 0,35 × 6,5 studs**, non collidables, déjà utilisées par le gameplay (4 pads Classic, Towers, Crossroads et Harbor ; 8 Orbital). Leur forme jouable reste un seul carré néon avec lampe. `arena-pad-ambient.client.lua` leur ajoute particules et contour, mais **aucune sculpture 3D source-authentique ni information sur la fonction et le numéro de la station**. Cette surface est au contact direct du joueur et reste très visible en Low Android.

## Remplacement P4 déjà codé, sans toucher aux physiques

### Source 3D réelle et authentifiée

Le nouveau `PremiumMobilityPad3DKit.lua` monte uniquement `ReplicatedStorage.ApprovedFloorReliefTemplates.CornerGuard` : **modèle de sculpture acier forgé original du créateur, Roblox Approved**, `Original3DAssetId=102215174919938`. C'est le même modèle autorisé déjà chargé par `PremiumFloorReliefAssets` pour les vrais reliefs au sol (historique d'import [#41740585965](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41740585965)). Aucun faux MeshId ni génération 3D primitive n'est utilisé. Le code vérifie propriétaire/asset/provenance/flags, **1 à 12 vrais MeshParts sans scripts**, et l'enveloppe attendue originale `X/Z=4.7..5.6, Y=.24..56` studs.

- Les MeshParts du clone original sont redimensionnés **proportionnellement** pour s'inscrire à l'intérieur du vrai pad 6,5 studs et émerger de **0,45 stud au plus**. Chaque pièce reste `Anchored`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false`, `CosmeticOnly=true`.
- Le **vrai pad serveur reste visible, CanTouch et autoritaire**. Les collisions, les dégâts, le boost, les attributs P3, les cooldowns, les lampes de serveur et les alertes de catastrophe sont inchangés.
- L'authenticité, le nombre de pièces et les dimensions sont contrôlés **avant** l'installation. Source manquante, retrait du modèle, descendant 3D perdu, pad détruit, streaming ou changement de carte → destruction du clone client. Le pad natif n'est **jamais masqué**, il reste la solution de repli.
- Le chargement serveur existant de l'asset peut arriver **après ~34 secondes**. `arena-pad-ambient` écoute le dossier de templates et sa réelle arrivée `CornerGuard`, sans timer de polling ni nouvel appel HTTP / LoadAssetAsync client.

### Une vraie priorité de performance Android

Le propriétaire local `OriginalMobilityPadHardwareLocal` est ajouté au census **déjà existant** `VisualBudgetRules.LocalFolders` (limites 440/680/900 Parts). Toutes les MeshParts du modèle original sont donc comptées, au lieu de contourner le garde-fou.

| Qualité | Modèles 3D au maximum, si la source existe et la scène est saine | Pression légère | Pression forte |
| --- | --- | --- | --- |
| Low | 0 | 0 | 0 |
| Medium | 2 | 1 | 0 |
| High Android | 3 | 1 | 0 |
| High PC | 4 | 2 | 0 |

Les pads sont classés par distance de la caméra au **moment d'une notification visuelle existante** et sélectionnés dans une liste bornée à huit, avec ordre déterministe. Pas de surveillance du déplacement à chaque frame ni boucle supplémentaire. `OptionalVfxPressure` retire d'abord les sculptures facultatives, sans jamais désactiver les vrais pads jouables.

### Signalétique premium de proximité, toutes qualités

Même en Low, chaque pad authentique affiche une plaque de fonction **sur sa propre face supérieure** (`SurfaceGui` non interactive et non flottante) : cadre industriel discret, numéro de station, trait de canal et fonction localisée :
- Classic : ÉVASION / ESCAPE
- Towers : ASCENSION / UPDRAFT
- Crossroads : VOIE / LANE
- Orbital : ORBITE / ORBIT
- Harbor : TRANSFERT / TRANSFER

Le panneau laisse transparaître le néon natif (fond sombre **72 % transparent**) ; un overdrive colore simplement les accents de la même couleur ambre que le halo déjà existant. Pas de bouton tactile, de barre centrale HUD, ni de confusion avec une alerte de danger. Toutes les ressources SurfaceGui, Highlight, particules et connexions sont retirées au changement de carte et en streaming. `LocalOriginalMobilityPad3DCount` est **un compteur local de modèles réellement montés**, pas un FPS mesuré.

## Critères de réception avant publication (non exécutés)

1. 5 cartes à 1 humain + 7 bots, 4/8 pads : vrai pad et labels FR/EN restent visibles en Low, même lorsque l'import original est absent. Les déplacements P3 et les interactions de tous les bots fonctionnent sans nouvelles collisions.
2. Medium/High et source Approved disponible : un maximum de 2/3/4 sculptures véritables (selon mobile/PC) couvre de vrais pads, sans clone fantôme ou changement de dimensions.
3. Mettre `OptionalVfxPressure` à 1 puis 2 : retrait de la sculpture sur des pads facultatifs; Low reste 0 3D; la lampe/le contact/Highlight restent natifs.
4. Retirer le `CornerGuard` source ou un de ses vrais MeshParts : clone devenu invalide disparaît, pad toujours opérationnel et visible. Recharger la source : présentation reconstruite via les watchers.
5. Pendant `ShrinkingArena`, effondrement de pont, `Darkness`, Double Chaos, dérive de caméra, changement de map, retournement Android et respawn : pas de sol fictif, pas de gros flash ni d'obstruction des alertes.
6. Mesurer réellement MeshParts, DrawCalls, p95 frame time et FPS Android avant **la prochaine publication** ; sans résultat moteur, on ne peut pas qualifier le rendu d'AAA certifié.

**Bilan honnête :** les modifications augmentent la présence de vrais détails 3D au premier plan et la lisibilité des interactions sur les cinq cartes **dans le code**. Elles ne prouvent pas encore que l'import Roblox réussit sur chaque téléphone ni que le résultat atteint le niveau AAA visé.
