# CHAOS SURVIVAL — Plan concret de refonte visuelle fichier par fichier

> **Scope :** code visuel dans `src/client` et tokens `src/shared`, sans gameplay/pay-to-win.  
> **Base :** branche d'intégration PR #18. Les travaux d'art restent dans une PR dérivée, avec validations propres.

## Répartition des expertises

Chaque lot est évalué par : directeur artistique (cohérence), environment artist (architecture), technical artist (réalisation Roblox), animateur (motion), VFX artist (feedback), UI/UX designer (hiérarchie), QA accessibilité (Android), ingénieur performance (LOD et mémoire). Un rendu techniquement fonctionnel n'est pas « premium » tant que toutes les revues utiles n'ont pas eu lieu.

## 0 — Fondations visuelles (P0, immédiatement)

| Fichier | Action concrète | Critère d'acceptation |
| --- | --- | --- |
| `src/shared/VisualTheme.lua` | Fixer palettes « Chaos Signal », matériaux et accent par arène | Aucun système n'introduit une palette discordante |
| `src/shared/UITheme.lua` | Uniformiser titres, composants, profondeur, motion et contrastes | Vote, lobby, HUD, résultats et Settings sont cohérents |
| `src/shared/VfxQuality.lua` | Budgets High/Medium/Low préservant les silhouettes héroïques | Low beau/lisible sur Android, pas de popup vide |
| `src/shared/VisualBudgetRules.lua` | Inventorier toutes les sources locales de pièces, lumières et effets | Zéro système VFX majeur hors métriques |
| `src/client/scenery-lod.client.lua` | LOD avec distance caméra, récupération à l'approche et caches sûrs | Pas de pop-in massif, de « ghost » après changement de carte |
| `src/client/arena-signatures.client.lua` | Construction/déconstruction synchronisées à la réplication, mouvement déterministe | Une seule sculpture par arène, aucun doublon |
| `src/client/ArenaSignatureKit.lua` | **En cours :** macro-silhouettes : radar segmenté, cage de levage, chevrons, pylônes de confinement | Identité sans couleur, non collidant, <= limites tier |
| `tests/engine/arena-presentation.spec.luau` | Assertions 4 arènes × 3 tiers + détails identitaires | Les silhouettes existent à tous les niveaux et ne bloquent pas |
| `docs/VISUAL_ART_DIRECTION_BIBLE.md` | Bible commune (matériaux, lumière, mouvement, UI, VFX) | Toute nouvelle PR peut s'y référer |
| `docs/VISUAL_FILE_BY_FILE_PLAN.md` | Inventaire, priorités et critères vérifiables | Aucune famille visuelle sans propriétaire |

## 1 — Décors : architecture, matière et profondeur (P1)

| Fichier | Action visuelle à réaliser | Contrôle |
| --- | --- | --- |
| `arena-hero-scenery.client.lua` | Harmoniser le grand landmark avec `ArenaSignatureKit`; éviter deux héros concurrents | Silhouette unique cadrée sur chaque arène |
| `arena-understructure.client.lua` | Poutres porteuses, couches de profondeur et contreventements crédibles | Lisibilité des bords de plateforme |
| `arena-midground-mass.client.lua` | Volumes intermédiaires différenciés pour chaque thème | Échelle sans surcharge |
| `arena-silhouette-breakup.client.lua` | Déconstruction du contour du niveau par masses et vides | Reconnaissable en contrejour |
| `arena-edge-profile.client.lua` | Bordures de jeu lisibles même en Low et dans Darkness | Zéro confusion entre bord et décor |
| `arena-platform-identity.client.lua` | Plates-formes déclinées par arène, usure et fonction | Gameplay sûr et style cohérent |
| `arena-surface-detail.client.lua` | Joints, plaques, lignes de construction, signage de détail | Pas de carrelage répétitif |
| `arena-surface-relief.client.lua` | Relief local sélectif sans géométrie excessive | Panneaux nets à moyenne distance |
| `arena-material-rules` / `material-variation.client.lua` | Presets matière logiques, suppression des variations aléatoires | Palette et performance stables |
| `arena-service-props.client.lua` | Cabines, consoles et renforts racontant la fonction de l'arène | Aucun cube isolé sans rôle |
| `arena-navigation-language.client.lua` | Direction des routes, hiérarchie des numéros, repères spatiaux | Se repérer même sans couleur |
| `arena-ambient-props.client.lua` | Détails secondaires asymétriques, sans répétition pure | Densité contrôlée |
| `arena-pad-ambient.client.lua` | Intégration des pads dans les surfaces et effets de contact | Pads identifiables en 1 seconde |
| `arena-lighting.client.lua` | Contraste de scène, lumière motivée et séparation du danger | Hazards lisibles |
| `arena-focal-lighting.client.lua` | Éclairage des points focaux par arène | Landmark présent sans surexposition |
| `arena-cinematic-depth.client.lua` | Profondeur et post-process limités en combat | Aucun flou gênant en Round |
| `arena-cinematic-disaster-atmosphere.client.lua` | Colorimétrie contextuelle spécifique aux risques | Signal important toujours prioritaire |
| `arena-spatial-ambience.client.lua` | Couche atmosphère adaptée à l'échelle | Immersion sans brouillard excessif |
| `environment-depth.client.lua` | Scènes d'horizon et plans multiples | Sens d'échelle |
| `ambient-atmosphere.client.lua` | Poussière/air ambiant bornés par tier | Peu de bruit visuel en Low |
| `CloudLayer.lua` / `world-polish.client.lua` | Ciel, nuages, horizon, gradation de profondeur | Pas de doubles Clouds/effets |
| `arena-reveal.client.lua` | Entrée dans l'arène par framing et reveal brefs | Aucun contrôle confisqué |
| `arena-hero-motion.client.lua` | Animation propre au héros existant | Rythmes lisibles, Reduce Motion |
| `arena-identity-motion.client.lua` | Animations secondaires en phase avec le thème | Pas de mouvement synchrone partout |
| `arena-silhouette-breakup.client.lua` | Relecture des contours après polish lumière | Aucun coin « primitive vide » |

## 2 — Lobby, Showtime et résultats (P1)

| Fichier | Action | Contrôle |
| --- | --- | --- |
| `ShowtimeProps.lua` | DJ booth multi-niveaux, sonorisation crédible, couronne, détails asymétriques | Stage lisible dès l'entrée, 3 tiers |
| `lobby-showtime.client.lua` | Panneau emotes accessible, dynamique de foule, lumière calme | Aucun conflit UI, stage absent en Round |
| `lobby-presentation.client.lua` | Signature d'accueil forte et mouvement environnemental subtil | Joueur comprend où aller |
| `lobby-core-orbit.client.lua` | Centre scénique, anneaux hiérarchisés | Le lobby a un point focal |
| `lobby-profile-hologram.client.lua` | Profil et progression avec verre, trames et relief | Lisibilité avant décoration |
| `lobby-progress.client.lua` | Progression/XP avec états visibles et microinteractions | Récompenses non invasives |
| `lobby-round-recap.client.lua` | Souvenir de la manche sans surcharge | Guide naturellement « rejouer » |
| `lobby-wayfinding.client.lua` | Repères parcours / vote / entraînement / zone sociale | Nouveau joueur se repère sans tutoriel long |
| `lobby-surface-detail.client.lua` | Matières et indices de profondeur | Pas de tapis plat répétitif |
| `lobby-course.client.lua` / `lobby-practice.client.lua` | Terrain d'entraînement avec feedback clair | Pas de collisions surprises |
| `result-constellation.client.lua` | Reveal score en profondeur, moins d'écrans empilés | Lecture du résultat en moins de 2 secondes |
| `result-survivors.client.lua` | Mise en scène des survivants, silhouettes et trophée | Visages visibles, pas de clipping |
| `round-celebration.client.lua` | Célébration liée à l'issue et aux emotes | Respect de Reduce Motion |
| `last-survivor-crown.client.lua` | Objet de victoire iconique mais sobre | Accessible sur Low |

## 3 — Catastrophes et VFX (P1–P2)

| Fichier | Action | Contrôle |
| --- | --- | --- |
| `ImpactSetpiece.lua` | Météores en éclats anguleux, bombe en onde de choc distincte | Effets brefs, bornés et nettoyés |
| `disaster-signature-vfx.client.lua` | Silhouette et anticipation propres aux 11 risques | Hazard identifiable sans texte |
| `disaster-setpiece.client.lua` | Scènes de catastrophe à forte identité, pas simple spam | Deux catastrophes coexistent |
| `disaster-premium-vfx.client.lua` | Flash/impact/retombée hiérarchisés | Pas de bloom plein écran |
| `disaster-motion-vfx.client.lua` | Mouvement des fragments, vents et poussières | Recyclage et budget strict |
| `disaster-climax.client.lua` | Intensification par phase, sans perdre la lisibilité | Warning reste prioritaire |
| `disaster-residue.client.lua` / `disaster-aftermath.client.lua` | Traces localisées de l'événement, disparition contrôlée | Pas de traces fantômes |
| `hazard-warning-visuals.client.lua` | VFX préparatoires formellement distincts | Lisibles en Low / daltonisme |
| `hazard-warning-signatures.client.lua` | Sémaphores du danger et animations d'alerte | Temps pour réagir |
| `hazard-route-readability.client.lua` | Guidance positionnelle nette, minimale | Impossible de confondre trajet/danger |
| `disappearing-platform-readability.client.lua` | Communication nette des plateformes instables | Fonctionnel en Low |
| `shrinking-arena-pressure.client.lua` | Bord mobile et zone sûre toujours visibles | Pas d'effet qui masque la limite |
| `tornado-visuals.client.lua` / `freeze-status.client.lua` | Matière propre : vent / cristal / refroidissement | Événements immédiatement reconnaissables |

## 4 — Personnages, mouvements, sensations (P2)

| Fichier | Action | Contrôle |
| --- | --- | --- |
| `character-polish.client.lua` | Silhouettes, palettes de personnages et qualité au spawn | Avatar toujours lisible |
| `character-motion-polish.client.lua` | Interpolation, rythmes et virages | R15/R6 sûrs |
| `body-feel.client.lua` | Anticipation, décélération et pose de réception | Aucune altération de moteur de gameplay |
| `movement-feel.client.lua` | Caméra/FOV qui valorisent la vitesse | Spectateur maître de sa caméra |
| `speed-feel.client.lua` / `momentum.client.lua` | Spectacle de vitesse sans abus de flou | Lisibilité, confort |
| `LocomotionGroundFx.lua` | Traces de contact par matériau et intensité | Courtes, intégrées au budget |
| `CharacterReactionVisuals.lua` | Chocs, near-miss et réceptions harmonisés | 12 faisceaux simultanés max |
| `character-danger-reactions.client.lua` | Réactions réservées aux participants vivants | Pas de FX de combat au lobby |
| `character-contact-vfx.client.lua` | Dust, trail, atterrissage différenciés | Pas de doubles effets |
| `bot-motion-polish.client.lua` | Animations bots convaincantes et variées | Bots crédibles en solo |
| `material-footsteps.client.lua` | Son/effet au contact cohérent matière | Pas de répétition excessive |
| `survivor-feed.client.lua` / `survivor-nameplate-visibility.client.lua` | Lisibilité des autres joueurs | Labels discrets |
| `spectator.client.lua` | Élimination → observation → retour naturel | Caméra jamais bloquée |

## 5 — Interface et feedback (P2)

| Fichier | Action | Contrôle |
| --- | --- | --- |
| `init.client.lua` | HUD, vote, countdown, progression, résultats : hiérarchie de plans | Actions prioritaires évidentes |
| `juice.client.lua` | Timing d'entrées, microfeedback, caméra, perf auto | Pas de suranimation |
| `boot-splash.client.lua` | Première impression et chargement avec vraie identité | Pas de flash vide |
| `mobile-readability.client.lua` | Safe areas, orientation, DPI, contrôle tactile | 320/360/400/440 px |
| `round-focus.client.lua` / `round-events.client.lua` | Transitions Ready/Round/Result cohérentes | Pas d'infos contradictoires |
| `ArenaGuide.client.lua` / `rookie-world-guide.client.lua` | Enseigner la première manche visuellement | Compréhensible en solo |
| `juice.client.lua` / `haptics.client.lua` | Feedback sensoriel borné par accessibilité | Son/haptique désactivables |
| `social-invite.client.lua` / `social-share.client.lua` | Invitations et moments partageables non intrusifs | Partager sans quitter le jeu |
| `social-reactions.client.lua` | Réactions sociales sans spam | Feedback discret |
| `save-status.client.lua` | États save/load courts et compréhensibles | Aucune promesse de sauvegarde non confirmée |
| `audio.client.lua` | Sound design localisé, dynamique et variation | Spatialisation claire, licence vérifiée |

## 6 — Tests, preuve et harmonisation (P3)

1. `tests/engine/arena-presentation.spec.luau` : géométries originales et cap de pièces sur **4 arènes × 3 tiers**.
2. `tests/engine/disaster-visuals.spec.luau` + `tests/engine/visual-budget-rules.spec.luau` : limites, nettoyage et effets.
3. `tests/engine/lobby-showtime-rules.spec.luau` : Stage Round/Result, propriétés, R6/R15 et Reduce Motion.
4. `src/client/studio-e2e.client.lua` + `src/server/StudioE2E.server.lua` : quatre arènes, HUD et témoins d'identité, parcours ordonné de manche.
5. `docs/ANDROID_QA_PLAYTEST.md` : vingt à trente minutes de test réel, Low/Medium/High, clips comparatifs, compte des bugs.
6. Réunir les critiques des différents métiers et **harmoniser** les couleurs, rythmes, palettes, signaux, charges GPU. Corriger les zones trop bruyantes et celles qui manquent de vie.
7. **Ne pas déclarer AAA atteint avant inspection visuelle manuelle** et mesure sur appareils cibles.

## Ordre des PR et livrables

| Sprint | Portée | Livrable bloquant |
| --- | --- | --- |
| 01 — direction + landmarks | Bible, 4 silhouettes, tests de budget | Compilation et 4 × 3 profils OK |
| 02 — arènes et matériaux | Structures, profondeur, décors, lighting | 4 captures Low/High comparables |
| 03 — lobby et résultats | Stage, récompenses, transitions, audio | Parcours 1er joueur fluide |
| 04 — catastrophes | 11 signatures + warnings + climax + résidus | Toutes lisibles en Low |
| 05 — personnages et UI | Motion, HUD, vote, spectateur, tactile | Studio E2E complet |
| 06 — certification | Perf thermique, Android réel, accessibilité, nettoyage | Vérification physique et revue artistique |

**État initial du sprint 01 :** implémentation engagée, **non certifiée visuellement**. Les sprints suivants ne sont pas « terminés » par la présence de code existant.

## Sprint 01/02 — changements déjà codés, à vérifier dans Studio

- [x] `ArenaSignatureKit.lua` : quatre silhouettes originales (radar, cage de levage, transit, confinement) + limites par tier et test moteur.
- [x] `ShowtimeProps.lua` : arche acoustique et ailes d'enceinte adaptées au tier avec test d'existence.
- [x] `ArenaDetailKit.lua` : huit motifs originaux répartis sur les équipements de service et les masses de décor, de 1 à 3 pièces selon Low/Medium/High.
- [x] `arena-service-props.client.lua` : détails industriels uniques sur les caméras, caisses, bornes et modules d'énergie.
- [x] `arena-midground-mass.client.lua` : reliefs et sous-silhouettes du lointain différenciés pour les quatre variantes.
- [x] `arena-focal-lighting.client.lua` : éclairages reconstruits sur apparition tardive de la Base et changement d'identité de l'arène.
- [x] `studio-e2e.client.lua` : vérification runtime de l'identité de deux motifs secondaires par arène et de l'absence de collision.
- [ ] Comparer par captures visuelles Low/Medium/High les quatre arènes et le Showtime en Studio.
- [ ] Essais Android réels et revue direction artistique ; aucun statut « AAA atteint » avant ces preuves.

Les cases « codé » signifient uniquement **présence dans la branche d'art**, pas rendu validé ou intégration publiée.

### Sprint 02 — habillage de plateformes mobiles

- [x] `PlatformFinishKit.lua` : détails de surface **distinctifs** pour 4 arènes, 1/2/3 éléments selon le tier, tous non collidants, sans masse ni animation supplémentaire.
- [x] `arena-platform-identity.client.lua` : finitions soudées aux plateformes mobiles (WeldConstraint) et reconstruction lorsque l'arène, le dossier `Platforms` ou une plateforme arrivent tardivement.
- [x] `tests/engine/arena-presentation.spec.luau` : vérifie 4 styles × 3 tiers, noms, quantité, absence de collisions, massless et attaches sur le vrai support.
- [ ] Studio authentifié : mesurer les effets sur plateformes en mouvement et vérifier le signal d'alerte des plateformes qui s'effondrent.
- [ ] Android réel : vérifier que les détails ne masquent ni bord de plateforme, ni sauts, ni dangers ; mesurer le coût en FPS et mémoire.

### Sprint 02 — éclairage motivé et surfaces répliquées

- [x] `arena-focal-lighting.client.lua` : habillage métallique des projecteurs, diffuseurs de verre High seulement, aucun projecteur ou effet lumineux supplémentaire.
- [x] `ArenaFocalLightingRules.lua` : contrôle des boîtiers 0/1/2 éléments par spot selon Low/Medium/High ; toujours 0 en Low.
- [x] `arena-surface-detail.client.lua` : recoloration des détails conservée, reconstruction sur arrivée tardive du sol et changement de variante, sans multiplication de couches.
- [ ] Studio : vérifier que les boîtiers ne masquent aucun élément de jeu et que les avertissements restent prioritaires pendant les catastrophes.
- [ ] Android : contrôler la nouvelle densité de pièces, les FPS et les transitions de qualité.

### Sprint 02 — validation de la présence effective des finitions

- [x] `studio-e2e.client.lua` : vérification complète après RESULT du monument, des deux familles de décors et d'un détail soudé à la plateforme. Une fenêtre de **2 secondes** absorbe les retards normaux de réplication, sans masquer un échec réel.
- [x] `StudioE2E.server.lua` : le serveur rejette explicitement un habillage de plateforme absent/détaché et journalise l'état des trois familles de décor.
- [ ] Exécuter ce scénario sur un Windows Roblox Studio authentifié et contrôler les résultats des quatre arènes.

## Sprint 02 — façades et bordures des arènes

- [x] `ArenaEdgeFinishKit.lua` : quatre façades latérales originales (radar, levage, transit, confinement) avec 1/2/3 détails par côté selon Low/Medium/High ; **aucun néon sur Low**, aucune pièce collidante.
- [x] `arena-edge-profile.client.lua` : les lip/trims/corners suivent désormais le `CFrame` de l'arène, y compris pour une carte tournée ; les façades sont placées à l'extérieur de la zone jouable.
- [x] `arena-edge-profile.client.lua` : reconstruction lors de l'arrivée tardive d'une Base ou d'un changement de `VariantId` via `MapVisualReadiness`.
- [x] `tests/engine/arena-presentation.spec.luau` : quatre arènes × trois niveaux, pièces ancrées/non collidantes, absence de Néon en Low et contrôle de placement sur arène tournée.
- [ ] Vérifier en Studio que la visibilité réelle des avertissements de danger reste prioritaire et que les bords ne sont pas occultés par la brume.


## Sprint 04 — catastrophes : identité physique de l'introduction

- [x] `DisasterIntroGlyphKit.lua` : les **11 glyphes** existants deviennent des plaques géométriques 3D propres à chaque danger, orientées vers l'arène et placées **en dehors du sol jouable** ; Double Chaos a deux emplacements distincts.
- [x] `disaster-setpiece.client.lua` : animation d'apparition et dissolution courte des plaques avec `Debris`, nettoyage en fin de manche, Reduce Motion, et un deuxième essai borné si `Arena.Base` réplique tard.
- [x] `VisualBudgetRules.lua` : le dossier `DisasterIntroGlyphLocal` entre dans le comptage global des pièces décoratives.
- [x] `tests/engine/disaster-visuals.spec.luau` : 11 catastrophes × 3 tiers × 2 emplacements, silhouettes distinctes, rotation de carte, absence de collisions, aucun néon en Low.
- [ ] Revue manuelle en Studio : les plaques ne doivent jamais masquer un danger, les introduc­tions Double Chaos ne doivent pas saturer le cadre.
- [ ] FPS Android et comparaison de lisibilité High/Medium/Low, notamment avec Reduce Motion.

## Sprint 04 — impacts de météores / bombes : signature de matière

- [x] `ImpactSetpieceRules.lua` : 2 (Medium) ou 4 (High) finitions géométriques supplémentaires, aucune en Low ou avec Reduce Motion. Répartition radiale **déterministe** et bornée.
- [x] `ImpactSetpiece.lua` : deux langages de matière immédiatement distincts : **éclats de bord de cratère minéral (WedgePart/Slate)** et **éléments tangentiels de front de pression (Metal)**. Décroissance courte et suppression Debris.
- [x] `hazard-impact-feedback.client.lua` : grands flashs réduits en épaisseur pour ne pas bloquer la vue, formes météore et bombe différenciées ; débris de matière déterministes et inventoriés dans `ImpactSetpieceLocal`.
- [x] Concurrence de VFX réduite à 8 Medium / 10 High (contre 10/14 auparavant) ; sons, collisions, dégâts, positions et temps de gameplay inchangés.
- [x] `tests/engine/disaster-visuals.spec.luau` : quantité, types, matériaux, limites Medium/High, trajectoires et absence de collisions sur deux classes d'impacts.
- [ ] Vérifier en Studio l'absence d'occlusion des trajectoires du joueur, la compatibilité Double Chaos et les FPS Android sur une succession dense d'impacts.

## Sprint 04 — retombées des neuf catastrophes non explosives

- [x] `AftermathSurfaceKit.lua` : 9 recettes originales formellement distinctes. Lave = croûte fondue, faible gravité = doubles arcs orbitaux, plateformes = lèvres cassées, tornade = sillons de vent, gel = aiguilles de givre, vitesse = traînées parallèles, obscurité = replis d'ombre, arène rétrécissante = bras convergents, saut électrique = zigzags de décharge.
- [x] `disaster-residue.client.lua` : après le Round, générer ces empreintes via le kit en suivant la normale du sol et le `CFrame` de l'arène (y compris tournée). Les empreintes de météores/bombes conservent leur système de cratères et de brûlures.
- [x] **Budget par empreinte** : 2 objets en Low, 3 en Medium, 4 en High ; les anciens budgets globaux de résidus restent en vigueur et les objets sont nettoyés par `Debris`.
- [x] `tests/engine/disaster-residue.spec.luau` : 9 catastrophes × 3 niveaux, géométries aux noms uniques, matériaux non-neon, absence de collisions, position correcte dans une scène tournée, entrées invalides.
- [ ] Revue Studio : s'assurer que les empreintes ne masquent pas les cibles de navigation ou les signaux de danger et qu'elles sont visibles sans surcharge.
- [ ] Comparaison Android Low/Medium/High et contrôle des résidus après un changement rapide de carte.

## Sprint 04 — harmonisation de la colorimétrie après la manche

- [x] `DisasterAftermathTone.lua` : extraire les 11 profils de couleur de résultat dans un module partagé et testable ; pour Double Chaos, mélanger les deux teintes (au lieu de choisir la seule la plus intense), mais limiter le contraste, la saturation et le flou.
- [x] `disaster-aftermath.client.lua` : affichage compact, atténué sur Android Low et Medium ; flou forcé à zéro avec Reduce Motion ; retour propre à la scène normale.
- [x] `tests/engine/disaster-residue.spec.luau` : profils présents pour 11 catastrophes, mélange Double Chaos, limites et qualité Low, Reduce Motion.
- [ ] Examiner les transitions Result → Lobby dans Studio, notamment un Double Chaos obscurité + météores, afin de confirmer la lisibilité.

## Sprint 04 — finition de matière et stabilité réseau des retombées

- [x] `DisasterResidue.lua` : neuf teintes de matériau **refroidi / dissipé** déterministes selon le danger ; transition de couleur seulement en Medium/High, jamais Low ni Reduce Motion.
- [x] `disaster-residue.client.lua` : la géométrie `AftermathSurfaceKit` se ternit une seule fois avant le fondu final ; aucune boucle RenderStepped, aucun objet supplémentaire, aucune modification du gameplay.
- [x] `disaster-residue.client.lua` : trois nouvelles tentatives bornées si `Arena.Base` arrive après `RoundState=result`, interrompues si la manche ou la carte change.
- [x] Nettoyage immédiat lors de la suppression de `GeneratedMap` ; adaptation du nombre de marques existantes lors d'un abaissement de qualité graphique.
- [x] `tests/engine/disaster-residue.spec.luau` : neuf teintes distinctes, transitions terminées avant l'effacement final, Low et Reduce Motion désactivent le vieillissement, aucune animation des cratères météore/bombe.
- [ ] Vérification visuelle sur Studio + appareil Android : stabilité des couleurs, transitions, événements à forte fréquence et identité durant Double Chaos.

## Sprint 05 — réception au sol, matériaux et sensation de contrôle

- [x] `GroundContactRules.lua` : règles de réaction au sol limitées aux survivants actifs ; avatar local prioritaire, zéro décoration à distance en Low, en final rush sur les autres avatars, ou avec Reduce Motion.
- [x] `character-contact-vfx.client.lua` : les réceptions distinguent désormais métal (copeaux mécaniques), ardoise/béton (éclats minéraux) et glace (cristaux de verre), orientés selon la normale réelle du sol, sans collision ni modification de la physique.
- [x] `character-contact-vfx.client.lua` : plafond global 6 / 18 / 30 pièces (Low / Medium / High), cooldown de 0,64 s par avatar et arrêt des effets au départ de la manche.
- [x] `character-contact-vfx.client.lua` : suppression de l'attente récursive non bornée pour les rigs incomplets au profit d'un événement ChildAdded à durée bornée.
- [x] `character-danger-reactions.client.lua` : ne pas afficher de réaction de near-miss quand la distance/rayon est invalide ; un impact hors écran ne consomme plus le cooldown d'une réaction visible.
- [x] `VisualBudgetRules.lua` : les anneaux et éclats de contact sont maintenant mesurés dans `CharacterContactLocal`.
- [x] `tests/engine/ground-contact-rules.spec.luau` : limites de pièces, conditions de manche, audio-matière existant, variétés de matériaux et cooldowns.
- [ ] QA Studio/Android : entendre et voir les réceptions sur plusieurs sols, vérifier l'absence de bruit VFX dans le lobby et la stabilité en serveur plein.

## Sprint 05 — cohérence audio 3D et retours de réception

- [x] `ImpactAudioRules.lua` : impacts spatialisés ciblés selon distance et niveau Android. Low = 1 couche max, Medium = 2, High = 3 seulement pour événements proches ; au-delà de 86 studs une couche, au-delà du rayon de diffusion aucune création.
- [x] `audio.client.lua` : n'instancier aucun son quand `AudioMuted` est actif ; calcul d'observateur compatible spectateur/caméra ; filtrage de portée **avant** consommation du cooldown, volumes plafonnés, durée des objets sonores réduite de 4 à 2,8 s.
- [x] `GroundContactRules.lua` : timbre de réception distinct selon le sol (métallique, minéral, cristal, neutre) avec volume doux ; le son supplémentaire n'apparaît qu'après une chute significative, avec atténuation Low/Reduce Motion.
- [x] `audio.client.lua` : plus de son de réception supplémentaire hors manche, sur un avatar éliminé ou réapparu ; les sons de base Roblox et la correction EQ des pas restent en place.
- [x] Tests moteur dans les **suites existantes** `audio-config.spec.luau` et `ground-contact-rules.spec.luau` (pas de nouveau fichier de test ni de modification du shard).
- [ ] Vérification humaine de la spatialisation au casque et sur Android, ainsi que des signaux en Double Chaos lors de fortes densités d'impacts.

## Sprint 05 — silhouettes de réactions en mouvement

- [x] `CharacterReactionVisuals.signature` : recettes déterministes de faisceaux par action et cause : météore = éjection haute, bombe = front de pression horizontal, esquive = filaments de fuite, réception = amortissement dirigé vers le bas.
- [x] `CharacterReactionVisuals.burst` : animation progressive de l'épaisseur des Beam (une seule Tween par faisceau, sans RenderStepped), objets toujours détruits automatiquement sous 0,5 s, aucune modification des Animators ou de la physique.
- [x] Chaque Beam expose les attributs `ChaosReactionMode` et `ChaosReactionKind` pour une vérification en Studio ; les modes inconnus sont rejetés.
- [x] Réduction du nombre de tâches différées de nettoyage (une par signature plutôt qu'une par attachment/faisceau).
- [x] Tests ajoutés dans `survival-feedback.spec.luau` (pas de nouvelle suite) : directions et couleurs distinguables, durées/largeurs bornées, attributs et modes inconnus.
- [ ] Valider visuellement avec 3 avatars, deux catastrophes simultanées et 30/60 FPS sur Android.


## Sprint 02 — skyline accents lisibles sur Android (9 octobre 2026)

- [x] `ArenaSilhouetteAccentKit.lua` : quatre identités physiques différentes au-delà des bords de jeu (instrument de mesure Classic, ailettes de refroidissement Towers, bifurcation de transit Crossroads, pétales de confinement Orbital), indépendantes de la couleur.
- [x] `arena-silhouette-breakup.client.lua` : deux pièces architecturales en **Low**, trois en **Medium**, quatre en **High**, par-dessus les volumes secondaires existants seulement sur Medium/High. Aucun effet Neon ou source lumineuse additionnelle.
- [x] Géométries **locales, ancrées, non-collidantes, non-touchables et non-interrogeables** ; placements relatifs à `Arena.Base.CFrame` pour les cartes tournées. Pièces comptabilisées dans le dossier `ArenaSilhouetteBreakupLocal` déjà audité.
- [x] Reprise automatique lorsque `GeneratedMap`, `Arena.Base` ou `VariantId` arrivent hors ordre ; le changement de qualité reconstruit proprement la couche, et la suppression de la carte détruit les pièces.
- [x] Tests de structures `arena-presentation.spec.luau` : 4 cartes × 3 tiers, noms spécifiques, matériaux Low, limites, orientation, non-collision et entrées invalides.
- [ ] **Validation bloquante** : vérifier Build Validation et Open Cloud sur le **SHA final**, puis quatre angles de caméra dans Roblox Studio et Android Low/Medium/High à 30/60 FPS avant déclaration de qualité de production.


## Sprint 02 — finitions matérielles des sols et remise en place des couches (9 octobre 2026)

- [x] `ArenaDeckFinishKit.lua` : six motifs distincts par arène ; gravure d'arpentage (Classic), plaques de charge et d'ancrage (Towers), flèches de transit en relief (Crossroads), iris de confinement (Orbital).
- [x] Detail borné par tier : **2 pièces Low / 4 Medium / 6 High**, sans particules, Neon, éclairage supplémentaire, hitbox, contact, query ni ombre coûteuse.
- [x] `arena-surface-detail.client.lua` : plans et compositions 3D calculés dans le repère `Arena.Base.CFrame` pour les arènes orientées ; colorimétrie réactive aux catastrophes préservée.
- [x] Correction de la superposition : le serveur instancie `ArenaDeckInset` au-dessus de `Arena.Base`. Les couches de détail client sont surélevées de **0,18 stud au-dessus du sommet de Base**, pour ne plus être masquées par le dessus du panneau (`Base + 0,15 stud`).
- [x] `arena-surface-relief.client.lua` : souscription à `MapVisualReadiness.watch` plutôt que fenêtre courte `Arena.ChildAdded` ; reconstitution après réplication tardive de `Base` ou `VariantId`, suppression des connexions et des instances à la fin de la carte.
- [x] Tests `arena-presentation.spec.luau` : 4 arènes × 3 tiers, pièces adaptées à chaque matériau, orientation de carte inclinée, contrôle de hauteur au-dessus de la fondation, propriétés physiques sûres, entrées invalides et nombre maximal.
- [x] `studio-e2e.client.lua` et `StudioE2E.server.lua` : vérification du motif de sol propre à chaque arène, en plus de la sculpture, de la skyline et des finitions de plateforme.
- [ ] Gates restant à remplir : GitHub Build Validation **et** 5 shards Open Cloud sur le SHA final ; scènes et captures Studio en quatre arènes ; contrôle Android réel High/Medium/Low en mouvement avec effets de catastrophes, lisibilité des signaux et FPS. **Aucune publication avant validation.**


## Sprint 02 — matériel de lumière et profondeur cohérente (9 octobre 2026)

- [x] `ArenaFocalFixtureKit.lua` : les boîtiers de SpotLight ont une architecture spécifique à chaque arène : optique de mesure (Classic), cage de refroidissement (Towers), capot de transit (Crossroads), collier d'iris (Orbital). Les **SpotLights existants** sont conservés sans ajout de sources lumineuses.
- [x] Budgets stricts : **0/1/2 pièces par projecteur Low/Medium/High**, aucun Neon, collision, particule, touch, query ou ombre supplémentaire.
- [x] `ArenaSceneryFrames.lua` et `arena-cinematic-depth.client.lua` : horizon, couronnes, pylônes, anneaux, balises et trajectoires aériennes transformés selon `Arena.Base.CFrame`, y compris si la carte est tournée ou inclinée.
- [x] Le trafic aérien décoratif cesse pendant la manche afin de préserver la hiérarchie d'attention des catastrophes, sans gêner les animations du lobby.
- [x] `arena-cinematic-depth.client.lua` et `arena-lighting.client.lua` : reconstruction / ambiance re-synchronisées avec `MapVisualReadiness.watch` lorsque la base et le type de carte arrivent après le modèle. Déconnexion après suppression de la carte.
- [x] Tests dans `arena-focal-lighting-rules.spec.luau` et `arena-presentation.spec.luau` : 4 styles × 3 profils, noms, matériaux, propriétés non-collidantes, repère incliné et cas invalides.
- [x] `studio-e2e.client.lua` / `StudioE2E.server.lua` : un luminaire physique propre à chaque arène est désormais requis en Medium/High ; le contrôle Low admet l'absence prévue de sources.
- [ ] Avant fusion : **Build Validation et cinq shards Open Cloud sur le même SHA**, Studio E2E, captures, mesures de FPS et vérification physique Android. Aucun nouveau rendu n'est déclaré AAA ou publié.


## Sprint 02 — portail de lobby cinématique et véritables anneaux de transition (9 octobre 2026)

- [x] `LobbyGateCueKit.lua` + `lobby-presentation.client.lua` : ailettes articulées non bloquantes à l'entrée de l'arène, flèches directionnelles sur la piste et graduations de fin de parcours ; construction différée tant que les véritables ancrages `ArenaGateTop` et `ArenaRunway` ne sont pas répliqués.
- [x] Cues de lobby par état : **social** = cyan discret, **vote** = magenta, **launch** = or et ailettes ouvertes, **inactive** = masqué. Changements animés uniquement à la transition de mode, sans nouvelle boucle RenderStepped. `ReduceMotion` saute les transitions.
- [x] Géométrie bornée **2/4/6 BaseParts Low/Medium/High**, non-collidante, non-interrogeable, sans Neon, light, hitbox, sons ou nouvelles textures ; entièrement comptée dans `LobbyPresentationLocal`.
- [x] `CinematicPulseRingKit.lua` : remplacement des cylindres pleins déguisés en anneaux par de **vrais contours creux de 4/6/8 segments** Low/Medium/High ; alignement à l'orientation du sol de `Arena.Base.CFrame`, disparition rapide, compatible `ReduceMotion`.
- [x] `round-transition-world-pulse.client.lua` : début de manche, final rush, fusion et réactions locales réutilisent la recette segmentée ; la seconde couronne est désactivée en Low et ReduceMotion.
- [x] `VisualBudgetRules.lua` : nouveau dossier `RoundTransitionPulsesLocal` audité pour éviter que les coûts de la transition restent invisibles dans les métriques.
- [x] Tests complémentaires dans `lobby-presentation-rules.spec.luau` et `round-event-presentation.spec.luau` : profils, couleurs de phase, attributs de pièces, forme **Block** non-disque, repère incliné, surfaces non physiques et cas invalides.
- [x] `studio-e2e.client.lua` / `StudioE2E.server.lua` : vérification d'une ailette de portail en mode **ready**, en plus de la suite de vérification des visuels par phase.
- [ ] Garde-fous : attendre la réussite de Build Validation et de tous les shards Open Cloud au **commit final** ; capturer l'enchaînement lobby → vote → entrée → manche et vérifier la lisibilité et le FPS sur Android Low/Medium/High. Sans validation Studio/Android, ne pas publier.


## Sprint 02 — réactions dirigées et célébrations réellement creuses (9 octobre 2026)

- [x] `CharacterReactionVisuals.lua` : le ruban de **Shock** reçoit maintenant la position exacte de l'impact, oriente le profil opposé à l'explosion dans le repère local de chaque avatar et conserve un repli sûr si l'origine est absente ou confondue avec le personnage.
- [x] Esquive **Meteor** : afterimage ascendant angulaire ; esquive **Bomb** : ruban bas, balayage latéral plus large. Pas de nouveau BasePart, moteur physique, Motor6D, Animator, asset importé ou RenderStepped.
- [x] `character-danger-reactions.client.lua` : la position de l'impact provenant du serveur est transférée aux effets pour les joueurs et survivants IA proches ; la sélection des participants, limites de distance, qualité, cooldowns et `ReduceMotion` sont inchangés.
- [x] Attribution `ChaosReactionDirectional` aux Beam pour l'audit Studio. Tests `survival-feedback.spec.luau` : avatar tourné, symétrie des deux rubans, direction de fuite, origine absente et silhouettes de deux catastrophes distinctes.
- [x] `round-celebration.client.lua` : conversion des célébrations Win / Clutch / Master / First Chaos / défaite en véritables anneaux segmentés via `CinematicPulseRingKit`, afin de ne plus dessiner de disques opaques sur le sol.
- [x] `VisualBudgetRules.lua` : ajout du dossier transitoire `RoundCelebrationPulsesLocal`. `visual-budget-rules.spec.luau` vérifie la présence des deux familles de contours et le nombre exact de pièces, sans lumière ou effet particulaire dans ces contours.
- [ ] Validation bloquante : les deux GitHub Actions sur le SHA final, captures Studio de deux impacts de côtés opposés, 1 joueur + 2 IA et séquences de victoire/défaite, FPS et contraste sur Android réel avant toute fusion ou publication.


## Sprint 02 — chorégraphies de groupe et hologrammes habillés (9 octobre 2026)

- [x] `ShowtimeChoreography.lua` : 6 motifs distincts **dance, shuffle, groove, cheer, wave, laugh**, avec poses indépendantes par danseur et alternance déterministe quand la scène ne suit pas d'emote humain.
- [x] Les danseurs décoratifs rejoignent la **même emote que le joueur** seulement si quelqu'un se trouve sur la piste ; cela ne télécommande aucun joueur, bot, Humanoid, Animator ni Motor6D.
- [x] `ReduceMotion` impose des poses immobiles et constantes dans le temps ; le profil Low ne crée toujours aucun mannequin.
- [x] `ShowtimeHologramDetails.lua` : visière et noyau de poitrine Medium ; bracelets en plus High. Respectivement **0 / 2 / 4 parties par mannequin** Low/Medium/High, sans collision, ombre, Neon, source lumineuse ou particules supplémentaires. Les détails suivent le corps pendant les gestes, puis disparaissent pendant `round`.
- [x] `lobby-showtime.client.lua` : les mouvements et les accessoires sont mis à jour **dans la boucle existante** de 0,10 s High / 0,16 s Medium, sans nouveau RenderStepped ni touche d'interface.
- [x] Marquee physique `ShowtimeTitle` rendu plus social : **DANCE TOGETHER / DANSONS ENSEMBLE**, **DUET / EN DUO** + nom de l'emote en FR/EN ; aucun nouvel élément d'écran ou équipement sonore.
- [x] `lobby-showtime-rules.spec.luau` : différences mesurables entre les six poses, invariants d'amplitude, proximité, six silhouettes statiques avec ReduceMotion, budgets de costumes, opacité active/inactive et traductions du panneau.
- [x] `studio-e2e.client.lua` : contrôle de la visière et du noyau Medium/High en `result`, invisibilité pendant `round` et règles Low inchangées.
- [ ] Validation obligatoire avant fusion : **Build Validation + Open Cloud** au SHA final, E2E du lobby en `waiting`/`result`/`round`, interactions emote à 1/2 joueurs, captures et FPS Android Low/Medium/High. Les gestes appartiennent aux hologrammes de scène : ce n'est pas encore un système d'animations AAA nouvelles pour avatars réels.


## Sprint 02 — avatar R15 réactif et bots IA expressifs (9 octobre 2026)

- [x] `BodyMotionRules.blastResponse` : direction locale et enveloppe d'intensité calculées depuis **l'impact effectif transmis par le serveur**, corrigées pour les avatars orientés arbitrairement et pour les rayons/distances invalides.
- [x] `body-feel.client.lua` : **l'unique propriétaire existant des C0 Motor6D R15** combine désormais esquive latérale des épaules, inclinaison du torse et anticipation avant/arrière selon la direction du souffle. Décroissance exponentielle brève ; aucun second Animator, nouveau RenderStepped, force, rotation forcée du joueur ni dégât ne sont ajoutés.
- [x] Réactions physiques visuelles uniquement pendant une manche pour les participants non éliminés, désactivées à la source avec `ReduceMotion`.
- [x] `BotMotionPresentationRules.lua` : signatures cosmétiques **Launch / Skid / Pivot** tirées de l'accélération et du changement de cap réels du bot, pas de commandes de trajet inventées. Exige un mouvement marqué, un sol détecté, la phase `round`, et la proximité de l'observateur.
- [x] `bot-motion-polish.client.lua` : un seul événement de trace par intervalle collectif, cooldown individuel d'au moins 1,35 s ; limites de distance **54 studs Medium / 78 High**, aucune trace en Low ou ReduceMotion.
- [x] Les traces utilisent `LocomotionGroundFx.emit` déjà existant et comptabilisé dans `LocomotionContactLocal`, sans nouvelle source lumineuse ni boucle graphique. Les traînées IA existantes sont brièvement colorées cyan/orange/violet lors de ces actions, puis restaurées.
- [x] Remplacement des tentatives infinies `task.delay(0.12)` pour les rigs IA partiels par une connexion `ChildAdded` **unique et nettoyée** après arrivée du root/Humanoid ou disparition du bot. Libération des anciens écouteurs et états lors du changement de dossier.
- [x] `body-motion-rules.spec.luau` : impacts de quatre côtés pour R15 tourné, valeurs absentes et hors portée, forte accélération, freinage et demi-tour IA ; vérification des critères de qualité, mobilité, distance, couleur et accessibilité.

- [x] `body-feel.client.lua` : un **numéro de génération par CharacterAdded** empêche un vieux `WaitForChild` en retard de réassigner les Motor6D d'un personnage précédent ; `Humanoid.StateChanged` de l'ancien rig est déconnecté, et les C0 sont restaurés lors de `CharacterRemoving`. Pas d'animation forcée ni de second gestionnaire d'articulations.
- [ ] Validation avant fusion : Build Validation et Open Cloud sur le SHA de pointe, Studio E2E avec **un joueur et plusieurs bots** et événements réels, contrôles de non-synchronisation des animations contre l'Animator Roblox, FPS Android Low/Medium/High. Aucun changement de serveur ni de publication.


## Sprint 02 — landing decals lisibles et culling des bots (9 octobre 2026)

- [x] `LandingImprintKit.lua` : les contacts de réception ne sont plus des **cylindres pleins**. À leur place : traces minces de chaussures / éclats matérialisés selon `Mechanical` (traits métalliques), `Mineral` (éclats angulaires), `Crystal` (prismes en verre) ou `Neutral` (traces discrètes). Expansion dans le **repère du sol incliné**, disparition courte, zéro collision, lumière ou particule.
- [x] `character-contact-vfx.client.lua` : réutilise la sélection des participants humains / bots, la portée visuelle, la raycast du sol et la limite globale de pièces existantes. **Aucune augmentation du budget** : réception locale Low 1, Medium 4, High 6 ; autres survivants Medium 3, High 4 ; aucun effet des bots en `ReduceMotion` ni pendant `FinalRush`.
- [x] `ground-contact-rules.spec.luau` : vérifie quatre matériaux, le sol incliné, les pièces sans hitbox ni ombre, les profils et les entrées invalides.
- [x] `BotMotionPresentationRules.trailVisible` : les traînées IA existantes sont dorénavant **cachées hors champ proche** (seuil d'apparition 66 studs Medium, 95 High ; seuil de disparition +12), tout en tenant compte de la vitesse au sol, du mode Low, de `ReduceMotion` et de la phase.
- [x] `bot-motion-polish.client.lua` : utilise la distance observateur calculée une fois par bot et la règle d'hystérésis pour éviter un clignotement des traces lorsque le joueur franchit un seuil de portée.
- [x] `body-motion-rules.spec.luau` : culling des traînées avec hystérésis, qualité, immobilité, phase et accessibilité ; `visual-budget-rules.spec.luau` : simulation de **4 bots avec réception et pivot simultanés**, 28 pièces tracées dans les deux dossiers connus, sans lumières ni effets GPU supplémentaires.
- [ ] Valider l'aspect réel des réceptions sur les quatre arènes (surfaces planes/inclinées, contrastes nuit/jour, disques supprimés), les impressions visuelles de bots isolés / en groupe et les fps Android. Les unit tests et la compilation ne remplacent pas ces playtests.
