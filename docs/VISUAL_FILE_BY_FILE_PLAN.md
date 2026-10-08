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
