# Chaos Survival — restitution de caméra spectateur et explosion Double Chaos

31 octobre 2026 — correction de code client, **sans audit visuel réel des cartes**, test moteur Roblox Studio ni publication.

## Défauts constatés dans le code

- Le spectateur réexécutait `refresh()` à chaque `RoundState`. En mode spectateur, `spectateIndex(false)` forçait `CameraType = Custom` puis `CameraSubject = humanoid`, y compris lorsqu'une cinématique extérieure venait de réclamer une caméra `Scriptable`.
- À la sortie du mode spectateur ou en pratique lobby, `restoreCamera()` imposait toujours la caméra sur le propre Humanoid du joueur, **même si ce script n'en était plus propriétaire**. Les scènes de manche, respawns et autres directeurs de caméra pouvaient être interrompus par une actualisation serveur périodique.
- `spectator.client.lua` appliquait les snapshots `RoundState` plus anciens, pouvant réactiver une cible spectateur d'une manche terminée.
- `hazard-impact-feedback.client.lua` gardait ses explosions locales jusqu'à `Debris` même lorsqu'un nouveau résultat, une autre manche ou un remplacement de carte avaient déjà eu lieu. Les callbacks `task.delay` décrémentaient `activeBursts` sans connaître la manche d'origine ; une remise à zéro naïve du compteur aurait fait perdre des places d'explosion à la manche suivante.
- Le profil d'explosion utilisait `VfxQuality.get(nil)` (High par défaut) sur Android avant que le régulateur de FPS ne publie le premier palier.

## Modifications

1. **Propriété caméra précise** : le spectateur garde `ownedCamera` et `ownedSubject` uniquement lorsqu'il choisit effectivement un `Humanoid`. La restitution vers le `Humanoid` local exige que la caméra courante et sa cible correspondent encore exactement à cette propriété ET qu'elle soit `Custom`. En cas de changement externe, le script ne force aucune propriété. Les cinématiques `Scriptable` sont respectées même pendant les snapshots répétés.
2. **RoundState ordonné** : ignorer les snapshots numérotés d'une manche antérieure, afin de ne pas imposer une ancienne cible spectateur après le démarrage de la suivante. Les événements non numérotés demeurent compatibles.
3. **Nettoyage local des explosions** : les pièces/anneaux/ancres et fragments propres à `ImpactSetpieceLocal` sont supprimés seulement lors d'une vraie transition de phase, d'un nouveau numéro de manche ou du retrait de `GeneratedMap`, sans suppression des avertissements ou hitboxes serveur.
4. **Compteur Double Chaos robuste** : `burstEpoch` est augmenté lors du nettoyage ; les anciens callbacks de durée de vie ne décrémentent pas le quota `activeBursts` d'une nouvelle manche. Pendant une manche inchangée, le budget et la densité visuelle habituels sont préservés.
5. **Android** : `VfxQuality.deviceTier(tier, TouchEnabled)` active Medium avant la première mesure sur appareil tactile, High sur PC. Le rendu d'impact accepté avant le premier `RoundState` reste autorisé pour ne pas supprimer la première explosion sur un client en streaming lent ; dès la première phase connue, les explosions cosmétiques sont limitées à la phase `round`.

## Vérification différée au jalon de publication

- Exécuter **Build Validation + les cinq suites Roblox Open Cloud** sur le SHA exact de `main` puis essayer sur Android réel et PC.
- Observer plusieurs joueurs éliminés, changer de cible, quitter le mode spectateur, passer en pratique lobby et revenir : pas de blocage sur une cible obsolète, caméra du joueur restaurée sans interrompre une cutscene.
- Pendant une cinématique `Scriptable`, recevoir dix snapshots successifs `RoundState` : aucun `CameraType=Custom` forcé par le spectateur. Tester une caméra remplacée pendant le streaming.
- Lancer 15 manches normales et Double Chaos, dont des impacts météores/bombes très proches du changement de phase. Le compteur local n'est pas pollué par les durées des explosions de la manche précédente, et les dangers serveur restent visibles et actifs.
- Vérifier les effets Medium à l'arrivée Android, puis Low/High adaptatifs et `ReduceMotion`. Mesurer réellement FPS, mémoire, cadence des impacts et transitions de caméra.
- Contrôler le comportement des avertissements et des résidus possédés par les **autres contrôleurs** ; cette modification ne doit jamais être présentée comme une validation visuelle de l'arène.

Aucun FPS, gain de mémoire ou effet en partie n'est certifié par la seule inspection statique de ce correctif. Aucun déploiement public Roblox n'a été effectué.
