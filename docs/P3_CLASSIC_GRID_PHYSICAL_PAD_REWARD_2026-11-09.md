# P3 — Classic Grid : un vrai choix de mobilité après le circuit

**9 novembre 2026.** Préparé depuis `main@ae4ae044e991ef4ca28a991991f2e11b9df49c84` sur `feat/p3-classic-grid-earned-pad-boost-20261109`. P2 a passé [Build Validation #42633546073](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42633546073), [Roblox Engine #42633618547](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42633618547) et sa [publication publique #42650986552](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42650986552) sur ce même SHA. **P3 n'est pas encore publiée ni certifiée sur moteur.**

## Constat source

Le défi `GridCircuitService` vérifie correctement la traversée chronométrée de 4 capteurs physiques en ordre horaire, avec suivi serveur par joueur ou bot, et `grid-circuit.client.lua` fournit un HUD FR/EN. Jusque-là, le parcours réussi validait le défi mais **ne changeait pas de choix de déplacement** ; les pads Classic donnaient la même impulsion avant/après réussite.

## Livraison proposée : boost unique et physique

1. Après un vrai `GridCircuitRules.advance(...)` qui retourne `completed=true`, le **serveur** attribue une charge `RoundGridCircuitBoostReady` (Player) ou `GridCircuitBoostReady` (modèle NPC). Une tentative incomplète, hors ordre, expirée ou répétée n'offre pas de charge.
2. Sur le prochain pad Classic que le participant **active physiquement** : l'impulsion existante est multipliée par **1,28**, puis repasse à la normale. Les deux chemins gardent la limitation `MovementSafety.addImpulse` (horizontal 60, vertical -52 à 58), les collisions ordinaires, la vitesse réelle du rig et le cooldown du pad. Aucun téléport, immunité, monnaie supplémentaire ou objet acheté.
3. Si un overdrive de manche est déjà actif, le pad conserve son comportement normal **et ne consomme pas la charge** : elle reste disponible jusqu'au prochain pad classique sans overdrive au cours de la même manche. Rien n'est réutilisable à la manche suivante.
4. Le chemin humain utilise `ArenaMechanics.start` et `ctx.IsContestantActive` ; le bot utilise `AISurvivorService.tryPadImpulse` sur son **vrai modèle vivant**, et le reset par `AISurvivorService.resetGridCircuit`. Même récompense et limites physiques, sans bot-only avantage.
5. Le HUD `grid-circuit.client.lua`, déjà rafraîchi et non intrusif sur Android, indique **BOOST PRÊT** puis **BOOST UTILISÉ** en FR/EN. `src/server/init.server.lua` réinitialise aussi la charge à **chaque manche**, même si la nouvelle arène n'est plus Classic. Aucun nouvel écran, boucle client, RemoteEvent, module ou asset factice.
6. Le challenge reste facultatif et le parcours libre reste viable sans le réussir. Ce lot n'ouvre pas de passerelle imaginaire, ne modifie aucun collider et ne touche pas aux statistiques de victoire.

## Réception nécessaire

- Classic, 1 humain + 7 bots, 4 stations successives en 20 s : après la dernière, la charge apparaît côté serveur et dans le HUD du joueur. Avancer hors ordre, après expiration ou avec un personnage mort n'attribue rien.
- Toucher un pad Classic actif : une seule impulsion majorée **sans dépasser MovementSafety** ; la charge devient fausse et le HUD indique « utilisé ». Toucher le pad suivant n'applique pas de second boost.
- Overdrive global actif : la charge n'est ni consommée, ni ajoutée à une impulsion déjà surmultipliée ; le premier pad ultérieur hors overdrive la consomme.
- Un bot ayant **physiquement** fini le circuit bénéficie du même boost au premier pad accessible qu'il emprunte ensuite ; aucun attribut joueur ou récompense persistante n'est écrit pour ce bot.
- Au changement de manche et de carte, `GridCircuitService.start` et `AISurvivorService.resetGridCircuit` remettent les charges à zéro. Rien n'est transmis au tour suivant.
- Android Low/Medium/High, jauges et alertes de Double Chaos : aucune superposition gênante, le HUD se retire hors Classic/ROUND ; les alertes mortelles restent prioritaires.
- Vérifier la consommation en cas de touche simultanée : **pas de double attribution**, grâce au cooldown existant de chaque joueur et au drapeau serveur remis à faux avant toute seconde touche ; les NPC gardent `nextPadAt`.
- Avant toute publication : Build Validation + Roblox Open Cloud Engine Tests sur **le SHA exact de main après fusion**, puis envoi vers le même univers/place public. La revue de code seule **ne certifie pas** le gameplay ni le rendu physique Android.

## Dépendances et garde-fous

Ce lot ne change que `src/server/GridCircuitService.lua`, `ArenaMechanics.lua`, `AISurvivorService.lua`, `init.server.lua`, `src/client/grid-circuit.client.lua`, `src/shared/GridCircuitRules.lua` et ce document. L'implémentation P3 est indépendante de la cadence IA P2 désormais **publiée**. P3 peut être fusionnée dans `main` ; le nouveau commit exigera sa **propre** validation Build/Roblox Engine et une publication distincte, sans supposer que les résultats verts du SHA P2 restent valables.

**Mesures non obtenues :** aucun gameplay observé sur Android pour cette branche, aucune statistique de part de circuit terminé ou de boost consommé, aucun gain de rétention ni de FPS mesuré. Les nouveaux attributs ne sont pas de la télémétrie.
