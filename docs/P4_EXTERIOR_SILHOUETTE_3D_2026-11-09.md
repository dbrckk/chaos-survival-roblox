# P4 — Grandes silhouettes industrielles extérieures, vraie géométrie 3D

**Mise à jour source intégrée :** workflow #42702281053 terminé avec quatre Models Approved (21 : 137744886537150, 24 : 74958476744494, 27 : 97864559770371, 30 : 112172520488996). Serveur, kit client, source, registre et budget visuel du jeu sont reliés à ces vrais IDs ; l'étape d'import futur ci-dessous est historique. L'intégration ne signifie PAS déploiement public Roblox ni FPS mesuré.

9 novembre 2026. Production de meshes originaux; aucune publication de Place Roblox.

## Audit du code source

MapBuilder.addExteriorSilhouettePairs construit quatre ExteriorSilhouette (North, East, South, West) par variante. Chacune contient six Parts : ReactorShell (grosse boîte), RoofCanopy (boîte de toiture), LeftRib et RightRib (supports rectangulaires), SignalBand (néon) et Antenna (repère vertical). Les quatre premières formes sont les cibles visuelles; les deux signaux restent natifs pour conserver la lisibilité.

Quatre hauteurs distinctes sont utilisées dans les sources de MapBuilder : 21, 24, 27 et 30 studs. Une extrusion uniforme d'une seule petite tour pour les quatre hauteurs déformerait les formes. Le nouveau générateur tools/generate_original_exterior_towers.py crée donc quatre profils originalement modélisés, adaptés aux dimensions de chaque vraie tour.

## Géométrie créée

Chaque profil présente une véritable coque à douze facettes et sept niveaux de section, toiture métallique chamfreinée et profonde, nervures diagonalement forgées, panneaux latéraux creusés, modules ventilés, renforts de façade et marquages techniques. Sept matériaux industriels du projet avec triangles, UV, normales et tangentes réels. Aucun MeshId imaginaire, aucune texture distante ni Roblox Part supplémentaire pour simuler une pièce 3D.

Le nouveau workflow .github/workflows/one-time-original-exterior-towers-20261109.yml contrôle ces quatre OBJ/glTF puis effectue quatre imports Model de façon séquentielle vers le compte Roblox créateur approuvé, sans publier de Place. Il faut récupérer les quatre vrais identifiants et la modération Approved avant toute intégration runtime.

## Périmètre chiffré et limites

Pour cinq variantes, 4 tours par variante, 6 pièces par tour : 120 primitives de cette famille dans les définitions. Quatre grandes natives par tour sont la cible = 80 pièces potentiellement substituables, 40 repères laissés natifs, couverture source visée 4/6 = 66,67 % de cette famille seulement. Une seule variante est active à la fois; les LOD peuvent réduire les modèles réellement affichés.

L'inventaire précédent de stations périphériques (16/23 = 69,57 %) représente une famille DIFFÉRENTE. Ces deux taux ne sont pas additifs et ne représentent toujours pas une mesure globale des éléments 3D de Chaos Survival. L'intégration future doit vérifier la véritable provenance de l'asset, la taille, le streaming et le budget Android avant de masquer quatre anciennes Parts, et garder le néon et l'antenne.

Pas de compilation Roblox Engine, test Android ni publication de jeu revendiqués pendant cette phase de fabrication.