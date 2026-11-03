# Chaos Survival — véritable grand portique d'arène 3D original dans le lobby

**3 novembre 2026 — lot visible VIS-012.**

## Traçabilité des vrais assets

- Script de fabrication original et reproductible : `tools/generate_original_lobby_gate.py`.
- Sculpture 3D : portique industriel à deux grands pylônes usinés, consoles, systèmes hydrauliques, haubans diagonaux, nervures, travée mécanique et couronne arquée.
- Sept groupes de matériaux 3D originaux (acier, alliage, carbone, grip, etc.), normales, coordonnées UV et tangentes glTF 2.0.
- Source, géométrie, UV/tangentes, tout le code Luau et construction complète Rojo **validés** : [source gate #41647780811](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41647780811).
- Import Roblox Open Cloud du propriétaire `9774173158` **réel, approuvé par modération** : Model `136009650118642`, [import #41648061984](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41648061984).
- Ces modèles sont des packages Roblox `Model`, jamais des `MeshId` inventés ou des Parts déguisées.

## Intégration en jeu

- Le serveur charge uniquement cet ID approuvé dans `PremiumLobbyGateMeshAssets.lua`. La routine existante `OriginalMeshScenery.sanitize` garde uniquement les vrais MeshParts et leurs apparences inertes, puis confirme les dimensions d'origine (largeur 24–28, hauteur 18–22, profondeur 4–8).
- Le client `lobby-gate-original-3d.client.lua` attache une seule copie `OriginalLobbyGate3DLocal` à la position du VRAI `ArenaGateTop`, après vérification des deux piliers physiques existants.
- Le chemin central de l'arche originale de largeur ~18 studs reste libre : piliers latéraux au-delà de x=+/-8.5, nouvelle couronne au-dessus de l'ancien panneau, **aucune surface 3D sur le texte natif "ARENA LINK"**. Les panneaux d'interface et les indicateurs de départ gardent leur propre contrôleur.
- Toutes les pièces importées sont `Anchored`, `Massless`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false`. Les scripts et autres composants non conformes sont supprimés pendant l'assainissement. Les collisions, le lobby spawn, le téléport, la progression et les bots restent au serveur.
- La copie locale écoute les arrivées/suppressions du map streaming et de l'asset approuvé : aucun nouveau `RenderStepped`, `Heartbeat`, `while`, `RemoteEvent` ou Tween. La source ne déplace pas le portail natif.
- Sur Android Low comme High : un seul portique de **sept MeshParts maximum attendu** (vérification de sécurité 1–12), inclus dans le recensement mobile `VisualBudgetRules.LocalFolders`; fallback natif si absent ou refusé. Attribut de diagnostic `LocalOriginalLobbyGateMeshCount`.

## Conditions de sortie / limites

Après fusion, **ne pas prétendre le résultat public** avant la validation du SHA final par Build Validation, les cinq suites Roblox Open Cloud et la publication contrôlée sur l'univers `10771083668` / lieu `95351659174730`.

Une validation de source et de moteur n'est **pas** une capture Studio authentique : vérifier sur vrai téléphone Android l'orientation, la superposition avec le SurfaceGui natif, la visibilité de l'accès, la lumière et les FPS Low/Medium/High. Ne pas cocher toute la catégorie VIS-012 sans ce contrôle ; le noyau et les sols du lobby contiennent encore des formes primitives à convertir.
