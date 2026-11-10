# Audit visuel et assets — Chaos Survival — 10 novembre 2026

**Base de référence :** commit public `b103f99ac88c276b8263032267c84deaac69d7ed`, Universe Roblox `10771083668`, Place `95351659174730`. Publication vérifiée par GitHub Actions `42905223602`, build `42904302951`, moteur Open Cloud `42904315240` (tous terminés avec succès).

**Nature de l'audit :** vérification du code, des modèles référencés, des matériaux, de l'éclairage, des politiques de qualité et des suites de tests. **Aucune nouvelle capture de pixels réels, mesure de FPS sur Android ou visite personnelle de la Place n'a été réalisée.** Ne pas confondre les tests du code et une certification esthétique AAA.

## Données factuelles — définitions précises

- `assets/source/roblox-asset-registry.json` liste **101 modèles Roblox**, tous marqués `Approved`. « Approuvé » signifie modération favorable du modèle, **pas** visibilité garantie dans une manche, authenticité de ses textures PBR ou certification de ses ombres.
- `default.project.json` sérialise **4 familles SurfaceAppearance** et **4 MaterialVariants** qui réutilisent les mêmes **16 Image asset IDs** (quatre cartes par famille : couleur, normales, rugosité, métal). Une preuve d'approbation à un instant donné figure dans `assets/source/roblox-pbr-approval-evidence.json`. Les quatre familles sont *BrushedTitanium, OxidizedSteel, DiamondArmor, ReactorCeramic*.
- Le convertisseur `tools/obj_to_gltf.py` et la palette `assets/source/chaos_route_kit.mtl` produisent, pour de nombreuses sculptures originales, des matériaux **metallic/roughness par facteurs constants** avec `baseColorFactor`. Ils ne créent pas de `baseColorTexture` ni de `normalTexture`. **Sept groupes de matériaux** ne signifient pas sept jeux de cartes PBR haute définition. Les originales 3D sont des MeshParts sculptées, mais leurs surfaces peuvent rester plates en gros plan.
- `src/shared/VisualTheme.lua` définit **cinq identités** et `src/client/arena-lighting.client.lua` fournit des ambiances daylight adaptées à chaque variante, dont Harbor. Le diagnostic critique ci-dessous concerne un **autre producteur**.
- `src/shared/Config.lua` définit des manches de **45 s** en groupe et de **30 s** en solo. Certains chargeurs de monuments décoratifs commencent leur première tentative à **44–199 s** selon l'arène et la priorité ; les appels sont limités par la FIFO globale de **2** requêtes en vol au maximum. La présence d'un modèle approuvé ne garantit donc pas son arrivée durant la première manche.
- `src/client/PremiumGroundPbrKit.lua` limite les îlots 2K PBR à **Low 0**, **Medium Android 2** et **High Android 6** hors pression, contre **4/12** sur PC. Les kits décoratifs ont chacun d'autres limites distance/LOD, et les formes natives restent actives en secours.
- `src/shared/VisualBudgetRules.lua` prévoit les plafonds locaux **Parts 440/680/900**, **Lights 32/48/64**, **Effects 56/82/110** pour Low/Medium/High. Il s'agit de compteurs d'instances, **pas** de triangles GPU ou draw calls mesurés. `visual-budget-pressure.client.lua` combine ces comptes au FPS/p95 mesurés.
- L'inventaire ciblé `docs/P4_SOURCE_3D_COVERAGE_INVENTORY_2026-11-09.md` compte **23 pièces natives par station périphérique**, **16 pièces éligibles à un remplacement 3D** et **7 restant natives**, soit **69,57 % d'éligibilité source des stations, uniquement**. Il y a 20 stations (4 par arène × 5), donc **460 pièces natives de station** définies, **320 éligibles** et **140 sans remplacement**. Ne jamais présenter 69,57 % comme la couverture de toute la carte.
- Le dépôt contient les scripts/générateurs, les IDs des images Roblox et des fichiers OBJ, mais **aucun fichier PNG/JPG/WebP versionné sur main**. Cela ne signifie pas absence d'images dans l'expérience : 16 textures approuvées sont effectivement référencées comme IDs externes.

## Problèmes et priorités

| Priorité | Point | Preuve / impact | Correction recommandée |
| --- | --- | --- | --- |
| P0 | **Rendu détaillé trop tardif** | First request des modèles actifs parfois après 45 s (première manche), inactive jusqu'à 199 s ; FIFO globale protège le débit mais peut accroître les attentes. | Instrumenter la première apparition de chaque vraie sculpture dans les cinq arènes ; avancer les art majeurs visibles au spawn par salves strictement bornées, sans rallumer le pic d'API ; précharger uniquement ce qui entre dans la vue. |
| P0 | **Finition matière insuffisamment diversifiée** | La grande majorité des nouvelles sculptures glTF exportées par `obj_to_gltf.py` portent des couleurs/facteurs de métal-rugosité sans textures d'image propres. Quatre familles d'atlas 2K sont partagées. | Ajouter de véritables cartes de normales/roughness/occlusion sélectives pour les surfaces maîtresses (portes, portiques, machines près caméra), avec UV, atlases adaptés au mobile et matériaux d'identité par arène. Préserver les 4 atlas approuvés en secours. |
| P1 | **Bug Harbor / Classic dans le décor atmosphérique serveur** | `src/server/ArenaAtmosphere.server.lua` ne contient que `Classic`, `Towers`, `Crossroads`, `Orbital`. `THEMES[variantId] or THEMES.Classic` colore Harbor comme Classic ; le `else` crée même `ClassicHubGlow` pour Harbor. L'éclairage client Harbor est correct, donc les deux auteurs ne concordent pas. | Définir un profil Harbor spécifique ; remplacer le hub générique par un repère de quai cohérent en s'assurant que l'effet ne masque pas les dangers. |
| P1 | **Accumulation d'objets natifs simples dans l'atmosphère** | Le même script crée 12 segments `PerimeterPulse`, 8 objets de tours, 16 pièces de silhouettes et 1 hub/couronne pour Classic/Towers/Harbor (**37 Parts par génération**), 16 guides Crossroads en sus (**52**), ou 9 pièces Orbital (**45**), sans substitution sculptée dans ce producteur. Les effets lumineux s'ajoutent. | Garder les signaux indispensables ; remplacer les grands piliers/couronnes par un petit nombre de MeshParts détaillées et agréger les éléments répétitifs, avec variant & LOD. |
| P1 | **Couverture incomplète des stations périphériques** | 7 pièces natives / 23 par station, soit 140 sur 5 arènes. Les `LeftLightNotch`, `RightLightNotch`, `CoreLens`, `WayfindingInset` doivent rester lisibles. | Convertir d'abord `InlaidStationBase` et `PodDataRailL/R` en finitions sculptées ; ne pas supprimer les signaux de navigation et de danger nécessaires aux joueurs. |
| P1 | **Qualité Low dégradée par design** | Les îlots PBR sont désactivés en Low et plusieurs kits 3D plafonnent à 0. Sans vraie capture, on ne peut pas quantifier l'effet final. | Produire des silhouettes low-poly **travaillées** ou des détails géométriques baked dans les actifs Low, plutôt que revenir à de simples blocs sur les structures hero les plus proches. |
| P2 | **Cohérence et densité de la scène non démontrées** | Les palettes sont définies, mais aucun rendu comparatif actuel certifié des 5 variantes n'est versionné. | Captures réelles Studio/Android des cinq arènes à mêmes angles et distances ; contrôler densité, hiérarchie du contraste, lisibilité des événements, parasites visuels et silhouettes au loin. |
| P2 | **Absence de score de finition d'assets mesuré** | Registre = certification de modèle, pas audit de topologie visible, densité de matériaux, LOD, UV, duplication ou draw calls. | Construire un inventaire par famille : cible native, source originale, nombre de MeshParts, triangles, maps PBR, matériau, tiers, fréquence de résidence, capture et coût GPU. |

## Plan d'action, dans l'ordre

**Phase 1 — Corriger le visible confirmé.** Corriger l'identité Harbor et les éléments atmosphériques génériques, sans toucher aux signaux de danger ni au gameplay. Réaliser la vérification source et une capture Studio sur les cinq thèmes. Pas d'esthétique prétendue avant image.

**Phase 2 — Prioriser l'apparition des vrais modèles.** Exploiter
`ServerStorage.PremiumApprovedImportDiagnostics` (`Waiting`,
`MaxQueueWaitMs`, `SlowestRequestAssetId`, `MaxRequestMs`,
`SlowestQueueAssetId`). Mesurer en moteur le temps de résidence de
chaque kit par arène à **10, 30, 45, 90 et 180 secondes**. N'avancer
que les modèles de premier plan dont le délai a été démontré.

**Phase 3 — Qualité des matériaux.** Implémenter un lot cohérent
*Classic/Towers/Crossroads/Orbital/Harbor* de surfaces originales,
avec vraie variation de roughness/normal et UV, sans texture
surdimensionnée sur mobile. Distinguer shader facteur PBR,
`SurfaceAppearance` avec cartes et `MaterialVariant` appliquée.

**Phase 4 — Silhouettes et formes restantes.** Éliminer le
décor atmosphérique répétitif, traiter les 140 détails natifs
des stations selon leur fonction, puis recenser les autres familles
du MapBuilder et de l'interface. Chaque conversion doit conserver
le marquage et les collisions si gameplay.

**Phase 5 — Validation de la qualité réelle.** Produire une grille
de captures Studio réelles (5 arènes × Low/Medium/High, caméra proche
et lointaine) et des mesures physiques Android :
FPS moyen/p95, pics d'import, mémoire, qualité des matières,
signalétique et coupures de silhouettes. Ne jamais utiliser
une image générée ou une capture d'un jeu homonyme en guise de preuve.

## Critères d'acceptation proposés

- Un style **distinct par arène**, notamment Harbor vs Classic.
- Les silhouettes hero visibles durant la première manche en Medium/High
  après chargement des vraies sources ; pas de régression au spawn.
- Les cues de catastrophes restent dominants et immédiatement lisibles.
- Aucune régression de collision, de spawn, de navigation, de retour aux
  formes natives ou de sécurité des imports.
- Qualité Low lisible et sans rectangle générique proéminent non justifié.
- Vérification visuelle à partir de **captures authentiques** et
  performances de **vrais appareils** ; pas d'annonce arbitraire
  « 100 % 3D » ni de note de beauté définitive issue du code seulement.

## Méthode de mesure de couverture future

Séparer les métriques :
1. **Static coverage:** nombre de Parts explicitement éligibles
   dans les générateurs, par famille et par arène.
2. **Live residency:** groupes ou MeshParts vraiment montés, et natives
   masquées, selon les attributs `Local*MeshCount` / relevés de pulsation.
3. **Perceived visual quality:** captures comparées et évaluation humaine
   sur textures, lumière, composition, finition et lisibilité.

Le pourcentage global de remplacement de toutes les formes primitives
reste **indéterminé** sans dénominateur exhaustif de tous les
générateurs. Toute note du rendu actualisé restera provisoire tant
que les captures in-engine ne sont pas disponibles.
