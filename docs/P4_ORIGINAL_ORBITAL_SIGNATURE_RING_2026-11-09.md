# P4 — Anneau réacteur géant sculpté pour Orbital

9 novembre 2026. Fabrication d'un Model original, sans mise à jour de Place.

## Cible réellement auditée

Dans src/server/MapBuilder.lua, la variante Orbital possède un ArenaSignatureMegastructure situé au nord, hors du terrain jouable. Son anneau vertical est encore constitué de **16 petits Parts rectangulaires ReactorArc1 à ReactorArc16**, répartis en cercle de rayon 20 studs et centrés à y=29. Le cœur lumineux et les deux supports de l'anneau sont des composants indépendants qui doivent rester.

## Nouveau mesh original

Le générateur tools/generate_original_signature_orbital_ring.py construit une vraie sculpture 3D avec quatre tore continus concentriques dont le centre est réellement creux, soixante-douze segments autour de la circonférence, des conducteurs métalliques, seize ventilations en relief et des indicateurs récessés. Sept groupes de matériaux PBR d'origine, un glTF indépendant, pas de Roblox Parts utilisés pour fabriquer le mesh. Le modèle source (diamètre environ 17 studs) est adapté par homothétie uniforme à un anneau de diamètre ≈41 studs lors de l'installation locale.

La vérification de la source OBJ et glTF dans .github/workflows/one-time-original-orbital-signature-ring-20261109.yml est obligatoire avant toute création d'asset Roblox. Seule une confirmation Moderation Approved et un Model ID réellement renvoyé par Roblox permettent l'intégration en source. L'import Model ne publie jamais de Place.

## Contrat runtime

À intégrer après approbation : seul GeneratedMap/Arena Orbital et le modèle ArenaSignatureMegastructure réellement construit par MapBuilder sont autorisés. Les seize ReactorArc doivent être présents, non physiques, avec dimensions, couronne et orientation exactes; monter les sept MeshParts complets AVANT de masquer le moindre arc. Garder Supports, RingFoot, SuspendedReactorCore, CoreRetainer et toute la logique de catastrophes originels intacts. Restauration automatique si streaming partiel, modèle absent, qualité Low, forte pression GPU, changement de carte, socle de terrain réduit. Le kit doit être cadencé par scenery-lod.client.lua et compté dans VisualBudgetRules.lua, sans nouvelle boucle.

Le résultat visé remplace seize blocs graphiques par une seule sculpture authentique, et non seize nouveaux meshes indépendants. Cela ne prétend pas mesurer la couverture 3D globale. Tests Engine/Android et déploiement public à réaliser au jalon de publication exact-SHA.
