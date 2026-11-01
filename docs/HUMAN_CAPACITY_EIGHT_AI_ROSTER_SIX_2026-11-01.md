# Dimensionnement Chaos Survival — 8 humains, 6 survivants visibles minimum ciblés

Date : 1er novembre 2026. Cible : toutes les cinq cartes **320 × 320 studs**, huit points de spawn réels sur chacune, 45 secondes en multijoueur, 30 secondes en solo.

## Décision produit

- **8 joueurs humains maximum par serveur de Roblox**. C'est une **cible** basée sur la densité de rencontres, le nombre de spawns (huit), les interfaces Android, les vingt à trente premières secondes d'une manche et la marge de performance encore non mesurée ; ce n'est pas une promesse de capacité AAA certifiée.
- **Population visible visée : 6 survivants** si le trafic est faible, mais **au plus 4 bots IA** pour ne pas multiplier excessivement les R15, l'animation, les décisions de danger et le trafic réseau. Un humain seul sera donc accompagné de **4 bots = 5 présents**, compromis explicite de coût/performance.
- **Arrivée d'humains prioritaire** : si 3 humains jouent, 3 bots ; 4 humains, 2 bots ; 5 humains, 1 bot ; 6 humains ou davantage, aucun bot. Le serveur ne *simule pas* de nouveaux comptes ; la substitution de bots se fait uniquement entre manches, jamais lors d'une catastrophe en cours.
- Le rythme des **4 bots** est ajusté de 0,18 à **0,24 s** : à pleine capacité bot, le nombre total d'étapes d'IA par seconde reste environ celui de la configuration antérieure **3 bots × (1/0,18)**. Les phases de résultat et le mode avec seulement 3 bots ne changent pas. Cela ne mesure pas l'impact GPU réel sur Android.
- Les humains gagnent réellement des opportunités d'interaction grâce aux **deux relais DASH coopératifs** (PR #522), qui restent facultatifs et fonctionnent en solo. Les bots, pour le moment, n'activent pas ces relais. Ne pas compter les bots comme de véritables interactions humaines dans les métriques.

| Humains admis au READY | Bots voulus | Participants visibles ciblés |
| ---: | ---: | ---: |
| 1 | 4 | 5 |
| 2 | 4 | 6 |
| 3 | 3 | 6 |
| 4 | 2 | 6 |
| 5 | 1 | 6 |
| 6 | 0 | 6 |
| 7 | 0 | 7 |
| 8 | 0 | 8 |

La population IA est **verrouillée pendant READY, ROUND et RESULT**. Une arrivée tardive ne modifie pas les concurrents engagés ; les remplacements se font au prochain changement de manche conformément au système existant.

## Réglage Roblox nécessaire — une action dans Creator Dashboard

**Important :** la valeur `Players.MaxPlayers` est en lecture seule dans le jeu. Ni `Config.RecommendedHumanCapacity = 8` ni les commits GitHub ne modifient la limite réelle d'une place Roblox ; celle-ci doit être enregistrée dans **Creator Dashboard**. Le serveur émet maintenant un avertissement non bloquant s'il constate une autre valeur, afin d'éviter de dire qu'une limite non modifiée est active.

Pour l'expérience existante **Universe 10771083668, Place 95351659174730** :

1. Ouvrir [Creator Dashboard](https://create.roblox.com/dashboard/creations) avec le compte propriétaire et choisir **Chaos Survival**.
2. Aller à **Configure → Places**, sélectionner le **start place**.
3. Dans **Access** (ou les paramètres de la place, selon l'interface), entrer **Maximum Visitor Count = 8** puis **Save**. Si proposé, préférer un remplissage social élevé/maximal pour rapprocher davantage de **vrais humains** ; éviter de répartir prématurément une faible population dans de nombreux serveurs sous-remplis.
4. Ne pas augmenter artificiellement `MinimumPlayers` : la partie doit toujours pouvoir démarrer avec un seul humain.

Ce réglage de capacité sur Creator Dashboard **ne publie pas** les nouveaux scripts : après la validation majeure du jeu, le flux de publication du projet doit publier le SHA source retenu. Le contrôleur Roblox peut ensuite annoncer `Players.MaxPlayers == 8` et le roster humain + bots peut être vérifié sans supposition.

## Vérifications à effectuer au jalon majeur (pas pendant l'amélioration)

- Contrôle statique : cinq cartes conservent leurs huit vrais spawns, pas de changement de `BaseSize`, prérequis client Android et compatibilité `SoloRules`.
- Vérifier sur **un seul SHA** : Build Validation + cinq suites Roblox Open Cloud, puis une vraie session Studio/Android solo et à deux/multiples joueurs ; 1+4, 2+4, 3+3, 4+2, 5+1, 6+0, 8+0 ; laisser partir/rejoindre pendant READY et ROUND, vérifier le verrouillage.
- Performances Android avec 4 bot R15 et catastrophes combinées ; 15 captures authentiques par partie ; CPU/mémoire du serveur, FPS client, retard d'évitement, stabilité des interactions DASH et apparition de rig ; rollback de la densité si les mesures réelles sont trop mauvaises.
- Mesures : humains réels par serveur, IA réellement active, taux de relais partagés à un **autre humain**, temps avant première interaction, survie et retour à J+1/J+7. N'augmenter 8 → 10/12 qu'avec des preuves.

**État** : code cible GitHub seulement ; le plafond Roblox n'a pas encore été modifié dans le Creator Dashboard et aucune nouvelle publication publique n'a eu lieu. Dernière publication publique vérifiée : `e8767c98c475a3efb39ed53ed7bbe16efa1865d2`.
