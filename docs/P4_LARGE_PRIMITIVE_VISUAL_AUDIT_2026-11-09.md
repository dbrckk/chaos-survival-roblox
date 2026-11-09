# P4 — Audit statique des grosses formes encore primitives, hors stations

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
