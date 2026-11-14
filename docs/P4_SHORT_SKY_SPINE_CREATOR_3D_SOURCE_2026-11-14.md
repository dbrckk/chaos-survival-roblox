# P4 — Nouveau sous-châssis 3D original pour les Sky Spine courts

**État : source 3D créée, import Roblox et validation du MeshId à venir.**
La source `tools/generate_original_short_sky_spine_cradle.py` produit un
assemblage industriel **réellement triangulé**, ajouré, avec sept familles
matière, longerons chanfreinés, treillis triangulés, amortisseurs,
écrans céramique, canaux carbone et signaux embarqués. Aucun Part Roblox
supplémentaire ni collision fictive n'est créé.

Les vrais Sky Spine (12 studs de largeur, environ 18 à 22 selon la carte)
ne rentrent pas tous dans le module LongCradle approuvé de 22 studs.
Ce modèle vise **l'extrémité courte** ; il devra être soumis à l'import
Roblox du créateur, recevoir un ID Model véritable et une modération
Approved avant toute liaison runtime. Le modèle LongCradle original
reste la bonne source pour les tronçons plus longs. Ne jamais réutiliser
l'ID de LongCradle pour prétendre que le nouveau modèle est importé.

Le workflow `p4-short-sky-spine-original-source.yml` vérifie les
dimensions, la topologie, les triangles, les sept matériaux et
l'export glTF self-contained. Il archive les fichiers OBJ/glTF et
leurs métriques pour inspection. **Il ne publie aucun asset**. La
prochaine intégration autorisée utilisera le registre
`roblox-asset-registry.json`, le chargement Model propriétaire et
le propriétaire LOD déjà en place, sans relèvement Android et avec
réversion native en cas de streaming incomplet.

Aucun pourcentage de formes remplacées en jeu ni gain FPS n'est
revendiqué tant que l'asset n'est pas réellement approuvé, monté et
testé sur les cinq variantes.

## Modèle réellement approuvé et chargé en production (14 novembre)

Le workflow [43643193625](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43643193625) a retourné le véritable Model Roblox **140716716476069**, avec statut **Approved**. Il rejoint le registre des **111 assets d'origine approuvés**. Le chargeur serveur vérifie ses sept MeshParts et les dimensions publiées (10,13 × 2,34 × 16,52 studs) puis la même file sérialisée de chargement Roblox que les autres modèles. Le kit client ne sélectionne ce modèle que pour un deck Sky Spine réellement collidable et stable, de longueur compatible, avec sous-cadre natif et truss complètement streamés. Il partage le même quota LOD qu'un LongCradle, garde ses conditions de repli et ne crée aucune collision.
