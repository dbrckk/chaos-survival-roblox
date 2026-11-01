# Chaos Survival — audit comparatif et plan premium (1er novembre 2026)

## Périmètre, statut de validation, score

- GitHub inspecté : `dbrckk/chaos-survival-roblox`, `main` SHA `8c16733c21ea019a08c475280833286a4214dfb9`.
- Dernière publication publique **vérifiée sur GitHub Actions** : SHA `e8767c98c475a3efb39ed53ed7bbe16efa1865d2`, [run de publication](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41287014148) (1er novembre). Les PR #514–#516 sont intégrées au **source main**, pas certifiées dans la publication actuelle.
- Le propriétaire déclare le 1er novembre que « toutes les vérifications fonctionnent ». À créditer comme validation rapportée par l'utilisateur ; pas un substitut à une capture Studio/Android, aux résultats exact-SHA ni aux mesures joueurs.
- **Estimation argumentée du produit côté source : 6,6/10**, contre une cible `>= 9/10`; l'écart artistique, social et mobile réel reste non mesuré. Ne pas présenter la note comme satisfaction utilisateur ou mesure de FPS.
- Comparables officiels : [Tower of Hell](https://www.roblox.com/games/1962086868/Tower-of-Hell), [Flood Escape 2](https://www.roblox.com/games/738339342/Flood-Escape-2), [Super Bomb Survival](https://www.roblox.com/games/164051105/Super-Bomb-Survival), [Natural Disaster Survival](https://www.roblox.com/games/189707/Natural-Disaster-Survival). Retenir principes de rythme/contrôle/variété, jamais copier assets ou cartes.

### Note par axe, barème pondéré

| Axe | Poids | Note | Motif |
| --- | ---: | ---: | --- |
| Déplacements / sauts / caméra | 20 % | 7,0 | coyote, buffer, réception et reprise de caméra ; feeling sur appareil non mesuré |
| Level design / parcours physiques | 15 % | 6,3 | cinq cartes distinctes mais espace réellement parcouru concentré |
| Catastrophes / équité | 15 % | 7,3 | 11 catastrophes et Double Chaos, pas de distribution de mortalité validée |
| Première minute / lisibilité | 10 % | 7,2 | guidage contextualisé FR/EN, interaction tactile corrigée |
| Identité 3D / PBR | 10 % | 6,0 | assets originaux et traitement PBR disponibles ; fidélité des rendus non certifiée |
| Animations / sons | 5 % | 5,8 | couches de retour sensoriel mais finition en session non revue |
| Bots / social | 5 % | 6,3 | vraie IA de navigation, non évaluée par joueurs aveugles |
| Progression / rétention | 10 % | 6,3 | économie, quêtes, collections, pas de métriques cohortes constatées |
| Android FPS / mémoire | 5 % | 5,5 | LOD et budgets, pas de benchmark récent exact modèle |
| Fiabilité / pipeline de publication | 5 % | 7,0 | forte infrastructure, écart main/public non certifié |
| **Total pondéré** | **100 %** | **6,6 /10** | Estimation, confiance faible-moyenne |

## État réellement observé

1. **Cinq arènes** (`Classic`, `Towers`, `Crossroads`, `Orbital`, `Harbor`) déclarent chacune `BaseSize = Vector3.new(320, 2, 320)` dans `src/server/ArenaVariants.lua`. Les plateformes clés occupent surtout les coordonnées proches du centre (de l'ordre de 12–51 studs pour les routes principales) : **une grande taille de sol ne vaut pas une grande zone d'action**. Étendre le terrain seul créerait un espace vide, sans bénéfice.
2. **Gameplay conséquent** : 11 catastrophes, solo avec bots, Double Chaos, parcours R15, récompenses serveur, quêtes, records, cosmétiques et progression. Ce n'est pas un prototype vide.
3. **Visuels** : modèle `OriginalMeshScenery.lua` intégrant jusqu'à huit placements extérieurs par carte via six Model packages du créateur (avec fallback). Ce ne sont pas nécessairement huit structures visibles sur tous les clients. Le registre `assets/source/roblox-asset-registry.json` indique `models_inserted_in_game=false` et `android_visual_qa_completed=false` malgré le chargeur runtime : rapprocher le statut de chargement réel, la provenance et les preuves visuelles.
4. **Véritable défaut de données confirmé dans le code** : `src/server/GameAnalytics.lua` utilise `KNOWN_ARENAS = {Classic, Towers, Crossroads, Orbital}`; **Harbor manque**. `GameAnalytics.arenaRoundFields` et `arenaBotMetrics` étiquettent donc les données Harbor `Arena:Unknown`, faussant les comparaisons de survie et d'IA pour cette carte. C'est la première correction de la feuille de route ; ne pas mélanger les anciennes métriques Unknown avec de futures séries Harbor.
5. **Livraison** : release public SHA `e8767c9` > source main SHA `8c16733` sur l'axe temps, mais source main est plus récent. `README.md` annonce encore le 31 octobre et `97a2533...` comme dernière publication vérifiée : documentation de statut à synchroniser avec les artefacts Actions de référence.
6. **Observabilité déjà implémentée** : `GameAnalytics.lua` trace onboarding, temps jusqu'à premier round, sortie de session, survivants humains/bots par carte et temps en vie. Exploiter les événements déjà présents avant de multiplier les systèmes ou d'inventer des chiffres.

## Plan ordonné — finir un lot complet avant le suivant

### P0.A — Réparer la mesure et la vérité de version

- Corriger `KNOWN_ARENAS.Harbor` ; conserver les valeurs de dimensions analytiques de faible cardinalité, et vérifier les deux événements humains et l'agrégat IA. Comparer les sessions *après* déploiement de la correction, sans rétroattribuer les anciens `Unknown`.
- Mettre à jour `README.md`, la documentation de publication et l'indication du SHA public depuis un run effectivement réussi ; sauvegarder les liens de preuve et distinguer source/published.
- Obtenir une première exportation des analytics existantes : `SessionExitStage`, `TimeToFirstRoundSeconds`, `RoundStarted`, `RoundCompleted`, `ArenaSurvived`, `ArenaBotSurvivalFraction`, rapports par appareil et mode. Calculer les dénominateurs et cohortes, sans fabriquer de valeurs manquantes.
- **Terminé si** les cinq valeurs d'arène sont correctement distinguées, preuve de version exacte archivée, dashboard de conversion première→deuxième manche lisible et aucun changement serveur hors correction.

### P0.B — Prototype de qualité **finale** sur une carte vitrine, puis diffusion du standard

- **Commencer par Storm Harbor** : plus différenciable (quais, portiques, grues, cargaisons, docks), cinq-mécanismes existants et correction analytique préalable. Ne pas agrandir un rectangle vide.
- Repenser l'**espace jouable** avec au moins quatre secteurs latéraux exploitant le véritable terrain 320×320, une destination visible dans chaque secteur, des trajets en boucle et au moins trois altitudes *réellement atteignables*. Les routes utilisent des sauts physiques, passerelles, transferts et raccourcis optionnels. Envisager 400–480 studs **uniquement si** les mesures de parcours et les performances justifient le changement, avec revue de toute la logique coordonnée (spawns, IA, hazards, shrinking arena, raycasts, monde visuel).
- Construire chaque secteur de façon terminée : géométrie modulaire sculptée/meshes natifs, signalétique, matériaux PBR, collisions simplifiées, LOD, éclairage, animation de mécanique et alternative de repli. Pas de chemin décoratif présenté comme praticable.
- **Terminé si** un novice comprend une première sortie et un expert choisit au moins deux stratégies, chaque liaison est franchissable en R6/R15/Android, aucun combo catastrophe n'isole la moitié du terrain et l'arène paraît vaste en vue du personnage.

### P1.A — Pipeline visuel et audio cohérent

- Faire passer les six Model packages existants d'« import tenté » à **instances authentiquement vérifiées** à l'écran, ou corriger le fallback. Contrôler droits, triangulation, tailles, matériaux, téléchargements Roblox, streaming et mémoire.
- Réaliser une **bible visuelle unifiée** (matériaux métal, béton, bois, silhouettes, palette par carte) ; PBR avec cartes normal/roughness/metalness là où Roblox et l'appareil le rendent utile, sans 4K systématique.
- Une signature animée réellement singulière pour chaque carte ; animations personnages R15 crédibles (anticipation, course, arrêt, saut, réception, esquive, victoire), gestion R6/fallback et ReduceMotion.
- Audio maîtrisé : une couche spatiale par carte, télégraphie sonore non agressive par catastrophe, sons de contact selon matériau, mix qui fait entendre l'essentiel avant les cosmétiques.
- **Terminé si** sur une capture sans nom chaque carte est reconnue, absence de fort clignotement/effet couvrant un danger, les silhouettes et le mix passent une revue réelle sur Android.

### P1.B — Gameplay tactique distinct pour les cinq cartes

- **Classic** : grille de choc prévisible et changements de hauteur choisis ; **Towers** : portillons, ascenseurs et embranchements ; **Crossroads** : aiguillage et traversée latérale sous pression ; **Orbital** : montée, sortie de l'anneau et helix ; **Harbor** : cargo sweep, transferts de quais, passerelles et abris.
- Ajouter la **destruction/évolution lisible** des zones lorsque la catastrophe le prévoit, et restituer le chemin ou une alternative sûre au cycle suivant. Priorité à la réaction tactique, pas uniquement aux particules.
- Contrats d'équité : avertissement avant impact, aucune route sans contre-mesure, bots soumis aux mêmes surfaces et informations visibles, éliminations imputables à une décision compréhensible.
- **Terminé si** les 5 mécanismes signatures offrent des décisions différentes et une reprise cohérente, sans raccourci impossible ou avantage bot.

### P1.C — Feel et ergonomie Android

- Ne changer coyote/buffer/JumpPower qu'après données de sauts ratés, temps de réaction, réception aux bords ; conserver le contrôle natif.
- Revoir caméra à hauteur d'avatar, collision caméra/structure, mouvements de FOV et HUD en 320–440 px, systèmes de priorité pendant Double Chaos.
- Fixer une grille de profilage : appareils Android faible/moyen/haut, Low/Medium/High, scènes calmes/denses, 10–30 min de jeu, CPU/FPS/p95 frame time, mémoire, températures, messages client.
- **Cibles de test à confirmer sur appareils :** >=30 FPS stable bas de gamme adapté, >=60 sur appareil capable si réalisable, zéro bouton inaccessible, zéro saut fantôme dans campagne de contrôle, zones de danger lisibles.

### P2.A — Rejouabilité réelle et communauté

- Exploiter la boucle déjà présente : résultat personnel immédiatement gratifiant → défaite expliquée → objectif pour manche suivante → relance automatique. Ajouter des défis **de compétence vérifiés serveur**, titres et parcours expert, pas des monnaies artificielles.
- Progression des cartes : maîtrise visible, records par parcours, défis hebdomadaires variés, collectibles non obligatoires, récompenses cosmétiques permanentes ; pas d'avantage payant de survie.
- Social : défi de record entre amis, performances comparables, emotes sûres, codes de partage/captures de résultat *sans exposition de données personnelles*.
- Bots : profiler leur taux de survie comparé aux humains par arène/danger/solo, corriger les passages non naturels ; ne pas employer « indiscernables » pour masquer qu'ils sont des bots auprès des joueurs.
- **Terminé si** les retours montrent volontairement une deuxième partie, une intention claire de rejouer pour mieux faire, et aucune inflation illimitée de récompenses.

### P2.B — Présentation et acquisition

- Capturer **les vraies** scènes du jeu : icône déjà acquise, miniature 16:9 authentique, galerie Android, bande-annonce 10–20 s (dangers, vrais transferts, victoire). Ne pas utiliser de faux gameplay.
- Optimiser texte de fiche Roblox, catégorie, accessibilité, onboarding visiteur; comparer les données de clic→entrée et de sortie de première minute aux cohortes réelles.
- **Terminé si** la page annonce fidèlement l'expérience et qu'une nouvelle personne peut décrire en 10 s ce qu'il faut faire.

### P0.C — Validation finale et déploiement unique public

- Jalon final : Build Validation + les cinq suites Open Cloud **sur le même commit**, puis Studio authentifié avec 5 arènes / Human+AI / enchaînement manches, 15 images réelles par carte si disponible, et Android physique.
- Vérifier 0 erreur bloquante, DataStore/rejoin, économie sans double gain, contrôle R6/R15, menace physique, streaming, fps et mémoire, contraste, réduire mouvement et audio.
- Publier **sur l'expérience publique existante seulement**, après critères ; faire correspondre le `versionNumber`, commit, SHA des artefacts et liens de logs. Garder rollback version précédente.
- **Terminé si** un même SHA certifié est réellement publié, reproduit et vérifiable ; aucune publication intermédiaire / privée.

## Ordre de production sans dispersion

1. **Correctif mesurable Harbor + vérité de la publication** (P0.A).
2. **Storm Harbor vertical et vaste, fini** (P0.B), inclut LOD/meshes/route/hazards/UX/AI.
3. **Transposer la qualité obtenue aux quatre autres arènes**, sans dégrader la jouabilité.
4. **Sons, animations et feedback** (P1.A), intégrés avec le nouveau level design.
5. **Équité des catastrophes et maîtrise des routes** (P1.B), y compris bots.
6. **Revue Android mesurée**, amélioration selon problèmes réels (P1.C).
7. **Objectifs de compétence + social + fiche Roblox** (P2), uniquement après le socle de jeu premium.
8. **Gate complet puis mise à jour publique** (P0.C).

## Score cible et acceptation finale

Viser **>=9/10** *après preuves visuelles indépendantes et métriques réelles*, aucun axe gameplay/art/perf critique <8/10. Conserver la capacité de rejouer cinq manches de suite sans blocage. Pour la première session, viser >=90 % de compréhension de l'action principale dans un test de nouveaux joueurs; suivre l'entrée en deuxième manche et la rétention J1/J7 avec cohortes réelles avant de fixer des objectifs business chiffrés. Ne pas déduire l'audience d'un nombre de scripts.

La note ne doit **pas** monter mécaniquement à chaque commit. Elle change seulement après des améliorations concrètes visibles, validées et, pour le produit public, publiées.
