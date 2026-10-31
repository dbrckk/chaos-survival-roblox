# Chaos Survival — climax, introductions et ambiance : cycle de vie Double Chaos

Date : 31 octobre 2026. Modifications du code client uniquement. L'audit visuel actuel des cartes, les tests Roblox Studio et la publication publique sont volontairement reportés.

## Défauts constatés dans `main`

- `disaster-climax.client.lua` vidait `DisasterClimaxLocal` et invalidait tous les tableaux de progression **à chaque** snapshot `RoundState` hors round. En revanche, une nouvelle manche numérotée pendant une phase `round` inchangée conservait l'ancien `stageById` et pouvait omettre l'introduction d'une véritable nouvelle manche. Le handler lisait `state.phase` sans vérifier la structure du snapshot.
- Le remplacement de `GeneratedMap` ne nettoyait pas immédiatement les anciens climax de l'arène retirée : l'annulation ne se produisait qu'au prochain message de manche.
- `disaster-setpiece.client.lua` utilisait `VfxQuality.get(nil)` (High) au démarrage mobile. Il présentait jusqu'à deux glyphes mais animait **toutes** les entrées reconnues du tableau `disasterIds` ; une liste dupliquée ou plus longue pouvait lancer des ornements de pleine arène non bornés par deux signatures. L'ancienne carte pouvait conserver des décorations jusqu'au délai Debris.
- `ambient-atmosphere.client.lua` reconstruisait systématiquement un `ColorSequence` et assignait le taux de particules à chaque heartbeat `RoundState`, même à palette/tier identiques. Le callback acceptait une valeur malformée et pouvait interrompre sa logique locale. Une séquence de personnage disparu pouvait conserver brièvement un émetteur sur l'ancienne racine.

## Corrections

1. **Climax ciblé sur les transitions réelles** : rejeter les snapshots malformés ou numériquement périmés ; retirer les silhouettes et invalider les `task.delay` seulement lors d'une transition de phase, d'un changement de numéro de manche ou de l'ancien map root. Une manche numérotée arrivant directement en phase `round` repart avec de nouveaux stages, sans recycler le Final Rush précédent.
2. **Identité d'arène** : quand `GeneratedMap` est retirée et que la base affichée lui appartient, nettoyer immédiatement les éléments temporaires. Les silhouettes et dégâts serveur ne sont jamais modifiés.
3. **Intro Double Chaos** : limiter à **deux identifiants de catastrophe distincts et reconnus**, en gardant deux glyphes/silhouettes cohérents même sur données de présentation inhabituelles. Les vrais avertissements de toutes les catastrophes actives restent ailleurs inchangés. Les fragments locaux disparaissent au retrait de la carte.
4. **Qualité initiale Android** : les deux chemins d'introduction emploient `VfxQuality.deviceTier(..., TouchEnabled)` ; Medium initial sur tactile, High sur PC, puis palier adaptatif.
5. **Ambiance particulaire** : construire `ColorSequence` uniquement lors d'un changement effectif d'identifiants ou après réinstanciation de l'émetteur ; n'assigner `Rate` que si son niveau varie. Le premier rendu sans catastrophe conserve l'ancienne palette de repli. Ignorer les snapshots invalides/anciens et détacher les particules sur `CharacterRemoving` pour ne pas attacher à un avatar obsolète.

## Périmètre inchangé

Aucun RemoteEvent supplémentaire, nouveau RenderStep, asset payant, collision, hitbox, dégâts ou vitesse. Les règles de visibilité des météores, des bombes, les warnings de secours, les effets d'impact serveur et les objectifs du match demeurent identiques.

## Validation différée — avant prochaine publication Roblox

- Build Validation et les cinq suites Roblox Open Cloud sur **le SHA exact de `main`** ; compléter par une session Android et PC réelle.
- Double Chaos à deux catastrophes : s'assurer que deux emblèmes différents apparaissent, que les climax passent aux étapes 1/2/3 et que la priorité des avertissements serveur demeure.
- Injecter dans un environnement autorisé un snapshot `disasterIds` long/dupliqué et des `RoundState` répétés/anciens : ne jamais instancier plus de deux familles de décorations d'introduction et ne pas effacer les phases actuelles à cause d'un paquet périmé.
- Enchaîner deux manches portant des numéros différents mais un même libellé `round` ; les nouvelles signatures doivent s'activer malgré l'absence de READY intermédiaire.
- Retirer `GeneratedMap` pendant un climax et une intro, puis streamer la nouvelle arène : aucune pièce orpheline ou reprise retardée de l'ancienne carte.
- Tester premier lancement Android sans `VfxQualityTier`, changement Low/Medium/High et `ReduceMotion` ; mesurer FPS/mémoire et nombre d'instances locales avant d'affirmer un gain.
- Vérifier les particules d'ambiance sur R6/R15 lors de réapparitions rapides et l'absence d'ancien émetteur accroché à l'avatar retiré.

Les changements sont vérifiés **statiquement**, mais aucune amélioration de FPS ou validation visuelle réelle n'est revendiquée. Aucun déploiement Roblox n'a été effectué.
