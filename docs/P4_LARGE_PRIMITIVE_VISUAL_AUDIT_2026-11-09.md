# P4 — Audit statique des grosses formes encore primitives, hors stations

**Classic — supports originaux du 10 novembre 2026 :** `RelayButtressWest/East`, `RelaySparWest/East`, `ServicePanel` sont éligibles à l'unique modèle 3D source de **5 924 triangles et sept MeshParts**, asset Roblox réellement Approved `91717127334369`. Le kit Classic primaire du mât et des deux paraboles reste indépendant. **Sur les 14 Parts/WedgeParts natives créées par `addArenaSignatureMegastructure` en Classic, 12 sont éligibles à un masquage 3D sous LOD** (sept du primaire et cinq de ces supports) ; `Foundation` et `InsetBase` restent dans leur forme native. Le pourcentage 12/14 ne vaut que pour ce monument, ni pour toutes les arènes ni pour tout le jeu.


**Classic — lot du 10 novembre 2026 :** les sept silhouettes `PrimaryRelayMast`, `RelayHead`, `DishBridge`, `ReceiverDishWest/East` et `ReceiverHubWest/East` du monument nord Classic possèdent désormais **un remplacement original commun** : 6 664 triangles, deux paraboles réellement creuses, sept MeshParts PBR, Model propriétaire `112493873850364` modéré Approved. Le kit intégré masque les sept natives en bloc, uniquement si la source et les éléments de la vraie carte sont validés. Cette étape ne modifie pas le dénominateur de 23 pièces des stations périphériques ; **ne pas présenter leur 69,57 % comme une amélioration du jeu entier**.


**Harbor — lot du 10 novembre 2026 :** la grosse poutre `QuayCraneSpanningBeam`, le contrepoids `QuayCraneCounterweight` et la cabine `QuayControlCab` de la vraie `ArenaSignatureMegastructure` Harbor sont désormais éligibles à une **sculpture 3D originale unique** de 2 940 triangles et sept matériaux, Model Roblox créateur `124368710235343`, modération Approved. Le montage source local ne supprime aucune pièce du gameplay. Cela ajoute **trois autres primitives-source potentiellement remplacées** hors de la famille des stations périphériques. Il ne faut toujours pas présenter la couverture 16/23 des stations comme une couverture 3D de l'ensemble du jeu.


**Crossroads — lot du 10 novembre 2026 :** `LowerExchange`, `UpperExchange`, `CantileverWest` et `CantileverEast` de la vraie `ArenaSignatureMegastructure` Crossroads sont désormais éligibles à **un unique modèle 3D authentique**, approuvé sous l'ID `96622579843060` (sept MeshParts, 4 356 triangles). L'échangeur ne touche ni les chemins jouables ni les signaux. Ce sont **quatre primitives-source conditionnellement remplaçables**, dans une famille séparée des stations périphériques et des tours extérieures. Aucun pourcentage global du jeu n'est déduit.


**Nouveau lot Towers (10 novembre 2026) :** les deux grandes masses primitives `OverheadServiceBridge` et `LowerTruss` du `ArenaSignatureMegastructure` Towers disposent maintenant d'un remplacement source original sculpté, Model `126298311664881` et sept MeshParts réels. Le montage est conditionnel, réversible et ne concerne **pas les ponts Skyrail jouables**. Deux pièces-source supplémentaires sont ciblées dans **une autre famille que les stations périphériques** ; le pourcentage station 16/23 = 69,57 % n'est pas modifié et ne décrit toujours pas l'ensemble des décors.


**Nouveau lot Orbital :** le modèle de monument `ArenaSignatureMegastructure` conserve ses structures physiques cosmétiques d'origine et son cœur, mais ses **16 ReactorArc** rectangulaires sont désormais éligibles à un remplacement atomique par un tore original 3D continu **vérifié, téléchargé et approuvé** (Model 125070862497818). Ces **16 éléments-source conditionnellement substituables** sont distincts des 23 éléments comptés par station, des 120 pièces de tours extérieures et ne constituent pas un pourcentage global. Le nombre réellement visible demeure dépendant du LOD et du chargement d'assets.


9 novembre 2026. Inspection de src/server/MapBuilder.lua et des kits de substitution client sur la branche main.

## Séparation impérative des populations

Les stations périphériques (quatre par carte, cinq variantes) sont une famille différente : 16/23 pièces natives possèdent un remplacement 3D dans le code (69,57 % de cette seule famille). Le nombre de pièces effectivement masquées dépend de la caméra/qualité. Ne jamais présenter ce chiffre comme le pourcentage du jeu entier.

Les quatre ExteriorSilhouetteNorth/East/South/West par variante comportent SIX natives non collisionnelles chacune : ReactorShell, RoofCanopy, LeftRib, RightRib, SignalBand, Antenna. Après ce lot, les quatre premiers rôles possèdent un modèle 3D original approuvé (1 232 triangles, sept MeshParts) avec vraie hauteur propre à chaque tour. Les deux derniers restent natifs pour le langage lumineux. En définition : 5 variantes × 4 tours × 6 = 120 natives, **80/120 = 66,67 % ayant un remplacement potentiel**, 40/120 natifs sans remplacement. À un instant donné, une seule variante est active et tous les meshes ne sont pas systématiquement résidents.

## Autres grands ensembles primitifs vérifiés (priorités)

| Générateur | Formes encore élémentaires observées | Intérêt pour la suite |
| --- | --- | --- |
| MapBuilder.addDistantSkyline | SkylineStructureNorth/East/South/West : StructuralCore rectangulaire, TopCap WedgePart, OuterRibL/R et formes spécifiques; SkylineDepth : huit DistantRoofMass WedgePart + huit DistantAerial Part | Horizon industriel très visible sur les cinq variantes ; viser de vraies façades et silhouettes profondes |
| MapBuilder.addArenaSignatureMegastructure | Une ArenaSignatureMegastructure par carte, avec pièces assemblées en Parts et WedgeParts, notamment lift towers, plateformes d'échange, relais, terminal de fret ou anneau segmenté selon variante | Grandes formes de repère dominant l'horizon : meilleure cible AAA après les tours |
| MapBuilder.addSouthHorizonMonument | Architecture sud construite en Parts/WedgeParts selon variante | Horizon opposé à l'architecture dominante |
| MapBuilder.addVariantIdentity et addVariantLandmarks | GridMarker, TowerSpine, CrossroadGate, OrbitalCrown, ClassicBroadcastFin, TowerMachinery, CrossroadGantry, OrbitalReactorNode... en primitives directes | Signaux importants : maintenir leur lisibilité et leur gabarit |
| MapBuilder.addExteriorCornerRidges | 4 ensembles de reliefs en WedgeParts | Les crêtes angulaires restent simplifiées |

Ce registre est une **liste vérifiée de cibles**, pas un comptage global des objets réellement affichés. Les fonctions créent des quantités variables selon arène/conditions et d'autres modules produisent des milliers de props client/serveur. Les nombres de sources Roblox Model dans le registre ne sont pas égaux au nombre d'instances ni de primitives supprimées.

## Méthode nécessaire pour calculer le vrai taux global

Construire un census runtime lu dans le client/Engine au jalon de release : pour chaque variante et qualité Android/PC, noter tous les BaseParts visuels actifs par origine, classe/native/MeshPart, Source IDs, original caché, éléments mobiles et effets. Classer séparément les objets fonctionnels (plateforme/collision) qui ne doivent pas être remplacés arbitrairement. Ne pas mélanger couverture source, assets approuvés, instances réelles et pixels perçus. Générer une photographie de chaque arène sous les cinq directions caméra.

**Aucun test Roblox Engine ou publication publique du nouveau commit n'a été effectué.** Le dernier upload public vérifié précédemment demeure P2 ae4ae044e991ef4ca28a991991f2e11b9df49c84.
