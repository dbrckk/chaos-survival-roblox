# P4 — Traverse ajourée et blindage de générateur authentiques

**9 novembre 2026.** Fabrication originale et import de Model uniquement ; aucun changement dans la Place publiée.

## Périmètre exact

Dans la fonction addPerimeterStations de src/server/MapBuilder.lua, chacune des quatre vraies stations possède CrossBrace (9,1 × 0,65 × 1,25 studs) et GeneratorShield (4 × 0,55 × 1,4 studs), deux gros blocs Part rectangulaires encore natifs. Dans les cinq variantes, cela représente 2 × 4 × 5 = **40 formes-source à remplacer**.

Le nouveau générateur source tools/generate_original_perimeter_structures.py construit deux meshes distincts, originaux et triangulés : une traverse en acier ajourée avec deux longerons indépendants, un réseau de diagonales en vrai relief, fixations céramique et capteurs ; un blindage de générateur ouvert au centre, avec absorbeurs, renforts, conduits et fenêtre d'état. Sept matériaux d'origine, aucun contenu tiers. Les détails sont de la vraie géométrie, non des Roblox Part rajoutés.

Les nouveaux profils perimeter_crossbrace et perimeter_generator_shield sont autorisés dans l'uploader source existant. Le workflow .github/workflows/one-time-original-perimeter-structures-20261109.yml vérifie les deux OBJ indépendants, dimensions, triangles, matériaux, et glTF avec UV/normales/tangentes. Il importe en série deux Models créateur, en maintenant la priorité des API et **sans jamais publier une expérience Roblox**.

## Mesure des formes de station

Audit statique de MapBuilder : **23 éléments natifs par station**, dont 2 éléments conditionnels selon la variante, tous cosmétiques et non physiques. Avant ce lot, quatre kits visent 12 éléments par station (piliers 2 + machines 3 + turbines 3 + ailes/capots 4) : **12 / 23 = 52,17 % de couverture source potentielle**. Avec traverse et blindage source-authentiques intégrés, ce serait **14 / 23 = 60,87 % de couverture potentielle** et **9 / 23 = 39,13 % restant natif**. Ce décompte ne correspond pas au taux de conversion de l'intégralité de Chaos Survival et n'est pas un taux de rendu effectif : les kits sont conditionnés par les imports approuvés, le Streaming et le LOD caméra ; Android Low n'affiche pas ces meshes optionnels.

Les 9 cibles natives qui resteront dans chaque station après ce lot sont : base incrustée (1), lumière de pilier (2), lentille centrale (1), repère de chemin (1), rails data des compresseurs (2) et les 2 composants de silhouette propre à la variante. Le nombre couvre les quatre stations et les cinq variantes en définition, mais pas l'ensemble des autres décors, plateformes, environnement, lobby, effets, architecture et accessoires.

## Prochaine étape

Ne renseigner les IDs Roblox et ne brancher les deux meshes au runtime **qu'après** réception de deux imports avec `Moderation: Approved`. Une fois source qualifiée, ne masquer aucune primitive si le clone 3D ne valide pas gabarit, orientation, provenance et streaming. La publication du jeu reste soumise au jalon exact SHA et à la vérification Roblox Engine/Android.
