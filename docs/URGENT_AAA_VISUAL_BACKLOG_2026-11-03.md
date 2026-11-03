# CHAOS SURVIVAL — INVENTAIRE URGENT DES VISUELS NON CERTIFIÉS PREMIUM

**Inventaire initial contrôlé le 3 novembre 2026 — main `49329942899ff0e9895d6756e40b08690582dcca` ; statut de livraison actualisé au SHA `38f1a3b184b85848a479cfe8bd9d4a49a6b06540`**. Dépôt : `dbrckk/chaos-survival-roblox`. Ce document est un **registre d'actions** couvrant l'intégralité des familles d'éléments visuels auditées, pas une déclaration qu'aucun travail n'existe déjà.

**Publication publique dernière confirmée :** SHA `38f1a3b184b85848a479cfe8bd9d4a49a6b06540`, [Build Validation #41621176592](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41621176592), [Roblox Cloud (cinq suites) #41621187036](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41621187036), [publication #41621772081](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41621772081). **Historique résolu :** échec antérieur de `addFoundation` (4 éléments attendus, 11 produits) dans [#41606219369](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41606219369). L'exécution moteur ultérieure est verte. **Les captures et mesures physiques Android ne sont toujours pas certifiées.**

### Méthode de preuve
- **[C]** Écart **confirmé dans le code ou la validation** (présence d'une primitive/source générique, asset de secours ou test bloqué). Ce n'est pas automatiquement un défaut perceptible sur chaque appareil.
- **[V]** **À évaluer visuellement** : pipeline présent, mais rendu final, stabilité, haute qualité ou accessibilité non certifiés par captures Android/Studio actuelles. Ne pas déclarer « cassé » sans preuve.
- **P0** = bloque publication, objectif perceptif ou lisibilité/danger ; **P1** = transformation visible significative ; **P2** = polish final.
- Tous les changements de mesh restent sûrs pour les collisions, l'IA, les routes, la caméra et le shrink. Réutiliser autant que possible le registre de six modèles 3D originaux approuvés et seize textures PBR approuvées ; ne pas inventer de Roblox AssetId. Les évaluations se font par lot complet, pas des micro-versions.

### Ordre impératif de production
**1.** Débloquer le test moteur du candidat et confirmer version publique → **2.** Captures et mesures Android qui ciblent les défauts réels → **3.** Sols/plateformes/passerelles/architecture proche caméra en meshes + UV → **4.** Matériaux PBR, signalétique et 2D UI originaux → **5.** Lighting + onze catastrophes → **6.** animations bots/joueurs → **7.** optimisation, finition, validation visuelle exhaustive et release.

## 0. Bloquants de livraison et preuves de qualité

- [x] **VIS-001 · P0 · C · RÉSOLU** — Discordance historique `OriginalMeshScenery.addFoundation` (11 éléments au lieu de 4) corrigée et revalidée : cinq suites moteur réussies au SHA `38f1a3b`, puis publication publique confirmée. Cette preuve de test ne remplace pas le contrôle visuel Android.
- [ ] **VIS-002 · P0 · V** — Obtenir des captures réelles du **lobby + cinq arènes** sur les niveaux graphiques Low, Medium, High, en vue de proximité, moyenne et panoramique. Le code et les tests moteur ne prouvent ni la forme, ni les ombres, ni les textures finales.
- [ ] **VIS-003 · P0 · V** — Obtenir le lot de **75 captures Studio authentiques (15 par arène)** au moyen du workflow de QA déjà présent, sans falsifier de capture ni lancer un Windows éphémère sans opérateur authentifié.
- [ ] **VIS-004 · P0 · V** — Comparer les mêmes séquences sur **un vrai téléphone Android** : luminosité, lisibilité des bots, efficacité des matériaux, température, FPS, mémoire et pires saccades. Un runner Cloud n'est pas un benchmark mobile.
- [ ] **VIS-005 · P0 · C** — Rapprocher le vrai SHA public, le SHA main et les preuves de publication. Le `README.md` contient encore des énoncés de source « non live » devenus anciens ; ne jamais annoncer la dernière refonte des socles comme publiée.
- [ ] **VIS-006 · P0 · V** — Mesurer le temps de chargement, les artefacts de streaming et la visibilité effective des **six modèles 3D Roblox approuvés**. Le registre de modèles indique encore `models_inserted_in_game=false` et `android_visual_qa_completed=false` : confronter ces métadonnées au runtime.
- [ ] **VIS-007 · P0 · V** — Contrôler les cinq arènes en phases lobby/READY/round/result et pendant un effondrement : aucun décor « premium » ne doit imiter une passerelle sûre, occulter un danger ou bloquer un bot.

## 1. Environnements, formes et assets 3D de gameplay

- [ ] **VIS-008 · P0 · C** — Remplacer l'apparence de la **dalle de sol carrée de 320 studs**, aujourd'hui BasePart native sous habillage modulaire, par une véritable stratification visuelle de terrain industriel et zones spécifiques, compatible avec le shrinking et les avertissements. `src/server/MapBuilder.lua`, `ArenaGroundArchitecture.lua`.
- [ ] **VIS-009 · P0 · C** — Remplacer les **plateformes de saut, paliers et lèvres génériques** par des familles de MeshPart originales optimisées, profils latéraux, fixations et dessous lisibles ; conserver les collisions officielles invisibles. `MapBuilder.lua`, `PlatformFinishKit.lua`.
- [ ] **VIS-010 · P0 · C** — Donner aux **ponts, passerelles, skybridges et jonctions Sky Spine** de vraies sections de structure (poutres, suspentes, garde-corps crédibles), plutôt que l'empilement de `Part`/`WedgePart`. `PromenadeArchitecture.lua`, `SkySpineArchitecture.lua`, `SkyRouteMonuments.lua`.
- [ ] **VIS-011 · P0 · C · EN COURS** — Faire évoluer les **16 bâtiments de districts et leurs façades** vers un kit de meshes modulaires cohérent : volume, entrée, toit, infrastructure, pièces industrielles et détails non répétitifs. **Lot source ajouté :** portails MeshPart réels, créateur-approuvés, réutilisant le Model `137284215564363` sur les entrées proches avec quota Android 1/2/4 ; géométrie de façade/étages/toits toujours en grande partie native et captures Android non certifiées. `ArenaDistrictArchitecture.lua`, `DistrictFacadeDetailKit.lua`, `DistrictGatewayMeshKit.lua`, `OriginalMeshScenery.lua`.
- [ ] **VIS-012 · P0 · C** — Remplacer les **éléments visuellement primitifs du lobby**, même après les derniers carénages : scène centrale, portique, pylônes, sols, bornes et supports. `MapBuilder.lua`, `StructureRetrofit.lua`, `lobby-surface-detail.client.lua`.
- [ ] **VIS-013 · P1 · C** — Reconcevoir les **quatre colonnes d'angle** et leur bardage en véritables modules sculptés UV/PBR ; la nouvelle structure `ArchitecturalCladding.lua` est encore assemblée à partir de primitives Roblox.
- [ ] **VIS-014 · P1 · C** — Refaire les **repères d'arène, mât radar Classic, antennes et consoles** avec des assets mécaniques détaillés, pas de silhouettes rectangulaires seulement. `MapBuilder.lua`, `ArenaSignatureKit.lua`.
- [ ] **VIS-015 · P1 · C** — Terminer les **tours, cabines, contrepoids, rails verticaux et ascenseurs Towers**, avec mécanismes cohérents et joints visibles. `MapBuilder.lua`, `tower-skyrail.client.lua`, `arena-hero-motion.client.lua`.
- [ ] **VIS-016 · P1 · C** — Terminer les **grands portiques Crossroads**, jonctions, panneaux et équipements de circulation. Les récentes brides et cales 3D restent des pièces natives ; viser meshes/UV et proportions contrôlées. `StructureRetrofit.lua`, `CrossroadsSwitchyard.lua`.
- [ ] **VIS-017 · P1 · C** — Refaire les **anneaux, gyroscopes, noyaux, hélices et dispositifs Orbital** en vraie mécanique sci-fi modulaire, sans sphère/cylindre standard apparent. `MapBuilder.lua`, `OrbitalHelix.lua`, `arena-hero-motion.client.lua`.
- [ ] **VIS-018 · P1 · C** — Finaliser **Harbor : grues, navire, docks, treuils, bollards, conteneurs, mâts, barrières** et transition mer/structure avec assets 3D optimisés. `HarborScenery.lua`, `HarborOutpostKit.lua`.
- [ ] **VIS-019 · P1 · C** — Transformer les **structures d'horizon lointaines** encore natives (skyline de `MapBuilder.lua`) en silhouettes manufacturées cohérentes, avec LOD plutôt qu'une multiplication de petits blocs.
- [ ] **VIS-020 · P1 · C** — Réduire la répétition des **six familles de vrais meshes importés**, réutilisées en huit emplacements par carte ; composer davantage de silhouettes réellement différentes, sans importer d'assets non approuvés. `OriginalMeshScenery.lua`.
- [ ] **VIS-021 · P1 · C** — Rendre les **socles et châssis importés** visuellement adaptés à chaque modèle (acier, équipement, ancrages, joints), plutôt qu'une base carrée décorée par sept petites pièces natives. `OriginalMeshScenery.addFoundation`.
- [ ] **VIS-022 · P1 · C** — Remplacer les **vaisseaux, cargos et véhicules aériens procéduraux** en Parts/Wedges par des coques MeshPart de formes crédibles, détails mécaniques et LOD. `ArenaSkyFleetKit.lua`.
- [ ] **VIS-023 · P1 · C** — Finaliser les **grandes architectures de skyline/hero props** des cinq cartes avec un objet iconique par carte, lisible sans néon. `HeroArchitecture.lua`, `arena-architectural-details.client.lua`.
- [ ] **VIS-024 · P1 · C** — Améliorer les **services périphériques : rampes, marches, portes, consoles, trappes et accès techniques**, avec épaisseur, fixations, panneaux et proportions humaines. `ArenaDetailKit.lua`, `arena-service-props.client.lua`.
- [ ] **VIS-025 · P1 · V** — Vérifier que les **finitions latérales et sous-faces des plateformes** suivent rotation, taille, fermeture et destruction ; éliminer intersections et flottement pendant le shrink. `ArenaFloorFollowerKit.lua`, `ShrinkingArena.lua`.
- [ ] **VIS-026 · P1 · C** — Remplacer les **objets d'ambiance génériques** et modules de surface à base de simples Parts par un petit catalogue art-dirigé réutilisable avec variation maîtrisée. `arena-ambient-props.client.lua`, `arena-surface-relief.client.lua`.
- [ ] **VIS-027 · P1 · C** — Créer de vraies **transitions volumétriques sol–bâtiment, structure–ciel, bord–vide, pont–ancrage** avec habillage de jointure, pas une simple superposition de cubes et glow.
- [ ] **VIS-028 · P1 · V** — Vérifier la **densité artistique des 320 studs** : lieux intéressants et parcours visibles sans créer une plaine vide, encombrer le terrain ou diminuer les options de navigation des bots.

## 2. Textures, UV, PBR et matériaux

- [ ] **VIS-029 · P0 · C** — Réduire les surfaces exposées en **matériaux natifs génériques** (`Slate`, `Metal`, `DiamondPlate`, `Neon`, `Foil`, `CorrodedMetal`) ; les déplacer vers des presets UV/PBR appropriés sans remplacer les matériaux de danger/collision. `VisualTheme.lua`, nombreux constructeurs.
- [ ] **VIS-030 · P0 · V** — Vérifier sur appareil que les **16 images PBR approuvées / quatre familles** (albedo/couleur, normal, roughness, metallic) sont réellement affichées sur les bonnes surfaces, et non uniquement référencées par le code. `pbr-district-materials.client.lua`.
- [ ] **VIS-031 · P0 · V** — Vérifier les **textures du premier plan** (sols, panneaux, atterrissages) en Low/Medium/High ; le budget global Android et la priorisation PBR peuvent encore laisser des régions entières en fallback natif. `PbrDistrictRules.lua`.
- [ ] **VIS-032 · P1 · C** — Créer des **UV continus, échelles texel cohérentes, normal baking et textures propres par famille 3D** ; un Assemblage WedgePart ne remplace pas un mesh UV-authored.
- [ ] **VIS-033 · P1 · C** — Développer les **familles PBR de surface encore peu différenciées** : peinture industrielle, béton stratifié, revêtement antidérapant, métal traité, acier marin, céramique sci-fi, isolants de câbles, vitres.
- [ ] **VIS-034 · P1 · V** — Équilibrer la **rugosité et la métallicité** : éviter aluminium miroir partout, surfaces mates sans relief et matériaux trop brillants sur Android.
- [ ] **VIS-035 · P1 · V** — Examiner la **qualité des normales aux angles, coutures et raccords**, et l'absence de répétition évidente sur les grandes dalles.
- [ ] **VIS-036 · P1 · C** — Ajouter des **variations de finition localisées et motivées** : salissures, abrasion aux contacts, éclats de peinture, corrosion marine, dépôts, traces de maintenance, sans bruit aléatoire uniforme.
- [ ] **VIS-037 · P1 · C** — Finaliser les **textures propres aux cinq arènes** : tonalité/matières doivent différencier Classic, Towers, Crossroads, Orbital et Harbor sans recolorer simplement le même panneau.
- [ ] **VIS-038 · P1 · C** — Créer la **signalétique originale haute résolution** : numérotation de portes, pictogrammes industriels, codes de secteur, symboles de danger et indications d'accès (normal/émissif si pertinent).
- [ ] **VIS-039 · P1 · V** — Vérifier et protéger les **surfaces UV / SurfaceAppearance des meshes importés** contre toute substitution PBR client non autorisée. `OriginalMeshScenery.lua`, `PbrDistrictRules.lua`.
- [ ] **VIS-040 · P1 · V** — Supprimer scintillement, **z-fighting**, banding d'alpha et décals superposés sur les modules très fins, particulièrement lors du shrink et aux transitions.
- [ ] **VIS-041 · P2 · V** — Vérifier la **modération, propriété et fraîcheur** des IDs Roblox PBR avant chaque gros lot ; conserver le fallback même si un asset devient indisponible.

## 3. Lumière, ciel, météo et post-traitement

- [ ] **VIS-042 · P0 · V** — Éliminer tout rendu **trop sombre** pour les personnages, sols, paliers et bords. Tester tous les cinq grades lumineux dans une vraie manche Android ; l'utilisateur a déjà signalé des silhouettes presque noires.
- [ ] **VIS-043 · P0 · V** — Établir une **hiérarchie key/fill/rim** lisible : éclairer les volumes réels et les bots sans noyer les avertissements ; une hausse globale de `Brightness` ne suffit pas. `arena-lighting.client.lua`.
- [ ] **VIS-044 · P0 · V** — Tester l'**enchaînement normal→READY→catastrophe→résultat** : pas de saut d'exposition, de lumière incohérente ou de catastrophe qui écrase les volumes importants.
- [ ] **VIS-045 · P0 · V** — Vérifier que le **désastre Darkness** conserve son intention de gameplay sans rendre les commandes ou avertissements essentiels illisibles ; ne pas le neutraliser par une lumière artificielle excessive.
- [ ] **VIS-046 · P1 · C** — Créer une vraie **direction de soleil, orientation de reflets et ambiances par carte** plutôt qu'un simple tableau de teintes/ClockTime/GlobalShadows. `arena-lighting.client.lua`, `ArenaFocalLightingRules.lua`.
- [ ] **VIS-047 · P1 · V** — Recalibrer **ombres proches et longues, AO perçue, biais d'ombre, contact au sol et douceur** sur structures et personnages ; vérifier également le mode Low sans ombres dynamiques.
- [ ] **VIS-048 · P1 · V** — Donner des **points lumineux motivés** aux portiques, ponts, consoles et équipements ; vérifier direction, portée et coût des SpotLights/PointLights existants.
- [ ] **VIS-049 · P1 · V** — Évaluer le **bloom**, halos et seuils pour éviter que les néons éblouissent, masquent les panneaux ou rendent le métal plastique. `ArenaPostProcessLayer.lua`, `arena-lighting.client.lua`.
- [ ] **VIS-050 · P1 · V** — Vérifier la **profondeur de champ** : aucun flou de plateforme, d'ennemi, de warning ou de UI en phase action.
- [ ] **VIS-051 · P1 · V** — Recaler **SunRays, glare, color correction et saturation** pour une image maîtrisée ; protéger les signaux d'urgence.
- [ ] **VIS-052 · P1 · V** — Terminer l'**atmosphère volumétrique perçue** : contraste proche/moyen/loin, densité de haze, couleurs du ciel et disparition graduelle du décor. `CloudLayer.lua`, `environment-depth.client.lua`.
- [ ] **VIS-053 · P1 · V** — Finaliser les **nuages, couches de ciel, vent et visibilité** selon l'arène sans créer un voile permanent qui cache les modèles 3D.
- [ ] **VIS-054 · P1 · V** — Tester **pluie, brouillard, givrage, tempête, lave, météo sombre** : lumière motivée par la scène et cohérence des effets avec les lumières d'origine.
- [ ] **VIS-055 · P1 · V** — Recalibrer les **matériaux métalliques au specular** et aux changements de vue pour que l'augmentation du PBR n'introduise pas de reflets excessifs.
- [ ] **VIS-056 · P1 · V** — Vérifier les **sources lumineuses animées** (balises, moteurs, arcs, éclairs) : pas de clignotement agressif ni déphasage avec l'animation du prop.
- [ ] **VIS-057 · P1 · V** — Rendre les **cinq arènes identifiables par l'éclairage**, tout en gardant une courbe de luminance similaire pour l'équité entre cartes.
- [ ] **VIS-058 · P2 · V** — Créer un **jeu de profils lumière accessibles/Reduced Motion/Low** avec effet visuel prévisible et sans conflit entre contrôleurs `Lighting` et effets de catastrophe.

## 4. Catastrophes, VFX et réaction du monde

- [ ] **VIS-059 · P0 · C** — Remplacer l'aspect de **lave comme grande Part Neon orange** par un rendu de surface de matière en mouvement, crêtes, bulles et reflets, tout en conservant le plan de contact serveur. `Disasters/RisingLava.lua`.
- [ ] **VIS-060 · P0 · C** — Remplacer le **météore serveur Part sphérique Basalt** et ses facettes WedgePart par un cœur fracturé original, traînée et impact crédibles, avec LOD et avertissement inchangé. `Disasters/Meteors.lua`, `MeteorCoreSculptKit.lua`.
- [ ] **VIS-061 · P0 · V** — Distinguer chaque catastrophe par **forme/silhouette et préavis**, indépendamment de sa couleur ; le spectacle ne doit jamais masquer la zone à éviter. `hazard-warning-visuals.client.lua`.
- [ ] **VIS-062 · P1 · C** — Finaliser la **tornade** : volume tourbillonnant, débris variés, mouvement de rotation et poussière ; les segments/bords sont toujours composés de Parts/Wedges. `tornado-visuals.client.lua`.
- [ ] **VIS-063 · P1 · V** — Finaliser **Freeze** : progression de la glace, fragmentation, matériaux givrés, buée, feedback de sortie sans confondre les zones dangereuses. `FrozenArmorKit.lua`, `Disasters/Freeze.lua`.
- [ ] **VIS-064 · P1 · V** — Refaire la chaîne visuelle des **bombes** : charge, anticipation, détonation, ondes secondaires, marques au sol et décroissance. `BombChargeKit.lua`, `Disasters/Bombs.lua`.
- [ ] **VIS-065 · P1 · V** — Améliorer **Disappearing Platforms** : fissures/avertissement, état instable, disparition, débris, retour éventuel, synchronisation parfaite avec collision serveur.
- [ ] **VIS-066 · P1 · V** — Créer une grammaire visuelle originale pour **JumpShock**, impact au sol, onde verticale et réception sans saturer la caméra.
- [ ] **VIS-067 · P1 · V** — Finaliser la **gravité faible** : flottement, particules physiques suggérées, réponses des vêtements/caméra et lecture claire des trajectoires.
- [ ] **VIS-068 · P1 · V** — Différencier **SpeedSurge** des effets de vitesse classiques : vent, direction, traînées sobres et surbrillance informative.
- [ ] **VIS-069 · P1 · V** — Rendre visuellement riche le **Shrink/effondrement** : bords qui rompent, supports qui cèdent, poussière et pièces qui tombent, sans faux sol restant visible.
- [ ] **VIS-070 · P1 · V** — Terminer les **effets d'impacts et résidus** : cratères, fissures, suie, éclats, brûlures et refroidissement par catastrophe. `ImpactSurfaceScarKit.lua`, `disaster-residue.client.lua`.
- [ ] **VIS-071 · P1 · V** — Composer les séquences **Double Chaos / climax** : pas de collision entre télégraphies, explosion de bloom ou saturation des particules. `disaster-climax.client.lua`.
- [ ] **VIS-072 · P1 · V** — Créer une vraie **réaction de l'environnement** à la catastrophe : machines ébranlées, signaux, lumières et éléments cassables cosmétiques, sans modifier la logique de dégâts.
- [ ] **VIS-073 · P2 · V** — Revoir **particules, fumée, étincelles, poussière, onde et brouillard** en Low/Medium/High, avec formes, tailles et émissivité variées, et vérifier le nettoyage après 30 min.

## 5. Survivants, bots, avatars et animations

- [ ] **VIS-074 · P0 · C** — Remplacer les cinq **animations R15 Roblox de secours** (`Idle`, `Walk`, `Run`, `Jump`, `Fall`) utilisées par les survivants IA par des clips originaux autorisés, enregistrés et adaptés aux déplacements réels. `src/shared/AnimationCatalog.lua`.
- [ ] **VIS-075 · P0 · V** — Filmer les **bots sur les vrais parcours** : pied qui glisse, saut sans anticipation, rotation brutale, oscillation, avatar coincé ou téléportation apparente ; corriger la présentation et les routes si nécessaire.
- [ ] **VIS-076 · P1 · V** — Finaliser les **transitions idle→marche→sprint→saut→atterrissage→chute→mort** sans pose cassée, latence visuelle ou animation artificielle.
- [ ] **VIS-077 · P1 · V** — Améliorer **virages, freinage, recul et strafe** : inclinaison adaptée au vecteur réel, pieds orientés et vitesse de cycle cohérente. `bot-motion-polish.client.lua`.
- [ ] **VIS-078 · P1 · V** — Ajouter des **animations de réaction** convaincantes aux impacts, évitements, explosions, faible gravité et sol gelé. `CharacterReactionVisuals.lua`.
- [ ] **VIS-079 · P1 · V** — Créer un **feedback visuel distinct des survivants humains et IA** sans trahir les bots par des mouvements répétitifs ou des noms/poses stéréotypés.
- [ ] **VIS-080 · P1 · V** — Améliorer les **cosmétiques équipables, effets de traînée et silhouettes d'avatar** : lisibles de loin, matériaux compatibles, pas de surbrillance cachant les hitboxes.
- [ ] **VIS-081 · P1 · V** — Vérifier la qualité du **ragdoll/mort/élimination**, l'arrivée au spawn, le retour lobby et le passage spectateur (pas de pop ni de personnage figé).
- [ ] **VIS-082 · P1 · V** — Finaliser les **performers/Showtime/hologrammes** du lobby : rig, silhouettes et animations non mécaniques ni désynchronisées. `lobby-showtime.client.lua`.
- [ ] **VIS-083 · P1 · V** — Rendre les **plaques de nom et marqueurs de survie** premium, bien proportionnés, ni illisibles ni gênants autour de huit participants.
- [ ] **VIS-084 · P2 · V** — Valider les animations, effets et apparences **R15, avatars divers, émotes, Reduce Motion, qualité Low et spectateur**.

## 6. Interface 2D, graphisme, HUD et marque

- [ ] **VIS-085 · P0 · C** — Produire une **vraie bibliothèque d'icônes et illustrations 2D originales** pour danger, vote, capacités, objectifs, rangs et récompenses. La plupart des UI vues dans le code sont des `Frame`/`TextLabel` et le dépôt ne contient aucun PNG/WebP/SVG d'interface source ; les gravures actuelles sont dessinées en code. `UITheme.lua`.
- [ ] **VIS-086 · P0 · V** — Recomposer la **première minute** : en entrant, le joueur doit identifier le but, le vote, le départ, la zone dangereuse et le bon mouvement sans lire un long tutoriel. `boot-splash.client.lua`, `rookie-world-guide.client.lua`.
- [ ] **VIS-087 · P0 · V** — Garantir un **HUD de manche lisible sur Android** (360–440 px) : objectif, temps, danger, survivants, contrôle tactile, pas de panneaux concurrents. `init.client.lua`.
- [ ] **VIS-088 · P0 · V** — Refaire la **présentation des votes/5 cartes/READY** en vraies cartes art-dirigées avec aperçus uniques, hiérarchie et animations claires, pas seulement du texte coloré.
- [ ] **VIS-089 · P0 · V** — Créer des **alertes de catastrophe** compréhensibles en mouvement à 1 seconde de lecture ; pictogrammes, formes et direction surpassent la couleur.
- [ ] **VIS-090 · P1 · C** — Créer un véritable **logo/identité Chaos Survival** déclinable sur boot, UI, bannière, iconographie et vignette du jeu (sans surcharger l'écran).
- [ ] **VIS-091 · P1 · C** — Remplacer le **splash/loading UI purement géométrique** par un visuel de marque original avec composition, profondeur et état de chargement honnête. `boot-splash.client.lua`.
- [ ] **VIS-092 · P1 · C** — Transformer les **cartes de résultats/winner podium** en composition premium : identité du gagnant, classement, distinctions, XP, animations de victoire, replay. `result-constellation.client.lua`, `round-celebration.client.lua`.
- [ ] **VIS-093 · P1 · V** — Finaliser le **panneau de progression/XP/monnaie, quêtes et défis**, avec vrais pictogrammes, hiérarchie et compatibilité FR/EN.
- [ ] **VIS-094 · P1 · V** — Uniformiser **boutons, gradients, stroke, coins, états press/hover/focus, tailles tactiles** ; ne pas appliquer la même carte rectangulaire partout. `UITheme.lua`, `UIResponsive.lua`.
- [ ] **VIS-095 · P1 · V** — Refaire les **badges, couronnes, récompenses de streak et succès**, affichables sans néon excessif, sans icônes stock ambiguës.
- [ ] **VIS-096 · P1 · V** — Améliorer les **interfaces de boutique/cosmétiques et aperçu d'avatar** : visuel réel, prévisualisation fidèle, confirmation d'achat claire et absence d'élément trompeur.
- [ ] **VIS-097 · P1 · V** — Finaliser les **panneaux de lobby physiques** : wayfinding, panneaux d'exercice, explication des modes, HUD de pratique, signalétique lisible à distance.
- [ ] **VIS-098 · P1 · V** — Travailler les **transitions UI** entre phases : vote, READY, round, élimination, spectateur, résultat, lobby, reconnexion ; éviter les pop-ups instantanés.
- [ ] **VIS-099 · P1 · V** — Optimiser la **typographie : tailles, graisse, interlignes, contraste, texte long FR/EN** et adaptation aux écrans Android étroits ; vérifier aussi l'accessibilité.
- [ ] **VIS-100 · P1 · V** — Revoir **notices sociales, invitation, partage, réactions/emotes, flux des survivants**, en conservant le danger prioritaire. `social-invite`, `social-share`, `survivor-feed`.
- [ ] **VIS-101 · P2 · V** — Créer une **cohérence des pictogrammes 2D et glyphes 3D du monde** (entrée, route, alarme, récompense, objectif), même charte de formes et même sens.
- [ ] **VIS-102 · P2 · V** — Vérifier les **indicateurs de chargement/connexion/sauvegarde et erreurs** pour éviter des visuels erronés ou des contrôles non disponibles pendant le streaming.

## 7. Cadrage, caméra, perception et feedback

- [ ] **VIS-103 · P0 · V** — Vérifier la **caméra de saut sur Android** : garder visibles le bord du prochain palier, la trajectoire et la hauteur du personnage, même sur scènes très détaillées.
- [ ] **VIS-104 · P0 · V** — Vérifier le **filtre d'occlusion** : meshes décoratifs et enseignes ne doivent pas masquer un joueur ou une voie praticable. `mobile-camera-sightline.client.lua`.
- [ ] **VIS-105 · P1 · V** — Finaliser les **cadrages d'ouverture des cinq arènes** : identifier en moins de 2 secondes la forme majeure, le danger, les routes et la profondeur.
- [ ] **VIS-106 · P1 · V** — Améliorer les **feedbacks d'accélération, freinage, saut, réception, choc, esquive et progression** sans secousse ni zoom excessif. `movement-feel`, `CameraFeelBus`.
- [ ] **VIS-107 · P1 · V** — Vérifier la **caméra spectateur et bots** : suivi fluide, changement de cible, pas de passage à travers le décor, noms lisibles.
- [ ] **VIS-108 · P1 · V** — Ajuster **FOV, angle, horizon, vibration et motion blur suggéré** selon écran, phase et accessibilité ; pas de caméra artificiellement « cinématique » pendant le danger.
- [ ] **VIS-109 · P2 · V** — Créer une **photo/capture de référence par carte et phase**, strictement issue du rendu Roblox, pour chaque passe artistique future.

## 8. Performance, LOD, streaming et qualité réellement observable

- [ ] **VIS-110 · P0 · V** — Contrôler que les vrais **MeshParts importés ne sont pas absents sur Android Low/Medium** ; l'actuel LOD n'en autorise qu'un dans 150 studs sur Low, trois dans 245 studs sur Medium. Vérifier le fallback natif perçu. `scenery-lod.client.lua`.
- [ ] **VIS-111 · P0 · V** — Tester les **10–15 premières secondes**, chargement asset/material, spawn, premier vote et premiers déplacements avec réseau mobile lent : aucune surface invisible ni image d'un prototype brut.
- [ ] **VIS-112 · P1 · V** — Mesurer **FPS, pires frames, nombre d'instances, particules, lumières, mémoire, streaming et consommation** sur Redmi Android réel et un appareil plus faible ; ne pas inventer de valeurs.
- [ ] **VIS-113 · P1 · V** — Définir des **LOD géométriques et de matériaux réellement distincts** (meshes simplifiés/atlas/fallback) et éviter un simple masquage brut des détails sur Low.
- [ ] **VIS-114 · P1 · V** — Vérifier le **budget PBR 2K** par propriétaire/tiers et le maintien des surfaces importantes lorsque la caméra tourne ; aucun affichage clignotant ou remplacement répété de matériaux.
- [ ] **VIS-115 · P1 · V** — Vérifier la **cohérence du streaming atomic des modèles**, à l'apparition/disparition en distance, changement d'arène, reconnexion et reprise en arrière-plan.
- [ ] **VIS-116 · P1 · V** — Tester **30 minutes et plusieurs manches** : absence d'effets, props ou UI fantômes après destruction/reconstruction des cartes.
- [ ] **VIS-117 · P1 · V** — Évaluer l'**overdraw** : fumée, alpha, glow, transparence, panneaux et halos ; mesurer coût des scènes de Double Chaos plutôt que supprimer des warnings.
- [ ] **VIS-118 · P2 · V** — Contrôler le **mode Reduce Motion, photosensibilité, daltonisme et faible luminosité** ; chaque information doit exister sans couleur ou animation.
- [ ] **VIS-119 · P2 · V** — Garder une **matrice de captures/comparaisons avant/après** avec SHA, date, appareil, tiers, arène et nombre de participants.

## 9. Présentation publique et détails périphériques

- [ ] **VIS-120 · P1 · V** — Vérifier les **icônes et miniatures Roblox Creator** actuellement en production : qualité, profondeur, originalité, lisibilité mobile et conformité à la version réellement publiée.
- [ ] **VIS-121 · P1 · V** — Créer des **captures de la vraie expérience** pour la fiche Roblox (cinq arènes, bot/interaction, catastrophe, victoire), pas des images ressemblantes mais non représentatives.
- [ ] **VIS-122 · P1 · V** — Synchroniser **titre, description, nombre d'arènes, modes, captions et supports FR/EN** avec la version publiée, sans promesses visuelles non tenues.
- [ ] **VIS-123 · P2 · V** — Ajouter de vrais **plans de présentation/teasers vidéo** issus du build public, avec silhouettes, danger, réaction joueurs et un moment de victoire.
- [ ] **VIS-124 · P2 · V** — Faire relire la cohérence **source assets ↔ licences ↔ IDs Roblox approuvés ↔ captures authentiques ↔ release source** ; aucun asset inventé ni image trompeuse.

## Critères de fermeture d'un élément

Pour cocher une ligne : (1) livrable réel intégré à `main` et sans placeholders, (2) compilation/build et tests moteur aux jalons, (3) captures **authentiques** avant/après quand une différence visuelle est revendiquée, (4) contrôles collisions/AI/warnings/mobiles et LOD, (5) workflow public exact-SHA réussi si l'élément est annoncé « live ». Pour l'éclairage, collecter rendu de chaque arène aux phases waiting/ready/round/result et en conditions Darkness/Double Chaos.

**Total inventorié : 124 actions (33 P0, 80 P1, 11 P2 ; 36 écarts confirmés/code et 88 validations visuelles à obtenir).**

### Sources du diagnostic
- Source 3D : `src/server/MapBuilder.lua`, `ArenaGroundArchitecture.lua`, `ArenaDistrictArchitecture.lua`, `ArchitecturalCladding.lua`, `StructureRetrofit.lua`, `OriginalMeshScenery.lua`, `src/client/PlatformFinishKit.lua`, `ArenaSkyFleetKit.lua`.
- Asset registry : `assets/source/roblox-asset-registry.json`, `assets/source/roblox-pbr-approval-evidence.json`, `assets/source/roblox-pbr-upload-receipts.json`.
- Éclairage : `src/client/arena-lighting.client.lua`, `ArenaPostProcessLayer.lua`, `arena-focal-lighting.client.lua`, `scenery-lod.client.lua`, `src/shared/VisualTheme.lua`.
- Catastrophes : `src/server/Disasters/`, `src/client/MeteorCoreSculptKit.lua`, `tornado-visuals.client.lua`, `disaster-premium-vfx.client.lua`.
- Survie, mouvement : `src/shared/AnimationCatalog.lua`, `src/client/bot-motion-polish.client.lua`, `CharacterReactionVisuals.lua`.
- Interface : `src/shared/UITheme.lua`, `src/client/init.client.lua`, `boot-splash.client.lua`, `lobby-round-recap.client.lua`, `result-constellation.client.lua`.
- Rendu non certifié : `docs/AI_VISUAL_QA_REMOTE_ANDROID.md`, `docs/VISUAL_QA_SCORECARD.md`, `docs/VISUAL_ART_DIRECTION_BIBLE.md`.
