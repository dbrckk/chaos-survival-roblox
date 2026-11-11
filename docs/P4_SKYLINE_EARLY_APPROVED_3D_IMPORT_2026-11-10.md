# P4 — Disponibilité plus rapide des quatre sources 3D d'horizon

## Historique du 10 novembre, remplacé par la priorité du 11 novembre

Le chargeur serveur des quatre modèles approuvés
`exterior_tower_21/24/27/30` attendait **145 secondes** avant
la première requête. Or trois clients (structures principales,
tours extérieures et toits éloignés) partagent ces sources et laissent
les formes natives affichées tant que la source n'est pas prête.

**Changement source :** premier essai après 36 secondes, puis
trois importations décalées d'au moins 36 secondes **après le traitement
du modèle précédent** (plus les 5 secondes de séparation déjà présentes).
Durées indicatives en absence de latence : environ 36, 77, 118, 159 s.
Pas de nouvelle requête, pas de client AssetService, pas d'exécution
parallèle supplémentaire. L'import reste facultatif, asynchrone,
sanitisé, limité à trois essais, et ne bloque ni personnages ni bots.

Important : les temps d'API Roblox, la concurrence avec d'autres familles
et les FPS Android ne sont pas mesurés dans les tests source. Une
régression source et son workflow garantissent les quatre IDs approuvés,
l'absence de concurrence nouvelle, les retries et le partage LOD.
Le benchmark réel join/streaming et un éventuel ajustement des espacements
restent nécessaires avant de qualifier cette amélioration de performance
réelle mesurée.

Ce changement ne publie pas la Roblox Place.


## Révision du 11 novembre — priorité réelle aux arènes actives

La liste fixe 21 → 24 → 27 → 30 rendait le rendu de **Towers**
inatteignable en première manche : les hauteurs 27/30 nécessaires
attendaient la troisième et quatrième importation, vers 118 et
159 secondes sans latence. **Orbital** attendait la hauteur 24 au
deuxième tour, vers 77 secondes. Cette séquence ne répondait pas
à l'objectif de skyline premium visible dès le début.

Le même chargeur et les **quatre mêmes modèles source** sont
conservés, mais à 26 secondes il relève la véritable variante de la
carte serveur et trie les modèles par utilité immédiate :

| Variante active | Sources prioritaires |
| --- | --- |
| Classic / Harbor | 21 |
| Crossroads | 21 puis 24 |
| Orbital | 24 puis 27 |
| Towers | 27 puis 30 |

Les deux modèles prioritaires, lorsqu'ils sont nécessaires, sont
espacés d'au moins 10 secondes après la fin de l'import précédent
et de son intervalle de séparation de 5 secondes. Les modèles non
prioritaires restent espacés de **34 secondes + 5 secondes** ;
la première demande ne commence pas avant 26 secondes. Si la carte
n'est pas disponible, l'ordre traditionnel est conservé.

Le global gate serveur borne toujours la concurrence à deux.
Aucun importer supplémentaire, création dynamique d'asset ou appel
client n'est ajouté. Les durées sont des opportunités de chargement,
pas des garanties de rendu : saturation réseau, temps Roblox,
rotation de carte et StreamingEnabled peuvent encore reporter les
meshes. **Pas de publication ni de FPS Android mesurés.**
