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

## 30 octobre — boucle de revanche personnalisée sans écran supplémentaire

### Déficit observé dans le code du récapitulatif

Le panneau existant `LobbyRoundRecapLocal`, visible après chaque manche,
présentait uniquement le nom de la catastrophe, les survivants et la consigne
de vote. Il ne rappelait pas au joueur **son propre résultat**, alors que
l'interface de résultat sait déjà distinguer survivant, champion,
participant éliminé et simple spectateur. L'ancien rafraîchissement
détruisait et recréait aussi tous les traits du pictogramme de catastrophe
à chaque paquet de compte à rebours (coût d'instances UI inutile sur Android).

### Modification finalisée côté code

- `ResultPresentation.lobbyReplayCue(feedback, localeId)` produit une
  incitation FR/EN **courte, factuelle, personnalisée**, sans argent ou XP
  inventé. Champion/Survivant : objectif de rejouer ; élimination avec
  cause serveur connue : **une action de progression**, comme monter plus
  haut contre la lave, quitter le rouge contre une bombe, ou mieux viser un
  saut. Cause inconnue : « Réessaie ! » sans accusation inventée.
- Le panneau `lobby-round-recap.client.lua` réutilise
  `ResultPresentation.fallbackFeedback` à partir des **listes figées
  de participants et survivants** du paquet `RoundState.result`.
  Un `RoundFeedback` individuel arrivé ensuite peut enrichir uniquement
  **cette même manche** avec la vraie cause d'élimination. Les reçus plus
  anciens sont rejetés ; un spectateur n'est jamais affiché comme
  participant ou perdant. Le bouton de vote/consigne « NEXT » reste visible.
- Les segments du pictogramme sont maintenant reconstruits **uniquement
  lorsque son identifiant de catastrophe ou sa couleur changent** (ou
  quand le vrai plateau/lobby est reconstruit). Les simples paquets de
  décompte ne créent plus de `Frame`/`UICorner` supplémentaires.
- Pas de RemoteEvent, écran, DataStore, monnaie, nouvelle progression,
  animation répétée, réseau externe ou boucle de rendu. On conserve le
  résultat personnalisé et la mécanique de vote existants.

### Critères de réception

Le cas moteur ajouté à la suite existante
`tests/engine/result-presentation.spec.luau` vérifie les intitulés
FR/EN, survivant, champion, élimination connue, cause inconnue,
spectateur et résultat incomplet. Au jalon de publication, vérifier
**en vrai sur Android** : fin de manche survivant → panneau du lobby
« Survécu — Rejoue », mort par lave → « Monte plus haut », entrée
en spectateur → panneau générique « Last Chaos », puis vote et démarrage
de la manche suivante. Si le reçu individuel arrive en retard, seule
la manche correspondante est enrichie ; aucun faux résultat après
`READY`. Confirmer la lisibilité sur écran paysage 360 px et l'absence
de recréation des glyphes à chaque seconde.

**Statut : candidat source, pas une publication Roblox ni une hausse
mesurée de rétention.** Le dernier upload public vérifié reste
[publisher 41112157340](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41112157340),
SHA `77e5805c96d9dd793e5bc058b93b4d7e904e1530`.
