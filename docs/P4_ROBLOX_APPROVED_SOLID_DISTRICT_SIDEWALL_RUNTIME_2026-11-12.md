# P4 — vraie sculpture 3D des murs latéraux : Roblox Approved et runtime sécurisé

**12 novembre 2026.** Développement fondé sur un upload réellement effectué, non sur un identifiant fictif.

## Preuve d'asset

- **Roblox Model `77387019170428`**, creator user `9774173158`, modération **`Approved`**.
- GitHub Actions d'import : `43302925840` — la sortie officielle affiche `Verified created Model asset ID: 77387019170428` et `Moderation: Approved`.
- Gate source : `43302778361` — `1,764` véritables triangles, `1,008` sommets source, `63` groupes d'objets et **6 primitives de matériaux glTF** avec `POSITION / NORMAL / TEXCOORD_0 / TANGENT`.
- Source `tools/generate_original_district_sidewall_shell.py`, `chaos_route_kit.mtl`. Registre `assets/source/roblox-asset-registry.json` mis à jour avec les preuves, sans MeshId inventé.

## Périmètre du remplacement réel

Une seule sculpture authentique et réutilisable couvre les cinq pièces géométriques **du bâtiment de quartier existant** :
1. `ServiceCore` : vrai noyau fermé biseauté, volume architectural central.
2. `ArmoredSupportL` et `ArmoredSupportR` : supports de grand format, colliers métalliques, pieds ancrés visuellement au sol.
3. `SideCassette-1` et `SideCassette1` : véritables parois métalliques latérales avec ventilations arrière, étanchéité et détails forgés.

**Jamais masqués :** `ServiceEntryDoor`, `ServiceEntryRecess`, `SideGlass±1`, `DataVaneL/R`, `RecessedSignal`, `BasaltFoundation`, `FoundationRim`, les avertissements et les géométries jouables. La porte native reste devant le volume 3D.

## Pipeline de production désormais intégré

- `PremiumDistrictSidewallAssets.start` : import *côté serveur uniquement*, asynchrone et décalé de 22 s pour protéger le démarrage. Il passe par le même `GlobalApprovedImportGate` (deux imports parallèles maximum), nettoie avec `OriginalMeshScenery.sanitize` puis exige **exactement six MeshParts** non physiques, le volume correct et la source propriétaire approuvée.
- `ApprovedDistrictSidewallMeshKit` : seul côté client, à partir de `ReplicatedStorage.ApprovedDistrictSidewallShellTemplates`. Vérifie l'ID, la propriété `OwnerVerified`, les six MeshParts, l'identité des 16 bâtiments, les cinq pièces natives originales, les matrices issues de la véritable porte, et les dimensions originales de l'arène.
- Le clone est **entièrement monté et validé avant** de masquer les cinq pièces natives. Les pièces originales restent ancrées et non-collisionnelles, intactes. Toutes les six pièces du modèle importé sont `Anchored / Massless`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false`.
- Le même passage `scenery-lod.client.lua` synchronise le modèle et expose deux compteurs lisibles : `LocalOriginalDistrictSidewallMeshCount` et `LocalOriginalDistrictSidewallPartsReplaced`. Les nouveaux modèles sont montés après les façades de toit déjà importées et avant la réconciliation globale des matériaux 2K.
- Retrait immédiat par callbacks si l'import source, le clone ou un MeshPart disparaît ; restauration des cinq pièces natives avant destruction. Si le modèle sort du champ, du quota, perd son approbation source ou si une manœuvre invalide les pièces serveur, le gameplay conserve le décor original.

## Budgets existants et priorité mobile

Les modèles vivent dans `ApprovedDistrictSidewallsLocal`, explicitement enregistré dans `VisualBudgetRules.LocalFolders` pour le **même** recensement Android de pièces locales. Les limites suivantes sont des plafonds, **pas des compteurs de rendu vérifiés en jeu** :

| Qualité | Desktop | Android | Sous pression |
| --- | ---: | ---: | --- |
| Low | 0 | 0 | Toujours zéro |
| Medium | 4 modèles | 3 modèles | Pression 1 : moitié ; 2 : zéro |
| High | 10 modèles | 8 modèles | Pression 1 : moitié ; 2 : zéro |

Six MeshParts par modèle : sur Android High, **48 MeshParts au maximum** supplémentaires, jamais 16×6 par défaut. Pas de nouvelle boucle `RenderStepped`, pas de client AssetService, pas de création de collisions, lumières ou remotes. Les quatre types de façades de toit préexistantes et leurs budgets sont conservés.

## Vérifications

L'intégration est couverte par l'extension du vérificateur existant `tools/verify_original_3d_budget_census.py` et ses GitHub Actions, sans créer de nouveaux tests unitaires. Les invariants contrôlés portent sur l'ID officiellement modéré, la source réelle, la sélection, la restitution native, les budgets et les positions.

**Ne pas prétendre** que la fusion `main` publie automatiquement dans le jeu : un Roblox Studio/Android visual QA et un déploiement séparé sont encore nécessaires avant annonce de la version publique. L'import externe officiel prouve l'approbation de l'asset, pas sa résidence effective dans la Place publique.

## Finition supplémentaire : véritables normal/roughness/metalness 2K

Le même maillage authentifié `ApprovedOriginalDistrictSidewall3D` (6 MeshParts) rejoint désormais le système partagé `PremiumNearfieldPbrKit`, **après** la sélection LOD du nouveau propriétaire `ApprovedDistrictSidewallMeshKit` et des autres sculptures de l'arène.

Seules les vraies surfaces structurelles statiques et visibles des groupes `ARMOR`, `BRUSHED`, `ALLOY` et `CERAMIC` peuvent recevoir une instance `SurfaceAppearance` provenant des **quatre modèles de matériaux PBR 2K déjà approuvés** (`BrushedTitanium`, `OxidizedSteel`, `DiamondArmor`, `ReactorCeramic` ; 16 Image IDs au total). `GRIP` et `CARBON`, ainsi que `SIGNAL` ou `GLASS` si rencontrés, ne sont jamais recolorés.

Les cinq variantes Classic/Towers/Crossroads/Orbital/Harbor partagent un plafond global inchangé de **2 modèles Medium/4 High sur Android**, 3/6 sur PC, réduit en cas de pression graphique, zéro en Low. **Ce n'est pas un quota additionnel** : une sculpture d'angle ou un monument prioritaire peut occuper une place à la place d'un mur latéral. Chaque overlay est réversible, et les matériaux d'import d'origine sont restaurés lorsque le modèle devient invisible ou non résident.

Contrat de source ajouté dans `tools/verify_premium_nearfield_pbr.py` et le workflow existant `original-nearfield-pbr-source.yml`. Mesures FPS/qualité visuelle Roblox Engine toujours requises.
