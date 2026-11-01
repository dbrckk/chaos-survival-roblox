# Huit participants au départ de chaque manche — remplissage IA automatique

Date : 1er novembre 2026. Cette décision remplace le compromis « six survivants visibles, quatre bots au plus » de `HUMAN_CAPACITY_EIGHT_AI_ROSTER_SIX_2026-11-01.md` pour les **futures** manches. Le propriétaire confirme avoir réglé **8 places humaines** dans Creator Dashboard ; ce réglage externe ne constitue pas une preuve technique que la place publique a déjà reçu la nouvelle version source.

## Contrat réel

- **8 places humaines par serveur** (configuration Roblox modifiée par le propriétaire ; le code Roblox lit `Players.MaxPlayers`, propriété en lecture seule).
- Chaque entrée en **READY** reconcilie son effectif sur les **humains réellement admis**, pas les spectateurs ni les personnes connectées trop tard.
- Pour 1 à 8 humains éligibles, le serveur essaie de compléter **8 combattants au lancement** avec jusqu'à **7 bots R15 originaux** (mêmes risques de catastrophe et mêmes règles d'élimination), sans inventer de comptes Roblox. En absence d'humain, aucun bot et aucune partie ne sont démarrés.
- Une fois la manche engagée, **aucun bot ne remplace un humain tardif** et **aucun mort n'est ressuscité**. Ainsi « toujours 8 » signifie huit participants **au départ quand les avatars ont pu être créés/apparaitre**, et non huit encore *en vie* à chaque seconde. Les humains ont toujours la priorité entre les manches.

| Humains prêts | Bots IA visés | Total au READY |
|---:|---:|---:|
| 1 | 7 | 8 |
| 2 | 6 | 8 |
| 3 | 5 | 8 |
| 4 | 4 | 8 |
| 5 | 3 | 8 |
| 6 | 2 | 8 |
| 7 | 1 | 8 |
| 8 | 0 | 8 |

## Robustesse réelle et coût

- Les huit spawns physiques de chacune des **cinq** cartes restent inchangés ; le bot passe par le même mécanisme `SpawnSafety.resolve` que les humains.
- Corrige un défaut préexistant : `LobbyReturnFormation.botLanding` rejetait tout slot IA au-delà de **trois**, ce qui rendait impossible la répartition de sept bots à des positions distinctes au lobby. La fonction couvre maintenant les slots 1..7 et choisit une place sûre **après** les huit retours humains et les premières positions réservées ; aucun fallback sur les slots des joueurs humains.
- Si une création de rig R15 ou un atterrissage échoue pendant READY, le service **retente au plus deux fois** uniquement pour les bots manquants, espacées d'au moins 0,9 seconde, sans modifier la liste des participants au milieu d'une partie et sans rafale de création non bornée. Une panne persistante produit une population inférieure : le jeu doit être fiable avant d'afficher un faux « 8/8 ».
- La cadence globale de réflexion des bots est limitée : `brainCadence = 0.06 × nombre de bots` à partir de 4 bots (4→0,24 s, 5→0,30, 6→0,36, 7→0,42). Cela conserve approximativement **16,7 décisions de bot par seconde** pour 3 à 7 bots, au prix d'une réaction individuelle un peu plus lente. Physique et rendu de sept rigs R15 restent plus coûteux que trois et devront être mesurés, **pas présentés comme déjà optimisés**.
- Les bots conservent leur personnalité, noms fictifs non usurpés, vote, déplacements, animations, prise en charge des vrais dangers et comptage de survie. Depuis le lot d'IA coopérative inclus dans le build public du 1er novembre, ils peuvent aussi rejoindre physiquement un relais `TeamDashRelay` pour recharger un **vrai humain proche**. Cela reste une aide NPC, pas sept nouveaux joueurs humains ni une coopération sociale humain→humain.
- Pas de nouveau RemoteEvent, de mode payant, d'achat, de physique différente ou de résurrection pendant les catastrophes.

## Critères de validation avant déploiement public

1. Les suites moteur déjà présentes `tests/engine/ai-survivor-rules.spec.luau` et `tests/engine/lobby-return-formation.spec.luau` couvrent le compte 1→7 jusqu'à 8→0, les sept atterrissages sûrs/espacés, et les cadences 4..7. Exécuter la Build Validation et les cinq suites moteur Open Cloud au **même commit** lors du jalon de publication.
2. Réel Roblox Studio : 1, 2, 4 et 8 humains, les cinq cartes, compter les bots **vivants et réellement téléportés** (pas uniquement les slots réservés). Vérifier les huit places du lobby, NPC nameplates et spawns sans collision ni apparition dans une plateforme haute.
3. Simuler un `Players.PlayerAdded` durant READY/ROUND, une déconnexion, une panne de `CreateHumanoidModelFromDescription` puis un atterrissage dangereux : les deux retries doivent rester limités à READY et ne jamais faire revenir un bot éliminé en ROUND.
4. Android : mesure du FPS et de la mémoire en solo avec sept R15, puis catastrophes simultanées et plusieurs joueurs humains. Vérifier que 0,42 s de cadence ne rend pas les évitements incohérents et que les alertes restent lisibles. Ajuster la cadence et les ressources sur **mesures**, pas au hasard.
5. Les événements analytics distinguent toujours **humains** et **IA**. Seuls les humains comptent dans les taux de coopération sociale et dans les métriques de rétention.

**Actualisation du 1er novembre** : Build Validation, les cinq suites Cloud et la publication de la place publique ont réussi pour le **même SHA `46263cbdced1bddf002a8d57867303eb21422c2f`** ([publication](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41322662162)). La logique de remplissage est donc incluse dans le build public ; la population effectivement visible, les cas de création de rigs et les FPS Android demandent toujours une observation réelle.
