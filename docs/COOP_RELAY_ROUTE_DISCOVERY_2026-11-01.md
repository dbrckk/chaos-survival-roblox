# Coopération DASH — stations accessibles sur les vrais trajets (1er novembre 2026)

## Constat vérifié dans le source

À la publication de `46263cbdced1bddf002a8d57867303eb21422c2f`, les deux stations `TeamDashRelay` essayaient d'abord les coordonnées `(-68, 45)` et `(68, -45)` : à environ 81,5 studs du centre. `TeamDashRelay.BotApproachRadius` est limité à **68 studs**, et la recharge partagée aux humains présents dans un rayon de **29 studs**. Un bot placé près du hub central ne peut donc pas même choisir la station comme destination. Les routes initiales et les huit spawns des cinq arènes se concentrent surtout autour de 12 à 51 studs. Le relais fonctionnait, mais avait peu de chances d'être trouvé et utilisé durant une manche solo de 30 secondes.

## Correction source appliquée

- **Deux stations maximum, toujours serveur-autoritaires**, équipées du même `ProximityPrompt`, du même dash réel et des mêmes limites d'activation. Aucun nouveau RemoteEvent, DataStore, mécanisme payant ou boucle de rendu.
- Chaque côté privilégie quatre nouvelles positions **réparties autour des routes accessibles** : environ `(-55,20)` et `(55,-20)` en premier choix, puis trois autres solutions de proximité.
- Les quatre anciennes positions de chaque côté sont conservées comme **fallback** si les nouveaux emplacements sont bloqués par une structure réelle.
- Avant l'installation, `SpawnSafety.clearAt` valide l'espace R15 au niveau du sol, et un second garde-fou rejette un relais à moins de **12 studs horizontalement d'un des huit marqueurs d'apparition**. On ne remplace jamais une collision de jeu par un décor non-collidable qui obstrue le personnage.
- La portée de lecture du petit panneau passe de **110 à 95 studs**. Les deux étiquettes restent attachées au monde et masquées par les obstacles ; pas de nouveau panneau permanent sur écran Android.
- Le rayon d'aide (29), de recherche IA (68), d'interaction (9), de validation serveur (12), le délai (0,65 s), la santé, la nécessité d'être au sol et les gardes de fin de manche sont **inchangés**.
- Une manche peut encore créer moins de deux stations si le terrain ne présente aucun emplacement valide : priorité à la sécurité physique, pas à un compteur de succès fictif.

## Effet attendu, non revendiqué comme observé

Un bot qui se trouve dans le hub principal peut détecter les nouveaux emplacements : premier choix de chaque côté à environ **58,5 studs**, sous sa limite de 68. Les humains proches des routes peuvent bénéficier de la recharge coopérative sans aller jusqu'aux extrémités désertes. Ce résultat est **géométrique et déduit du code** ; il ne remplace ni métrique d'utilisation ni validation en session réelle.

## Validation exigée au prochain jalon (aucun test pendant la phase d'amélioration)

1. Sur un **SHA figé** : Build Validation et cinq suites Open Cloud, puis Studio authentifié et Android.
2. Tester les cinq cartes, deux stations créées lorsque possible ; contrôler positions physiques au sol, 12 studs libres autour de chaque spawn, HUD libre, aucun chemin coupé, et comportement pendant `ShrinkingArena`, `RisingLava`, `Meteors` et `DisappearingPlatforms`.
3. Tester solo **1 humain + 7 bots**, puis 2+6 et 8+0. Un bot doit voir le relais, y courir réellement (sans téléportation), s'arrêter, puis n'activer que si un humain vivant est dans le rayon et reçoit réellement son DASH.
4. Valider `ProximityPrompt` sur tactile et clavier, recharge en cooldown, réserve non-cumulable, retour de résultat, déconnexion, mort, activation concurrente, panne de montage et nettoyage entre deux manches.
5. Lire les métriques existantes `TeamDashRelayUsed` (humain) et `TeamDashBotHelped` (IA) par arène ; comparer aux manches jouées et aux humains actifs, sans traiter une activation NPC comme une interaction entre humains.
6. Mesurer les FPS et la fluidité Android avec sept rigs R15. Garder les zones de fuite lisibles, plutôt que d'encourager le joueur à interagir au détriment de sa survie.
7. Mettre à jour la place publique **seulement** après le gate exact-SHA et conserver une possibilité de rollback.

## Livraison

Cette correction et la mise à jour de README appartiennent à une **branche source** ; elles ne sont **pas** intégrées à la publication vérifiée `46263cbd...` du 1er novembre tant que la branche n'a pas été intégrée puis publiée. Le workflow public validé sur ce SHA est [41322662162](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41322662162), avec [Build Validation](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41322299252) et [cinq suites Roblox Cloud](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41322305051).

## Prochain goulot produit

Après certification, regarder le taux d'utilisation réel des relais, l'identité visuelle de chaque carte, les sorties entre manche 1 et 2, les erreurs d'accès aux parcours, et l'Android Low. Une amélioration du code n'est pas automatiquement une note d'expérience supérieure.
