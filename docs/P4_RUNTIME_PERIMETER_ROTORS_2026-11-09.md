# P4 — Remplacement réellement branché des rotors primitifs des stations

**9 novembre 2026 — code source intégré, non publié dans Roblox.**

## Provenance réelle

Le nouveau rotor a été généré par tools/generate_original_perimeter_rotor.py : 1 304 triangles, 32 groupes sources, 7 matériaux, 2,56 × 0,8155 × 2,56 studs. Le run GitHub Actions **#42691052644** a vérifié l'OBJ et ses normales/UV/tangentes, puis a réellement créé le **Model Roblox 133526819668194**. Le log de l'upload rapporte **Moderation: Approved**. L'ID figure désormais dans assets/source/roblox-asset-registry.json ; ce n'est pas un MeshId fabriqué ou une preuve de rendu sur Android.

## Code intégré

- src/server/PremiumPerimeterRotorAssets.lua : chargement AssetService.LoadAssetAsync retardé et indépendant du gameplay ; assainissement via OriginalMeshScenery.sanitize et vérification de 7 véritables MeshParts avec des dimensions de disque uniquement, quel que soit l'axe mince après import.
- src/client/ApprovedPerimeterRotorMeshKit.lua : quatre vrais modèles PerimeterStationNorth/East/South/West dans la GeneratedMap active, un noyau mécanique et les trois vrais cylindres natifs exactement identifiés. Les trois clones 3D d'une station sont montés **atomiquement** avant masquage local de ses 3 cylindres. Rejet total si un seul modèle source est incomplet ou n'entre pas uniformément dans le gabarit de la pièce.
- src/client/scenery-lod.client.lua : réutilisation de l'unique cadence caméra existante, sans nouvelle boucle, tween ni service distant côté client. Les latences d'arrivée du source AssetService sont récupérées par la cadence existante.
- src/shared/VisualBudgetRules.lua : le dossier ApprovedPerimeterRotorsLocal est explicitement compté dans le census de parties locales 440/680/900, chaque rotor contenant **7 MeshParts**, soit 21 par station montée. Aucune allocation hors quota.

| Qualité | Stations max | Cylindres natifs remplacés max | MeshParts additionnels max |
| --- | ---: | ---: | ---: |
| Low | 0 | 0 | 0 |
| Medium | 1 | 3 | 21 |
| High Android | 2 | 6 | 42 |
| High PC | 3 | 9 | 63 |

Pression GPU optionnelle 1 : limite de stations divisée par 2 (arrondi inférieur). Pression 2 : retrait de toutes les sculptures et restitution des cylindres d'origine. Seules les stations proches (170 studs Medium, 245 High) sont candidates ; rétention de 16 studs pour éviter les oscillations visuelles.

Chaque MeshPart est ancré, Massless, CanCollide/CanTouch/CanQuery/ CastShadow à false et ne peut intervenir dans les collisions, l'IA ou les catastrophes. Une source absente/refusée, une station partiellement streamée, un morceau détruit, une carte changée, ou une diminution de la base restaurant le fallback natif sont gérés. Les attributs clients LocalApprovedPerimeterRotorStationCount et LocalPerimeterPrimitiveRotorsReplaced reportent uniquement les montages réellement présents, non des statistiques FPS.

## Statut de sortie

**Non exécuté ici :** compilation Luau / Rojo, tests Roblox Engine, captures Android, benchmark FPS et publication. La dernière mise à jour publique attestée demeure P2 ae4ae044e991ef4ca28a991991f2e11b9df49c84 (workflow #42650986552). Avant le jalon de publication exact-SHA : vérifier que les 7 MeshParts provenant du Model approuvé sont bien rendus, que les pales ne traversent pas les trois gabarits natifs orientés, que le chargement tardif et les réductions de qualité restaurent les trois cylindres, et que le FPS Android ne régresse pas.
