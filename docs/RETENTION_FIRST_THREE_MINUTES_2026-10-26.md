# Chaos Survival — mesure des 3 premières minutes (26 octobre 2026)

## Pourquoi cette instrumentation

L'expérience publique comptait 9 visites lors du contrôle du 26 octobre.
Cet échantillon **ne permet pas** de calculer une rétention significative.
Il ne faut pas déclarer une amélioration de D1/D7 sans nouvelles cohortes de
joueurs authentiques et une version publique reliée au SHA GitHub déployé.

Le jeu possède déjà le funnel Roblox `Joined`, `FirstVote`,
`FirstRoundStarted`, `FirstRoundCompleted`, `FirstSurvival` ainsi que
`TimeToClientReadySeconds`, `TimeToFirstRoundSeconds` et
`SessionExitStage`. Cette modification ajoute des dimensions à faible
cardinalité qui rendent comparables les entrées **pendant une manche** et
les entrées **pendant le lobby**.

## Définition des cohortes et événements

| Événement existant | Dimensions ajoutées | Interprétation |
|---|---|---|
| `SessionStarted` | `Arrival:<phase>`, `PhaseRemaining:<band>` | Phase du serveur et tranche des secondes de la phase en cours à l'arrivée |
| `TimeToClientReadySeconds` | `Arrival:<phase>` | Temps de démarrage client par situation d'arrivée |
| `TimeToFirstRoundSeconds` | `Arrival:<phase>` | Temps réel avant de pouvoir jouer la première manche |
| `TimeToFirstCompletionSeconds` | `Arrival:<phase>` | Temps de la première participation jusqu'à une partie terminée |
| `SessionDurationSeconds` | `Arrival:<phase>`, `FirstRound:<boolean>` | Comparaison des départs précoces et des sessions réellement jouées |

`phase` est **uniquement** l'une des valeurs stables `waiting`,
`intermission`, `ready`, `round`, `result`, `unknown`. Les tranches
`PhaseRemaining` sont `0-10s`, `11-30s`, `31-60s`, `61s+`,
`Unknown`. Ce n'est pas une estimation du temps de toute l'attente
ni une affirmation que le joueur peut rejoindre une manche démarrée.

## Expérience produit à mesurer

**Hypothèse :** les arrivées pendant `round` quittent davantage avant leur
première manche. Proposer `Regarder / Entraînement` doit leur donner une
action utile, sans passage forcé dans l'arène ni avantage compétitif.

1. Valider avec un build de staging dont le SHA est connu, puis publier
   délibérément un candidat contrôlé ; ne pas interpréter le `main` du dépôt
   comme une publication Roblox.
2. Comparer les cohortes `Arrival:round` et `Arrival:intermission` en
   observant le temps jusqu'à la première manche, les sessions sans aucune
   manche et la fraction de départs sous 60 s, puis entre 61 et 180 s.
3. Sur Android, vérifier qu'il est possible de toucher `ENTRAÎNEMENT`,
   utiliser les pads du lobby, toucher `REGARDER` et voir à nouveau une IA
   ou un joueur humain **pendant la même manche**.
4. Vérifier les cas limites : élimination, Humanoid réapparu, aucun survivant
   disponible, vote/READY, changement de carte et fin de manche. Un joueur
   éliminé ne doit jamais récupérer l'entraînement par cette commande.
5. Contrôler la fluidité de 30 minutes de transitions spectateur/entraînement,
   les captures de vrai écran, la taille du bouton et la lisibilité du HUD.

## Décisions uniquement basées sur des données suffisantes

- Si les arrivées pendant une manche quittent avant la première participation,
  améliorer le spectateur, rendre les pads du lobby plus visibles ou réduire
  l'attente **sans modifier la liste serveur des participants**.
- Si les premières manches commencent vite mais les sessions s'arrêtent
  immédiatement après le résultat, améliorer satisfaction, revanche, rythme et
  objectifs de manche avant d'ajouter des monnaies.
- Si les abandons dépendent surtout de l'appareil, analyser les groupes
  `ClientPerformancePulse` et les véritables FPS/temps de frame Android.

**Limites :** les événements sont des observations côté serveur, ils ne
prouvent ni la qualité artistique, ni les causes de départ. Mesurer la D1/D7
dans l'Analytics Roblox avec ses définitions officielles et des cohortes
suffisantes. Respecter les règles de confidentialité et ne jamais loguer de
pseudonymes, chat, identifiants personnels ou données sensibles ici.
