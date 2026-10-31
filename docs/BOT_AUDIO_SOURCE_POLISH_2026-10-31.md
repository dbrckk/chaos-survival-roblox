# Chaos Survival — audio Harbor, budget de tweens et traces IA hors écran

31 octobre 2026. **Correctifs source uniquement**, sans exécution du jeu, Roblox Studio, benchmark Android, nouvel asset sonore, test automatique ou publication.

## Problèmes confirmés dans les scripts

- `src/client/audio.client.lua` comportait un tableau `ARENA_AUDIO` pour Classic, Towers, Crossroads et Orbital mais **pas Harbor**. La fonction `arenaAudioProfile()` utilisait donc le mix Classic pour Harbor.
- Le serveur envoie des `RoundState` successifs : `setMix()` créait à chaque événement **six TweenService** nouveaux sur les cinq SoundGroups et l'EQ, même si phase, réglages de volume et spectre n'avaient pas changé. `musicVolume()` recréait aussi une interpolation identique du volume de base.
- `playRaw()` et `playSpatialImpact()` pouvaient lancer/cloner des effets avec `AudioMuted=true` ou `EffectsVolume=0` : un travail local inutile et inaudible.
- `src/client/bot-motion-polish.client.lua` supposait `onScreen=true` lorsqu'aucune caméra Roblox utilisable n'était présente ; de faux effets de pas/rebond pouvaient dépenser le budget local `GroundFx` lors de la suspension/reprise d'Android. Une rig morte conservait également son dernier échantillon de mouvement.

## Changements

- Ajouter un **profil spectral Harbor original** à la même table, en utilisant uniquement les voix et la musique déjà incluses dans le jeu. Aucun téléchargement, allocation ou effet supplémentaire.
- Mémoriser les huit destinations de mix (cinq groupes + trois bandes EQ) et n'interpoler que lorsqu'au moins une destination change ; mémoriser aussi le volume musical et annuler la transition précédente avant d'en lancer une autre. Les réglages utilisateur, les phases, le Double Chaos et les événements de danger restent autoritaires.
- Ne pas allouer de voix SFX ni d'émetteurs d'impact lorsque les effets sont muets. Les boucles ambiantes existantes et leurs groupes de gain restent pilotés par le propriétaire sonore d'origine.
- Gater les effets de sol optionnels des bots à une **caméra effective avec viewport non nul et bot visible**. Réinitialiser les traces/cues d'une rig morte avant réutilisation. Navigation, vrais `Humanoid`, Animator, serveur, collision, vitesses et chances de survie restent inchangés.

## Critères pour le prochain jalon important

1. Valider Build Validation et les cinq suites Roblox Engine sur **un même SHA main**, juste avant publication ; ne rien ajouter comme test périodique pendant les améliorations.
2. Dans une vraie partie Harbor, comparer le mix avec Classic sans promettre d'emblée une amélioration perceptive : vérifier la lisibilité des dangers, MusicVolume/EffectsVolume, mute et ReduceMotion.
3. Sur Android, changer les réglages audio pendant une manche et vérifier que les SoundGroups et la musique s'adaptent une fois, sans volume bloqué ni faux son.
4. Mettre le téléphone en arrière-plan puis revenir pendant que des bots courent ; vérifier absence d'effets de sol fantômes et fonctionnement normal de leurs animations. Mesurer FPS/CPU et les diagnostics si possible.

Les corrections ne prouvent **aucune hausse d'audience ou de performance mesurée** et ne sont **pas** une nouvelle version de l'expérience Roblox publique. La validation visuelle des cinq cartes reste volontairement exclue.
