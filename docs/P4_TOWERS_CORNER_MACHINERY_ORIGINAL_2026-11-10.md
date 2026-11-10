# P4 — Sculpture d'origine des quatre machines d'angle de Towers

10 novembre 2026. Ce lot crée une nouvelle **source OBJ originale** adaptée
aux `TowerMachinery1..4` et `TowerMachineryCap1..4` du générateur
`MapBuilder.addVariantLandmarks`. Le source a un fût dodécagonal
à rayon variable, des struts diagonaux, ventilations en relief et une
couronne fraisée : **vraie géométrie triangulée à sept matériaux**.
Enveloppe attendue `7.36 × 24.9 × 7.36` studs, sans collider.

L'antenne `TowerAntenna1..4` **reste intacte** pour la lisibilité
de l'arène. La même géométrie 3D authentique peut servir quatre positions
sans inventer quatre Asset IDs.

Le lot source et son workflow n'activent **aucun** remplacement tant
qu'un Model Roblox propriétaire n'a pas reçu un identifiant réel et
une modération `Approved`. L'upload automatisé de la source
est gardé par une vérification OBJ/glTF de la géométrie, sept matériaux,
normales, UV et tangentes. L'import ne publie PAS la Roblox Place.

La suite du workflow est de lire l'ID du vrai Model modéré, de
l'ajouter au registre et de monter le modèle à ses quatre positions
via le LOD commun en conservant les Parts natives en fallback.
**Ne pas déclarer cette famille remplacée avant le kit validé.**

## Livraison source et montage runtime — 10 novembre 2026

L'import réel via GitHub Actions [#42861370182](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42861370182) a abouti : propriétaire Roblox, Model **72143366927826**, **Moderation: Approved**.

Le code de jeu peut désormais charger ce Model de manière différée et
contrôlée via `PremiumVariantTowersLandmarkAssets`. Le kit client
`ApprovedVariantTowersLandmarkMeshKit` contrôle les quatre vraies paires
`TowerMachinery` + `TowerMachineryCap` et ne masque les deux natives
qu'une fois **sept MeshParts réelles** montées. Chaque antenne reste
visible. Couverture source de cette famille : **8/8 pièces éligibles**
dans Towers. Les quatre machines existent sur une seule arène Towers
active, pas sur chacune des cinq variantes.

Budget de présence simultanée : Low 0 ; Medium Android 1 / PC 2 ;
High Android 2 / PC 4, avec rétrogradation en fonction de la pression.
Les attributs du client enregistrent les MeshParts effectivement montées
et les primitives masquées. Ces compteurs ne prouvent pas le rendu final
ni les FPS Android. Les tests Studio et la publication publique restent
des opérations distinctes et non attestées par une simple fusion GitHub.

## Correctif de stabilité : capot animé et plancher qui rétrécit

Le module arena-identity-motion modifie la transparence et la position
verticale de TowerMachineryCap (+/-0.18 stud) ; il anime aussi la
transparence et l'orientation des quatre TowerAntenna.

Le kit original acceptait seulement un capot immobile à 0.16 stud près
et une transparence proche de 0.18, puis le masquait par
Part.Transparency=1. Il pouvait échouer ou provoquer un clignotement
à chaque cycle d'animation.

Correction : le capot authentifié accepte son enveloppe de mouvement
(0.28 stud) et sa plage de transparence active (0.05..0.68).
Une fois sept MeshParts sculptées en place, il est masqué localement
par LocalTransparencyModifier=1 et SceneryLodHidden=true. L'animation
existante reconnaît le flag, restaure sa pose de base et ne lutte plus
contre la visibilité LOD. À la suppression du 3D, la visibilité et le
propriétaire LOD antérieurs sont restaurés, puis l'animation peut reprendre.

La TowerAntenna reste native et animée ; les TowerBand des quatre
fûts internes sont également conservés. Les positions des quatre
machines d'angle utilisent désormais les attributs immuables
OriginalSizeX/Z de MapBuilder plutôt que la taille instantanée de
la plateforme qui rétrécit en pleine manche.

Aucune source d'asset, collision, boucle RenderStepped, RPC ou
publication Roblox Place n'est changée. Contrôles GitHub source ;
mesure FPS et captures Studio/Android non attestées.
