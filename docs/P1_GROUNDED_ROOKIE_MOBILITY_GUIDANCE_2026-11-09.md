# P1 — guidage rookie vers des pads physiquement accessibles (9 novembre 2026)

**Lot :** première prise en main de Chaos Survival ; branche `feat/rookie-safe-pad-ready-guidance-20261109`.  
**Référence du code initial :** `main@0d334571560dac92d55190b02f19c1221b28959b`.  
**État :** code intégré dans une branche distincte, **pas fusionné ni publié**. La sortie publique P0 et les tests moteur du SHA actuel restent prioritaires.

## Défaillance identifiée dans le code source

`src/client/rookie-world-guide.client.lua` affichait pendant READY, uniquement sur ordinateur, un grand guide `ESCAPE_PAD` sur le pad le plus proche en **distance 3D**. La sélection ne contrôlait ni l'altitude, ni les murs, ni la présence d'un vrai sol continu. Sur les cinq grandes arènes, le repère pouvait donc suggérer une approche directe qui ne traversait pas une vraie route. Sur Android, le repère était entièrement désactivé pour éviter qu'un grand `BillboardGui.AlwaysOnTop` masque l'avatar. Enfin, le guide ignorait la capacité de présentation dégradée en cas d'indisponibilité temporaire des données et se limitait au premier round, alors que le HUD d'apprentissage couvre les **trois premiers**.

**Correction :** conserver la durée READY et la logique serveur actuelles ; n'afficher un guide que s'il pointe vers un vrai `ArenaMobilityPad` encore `CanTouch`, dans la vraie arène du `GeneratedMap`, au même niveau, accessible en approche directe, et sur un trajet échantillonné au sol physique.

## Implémentation

1. `nearestReachablePad` remplace l'ancien simple calcul de distance ; il filtre la distance horizontale (4–56 studs), la hauteur (5 studs), le parent réel, l'attribut `ArenaMobilityPad` et `CanTouch`.
2. Un raycast horizontal depuis le HumanoidRootPart rejette les obstacles collidables dans l'approche ; des raycasts verticaux adaptatifs (départ, arrivée, puis intervalles ≤3,5 studs) vérifient le support physique échantillonné du sol `Arena`, une normale de support suffisante, le vrai sol sous les pieds au départ et les transitions de hauteur (≤2 studs entre échantillons). Si **aucun** pad n'est vérifié : **aucune flèche ni marque trompeuse**. Ce n'est pas un pathfinder : les chemins contournés restent à parcourir librement, ils ne sont pas annoncés comme raccourcis directs.
3. Pendant le compte à rebours READY, PC conserve le grand repère uniquement lorsque cette approche est sûre. Sur écran tactile, le marqueur physique `Highlight` / anneau existant est autorisé mais **sans BillboardGui**, ni panneau supplémentaire ; les HUD de survie et de danger restent prioritaires. Tier Low : aucun nouvel anneau 3D (comportement de VfxQuality existant), seulement le Highlight quand vérifié.
4. Le repère reste limité aux **trois phases d'apprentissage** déjà définies dans `FirstTimeExperience.isGuidedPhase`. Aucun marqueur n'est visible pendant le Round, même les six premières secondes, pour éviter de pousser à travers un danger déclenché après READY ; il disparaît également lors des votes, morts, sorties de phase et changements de carte.
5. Une session dont DataStore est indisponible peut toujours afficher ce guide **en lecture seule** lorsque `DataLoadFailed` est confirmé ; aucune autorisation d'accès à une manche, transaction, récompense ni sauvegarde ne dépend de cet affichage.

**Performance :** mêmes événements `RoundState`/instances/attributs que le script existant ; au maximum huit pads par carte et dix-sept sondages de sol par candidat (distance ≤56 studs), lors du rafraîchissement existant de READY, aucune boucle `RenderStepped`, RemoteEvent ou scanner global. Les repères utilisent `markerFolder` et le nettoyage existant.

## Réception à exécuter dans Roblox Engine / client

- READY 1+7 sur Classic, Crossroads, Towers, Orbital, Harbor : si un pad est accessible en ligne droite sur le sol actuel, highlight correct ; si aucune ligne vérifiée, pas de faux chemin.
- Personnage sur passerelle haute ou derrière un mur réel : aucun pad du sol ne doit être marqué comme direct, même si sa distance 3D est petite.
- Trou de sol entre deux positions anciennement sondées : le nouvel échantillonnage adaptatif et les deux extrémités doivent rejeter ce faux chemin. Un intervalle inférieur à 3,5 studs peut toujours exiger une vérification physique sur appareil ; ne pas prétendre à une preuve mathématique de continuité.
- Début de manche / finale / résultat : highlight et billboard retirés ; jamais d'indication de traverser une zone létale.
- Android Low, Medium, High et portrait/paysage : pas de grand panneau en superposition, pas de modification des boutons saut/dash, pas d'avertissement masqué ; Low ne construit pas d'anneau 3D.
- Premier, deuxième et troisième READY : même règle et aucun guide persistant après la troisième manche.
- DataStore temporairement indisponible : guide facultatif uniquement ; aucune monnaie, victoire, progression ou achat attribué côté client.
- Vérifier visuellement un parcours d'environ cinq minutes à huit compétiteurs et contrôler le coût des raycasts/streaming ; ne pas annoncer un gain de FPS sans mesure.
- Si les obstacles de décor créent des rejets trop conservateurs, **conserver l'absence de repère** jusqu'à vérification d'un vrai chemin, plutôt que relâcher les contrôles de collision.

## Conditions de fusion et publication

La branche reste séparée du `main` existant pour ne pas invalider le gate de P0. Aucun test unitaire nouveau. L'intégrer après les réussites exact-SHA Build + Open Cloud et la publication du candidat précédent, puis vérifier ce lot au prochain jalon de release. Les tests automatisés sont nécessaires mais ne prouvent pas la qualité visuelle d'un guidage Android, laquelle dépend d'une capture de partie.
