# V3 Lot 2 — navigation physique et choix tactiques dans les cinq arènes

**5 novembre 2026 — code source uniquement. Aucun déploiement public Roblox.**

## Constat sur le dépôt inspecté

Les cinq arènes ont **déjà** deux promenades élevées physiques de huit
modules chacune et un corridor transverse Sky Spine de dix plateformes.
Leurs 2,4 studs de saut entre deux modules sont de vrais intervalles
server-owned. Aux extrémités, les promenades rencontrent les quatre vrais
belvédères des branches ; au milieu, les deux jonctions de la Sky Spine
sont des surfaces qui se recouvrent physiquement.

La lacune était dans le parcours proposé aux joueurs :
`JumpRouteCueRules.nextPhysical` dirigeait vers des ascensions en
`RouteTier + 1` (ou les skyways spécifiques de Harbor). Les promenades
et la Sky Spine restent au `RouteTier=4`; leurs sauts de niveau ne
pouvaient donc jamais être sélectionnés. Les quatre belvédères de branche
se terminaient artificiellement dans le coach, même si les routes
physiques continuaient. Aucun besoin de construire un faux nouveau pont.

## Changement réalisé

1. `JumpRouteCueRules.skyNetworkLink` vérifie un **couple de véritables
   Parts** : même dossier de plateformes, propriété
   `ChaosPermanentRoute` sur les deux, coordonnées/taille et collision,
   pas de danger `Warning/Gone`, tops à 0,25 stud maximum d'écart
   et au plus 3,85 studs d'espace horizontal. Un recouvrement des
   surfaces est correctement un **passage à pied**, pas un saut.
2. `skyNetworkOptions` relie les deux sens des huit étapes de chaque
   promenade, les deux sens des dix étapes de la Sky Spine, les quatre
   belvédères finaux et les deux jonctions H réelles.
3. `nextPhysical` interroge ce système **avant** les règles d'ascension
   réservées aux anciennes routes. Pas de changements de mécanique de
   saut/collision, route server-side ou récompense.
4. Le coach novice mémorise les **vrais decks touchés** et détermine
   le sens de déplacement. Rotation de caméra ≠ changement de sens.
   Au niveau des deux jonctions, il signale `2 SKY ROUTES` /
   `2 CHEMINS EN HAUTEUR` avec la même interface Android.
5. Si le trajet indiqué traverse un danger temporaire, le coach essaie
   le **véritable** autre itinéraire de la jonction. Aucun panneau
   inventé au-dessus d'un vide ou d'une plateforme effondrée.

## Critères de réception (jalon moteur, non exécutés dans ce lot)

Le nouveau test d'intégration `tests/engine/sky-network-physical-wayfinding.spec.luau`
instancie les cinq arènes par `MapBuilder.build` dans le vrai moteur
Roblox. Il vérifie :

- quatre entrées/retours à partir des vrais belvédères pour chacune ;
- chaque liaison promenade est proposée dans les deux directions ;
- les neuf sauts consécutifs de la Sky Spine sont proposés dans les
  deux directions ;
- jonctions au niveau 4 et retours de la Sky Spine ;
- un deck `Warning` n'est jamais suggéré et une jonction sûre est
  utilisable à sa place ;
- aucune destination fantôme lorsque la collision manque.

**Publication :** uniquement après les tests Roblox Open Cloud et Build
Validation sur le SHA exact, puis un contrôle de terrain Android/PC.
La capacité à réellement franchir tous les sauts avec un avatar standard
doit encore être confirmée dans les tests moteur et une partie ; les
définitions de géométrie seules ne prouvent pas l'expérience complète.
