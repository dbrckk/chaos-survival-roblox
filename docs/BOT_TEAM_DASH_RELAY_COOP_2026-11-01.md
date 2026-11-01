# Chaos Survival — IA coopérative sur les vrais relais DASH

Date : 1er novembre 2026. Portée : la prochaine mise à jour source des cinq arènes 320×320 avec capacité réelle du start place réglée à huit humains par le propriétaire, et remplissage 1+7 → 8+0 par IA prévu par PR #524.

## Déficit de jeu résolu

Les sept bots potentiels d'une partie solo se comportaient jusque-là comme des concurrents/silhouettes : ils pouvaient suivre les joueurs et utiliser des routes, mais **ils n'activaient pas les deux consoles physiques Team DASH** de la PR #522. Les humains se retrouvaient seuls à interagir avec le décor et ne pouvaient pas bénéficier d'un comportement coopératif des NPC.

## Action réellement ajoutée

Le serveur permet maintenant à **un bot R15 réellement en vie** de :
1. Sur une manche `round`, repérer une console **encore disponible** parmi deux, en restant au sol et dans un rayon de **68 studs** ; vérifie qu'au moins **un vrai humain, vivant, prêt et participant** se trouve **à moins de 29 studs de la console**. Aucun client ne transmet d'identité ou de liste de récompenses.
2. Réserver brièvement ce point pour éviter une ruée de sept bots sur le même objet. Le bot **se déplace avec ses commandes Humanoid normales**, sans téléportation ni vitesse additionnelle, et abandonne son déplacement pour esquiver les dangers. Les catastrophes `ShrinkingArena`, `RisingLava` et `Tornado` désactivent la recherche d'aide volontaire ; les alertes de danger immédiat conservent toujours priorité.
3. Arrivé physiquement au relais (point réel et sans faux collider), s'arrêter pendant **0,65 seconde**, comme l'appui long humain. À la fin, le serveur vérifie **à nouveau** le modèle IA dans `workspace.AISurvivors`, ses attributs de manche, sa santé, la distance **7,5 studs** à la console, le sol solide et non rétréci, le nombre d'activations, le bénéficiaire humain encore présent et la validité du tour.
4. Activer le **même** chemin serveur que la ProximityPrompt humaine. La vraie méthode `PhaseDashService.recharge(Player)` gère les cooldowns humains : DASH disponible immédiatement ou **une réserve d'urgence non cumulable** si déjà prêt. L'IA ne crée pas d'avatar Player, ne gagne pas de DASH réservé, ne contourne ni les pouvoirs normaux ni les résultats de manche.
5. Mettre à jour la **même console 3D publique** (`RelayUsed`, `TeamBeneficiaries`, `BotActivated` pour les métriques internes, impulsion sobre de 0,7 s, étiquette « ALLY HELPED »), signal bref du NPC `TEAM UP!`, et message discret pour les vrais bénéficiaires (`ALLY DASH SHARED`, français « ALLIÉ : DASH RECHARGÉ »), sans nouveau panneau HUD.
6. Alimenter la télémétrie `TeamDashBotHelped` par bénéficiaire réel, **distincte** des activations de coopération humain→humain `TeamDashRelayUsed`. Un bot ne produit ni monnaie, ni XP, ni faux humain.

## Sécurité, performance, cycle de vie

- `TeamDashRelay` est l'unique propriétaire de la station, de la sélection des humains, de son verrou `guard`, des récompenses et de son cycle de vie. `AISurvivorService` n'est autorisé qu'à chercher, approcher, patienter et demander une activation **serveur**.
- La réservation expire au bout de **5 secondes** si un bot ne progresse plus ; libération immédiate à la disparition du rig, au changement de manche, quand un danger majeur apparaît ou quand le dernier bénéficiaire s'éloigne. Les humains peuvent utiliser une console même si un bot la vise.
- **Maximum deux consoles utilisées par manche** ; deux bots au plus détiennent une réservation pendant leur approche. Les recherches sont limitées à deux stations, à huit vrais joueurs au plus et aux ticks existants de l'IA (jusqu'à sept bots, cadence agrégée visée ~16,7 décisions/s).
- Aucune nouvelle `RemoteEvent`, `Heartbeat`, `RenderStepped`, boucle, tâche de scan périodique, asset coûteux, collider, DataStore ou surface PBR 2K. Le relais garde les mêmes signaux visuels et le même budget par arène.
- Les identités de bots sont des **identités originales de jeu**, sans usurpation de comptes Roblox. Le HUD dit « ALLY » pour l'action coopérative, tandis que l'analytique interne conserve la source IA explicite et vérifiable.
- Le résultat d'une activation ne devient pas une promesse de réussite au combat : un joueur peut consommer son DASH ou mourir ensuite. Aucune résurrection pendant la manche.

## Conditions de validation au jalon majeur

1. Même SHA : `Build Validation` + cinq suites `Roblox Open Cloud Engine Tests`, puis Studio authentifié, cinq cartes et Android réel.
2. Solo **1 humain + 7 bots** : rester près d'une console ; vérifier le bot approche avec trajectoire physique, s'arrête ~0,65 s, puis qu'une **vraie** recharge/charge de réserve est visible et utilisable sur le bouton DASH. Répéter en 2 humains + 6 bots à deux distances : bénéficiaire à 28 studs, non-bénéficiaire à 30.
3. Vérifier deux bots intéressés par la même console, réservation expirée, activation humaine pendant l'approche, mort du bénéficiaire, bot tué pendant l'approche, streaming du modèle, changement d'arène et manche terminée.
4. Pendant `Meteors`, `Bombs`, `ShrinkingArena`, `Tornado`, `RisingLava` et `DisappearingPlatforms`, la **fuite prime toujours** sur l'aide ; aucun bot n'active une console flottante au-dessus d'un plancher détruit.
5. Contrôle 30 minutes d'Android Low et Medium en 1+7 : FPS, mémoire, visibilités, panneaux « ALLY », anti-spam des toasts, usage réellement mesuré (nombre de bénéficiaires, activation par carte, rapport aux joueurs humains).
6. Ne pas afficher un objectif de coopération sociale atteint seulement grâce aux NPC. Les métriques humain→humain et bot→humain doivent rester séparées.

**Actualisation du 1er novembre** : le workflow de publication publique a réussi sur le SHA exact `46263cbdced1bddf002a8d57867303eb21422c2f` ([preuve](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41322662162)), incluant cette coopération IA. **L'activation physique réelle et le comportement Android restent à confirmer en jeu.** Les positions des stations sont améliorées ensuite dans une nouvelle branche source : [accessibilité des relais](COOP_RELAY_ROUTE_DISCOVERY_2026-11-01.md) ; ce correctif ultérieur n'est pas dans le build public certifié.
