# Chaos Survival — audit ciblé de star-list (21 octobre 2026)

## Périmètre et décision

Inventaire inspecté : `dbrckk/star-list` branche `main`, `catalog.json` (**1 023 dépôts**), `websites.json` (**14 sites**), `AGENT_SKILLS.md`, `WEB_RESOURCES.md` et dépôts sources des candidats prioritaires. Le tri initial porte sur **toutes les entrées du catalogue**, par métadonnées, domaine, compatibilité et usage ; il ne prétend pas avoir audité chaque ligne de code de 1 023 projets. Les README de six outils Roblox/3D les plus spécifiques ont été lus, et les références Web prioritaires ont été consultées.

Les notes ci-dessous évaluent exclusivement l'utilité probable **pour Chaos Survival Roblox/Luau**, sur 5. Elles ne mesurent ni le niveau de sécurité, ni la conformité des licences, ni le score général de star-list. Source d'implémentation : `dbrckk/chaos-survival-roblox`, Luau + Rojo, quatre arènes, onze catastrophes, bots Solo Rush, protections serveur des récompenses, tests moteur Open Cloud. Les scripts existent déjà : ne pas remplacer les systèmes par un moteur tiers.

| Rang | Référence présente dans star-list | /5 | Utilité concrète | Nature / réserve |
| ---: | --- | ---: | --- | --- |
| 1 | [Chrrxs/robloxstudio-mcp](https://github.com/Chrrxs/robloxstudio-mcp) | **5,0** | Tester réellement Studio solo/multijoueur, capturer logs, micro-profiler, mémoire et captures ; reproduire victoire → récompense → nouvelle manche et vérifier les IA. | Outil de production, pas code de gameplay ; demande Roblox Studio sur une machine prise en charge et un contrôle explicite des permissions. MIT indiqué au catalogue. |
| 2 | [TabooHarmony/roblox-brain](https://github.com/TabooHarmony/roblox-brain) | **4,9** | Guide spécialisé Luau, réplication, NPC, physique, UI, sécurité, expérience et analyse. Réduire les régressions dues aux modifications assistées par agent. | Référentiel de connaissances ; vérifier les instructions avant de les charger ; MIT indiqué au catalogue. |
| 3 | [Game Art Style](https://gameartstyle.loopyhop.com/) | **4,9** | Références de styles pour fixer une vraie direction artistique différenciée par arène : silhouette, matières, couleur, contraste, landmarks et composition, au lieu d'empiler des néons génériques. | Référence visuelle uniquement ; ne pas copier les captures et assets d'autres jeux. |
| 4 | [ahujasid/mcp-for-blender](https://github.com/ahujasid/mcp-for-blender) | **4,7** | Créer des mesh originaux, structures d'arène, props détaillés et animations, puis préparer un pipeline d'export/import Roblox. | Blender externe obligatoire ; validation des droits, échelle, collisions, budgets triangles et textures ; MIT indiqué au catalogue. |
| 5 | [S4US/Roqer](https://github.com/S4US/Roqer) | **4,6** | Assistant Roblox Studio capable d'aider à produire scripts, VFX, éléments de monde et playtests itératifs. | Haute complexité ; licence AGPL-3.0-or-later, évaluer impacts juridiques et accès agent avant usage ; aucun auto-déploiement. |
| 6 | [PINOC MCP / Viggle](https://viggle.ai/pinoc/mcp) | **4,5** | Presets de mouvement / mocap pour remplacer l'aspect « animation Roblox standard » des célébrations, locomotions et émotes. | Presets libres à consulter, génération avec crédits ; exports GLB/FBX ne garantissent pas retarget R15 ni import Roblox ; authentification requise. |
| 7 | [ShiroKSH/skills](https://github.com/ShiroKSH/skills) | **4,5** | Workflow Roblox Studio inspecter → SceneSpec → prévisualiser → appliquer → valider → playtester pour des arènes/modèles plus complexes, avec Undo et dossiers de brouillon. | Étiquette `audit` dans star-list : revue de sécurité avant toute autorisation d'écriture ; nécessite Studio et Node. |
| 8 | [60fps.design](https://60fps.design/) | **4,4** | Inspirations de micro-interactions pour le vote, les résultats, les unlocks, la hiérarchie HUD et le confort tactile sur mobile. | Références, pas composants Luau directement réutilisables ; respect des droits des designers. |
| 9 | [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | **4,3** | Techniques d'art direction et production visuelle, gameplay, performance et pipeline game dev avec sections Roblox. | Agrégateur de SKILL.md ; `audit` dans star-list : chaque skill doit être relu avant tout chargement. Apache-2.0 indiqué au catalogue. |
| 10 | [Skill Issue](https://skill-issue.in/) | **4,2** | Index de compétences ciblées design, game dev, motion et automatisation ; orienter les futures tâches vers une expertise plus spécifique. | Répertoire de découverte, pas gestionnaire de dépendances sûr ni exécuteur ; lecture/revue humaine requise pour les scripts tiers. |

**Exclusions volontaires :** Godot, Unity, Unreal, React Three Fiber et Nakama ne s'intègrent pas directement dans le runtime Roblox ; `roblox-ts` impliquerait de migrer la base existante Luau sans nécessité démontrée ; les anciens MCP Roblox archivés ne doivent pas être prioritaires. Le lien Jupiter the Warlock est conservé dans star-list mais sa page n'a pas pu être chargée indépendamment pendant cette revue : pas d'affirmation sur son contenu ni de copie d'asset.

## Ce qui fera le plus évoluer le jeu

### Vague 0 — fiabilité avant extension du contenu (bloquant)

- **Victoire et rejouabilité** : vérifier dans un vrai client Studio et Android le parcours rejoindre → voter → READY → survivre → écran résultat visible → Coins/XP → retour lobby → **nouvelle READY** → nouvelle manche. En solo et à plusieurs ; rejouer au moins 5 manches successives. Vérifier absence de double paiement, absence de carte de résultat obsolète, aucun personnage bloqué.
- **Robustesse solo** : les bots doivent apparaître, naviguer, subir les mêmes dangers, donner une sensation de compétition et disparaître/nettoyer correctement à chaque cycle.
- **Observabilité** : capturer erreur serveur, erreur client, FPS sur Android, mémoire, latence, temps de chargement, échec de round ; corriger les problèmes reproductibles avant d'introduire des plugins externes.
- **Livraison** : distinguer HEAD GitHub, version de place réellement publiée et session de test ; ne pas annoncer de déploiement Roblox tant que non confirmé.

### Vague 1 — refonte artistique de quatre arènes (meilleur impact perceptible)

Définir une charte globale *sci-fi survival-show haut de gamme*, puis une identité distincte par arène :
- **Classic** : grille/émission télévisée futuriste, radar central et signalétique broadcast.
- **Towers** : verticalité industrielle, ascenseurs, machinerie, étages et profondeur réelle.
- **Crossroads** : gare/transit futuriste, directions franches, passerelles et panneaux de route.
- **Orbital** : station mécanique spatiale, gyroscope, structures circulaires et skyline.
- Préparer des **mesh originaux** cohérents dans Blender, avec collisions simples et LOD, puis exporter/importer uniquement après contrôle taille/performance. Ne pas réduire la lisibilité des signaux Meteor/Bomb/Lava ni obstruer les mouvements/pads.

**Critère de validation :** une capture neutre de chaque arène doit être immédiatement identifiable sans lire le nom, et les routes sûres doivent rester lisibles en moins d'une seconde sur un vrai écran Android.

### Vague 2 — interaction et animation (plaisir de la minute de jeu)

- Clips d'animation authored R15 originaux/à droits confirmés : idle, course, réception, propulsion, élimination, victoire, célébrations et deux émotes sociales. Garder le fallback procédural existant et Reduce Motion.
- Repenser le **moment de victoire** : présentation compréhensible du gagnant, récompenses effectives, objectif de prochaine partie, transition automatique sans action requise. Pas de mécanisme aléatoire payant.
- Reprendre le **HUD Android** selon priorité danger → objectif → chrono → récompense. Améliorer les transitions vote/READY/résultat sans masquer les warnings.
- Établir une bibliothèque sonore originale ou explicitement licenciée : identité par danger/arène, mix propre, ducking pendant les moments critiques.

**Critère de validation :** nouveaux joueurs comprennent la première partie sans explication externe ; chaque manche offre au moins une décision/interaction perçue ; les transitions ne perturbent pas les commandes sur mobile.

### Vague 3 — engagement réel et découverte

- Tester plusieurs rounds en solo et entre amis avec joueurs réels ; mesurer retour deuxième manche, troisième manche et durée de session, puis ajuster équilibre.
- Mieux distinguer mécaniques et routes à risque/récompense pour éviter que quatre arènes n'aient le même gameplay.
- Produire de **vraies captures Roblox** d'une version testée, miniature 16:9 et courte vidéo authentique ; la fiche publique et la place ne se mettent pas à jour depuis GitHub automatiquement.
- Équilibrer objectifs quotidiens, maîtrise, collection cosmétique et récompenses en respectant l'économie et l'équité existantes.

## Règles d'intégration et portes de qualité

1. **Ne pas installer les dix ressources** : choisir un outil selon un manque démontré ; la plupart sont externes au runtime. Vérifier révisions, licence, permissions, coûts, assets, modèles et consignes tierces ; les répertoires/skills ne constituent pas une autorisation d'exécution.
2. Pour toute nouvelle fonctionnalité, utiliser une branche dédiée ; protéger le serveur, les données joueur, la compatibilité Rojo/Luau et les paramètres Low/Medium/High.
3. Exécuter les validations existantes (**Build Validation**, **Roblox Open Cloud Engine Tests**) avant de fusionner ; pas de nouveaux tests unitaires conformément à `AGENTS.md`.
4. Tester ensuite sur une vraie session Studio et au moins un Android cible. Les captures générées hors du jeu ne prouvent pas le rendu réel ; les tests moteur ne certifient pas les FPS et le toucher.
5. La revue art, animation, sons et UX doit viser un ensemble harmonisé, pas simplement le nombre d'assets.

## État précis à la rédaction

La PR [#117](https://github.com/dbrckk/chaos-survival-roblox/pull/117) a été fusionnée dans `main` (commit `36e94cb43d61c8e6fbcb0ceb8111aa67a78bf6f8`) pour préserver la carte de victoire pendant RESULT et rejeter des récompenses/overlays périmés. La Build Validation a réussi sur le commit `main`; les tests moteur de la branche PR ont réussi, mais ceux du commit fusionné étaient encore en file d'attente lors de la vérification. Aucune publication de cette version dans Roblox ni certification Android n'est revendiquée.
