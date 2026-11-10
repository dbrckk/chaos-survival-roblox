# P4 — Disponibilité plus rapide des quatre sources 3D d'horizon

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
