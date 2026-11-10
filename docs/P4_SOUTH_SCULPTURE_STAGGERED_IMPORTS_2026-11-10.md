# P4 — Réduire le pic de huit importations 3D sud à la 49e seconde

10 novembre 2026 — audit du code serveur et correctif ciblé du calendrier
de chargement. **Huit** chargeurs non physiques des ensembles sud
appelaient potentiellement `AssetService.LoadAssetAsync` à la
même 49e seconde après leur démarrage : les cinq structures centrales
Classic/Crossroads/Harbor/Orbital/Towers, plus deux extensions sud Towers
et l'anneau d'observation sud Orbital.

Ces huit sources sont toutes des **Models propriétaire Approved** déjà
enregistrés. Le code runtime et les kits LOD ont été conservés.

Le module partagé `PremiumActiveVariantImportSchedule` choisit
maintenant l'horaire par arène active :

| Source sud | Si arène active | Sinon |
| --- | ---: | ---: |
| Classic observatoire | 59 s | 101 s |
| Crossroads échangeur | 59 s | 115 s |
| Harbor drydock | 59 s | 129 s |
| Orbital finition | 59 s | 143 s |
| Towers finition | 59 s | 157 s |
| Towers skytransfer | 75 s | 171 s |
| Towers lift twins | 91 s | 185 s |
| Orbital observation ring | 75 s | 199 s |

Une carte Classic/Crossroads/Harbor active bénéficie donc d'un
modèle sud prioritaire ; Orbital de deux ; Towers de trois. Pour une
carte manquante, seules les fenêtres de secours s'appliquent.

La régression source vérifie les huit IDs authentiques, l'absence
d'import initial systématique à 49 s, les **huit créneaux distincts**
pour toutes les cinq variantes et l'absence de nouvel appel ou de
boucle réseau. Les retries, la désinfection `OriginalMeshScenery`,
les sept MeshParts d'origine, la physique et les natives de secours
restent inchangés.

**Attention :** cette correction répartit les délais nominaux ; elle
ne constitue PAS un verrou d'exclusion mutuelle des appels Roblox.
D'autres chargeurs (environnements, façades, ciel et décor) restent
indépendants ; les durées d'appels et de réplication peuvent se
chevaucher. La mesure de pression réelle AssetService et des FPS
Android requiert Roblox Studio et un appareil de test. Aucune
nouvelle publication de la Place n'est revendiquée.
