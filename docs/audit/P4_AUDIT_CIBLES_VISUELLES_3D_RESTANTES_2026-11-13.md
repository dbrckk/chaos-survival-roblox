> **Mise à jour :** [cinq assets Roblox approuvés et montage réel sécurisé sur des plateformes de 3/13,8/28,2 studs](../P4_FIVE_APPROVED_P0_ORIGINAL_STRUCTURES_2026-11-13.md). Les limites de résidence et les primitives profondément porteuses restées natives sont détaillées dans ce rapport.

> **Rectificatif après inspection des propriétaires et du registre de publication (13 novembre 2026).** Les cinq modèles `ascension_access_arch`, `ascension_transfer_arch`, `ascension_summit_arch`, `architectural_column_casing` et `orbital_helix_underframe` sont **déjà publiés et approuvés** dans `assets/source/roblox-asset-registry.json` (IDs réels 110243423264048, 107273631120961, 127049813505254, 130196548599769, 106863534763803). `src/client/ApprovedRemainingStructureMeshKit.lua` les monte déjà, sur la même boucle LOD, avec quotas Low/Medium/High et conservation des signaux, colliders et fallback. **La mention « source dédiée non identifiée » dans l'analyse historique ci-dessous est donc périmée.** Les vrais chantiers restants sont la **couverture partielle** : 5 pièces supérieures par arche sélectionnée (quille et poutres profondes conservées), 11 par casing sélectionné, 4 par rampe Helix sélectionnée. Plafonds normaux PC Low/Medium/High : arches **1/3/6**, casings **1/2/4**, Helix **0/2/6** ; plafonds tactiles encore plus faibles. L'existence de ces assets ne démontre pas une couverture 100 % en session.

> **Mesure désormais instrumentée :** `src/client/RemainingVisualNativeCensus.lua` observe toutes les **16 passes LOD** les véritables `Part/WedgePart/CornerWedgePart/TrussPart` natives non physiques encore présentes et non masquées localement, dans la carte active. Le recensement inclut façades, casings, arches, Helix, supports, bordures, sous-cadres, panneaux, finitions de sol, stations périphériques, monuments, skyline Harbor et passerelles. Les attributs `LocalP4VisibleNativeAscensionStructure`, `...AscensionSignal`, `...HelixStructure` et `...HelixSignal` séparent **les vrais volumes primitifs des signaux de navigation**. `LocalP4VisibleNativeAllScanned` donne le nombre de primitives natives visibles dans les deux dossiers parcourus, sans prétendre qu'elles méritent toutes un remplacement. Les comptes sont des **instantanés des objets streamés et non masqués**, ni des pixels rendus ni un FPS. Les vrais colliders sont exclus. Les arènes absentes sont signalées par `LocalP4NativeCensusReady=false`, et non traitées comme un zéro validé.

# Audit P4 — structures primitives encore candidates au remplacement 3D

**Date :** 13 novembre 2026 · **Dépôt :** `dbrckk/chaos-survival-roblox` · **Code actuel audité :** `16b8a52cc128e9130ba97a8a5e876d004c946b76` (branche `main`).

**Inventaires vérifiables :** [754 lignes du relevé moteur d'origine](structure-family-census-2026-11-13.csv), [25 groupes priorisés et cinq colonnes par arène](remaining-3d-priority-matrix-2026-11-13.csv), [audit historique et méthode](P4_AUDIT_EXHAUSTIF_STRUCTURES_RESTANTES_2026-11-13.md).

## Conclusion

Il n'existe **aucun nombre exact démontré de modèles « non remplacés actuellement à l'écran »** : le serveur conserve les primitives de repli ; les copies MeshPart réelles sont activées localement selon la caméra, le streaming, la carte, la qualité et la pression GPU. Il est incorrect de dire que les 13 846 natives initiales restent toutes visuellement primitives.

Les trois familles ci-dessous étaient des **lacunes au moment du recensement moteur historique**. Elles ont depuis reçu cinq modèles approuvés et un propriétaire de remplacement 3D LOD : leur *stock natif initial* reste utile pour quantifier la couverture non masquée, mais n'est plus un manque d'asset.
- **Monuments des routes d'ascension (`SkyRouteMonument`) : 904 natives initiales** dont 280 signaux. Les 624 autres sont des volumes/matériaux non signalétiques, mais toutes ne justifient pas un gros mesh. `src/server/SkyRouteMonuments.lua` dessine des pylônes, `MonumentalOverpass`, `TaperedFin`, `LoadBearingKeel`, `RecessedCentralGirder` en primitives non collidantes ; les modèles physiques des vrais decks appartiennent à d'autres systèmes.
- **Revêtements `OriginalPremiumColumnCladding` : 260 natives**, exactement 4 casings de 13 pièces par arène. `src/server/ArchitecturalCladding.lua` utilise notamment `FoundationFoot`, `ArmoredFrontShell`, `AngledArmorFin`, `DiagonalLoadSpar`, `MachinedUpperCollar`, `RecessedCrown` et la tête de navigation. Les cinq assets approuvés `column_classic/...` concernent `ArenaAtmosphere`, pas ces casings.
- **Circuit Orbital `HelixCircuit` : 132 natives non physiques**, dont 63 signaux, en plus des **24 éléments physiques** qui doivent rester autoritaires. Priorité aux `HelixUnderframe*` et `HelixSpineBrace*` ; préserver `HelixEdgeSignal*`, le suivi des rampes et les collisions.

Les familles **partiellement remplacées** les plus massives restent les 2 248 natives des districts, 2 080 bordures de decks, 800 supports, 520 sous-cadres, ainsi que Promenade/Sky Spine/Harbor. Plusieurs disposent déjà de sources 3D validées et **ne nécessitent pas** 1 asset différent par Part serveur.

## Chiffres vérifiés et limites

Le relevé de `MapBuilder` dans un vrai Roblox Engine (run [43400304859](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43400304859), SHA `f099298b`) contient **14 480 BaseParts**, dont **13 846 natives non physiques** et **4 911 natives non physiques de taille ≥12 studs**, sur cinq reconstructions avec le lobby répété. **Chaque variante n'est pas visible en même temps**. Après déduplication du lobby, ce catalogue contient **13 498** natives non physiques sur cinq arènes et un lobby unique. Le recensement moteur détaillé **n'a pas été recalculé sur le dernier SHA** ; les modules 3D et budgets ont évolué depuis.

| Arène | BaseParts initiaux | Natives visuelles non physiques | Grandes natives |
|---|--:|--:|--:|
| Classic | 2 673 | 2 561 | 889 |
| Towers | 2 776 | 2 659 | 954 |
| Crossroads | 2 754 | 2 641 | 962 |
| Orbital | 2 916 | 2 778 | 992 |
| Harbor | 3 361 | 3 207 | 1 114 |
| **Somme avec lobby x5** | **14 480** | **13 846** | **4 911** |

Le contrôle du **code actuel** recense **103 modèles originaux approuvés sur 103**, **67** modules MeshKit/3DKit, **57** reliés directement au LOD, **65** avec un ID connu et **489** fichiers Luau. **Zéro ancien garde de largeur globale 318** ne reste dans les kits vérifiés : c'est une correction de shrink, pas un taux de conversion 3D.

## Familles à traiter par ordre d'importance

Nombres = **pièces du générateur natif initial sur cinq cartes**, et non modèles réellement non masqués sur client. La colonne signal est un *sous-ensemble* qu'il faut traiter séparément.

| Famille | Natives source | Grandes ≥12 | Signaux | Priorité | Situation |
|---|--:|--:|--:|:--|:--|
| Bâtiments de district | 2 248 | 440 | 120 | P0 | PARTIEL SOURCE 3D |
| Bordures WedgePart | 2 080 | 1 148 | 0 | P0 | PARTIEL SOURCE 3D |
| Supports de decks | 800 | 592 | 0 | P0 | PARTIEL SOURCE 3D |
| Sous-cadres de decks | 520 | 317 | 0 | P0 | PARTIEL SOURCE 3D |
| Monuments des routes ascensionnelles | 904 | 140 | 280 | P0 | SOURCE DEDIEE NON IDENTIFIEE |
| Habillages de colonnes architecturales | 260 | 0 | 0 | P0 | SOURCE DEDIEE NON IDENTIFIEE |
| Panneaux supérieurs de decks | 520 | 149 | 0 | P1 | NATIF MATERIAU PBR |
| Promenade / portiques | 590 | 116 | 332 | P1 | PARTIEL SOURCE 3D |
| Sky Spine transversal | 392 | 334 | 162 | P1 | PARTIEL SOURCE 3D |
| Circuit orbital (hors colliders) | 132 | 73 | 63 | P1 | SOURCE DEDIEE NON IDENTIFIEE |
| Flotte grues / navire Harbor | 207 | 80 | 4 | P1 | PARTIEL SOURCE 3D |
| Monuments des 4 coins | 285 | 100 | 30 | P1 | PARTIEL SOURCE 3D |
| Rétrofits extérieurs | 276 | 48 | 20 | P1 | PARTIEL A VERIFIER |
| Structures skyline | 164 | 56 | 0 | P1 | PARTIEL SOURCE 3D |
| Modules de finition au sol | 180 | 180 | 0 | P1 | SOURCE 3D EXISTANTE |

### Répartition par arène des principaux chantiers

| Famille | Classic | Towers | Crossroads | Orbital | Harbor | Total |
|---|--:|--:|--:|--:|--:|--:|
| Bâtiments de district | 440 | 456 | 456 | 456 | 440 | 2248 |
| Bordures WedgePart | 376 | 396 | 380 | 384 | 544 | 2080 |
| Supports de decks | 128 | 136 | 152 | 140 | 244 | 800 |
| Sous-cadres de decks | 94 | 99 | 95 | 96 | 136 | 520 |
| Monuments des routes ascensionnelles | 176 | 176 | 176 | 188 | 188 | 904 |
| Habillages de colonnes architecturales | 52 | 52 | 52 | 52 | 52 | 260 |
| Panneaux supérieurs de decks | 94 | 99 | 95 | 96 | 136 | 520 |
| Promenade / portiques | 118 | 118 | 118 | 118 | 118 | 590 |
| Sky Spine transversal | 78 | 78 | 78 | 78 | 80 | 392 |
| Circuit orbital (hors colliders) | 0 | 0 | 0 | 132 | 0 | 132 |
| Flotte grues / navire Harbor | 0 | 0 | 0 | 0 | 207 | 207 |

**Harbor**, avec 3 207 natives non physiques, est la variante la plus dense. **Orbital** ajoute les rampes physiques et décoratives de `HelixCircuit` ; ces pièces doivent être traitées comme un ensemble asservi au même vrai deck. **Towers** exige la priorité au contraste des passerelles hautes. Les cartes Classic/Crossroads sont concernées par les mêmes monuments de route et casings.

## Ce qui possède déjà un modèle 3D et ne doit pas être recréé à l'aveugle

1. **Bordures + supports + sous-cadres :** la famille `PlatformBevel` comporte 4 wedges par `PlatformN` et peut bénéficier d'une carapace originale approuvée qui masque 4 wedges + un sous-cadre, **Low 1 / Medium 8 / High 16 decks maximum sur la carte active**, si la source, les limites caméra et l'état du deck le permettent. Cela couvre au maximum 4 / 32 / 64 bordures dans le budget propre à ce kit sur une arène, bien moins que le stock natif d'origine. Les colonnes de support 3D ont des plafonds de **1 / 8 / 16 modules source** ; les hauts piliers peuvent consommer plusieurs modules. Le vrai gain est la meilleure distribution spatiale des modèles admis, pas un relèvement aveugle de GPU Android.
2. **Districts :** 16 bâtiments par arène et 2 248 natives cumulées. Sur le dernier code, High PC sain peut allouer **16 façades sculptées** et **12 coques latérales** ; Android tactile High est plafonné à **8/8**, Medium à 3 façades et 3 coques en tactile, Low à 1/1 sans pression. Les murs/socles/guidages non couverts ne deviennent pas automatiquement de vrais MeshParts.
3. **Promenade / Sky Spine :** respectivement **590** et **392** natives initiales, dont **332** et **162** signaux. Harbor dispose de modèles cargo, Sky Spine de couronnes et LongCradle, mais seulement sur les propriétaires sélectionnés. Les autres architectures, bandes d'accès et sous-structures demandent un audit client par classe d'objet.
4. **Harbor :** `StormHarborGantryFleet` = **207** natives initiales pour 4 grues et le navire. `HarborFreighterMeshKit` et `HarborGantryKineticMeshKit` possèdent déjà des sources approuvées, mais leur visibilité reste bornée par les LOD. Il faut déterminer la silhouette effectivement visible avant de refaire ces modèles.
5. **Monuments de coins et extérieurs :** **285** et **276** natives initiales. Les vraies sources approuvées masquent les silhouettes redondantes ; les socles, pointes, antennes et indications restent souvent volontairement natifs.
6. **Sol / stations / profondeur :** les 180 modules de sol ont déjà une source originale (résidences normales Low 2, Medium 16, High 36 par carte). Les stations ont **17/23 pièces éligibles** à la source 3D, soit **340/460** du catalogue, les 120 autres étant des éléments conservés. Horizon sud **73/73**, crêtes **60/60** éligibles ; SkylineDepth **40/80** (toits, avec 40 antennes natives).

### Ce qu'il faut préserver ou transformer en finition plutôt qu'en gros mesh

`PlatformGlow` **520** et `PlatformCoreGlow` **520** sont des signaux natifs initialement visibles, essentiels à la navigation et aux catastrophes. De même, beaucoup des 280 signaux `SkyRouteMonument` et des 332 signaux `Promenade` doivent rester contrastés. Les **520** `PlatformPanel` sont des plaques fines de matériau et d'orientation, déjà traitées par le système PBR : poser une grosse sculpture dessus pourrait créer un faux sol ou effacer les alertes. La cible est une finition de meilleure qualité, pas une disparition systématique.

## Ordre d'exécution recommandé

**P0 — lot 1, sculptures d'ascension :** créer/valider un original 3D par gabarit `ACCESS / TRANSFER / SUMMIT` avec cinq matériaux d'arène et remplacement uniquement des pylônes, portiques, poutres et coques dont l'empreinte est authentifiée. Conserver les vraies flèches, balises, signaux et le repli natif sous `CollapsePhase`, shrink et streaming.

**P0 — lot 2, casings :** rehausser les **20 casings / 260 primitives** des colonnes centrales, sans modifier leur collision ni leur repère de navigation. Réutiliser des assets approuvés uniquement s'ils ont réellement les bonnes dimensions ; sinon produire de nouvelles sources créateur, les faire approuver, puis les monter avec LOD.

**P0 — lot 3, couverture proche :** mesurer la résidence réelle des carapaces, supports et sous-cadres dans les cinq arènes. Les attributs existants `LocalBevelNativePartsReplaced`, `LocalSupportNativePartsReplaced` et `LocalUnderframeNativePartsReplaced` fournissent des comptages **des natives réellement masquées** sur le client ; agréger sans additionner cinq cartes comme une session unique.

**P1 — Orbital/Harbor et passerelles :** vraies structures techniques sous rampes, arches et grues ; préserver l'état des vrais decks, les 24 collisions Orbital et les signaux.

**P1/P2 — finitions :** vérification des façades/volumes restants, panneaux PBR, ambiance/lumière, relief, compression des détails répétitifs et cohérence des cinq matériaux d'arène.

### Critères d'acceptation non négociables

Un remplacement n'est terminé que lorsque : **asset original réellement approuvé**, colliders inchangés, masquage seulement des natives effectivement couvertes, restauration immédiate si source/mesh/weld manque ou lors de danger, qualité Low/Medium/High cohérente, quotas Android de **440 / 680 / 900 Parts locaux**, Build Validation + sept suites Roblox Engine réussies, et **captures d'un vrai client Studio/Android** (caméra proche/loin, pression 0/1/2, cinq variantes). Les fps p50/p95 et le nombre exact de silhouettes encore perçues **ne sont pas mesurés dans cet audit**.

## Preuves actuelles

- [Audit sources / 103 assets / 489 Luau / 0 ancien garde global : réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43460240975)
- [Budget Android et origine 3D : réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43460241005)
- [Build Validation : réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43460240862)
- [Sept suites Roblox Open Cloud Engine : réussi sur `16b8a52`](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43460377189)

**Cette intervention constitue un audit et un plan priorisé ; aucune nouvelle sculpture, mesure FPS Android ou republication Roblox n'est revendiquée.**
