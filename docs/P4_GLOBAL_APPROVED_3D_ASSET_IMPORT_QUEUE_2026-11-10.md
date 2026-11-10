# P4 — Limiteur global des imports 3D approuvés

Date : 10 novembre 2026. Lors de l'audit du code principal,
**46** modules `Premium*Assets.lua` contenaient leur propre chemin
d'accès aux Models originaux Roblox modérés. Seuls les huit chargeurs sud
partageaient précédemment une limite de concurrence. Décaler les premiers
appels par des `task.wait` ne suffit pas lorsque les délais de réseau
varient ou que Roblox répond lentement.

## Nouveau contrat

Le module serveur `PremiumApprovedAssetImportGate` fournit une file
**FIFO à deux permis**, accessible par `GlobalApprovedImportGate.load`.
Les 38 chargeurs non-sud utilisent cette méthode. Les huit chargeurs sud
continuent de passer par leur sous-verrou exclusif
`PremiumSouthApprovedImportGate`, qui appelle désormais le même
limiteur global. La concurrence nominale totale des 46 propriétaires
est donc **au maximum de deux appels AssetService à la fois**, dont
**au maximum un appel sud**.

La file s'endort sur `BindableEvent.Event:Wait` au lieu d'utiliser
une boucle de vérification périodique. Un permis est transmis dans
l'ordre d'arrivée aux demandeurs ; il est libéré même en cas d'erreur
de `LoadAssetAsync`. Les anciens `pcall` externes, la politique
de 3 retries, les contrôles MeshPart, les modèles natifs de secours,
les délais initiaux, collisions et limites LOD sont conservés.

L'API `Gate.snapshot()` renvoie les indicateurs
`InFlight`, `Waiting`, `PeakInFlight`, `Limit`, `Completed`,
`Failed` et `TotalWaits`. Les compteurs sont temporaires,
locaux à chaque serveur, sans stockage, réseau ou boucle supplémentaire.

## Limites de mesure

Ce lot protège les **46 chargeurs Premium référencés** du dépôt.
Les autres scripts qui utiliseraient directement `AssetService` ne sont
pas inclus dans cette limite. Une requête Roblox suspendue sans retour
peut retarder les imports cosmétiques restants : le gameplay, la
génération de carte et les bots ne doivent pas attendre la file.

Les tests automatisés peuvent vérifier l'usage du module, le code
de la file et l'absence de nouvel appel direct, mais ne prouvent
pas le comportement réseau et le FPS en conditions réelles.
Avant de qualifier le résultat, consulter les compteurs du serveur
dans Studio et les mesures de FPS Android.

## Mesures serveur et suppression du polling sud

Le module `PremiumApprovedAssetImportGate` expose désormais des
mesures **réelles de la file serveur** dans
`ServerStorage.PremiumApprovedImportDiagnostics` : `InFlight`,
`Waiting`, `PeakInFlight`, `Limit`, `Completed`, `Failed`,
`TotalWaits`, `LastQueueWaitMs`, `MaxQueueWaitMs`,
`LastRequestMs` et `MaxRequestMs`. Les durées utilisent
`os.clock()`, sont arrondies en millisecondes, et ne sont pas
transmises aux clients : elles sont consultables depuis le côté
serveur dans Roblox Studio. Les attributs sont mis à jour lors
d'une entrée, sortie et fin de requête sans nouvelle boucle de mesure.

Le sous-verrou des huit imports sud est désormais également une file
FIFO `BindableEvent` : les travailleurs sont réveillés quand le
précédent leur transmet le permis. L'ancien `task.wait(.2)` en boucle
n'est plus nécessaire. Les sauvegardes serveur, la physique, le
système de LOD et les limites strictes (2 au total, 1 sud) sont
inchangés.

Ces compteurs mesurent la durée des appels API, pas les FPS ou la
visibilité d'un MeshPart sur Android ; la mesure sur appareil reste
distincte.


## Identification du vrai modèle 3D qui ralentit le chargement

Le dossier **serveur uniquement**
`ServerStorage.PremiumApprovedImportDiagnostics` expose maintenant aussi
les attributs numériques suivants, mis à jour **après des appels réels** :

| Attribut | Sens |
|---|---|
| `LastRequestAssetId` | Asset ID Roblox du dernier appel terminé |
| `SlowestRequestAssetId` | Asset ID responsable de la requête API la plus longue |
| `MaxRequestMs` | Durée de cette requête en millisecondes |
| `SlowestQueueAssetId` | Asset ID dont le temps d'attente en file a été le plus long |
| `MaxQueueWaitMs` | Durée de cette attente |
| `TotalRequestMs` | Somme des durées des appels API terminés |
| `TotalQueueWaitMs` | Somme des attentes terminées |
| `SlowRequestCount` | Nombre d'appels d'au moins huit secondes |
| `SlowQueueCount` | Nombre d'attentes d'au moins huit secondes |
| `SlowThresholdMs` | Seuil diagnostic : 8 000 ms |

À défaut de requête terminée, l'identifiant reste **0**, pas une valeur
inventée. Les compteurs ne sont pas répliqués aux joueurs et ne
modifient ni le LOD, ni le taux de FPS. Les totaux sont propres à la
session serveur (non persistants) et un appel qui reste bloqué dans
l'API n'entre pas dans les durées *terminées*.

**Pour diagnostiquer sans exporter de données privées :** dans une
session de test **Serveur** de Roblox Studio, ouvrir
`ServerStorage > PremiumApprovedImportDiagnostics`, consulter les
attributs après quelques manches, puis rechercher l'ID le plus lent
dans `assets/source/roblox-asset-registry.json` du dépôt. Répéter
sur plusieurs sessions : un seul maximum peut refléter une lenteur
transitoire du réseau Roblox.

Les tests Python vérifient ces chemins et leurs invariants dans le code.
Un test Lest côté moteur vérifie le conteneur de diagnostics et le rejet
des appels malformés sans importer d'asset. Les vrais temps d'API et
les FPS Android ne sont **pas** inventés par la CI source.
