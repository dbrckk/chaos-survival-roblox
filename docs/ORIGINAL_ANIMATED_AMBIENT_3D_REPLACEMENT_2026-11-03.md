# Remplacement original des objets d'ambiance animés — cinq arènes

Date : **3 novembre 2026**. Catégorie VIS-026, chantier visuel majeur.

## Ce qui a été réellement créé et approuvé

Cinq objets sculptés en géométrie triangulée OBJ d'auteur, conversion glTF 2.0, UV/normales/tangentes et sept matériaux industriels distincts (ARMOR, BRUSHED, CARBON, GRIP, ALLOY, CERAMIC, SIGNAL). Chaque source a réussi ses contrôles de dimensions, groupes, triangles, glTF et reçu **Approved** par la modération Roblox dans le [workflow #41733818047](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41733818047).

| Arène | Objet source remplacé | Véritable nouvel objet 3D | ID Roblox Model |
| --- | --- | --- | --- |
| Classic | `BroadcastDrone*` et plaque `BroadcastDroneGlow*` | Drone de diffusion caréné, bras latéraux, deux groupes de rotors, antenne et capteurs | `102850052145878` |
| Towers | `LiftPod*` | Cabine d'ascenseur fermée, vitrage, rails verticaux et ventilation | `72210530094580` |
| Crossroads | `TransitMarker*` | Balise de transit directionnelle avec grille, capteurs, ailerons et signaux | `116186226477876` |
| Orbital | `SatelliteNode*` sphérique | Microsatellite trussé, panneaux radiateurs, télescope et optique directionnelle | `127850230318627` |
| Harbor | `HarborCargoHoist*` et `HarborCargoHoistTrim*` | Conteneur suspendu, crochets de levage, longerons, rivets et brides | `131294203899636` |

Ces identifiants sont des **Roblox Model asset IDs**, jamais un MeshPart.MeshId arbitraire. Les reçus figurent dans `assets/source/roblox-asset-registry.json`. Les OBJ restent reproductibles à partir de `tools/generate_original_ambient_motion.py`, sans assets externes, sans licence payante et sans serveur 3D supplémentaire.

## Intégration et sécurité

- Serveur : `src/server/PremiumAmbientMotionAssets.lua`, appelé par `src/server/init.server.lua`. Il charge les cinq modèles originalement détenus, **en différé et un à un**. Chaque import passe le sanitizer commun et un contrôle de dimensions et de contenu **100 % MeshPart**. Si un paquet manque, la machine native demeure.
- Client : `src/client/PremiumAmbientMotionMeshKit.lua` est utilisé par `src/client/arena-ambient-props.client.lua`. Les vrais meshes remplacent localement les formes natives ; ces dernières sont conservées uniquement comme points d'ancrage de mouvement, avec `Transparency=1`. Le remplacement se produit **seulement après montage et validation de tous les MeshParts**.
- Les parties importées n'ont **aucune collision, aucun toucher, aucune requête, aucune ombre**, aucun rôle dans les checkpoints, dans la physique, l'IA, les dangers ou les trajectoires d'obstacles.
- Le déplacement des modèles réutilise strictement la boucle animée existante de **10 Hz** : oscillation, translation, orbite, pulsation, animation Harbor et paramètres `ReduceMotion`. Aucun `RenderStepped` ni `Heartbeat` de plus.
- Les budgets réels sont `Low 2 / Medium 4 / High 6` **Models** au maximum dans la seule arène active, tous comptés dans le même dossier `ArenaAmbientPropsLocal` que la télémétrie graphique existante.
- Un asset ne peut être affiché que si son `OwnerVerified`, son vrai asset ID, son type, ses dimensions et sa provenance serveur concordent.
- Réaction aux arrivées tardives des templates, changement de variante, retour à la forme native si le clone est détruit, extinction de la partie, et réduction des mouvements restent pris en charge.
- `scenery-lod.client.lua` utilise le **sampler existant** (seuils Low 230 / Medium 290 studs autour du centre), car les objets sont placés hors des bords du sol de 320 studs ; un seuil Low 125 masquait ces vrais objets à la caméra.

## À ne pas confondre avec une publication

**Import et compilation source ≠ présence effective dans le jeu Roblox public.** Le registre conserve `ambient_models_inserted_in_game=false` et `android_visual_qa_completed=false` tant qu'une publication publique du SHA approprié et de vraies captures sur téléphone Android ne sont pas vérifiées. Les tests Build/Cloud restent à effectuer sur un jalon source complet ; aucune publication de place n'est impliquée dans cet import.

### Prochaines familles visuelles à remplacer

L'apparence des objets animés de ce lot n'élimine pas encore les formes de base des autres dossiers : gravure de sol et bas-reliefs `ArenaSurfaceReliefLocal`, plateformes physiques (habillage uniquement), objets du lobby, kiosques de signalisation, structures de pont et façades hors quotas. Le prochain lot doit commencer par les **vraies pièces de sol exposées** pour les cinq arènes, avec un nouveau modèle triangulé de finition et un montage qui ne touche pas aux colliders, à la lisibilité des hazards, ni au shrink.
