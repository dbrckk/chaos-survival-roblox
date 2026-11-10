# P4 — Anneau d’observation Orbital de l’horizon sud (source originale)

**10 novembre 2026.** Audit de \`src/server/MapBuilder.lua\` à \`addSouthHorizonMonument\` : Orbital crée **14 Part rectangulaires non physiques** \`ObservationArc1..14\` d'un anneau vertical de rayon 17 studs, centre d'origine (0,23,0), segments orientés autour de Z. Les supports \`LeftRingSupport\` et \`RightRingSupport\`, l'orbe luminescent \`SuspendedOrb\` et \`OrbClamp\` sont déjà des repères utiles et doivent rester inchangés.

Une sculpture originale de véritable tore creux à 72 sections remplace les 14 rectangles. Le générateur \`tools/generate_original_south_orbital_observation_ring.py\` crée quatre coques toroïdales concentriques réelles, 14 supports de champ, 14 modules de ventilation en volume et 14 lecteurs de signal, sept matériaux PBR et géométrie OBJ/glTF source avec UV, normales et tangentes. Ce modèle est distinct de l'anneau **nord** (\`ReactorArc1..16\`), déjà remplacé ; les deux kits ne doivent jamais masquer les mêmes primitives.

Le workflow \`.github/workflows/one-time-original-south-orbital-ring-20261110.yml\` reconstitue et vérifie les sources, puis utilise l'import original du créateur, sans publier de Place. Le code client ne doit masquer les 14 natives que si la véritable carte Orbital, la véritable \`SouthHorizonMonument\`, les 14 arcs, l'orbe et les supports sont présents, non physiques, dimensionnés et correctement positionnés. Montage atomique dans un seul dossier au budget LOD Android partagé ; restauration de toutes les natives sur perte du Model, carte modifiée, streaming, profil Low ou pression GPU.

Cette tâche est indépendante des collisions de plateformes et des hazards. L'intégration source n'est ni une preuve de FPS mobile, ni une publication du jeu.
