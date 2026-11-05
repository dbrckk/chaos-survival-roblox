# Chaos Survival — nouveau plan premium V3 (5 novembre 2026)

## Objectif produit
Faire de Chaos Survival une expérience de plateforme-survie multijoueur **visiblement premium et réellement agréable à jouer**, sur Android comme PC : 5 arènes reconnaissables, 11 catastrophes, 8 participants au **début** des manches (humains + jusqu'à 7 bots), vraies interactions, mouvement convaincant et sortie de manche gratifiante.

La priorité n'est plus d'empiler des MeshParts et de grands effets. Il faut établir que la version réellement jouée présente les assets originaux, remplacer les gros volumes basiques **près du joueur**, rendre les parcours utilisables et les bots crédibles, puis terminer ensemble direction artistique, catastrophe, animation, son et UX.

**Règles :** fiabilité > fonctionnement réel > équité/sécurité > performances > impact visuel > fonctionnalités annexes. Un lot fini en qualité finale avant d'entamer le suivant. Pas de publication publique intermédiaire, pas de nouveau mock ou d'assets inventés. Tests moteur/build aux jalons importants seulement ; ne jamais confondre résultat CI et rendu Android.

## État réellement observé au 5 novembre 2026

- Dépôt : dbrckk/chaos-survival-roblox, branche main.
- Dernier SHA main inspecté : `8990b440645b733be79ff5946a34c2d5f52f9633` (correctif des spécifications Cloud de résidence 3D).
- Build Validation vert : https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42089242075
- Roblox Open Cloud Engine Tests vert : https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42089257938
- Dernier SHA de **publication publique vérifiée** : `9033d6799885ac32cf88222bbd07edace82e9266`, publisher vert : https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42082161343
- Universe 10771083668, starting place 95351659174730 : https://www.roblox.com/games/95351659174730/Chaos-Survival
- La nouvelle instrumentation `ClientOriginal3DResidencyPulse` est **en source main**, pas prouvée dans la publication publique au moment du plan. Aucun chiffre de modèles résidents en production ne doit être inventé.
- L'incident de connexion #563 reste « open » dans GitHub, ce qui **ne démontre pas** que le blocage persiste aujourd'hui. Vérifier une connexion neuve, puis clore seulement avec preuve : https://github.com/dbrckk/chaos-survival-roblox/issues/563
- Les cinq cartes ont une base 320×320, mais la surface totale n'est pas un indicateur de qualité du parcours. Les MeshParts 3D et matériaux PBR sont déjà largement intégrés en source ; leur couverture réelle Low/Medium/High sur appareil manque encore de validation.
- Document antérieur de référence : ROADMAP_POST_PUBLIC_2026-11-05.md. Ce V3 **réordonne et rend vérifiables les lots**, sans effacer ses contrats ni les exigences de RELEASE_CHECKLIST.md.

## Priorités, séquence et contrats de fin

### Lot 0 — vérité du runtime, version publique et problèmes bloquants (P0, bref et transversal)

1. Confirmer le SHA / Roblox version de la place jouée ; démarrer au moins une vraie session Android et une nouvelle session, lobby puis manche puis résultat ; qualifier #563 sans supposition.
2. Enregistrer des prises de vue authentiques du spawn, de la route et d'un danger dans les 5 cartes, et classer S0 (impossible de jouer), S1 (déplacement/bot/danger trompeur), S2 (visuel), S3 (détails).
3. Croiser les compteurs `LocalOriginal*` et les fallbacks natifs avec les captures ; les données `ClientOriginal3DResidencyPulse` ne deviendront production qu'après publication du code qui les émet.
4. S'il manque une session Studio authentifiée, documenter « non validé sur appareil » et poursuivre l'intégration des gros lots de code, sans capture simulée.

**Terminé :** version publique connue, S0 identifiés/corrigés, statut de preuves transparent, pas de confusion source/public. Ne pas en faire une longue phase d'infrastructure.

### Lot 1 — vrai premier plan 3D de qualité finale sur les cinq cartes (P0 visuel)

**Modules existants à réutiliser :** `PremiumRouteMeshKit`, `PremiumPlatformSideMeshKit`, `PremiumGroundMeshKit`, `PlatformNativeTrimReplacementKit`, `SkySpineCrownMeshKit`, les kits approuvés propres à Harbor/Towers/Orbital ; collisions et `MapBuilder` restent autoritaires sur serveur.

1. Inventorier les gros volumes visibles dans un rayon fonctionnel de 80 studs autour du joueur, en séparant plancher jouable, sécurité et décor ; retenir d'abord les surfaces occupant le plus d'écran.
2. Remplacer les formes primitives dominantes par les vrais Models approuvés : sols, flancs, carapaces, châssis, jonctions, portiques, piliers, escaliers, dessous de passerelles et structures de lobby ; une sculpture doit **couvrir réellement** la forme qu'elle prétend remplacer.
3. Garantir le masquage atomique : ne cacher les éléments natifs qu'après montage réussi et restituer immédiatement au retrait du mesh, streaming, changement de tier, Collapse, ShrinkingArena ou shutters.
4. Harmoniser les UV, normal/roughness/metalness et textures approuvées là où l'échelle écran le justifie ; Low garde un rendu propre et plus simple. Ne pas multiplier les modèles lointains lorsque le sol proche reste cubique.
5. Terminer une famille entière par carte, sans cinq séries de décorations mineures.

**Cible de réception :** sur High, ≥90 % des **grandes structures cosmétiques jouables cadrées** ont des silhouettes 3D crédibles, évaluées par inventaire + captures, et non sur un comptage théorique d'IDs ; aucune vraie collision ni avertissement n'est masqué, Low propre et repli fiable.

### Lot 2 — cinq arènes réellement vastes et riches en décisions (P0 gameplay)

1. Exploiter d'abord les 320×320 existants, sans augmenter aveuglément BaseSize. Depuis chaque secteur principal, au moins deux options franchissables : trajet rapide/risqué, détour sûr, route verticale/échappatoire.
2. Créer ou finir une signature de parcours et de menace **physique** pour chaque monde : Classic (grille/relai), Towers (hauteur/portes), Crossroads (aiguillage), Orbital (hélix/anneau), Harbor (quais/cargos/passerelles).
3. Les silhouettes, les flèches et le HUD pointent vers de vrais points sûrs du serveur, dont les changements sous catastrophe sont répliqués. Pas de skybridge décoratif présenté comme passage.
4. Tester départs, retour lobby, catastrophe et accès périphériques avec R15, R6 si supporté, sauts tactiles et bots. Garder des options de reprise au cours des catastrophes.

**Réception :** cinq cartes jouables, ≥2 routes viables à chaque choix principal observé, 0 route impossible annoncée comme praticable, aucune zone isolée sans avertissement raisonnable, orientation du joueur reconnaissable en caméra réelle.

### Lot 3 — bots crédibles et huit participants initiaux (P0 engagement)

1. Préserver la cible **8 participants en début de manche**, humains en priorité puis ≤7 bots ; zéro remplacement magique des participants éliminés.
2. Terminer la chaîne `perception réelle → objectif atteignable → marche/saut/évitement → récupération → prochaine décision` dans `AISurvivorService` et `AISurvivorRules`; profiter des correctifs source déjà intégrés le 5 novembre sur les shutters, obstacles et corridors vivants.
3. Retirer zigzags, coupes d'angles, marches contre les murs, hésitations invraisemblables, faux sauts et collisions répétées ; varier les comportements sans triche physique ni téléportation.
4. Rendre plus humains le regard, l'anticipation, l'accélération, la réception, les gestes et la réaction sociale, en conservant la distinction bot/humain dans les données.

**Réception de test :** aucun bot bloqué sans stratégie de reprise >3 s dans les scènes QA, aucun saut sur plateforme supprimée, activité crédible et mesurée dans 5 arènes/11 dangers, dégradation FPS 7 bots observée sur Android.

### Lot 4 — lumière, matériaux, identité des cinq mondes (P1)

1. Calibrer caméra identique sur chacune des cinq cartes en lobby, READY, manche, nuit/atmosphère et Darkness, par tiers de qualité.
2. Renforcer les différences de monde par volumes architecturaux, profondeur, météo ambiance, surfaces, mobilier et lumières motivées — pas par simple couleur/néon.
3. Corriger surexposition, noirs bouchés, brouillard et ombres qui masquent le joueur, le chemin ou les alertes ; conserver Darkness volontairement difficile mais équitable.
4. Vérifier PBR réel, UV, cartes normales, rugosité, métallicité, reflets et streaming des matières ; limiter PBR 2K et lumières dynamiques sur Android aux surfaces de fort impact.

**Réception :** 5 cartes reconnaissables sans HUD, 0 danger caché, contrastes sûrs en Low/Medium/High, avant/après authentiques et scores VISUAL_QA_SCORECARD fondés.

### Lot 5 — catastrophe spectaculaire ET interaction joueur-monde (P1)

1. Réviser les 11 catastrophes : préavis identifiable → changement de l'environnement → danger réel cohérent → conséquence visible → nettoyage. Reprendre en priorité Meteor/Bomb, Lava, Tornado, Collapse, Darkness et Double Chaos.
2. Exploiter et terminer les mécanismes déjà en code (`TeamDashRelay`, `SkybridgeShutters`, `ArenaSkyShieldNetwork`, `RoundCollectibles`, mécanismes Harbor) avant d'en inventer d'autres.
3. Fournir au moins **deux choix tactiques réellement utilisés** par monde : détour, couvert, interrupteur, entraide, abri ou traversée risquée ; jamais seulement un VFX non interactif.
4. Faire réagir de grandes structures et le son à la menace, tout en respectant le collider serveur et le budget Low.

**Réception :** 11 dangers distinguables sans leur titre, interactions réellement utilisées et synchronisées, 0 avertissement trompeur, 0 VFX restant après 10 manches, bots/humains soumis aux mêmes règles.

### Lot 6 — sensations, animations, son, lisibilité Android et satisfaction (P1)

1. Produire/autoriser des clips R15 de locomotion, arrêt, saut, réception, esquive, victoire, réaction bot ; transitions fidèles au mouvement physique et fallback R6. Remplacer les sons historiques non premium et améliorer ambiances, spatialisation, mix et musique.
2. Une seule priorité à l'écran : ENTRER → VOTER → SE PRÉPARER → SURVIVRE → RÉSULTAT → REJOUER. Conserver FR/EN, alertes devant cosmétiques et contrôles tactiles accessibles.
3. Rendre objectif et première vraie action compréhensibles sans texte long ; le résultat affiche victoire ou cause d'élimination, récompense serveur réelle et motivation à relancer immédiatement.
4. Protéger ReduceMotion, daltonisme, le gameplay muet, l'occlusion caméra, les joueurs en portrait et le freinage/FOV sur Android.

**Réception :** objectif expliqué par un novice en ≤10 s après contrôle du personnage (cible à mesurer), aucun résultat de round absent, aucune animation de glissement flagrante, aucun son Roblox générique dominant, commandes tactiles fiables.

### Lot 7 — performances, fiabilité, sécurité et rétention (P0 de livraison + P2 produit)

1. Préserver les propriétaires existants de LOD et performance, les quotas MeshParts/Lights/Effects, les contrôles serveur et l'anti-abus ; pas de seconde boucle de rendu ou RemoteEvent superflu.
2. Mesurer 30 minutes sur Android modeste/moyen et PC : FPS, p95 frame time, mémoire, chauffe, streaming tardif, rejoin après suspension, 7 bots. Cibles de départ : ≥30 FPS soutenus sur appareil faible capable avec Low, ≥60 visés sur appareil adapté ; critères à ajuster au matériel mesuré, jamais inventés.
3. Tester sauvegarde, récompenses/monétisation non P2W, cycles de manche, retour lobby, effets supprimés, transitions Low↔High et panne/latence réseau.
4. Utiliser les événements `GameAnalytics` existants : entrée en première manche, réussite, entrée en seconde, départ première minute, D1/D7 quand échantillon suffisant ; ne pas ajouter de monnaie ou de système de collection avant de confirmer les défauts de boucle.

**Réception :** aucune régression critique, pas de fuite mémoire manifeste, suivi reproductible et appui sur données réelles.

### Lot 8 — une seule publication majeure certifiée (P0 final)

1. Geler la source, auditer le registre d'assets, les permissions, le plan de rollback et les licences.
2. Au **SHA final exact**, Build Validation + sept suites Roblox Open Cloud réellement exécutées, release gate, tests Studio authentifiés et Android/PC.
3. Capturer les cinq cartes et tous les types majeurs de danger ; vérifier huit participants au départ, retours de manche, persistance, UI et performance.
4. Publier uniquement l'expérience publique existante (universe 10771083668, place 95351659174730) via workflow gardé ; confirmer version Roblox et nouvelle session, conserver le rollback.

**Réception :** le SHA certifié est effectivement publié, un humain peut entrer, jouer et relancer sans incident S0/S1 ; progrès visuel et technique attesté par captures/mesures.

## Cadence et classement

- **Maintenant :** Lot 0 bref (vérifier public/source et barrières). Il n'interrompt pas indéfiniment le travail artistique.
- **Prochain gros chantier :** Lot 1 sur la géométrie proche caméra, avec continuité de route, vrais modèles et fallback ; puis Lot 2 (navigation/choix) et Lot 3 (bots). Ne pas recommencer la skyline lointaine sans bénéfice observé.
- **Finition :** Lots 4–6, puis 7 transversal et 8 final.
- **Statuts à écrire pour chaque chantier :** À faire / Code intégré / Build + Cloud même SHA / Visuel appareil validé / Publié. Toute déclaration doit posséder son SHA et ses preuves.

## Fichiers de référence
- `docs/ROADMAP_POST_PUBLIC_2026-11-05.md` : détail de la version V2 et publication.
- `docs/LOT0_PUBLIC_REAL_3D_RESIDENCY_OBSERVABILITY_2026-11-05.md` : observabilité 3D ajoutée en source.
- `docs/NEXT_PREMIUM_PRODUCTION_ROADMAP_2026-11-04.md` : contexte et contrats d'art/IA.
- `docs/VISUAL_QA_SCORECARD.md`, `RELEASE_CHECKLIST.md`, `ROLLBACK_RUNBOOK.md` : critères immuables de réception.
- `assets/source/roblox-asset-registry.json` : IDs et provenance, pas preuve de visibilité.

**Prochaine action d'implémentation :** terminer et mesurer les grandes coques de plateformes, flancs, jonctions et sous-châssis authentiques effectivement visibles à hauteur du joueur dans les cinq arènes, en conservant l'autorité des colliders/dangers serveur et la restauration native en streaming. Aucun déploiement implicite.
