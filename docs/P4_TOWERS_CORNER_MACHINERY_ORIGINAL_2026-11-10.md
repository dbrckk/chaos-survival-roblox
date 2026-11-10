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
