# P4 — Couronnes de stations propres aux cinq arènes

9 novembre 2026. Fabrication de modèles originaux exclusivement, sans mise à jour de Place publique.

Les cinq variantes possèdent chacune deux pièces natives spéciales au sommet des stations. Quatre familles géométriques couvrent les cinq variantes.

| Variante | Natives à remplacer | Union X×Y×Z (studs) | Source originale |
| --- | --- | --- | --- |
| Towers | ServiceMast + SignalCrown | 2,2 × 8,1 × 1,8 | perimeter_towers_apex |
| Orbital | ReceiverDish + ReceiverAntenna | 3,4 × 3,975 × 3,4 | perimeter_orbital_apex |
| Crossroads | ExchangeBeam + SwitchyardMarker | 2,5 × 3,175 × 8,5 | perimeter_crossroads_apex |
| Classic, Harbor | RelaySpire + RelayCrown | 2,4 × 6,1 × 2 | perimeter_relay_apex |

Le générateur tools/generate_original_perimeter_apex.py fabrique quatre silhouettes distinctes et véritables, avec sept groupes de matériaux PBR originaux, UV, normales et tangentes. Towers : mât industriel effilé et couronne métallique à ailettes. Orbital : parabole creuse, nervures de réception et antenne centrale profilée. Crossroads : double chemin de transit ajouré et station de signalisation. Classic/Harbor : tour relais métallique avec couronne radio détaillée.

Le workflow .github/workflows/one-time-original-perimeter-apex-20261109.yml vérifie les fichiers OBJ et glTF authentiques et importe les quatre Models séquentiellement avec la configuration Roblox déjà approuvée. Cette phase ne publie aucune Place, ne change ni bots ni collisions et ne déclare pas d'identifiants d'assets avant modération.

Une fois les quatre imports approuvés et intégrés en source, deux éléments supplémentaires par station seront éligibles à une substitution atomique par un seul Model, soit **16 / 23 (69,57 %) des pièces de station potentiellement remplacées**, contre 14 / 23 (60,87 %) avant ce lot. Sur quatre stations par variante × cinq variantes : 40 primitives ciblées. Ceci ne mesure ni la couverture du jeu entier ni le rendu effectif sur Android Low.

Aucune publication publique ni mesure FPS Android n'est encore revendiquée. L'intégration future doit conserver le fallback des deux natives, le streaming, la réduction de carte et le système de pression GPU.
