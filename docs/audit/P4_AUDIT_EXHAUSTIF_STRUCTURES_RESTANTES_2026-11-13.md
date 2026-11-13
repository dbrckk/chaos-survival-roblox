> **Ré-audit au code actuel `16b8a52` :** [audit P4 des vraies cibles visuelles restantes](P4_AUDIT_CIBLES_VISUELLES_3D_RESTANTES_2026-11-13.md) · [matrice chiffrée par variante et priorité](remaining-3d-priority-matrix-2026-11-13.csv). Le relevé historique ci-dessous recense les natives **avant les substitutions client** et certains paragraphes décrivent des commits antérieurs.

# Chaos Survival — audit exhaustif du parc de structures visuelles, 13 novembre 2026

## Conclusion et définition des nombres

**Dépôt :** `dbrckk/chaos-survival-roblox`, branche `main`, cinq variantes `Classic, Towers, Crossroads, Orbital, Harbor`.

**Preuve :** cinq cartes + lobby vraiment construits dans Roblox Open Cloud Engine par `MapBuilder.build(Config, variant, ArenaVariants, VisualTheme)`, classe de **chaque** descendant `BasePart` comptée puis répartie en groupes de propriétaires ; tous les groupes sont exportés dans **[structure-family-census-2026-11-13.csv](structure-family-census-2026-11-13.csv)**, soit **754 lignes de familles/variantes** et 9 colonnes quantitatives. Relevé moteur [43400304859](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43400304859), exécuté sur le commit `f099298ba3613c1baf42712bb76c1664f8c1bc36`. Cette exécution était volontairement diagnostique (résultats produits en sorties d'assertions) et n'est **pas** une preuve de test release vert ; le scénario a ensuite été converti en test moteur normal, avec nettoyage et contrôles de cohérence.

### Tableau intégral du nombre de primitives dans le monde serveur initial

| Variante avec lobby | BaseParts au total | Visibles | Visuelles natives non physiques | Dont taille maximale ≥ 12 studs | Dont taille maximale ≥ 30 studs | Éléments physiques visibles | MeshParts dans MapBuilder |
|:--|--:|--:|--:|--:|--:|--:|--:|
| Classic | 2 673 | 2 671 | 2 561 | 889 | 86 | 110 | 0 |
| Towers | 2 776 | 2 774 | 2 659 | 954 | 113 | 115 | 0 |
| Crossroads | 2 754 | 2 752 | 2 641 | 962 | 80 | 111 | 0 |
| Orbital | 2 916 | 2 914 | 2 778 | 992 | 71 | 136 | 0 |
| Harbor | 3 361 | 3 359 | 3 207 | 1 114 | 116 | 152 | 0 |
| **Somme des cinq relevés** | **14 480** | **14 470** | **13 846** | **4 911** | **466** | **624** | **0** |

**Attention :** le lobby est **le même**, reconstruit cinq fois ; il contient **103 BaseParts**, dont **102 visibles**, **87 visuelles non physiques**, **37 grandes** et **15 physiques visibles** dans chaque relevé. Après déduplication *du lobby uniquement*, le catalogue des cinq variantes **plus un seul lobby** contient **14 062 primitives visibles**, dont **13 498 visuelles non physiques** et **4 763 grandes (≥ 12 studs)**. Ce n'est **pas** la quantité simultanément visible : une seule arène existe à la fois. On ne peut pas additionner les cinq populations comme un instantané de performance.

**Définition :** « visuelle native non physique » = `Part`, `WedgePart`, `CornerWedgePart` ou `TrussPart`, avec `Transparency < 0.99`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`. « Grande » = `max(Size.X,Size.Y,Size.Z) >= 12` studs. Les tuyaux, vitres, signaux et bordures peuvent être comptés plusieurs pièces par monument : une pièce n'est pas un monument et une grande pièce n'est pas automatiquement un asset à remplacer.

### Ce que mesure réellement le 0 MeshPart

**Zéro MeshPart dans ces cinq cartes initiales n'est pas une absence de 3D approuvée.** `MapBuilder` fabrique volontairement les *natives de secours* ; les 3D authentiques sont importées par les chargeurs serveur puis clonées / activées par les kits clients en fonction de la caméra, du streaming, de `OptionalVfxPressure` et de Low/Medium/High. La présence d'un modèle disponible ne prouve pas son activation ni sa qualité PBR. Il serait **faux** de dire « 13 846 primitives restent définitivement sans remplacement ». Ces 13 846 constituent le **stock initial brut** que les remplacements conditionnels, les effets, l'accessibilité et le LOD peuvent ensuite modifier.

## Inventaire exhaustif du code et des sources 3D

Le script reproduisible **[tools/audit_visual_structure_sources.py](../../tools/audit_visual_structure_sources.py)** inspecte **tous les 488 fichiers Luau** sous `src/`, le registre des modèles, les modules clients et les noms d'owners GPU. Workflow et artifact JSON téléchargeable : [Actions 43401153095](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43401153095).

| Indicateur source | Mesure |
|:--|--:|
| Fichiers Luau analysés | 488 |
| Modèles créateur répertoriés et `Moderation: Approved` | **103 / 103** |
| Modules clients `*MeshKit.lua` / `*3DKit.lua` | 67 |
| Kits directement référencés par `scenery-lod.client.lua` | 57 |
| Kits contenant un ID d'asset du registre approuvé | 65 |
| Dossiers `*Local` inscrits dans `VisualBudgetRules.LocalFolders` | 122 |
| Dossiers visuels `*Local` effectivement détectés par le scanner | 119 |
| Kits 3D avec un contrôle potentiellement fragile `base.Size.X/Z < 318` après correction des ridges | **32** |
| Sites sources `Instance.new("Part")` | 118 |
| Sites sources `Instance.new("WedgePart")` | 17 |
| Sites sources `Instance.new("Model")` | 30 |

Les **118/17/30** sont des **emplacements de constructeur dans le code**, pas des nombres d'objets créés. Les 10 kits non directement liés à `scenery-lod` peuvent avoir d'autres propriétaires : ils ne sont pas automatiquement morts ou cassés. Les trois owners détectés hors budget typique sont examinés séparément : un dossier audio à ancres invisibles et deux pièces d'effets de ramassage temporaires ; ils n'ont pas été faussement classés comme sculptures 3D permanentes.

## Les grosses familles : exactement combien de volumes natifs ?

Les valeurs ci-dessous sont les sommes **des cinq définitions de cartes**. Elles sont disjointes pour ces familles, sans doubler les sous-modèles :

| Famille native initiale | Pièces visuelles non physiques | Dont grandes ≥ 12 studs | Priorité et risque |
|:--|--:|--:|:--|
| `PlatformBevel` — bordures et chanfreins | **2 080** | **1 148** | **P0** : très répétitif ; mutualiser les géométries cosmétiques sans changer le collider |
| `ArenaDistrictArchitecture` — 16 districts × 5 cartes | **2 248** | **440** | **P0** : blocs de façades encore nombreux ; plusieurs kits approuvés mais seulement partiellement résidents en Low |
| `PlatformSupport` — supports natifs de deck | **800** | **592** | **P0** : volumes larges très visibles ; conserver les vrais appuis physiques |
| `PlatformUnderFrame` — sous-cadres | **520** | **317** | **P0** : répétition côté/contre-plongée et coût de rendu |
| `PlatformPanel` — panneaux natifs | **520** | **149** | **P1** : regrouper ou sculpter par famille sans faire disparaître l'identité de plateforme |
| `PlatformGlow` — bandeaux néon | **520** | **289** | **Préserver comme signal**, optimiser émission/LOD plutôt que remplacer systématiquement |
| `ArenaCornerLandmarks` | **285** | **100** | **P1** : traiter géométrie et éclairage séparément |
| `OriginalExteriorRetrofits` | **276** | **48** | **P1** : contrôler les vraies coques 3D et leurs natives restantes |
| `StormHarborGantryFleet` (Harbor uniquement) | **207** | **80** | **P1** : quatre grues et navire, certaines familles 3D déjà éligibles, autres primitives toujours visibles |
| `HelixCircuit` (Orbital uniquement) | **132 cosmétiques**, 24 physiques | **73 cosmétiques** | **P1** : 24 colliders sont une obligation gameplay ; ne remplacer que l'habillage |
| `PremiumGroundModule` | **180** | **180** | **P1** : couverture/texture et répétition du sol |
| `ArenaSignatureMegastructure` (monument nord) | **80** | **43** | **P1** : finitions déjà originales pour certains morceaux, pas toute la masse |
| `SouthHorizonMonument` (monument sud) | **73** | **34** | Déjà **73 cibles-source éligibles**, résidence graphique à vérifier plutôt que recréer |
| `ArenaHeroArchitecture` | **124** | **33** | **P2** : modèles signatures et mouvement selon la variante |

Ces principaux groupes sont documentés individuellement dans le **CSV complet des 754 groupes**. Certains sont « habillages natifs encore présents » plutôt que « objets sans équivalent 3D » ; la colonne de droite ne constitue pas une certification de couverture visible en temps réel.

**Concentration :** bordures + supports + sous-cadres = **2 057 des 4 911 grandes primitives** de toutes les variantes (41,9 %). C'est le premier gisement de simplification et de détails AAA visibles ; le bénéfice n'est pas mesuré tant que FPS et draw calls ne le sont pas.

## Sous-ensemble à couverture 3D source directement vérifiable

Pour éviter de confondre une pièce native et une absence d'asset, cinq familles bien délimitées possèdent un inventaire de cibles disjointes. Il s'agit de la **capacité de remplacement source**, pas des MeshParts réellement montés en Low au même instant :

| Famille sur les 5 cartes | Cibles natives | Éligibles à une vraie substitution 3D approuvée | Restent natives dans cette famille |
|:--|--:|--:|--:|
| Stations périphériques, 4 × 23 par carte | 460 | **340** (17 par station) | 120, dont six éléments d'indication par station |
| Tours extérieures, 4 × 6 par carte | 120 | **80** corps de structure | 40 bandes de signal / antennes |
| Crêtes extérieures, 4 × 3 par carte | 60 | **60** wedges avec source approuvée | 0 en couverture source |
| Toitures de profondeur, 8 roofs + 8 antennes par carte | 80 | **40** toits | 40 antennes natives |
| Monuments de l'horizon sud | 73 | **73** sous LOD authentifié | 0 en couverture source |
| **Sous-ensemble de ces 5 familles, uniquement** | **793** | **593** | **200** |

Les **200 formes conservées natives** sont surtout des éléments de navigation/signalisation ; leur maintien n'est pas une erreur esthétique. Les **593 cibles éligibles** continuent à utiliser leurs natives lors des retours de pression, en cas de manque de source, de caméra éloignée ou de streaming. Le taux 593/793 **ne représente pas** la couverture globale de Chaos Survival.

## Volumes supplémentaires hors snapshot MapBuilder

`ArenaAtmosphere.server.lua` est un producteur **séparé** et n'a pas été exécuté par le test qui appelle `MapBuilder.build`. Son code définit de manière déterministe :

| Variante | Parts atmosphériques créées par le script, si activé | Lumières ajoutées |
|:--|--:|--:|
| Classic | 37 | 4 |
| Towers | 37 | 4 |
| Crossroads | 52 | 4 |
| Orbital | 45 | 5 |
| Harbor | 36 | 4 |

À cette architecture serveur s'ajoutent, de manière **non constante** : 3D client conditionnelle (67 kits), effets de catastrophes, bots et accessoires/avatar, lumières et débris, visuels d'entraînement, matériaux PBR, UI 2D, graphismes propres à chaque qualité, `StreamingEnabled` et pression GPU. Leur nombre **ne peut pas être donné comme un nombre unique universel** depuis une capture serveur à T0. Il faut un snapshot Roblox Studio **client** (5 variantes × 3 qualités × plusieurs positions × pression 0/1/2), avec `BasePart.Transparency`, `LocalTransparencyModifier`, `MeshId`, triangle count/source-ID et fenêtres temporelles après chargement. Aucun nombre de « structures restant définitivement à remplacer » ne sera inventé pour ces cas.

## Chantier visible livré durant cet audit

**Crêtes originales sur les cinq cartes :** `ApprovedExteriorRidgeMeshKit.lua` vérifie à présent la véritable `Base` et son empreinte initiale signée `OriginalSizeX/Z`, et place les trois wedges de chaque coin relativement à l'empreinte d'origine. Le rétrécissement réel du sol ne désactive plus automatiquement les **12 primitives source éligibles par arène**. Le kit conserve son choix **Low 1 / Medium 2 / High 4 modèles de sept MeshParts**, les limites caméra, la pression 1 sur Low qui restaure les natives et l'interdiction de collision. Le test moteur utilise une vraie `ExteriorRidgeNW` générée par `MapBuilder` et un modèle de source limité au fixture de test : rapprochement, shrink, repli GPU, refus d'expansion. **Aucun faux asset ni nouvelle physique n'a été déployé.**

## Chantier complémentaire : quatre tours extérieures par carte

Le kit `ApprovedExteriorTowerMeshKit.lua` était encore l'un des contrôles de taille `base.Size.X/Z < 318` fragiles. Il validait en outre le périmètre externe à partir de la taille **courante** du plancher. Désormais il utilise `OriginalSizeX/Z` pour la frontière signée et vérifie que la vraie base est ancrée, collidable, toujours enfant de l'arène et jamais agrandie au-delà de sa taille d'origine.

Cela préserve l'éligibilité des **quatre tours par variante**, soit **20 tours** sur les cinq définitions de carte, à leurs MeshParts approuvés pendant Shrinking Arena, sans changer la sélection par caméra, la limite Low **1 tour**, ni la restauration des quatre corps natifs par tour sous pression. Cela représente **80 corps natifs source éligibles** au total, mais **pas 80 MeshParts simultanément actifs**. La couverture visuelle réelle et les FPS Android nécessitent toujours des captures client.

Le recensement source CI contient une assertion explicite pour empêcher le retour du test de largeur live et de la frontière calculée sur une plateforme rétrécie.

## P0 — supports de 4,85 studs sur les premières routes Crossroads

**Constat vérifié dans les générateurs serveur :** `Crossroads` définit les plateformes physiques `Platform2/4/6/8` à une altitude de 7 studs avec 2 studs d'épaisseur. `MapBuilder` construit leurs supports entre le bas de la plateforme (Y=6) et la dalle de référence (Y=1,15), soit **4,85 studs**. Pour chacune des quatre plateformes 14×12 / 12×14, les quatre `PlatformSupportN_1..4` existent : **16 supports natifs distincts dans cette famille de Crossroads**.

L'ancien filtre `validNativeSupport()` exigeait `Size.Y >= 5`, ce qui rejetait systématiquement ces **16 supports** avant même le test d'échelle du véritable modèle original `93993697329658`. Le seuil a été ajusté à **4,75 studs** : le garde de *source approved*, exactement **sept MeshParts** sur Low sain, l'échelle `>= 0.34`, la largeur, la distance maximale caméra de 125 studs et le repli à pression >0 demeurent obligatoires.

**Capacité, pas résidence :** les 16 piliers deviennent candidats de remplacement par une sculpture 3D approuvée, mais **un seul module structurel à la fois** peut être présent sur Android Low sain dans ce kit (sept MeshParts) : soit un pilier, soit un long sous-cadre. Si les deux modèles approuvés sont disponibles, le kit utilise le classement caméra existant et privilégie le pilier lorsque son score de proximité est meilleur de plus de huit studs ; sinon le long treillis garde la priorité. Contrairement au comportement antérieur, un treillis à 100 studs ne monopolise plus la sculpture alors qu'un vrai pilier proche du joueur attend. Aucune augmentation de MeshParts, de quotas, d'import serveur ou de boucle de rendu. Les 800 supports du tableau initial restent **800 natifs serveur** pour garantir un retour aux formes natives, ce qui est intentionnel. Aucun collider de joueur, destination de saut, ni indicateur de danger n'a été modifié.

**Chargement des sous-cadres également corrigé :** `PremiumLargeStructureAssets.lua` charge le modèle de pilier approuvé pour la **vraie variante active**, puis le modèle créateur approuvé `LongCradle` (treillis d'environ 22 studs) **en deuxième**, et enfin les quatre autres variantes inactives. Le modèle de sous-cadre était auparavant **dernier** derrière les quatre autres, retardant son apparition et les reconstitutions après le chargement. La file globale reste unique et limitée à deux imports concurrents, avec exactement les six mêmes IDs modérés et tentatives que précédemment. Les remplacements 3D sont donc disponibles plus tôt, sans promettre de délai réseau ou de FPS non mesuré.

La régression `verify_platform_trim_mesh_ownership.py` contrôle les quatre configurations authentiques, leurs 4,85 studs, la limite de sept pièces et le retour natif. Une validation spécifique est intégrée dans `native-premium-fallback.spec.luau`, sur une vraie carte `MapBuilder.buildArena` avec source MeshPart de test locale aux proportions de l'asset modéré ; elle couvre les phases `Warning/Normal` et la disparition de la dernière pièce 3D.

## Plan d'élimination ordonné et conditions d'acceptation

1. **P0 :** fusionner / masquer de façon sûre les bordures `PlatformBevel`, les supports `PlatformSupport` et les sous-cadres `PlatformUnderFrame`, en réutilisant des géométries et kits originaux approuvés adaptés aux différents gabarits. Ne jamais supprimer un `CanCollide` de gameplay ni un indicateur de danger.
2. **P0 :** finir les enveloppes de district (coques, arêtes, bandeaux, toits) sur **16 bâtiments par variante**, privilégier l'apparition réelle en Low/Medium et le GPU p95 plutôt que des dizaines de MeshParts invisibles.
3. **P1 :** auditer les 32 modules 3D avec test strict de `base.Size < 318`. Corriger seulement les propriétaires de décor réellement statique ; conserver les gardes stricts sur les plateformes physiques en mouvement. Intégrer test Shrinking Arena sur les quatre arènes non Harbor.
4. **P1 :** optimiser Harbor (`StormHarborGantryFleet`) et Orbital (`HelixCircuit`) à partir de vrais modèles mesh non physiques. Sur Orbital, préserver obligatoirement les **24** colliders présents dans le circuit.
5. **P2 :** réduire les effets natifs répétitifs sans détériorer la lisibilité des risques ; terminer les finitions PBR avec vraies cartes de normal/roughness à densité adaptée aux appareils.
6. **Validation release :** les sept suites Engine et les contrôles d'import/repli doivent être verts, puis captures sur vrai client Android, FPS p50/p95, mémoire, temps de chargement des modèles et cohérence des visuels Low/Medium/High. Une publication Roblox demande une preuve de workflow de publication explicite.

**Statut vérifié au 13 novembre 2026 :** inventaire des 754 groupes et CSV archivés ; recensement source CI [43401153095](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43401153095) réussi ; Build Validation [43400848590](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43400848590) réussi ; **sept suites Roblox Engine réussies** sur le correctif des ridges et les tests de cohérence des cinq cartes ([43400918529](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43400918529), commit `47565a62d94b839d77e374f9acc3cba699797542`). Ces contrôles n'attestent ni des captures et FPS Android, ni d'une publication de la Place Roblox.


## Addendum — 13 novembre 2026 : 14 sculptures fixes supplémentaires corrigées

**Périmètre :** branche `main`, après le premier lot de six modules de structures fixes (voir [note précédente](../P4_FIXED_OUTBOARD_3D_SHRINK_RECOVERY_2026-11-13.md)). Les sept classes de monuments sud, les trois signatures principales nord (Classic, Towers, Crossroads), les ailes Classic et portiques Crossroads ont été rendus indépendants de la taille **actuelle** du sol lorsque leur sculpture et leurs parts natives sont en réalité fixes. L'anneau orbital de profondeur cinématique est aussi corrigé dans le client **et** dans `CinematicOrbitalHaloMeshRules.position`.

### Modifications vérifiables

- **6 modules nord :** `ApprovedClassicBroadcastFinMeshKit`, `ApprovedClassicForgedSupportsMeshKit`, `ApprovedClassicSignatureObservatoryMeshKit`, `ApprovedCrossroadsOpenGantryMeshKit`, `ApprovedCrossroadsSignatureInterchangeMeshKit`, `ApprovedTowersSignatureBridgeMeshKit`.
- **7 modules sud :** `ApprovedSouthClassicObservatoryMeshKit`, `ApprovedSouthCrossroadsExchangeMeshKit`, `ApprovedSouthOrbitalFinishingMeshKit`, `ApprovedSouthOrbitalObservationRingMeshKit`, `ApprovedSouthTowersFinishingMeshKit`, `ApprovedSouthTowersLiftTwinsMeshKit`, `ApprovedSouthTowersSkytransferMeshKit`.
- **Halo Orbital :** `ApprovedOrbitalHaloTrussMeshKit` et ses règles partagées ; le calcul du rayon utilise maintenant l'empreinte initiale `OriginalSizeX/Z` lorsque présente.

Tous les modules conservent les contrôles d'origine authentique, les sources réellement approuvées, les plafonds Low/Medium/High, les retours à la primitive native, le streaming et les colliders préexistants. Les positions des sculptures non physiques sont validées contre les coordonnées du constructeur, **pas contre la bordure du sol qui se contracte**. L'assertion de provenance et les abonnements de repli ont été adaptés. Le contrôle existant du portique Crossroads a été mis à jour pour vérifier l'empreinte originale sans le figer à l'ancienne taille live.

**Audit de régression, réussi sur le commit `3dce5ae26eaf7b361af3e7137384ef1f4238c2c7` :** [GitHub Actions — recensement complet](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43439409748). Il dénombre **5 kits visuels avec un garde restant sur la largeur live**, contre 19 au début de ce second lot. Les cinq sont des propriétaires de **sols et routes physiques** : `HarborDockCaissonMeshKit`, `HarborPromenadePortalMeshKit`, `PremiumGroundMeshKit`, `PremiumRouteMeshKit` et `SkySpineCrownMeshKit`. Leur restauration primitive pendant le shrink est conservée : retirer ce contrôle sans suivre les vraies plateformes mobiles afficherait de faux ponts et surfaces. Un travail futur d'adhérence géométrique, basé sur les vrais decks, est nécessaire pour les conserver en 3D au cours du shrink.

**Vérifications complémentaires réussies :** [les quatre suites source des monuments sud](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43438766149), [Crossroads sud](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43438766261), [Orbital sud](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43438766252), [Towers sud](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43438766181), et [portique Crossroads après correction du contrôle](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43438599890). Ces workflows ne prouvent pas la résidence finale des meshes ou des FPS sur Android.

**Non effectué :** suite Roblox Open Cloud Engine sur le HEAD final, essai Android réel et republication publique. La correction des garde-fous ne signifie pas que toutes les structures 2D/3D natives de la carte sont remplacées ; l'inventaire chiffré en haut du présent document conserve sa portée initiale.
