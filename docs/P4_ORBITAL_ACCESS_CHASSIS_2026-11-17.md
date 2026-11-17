# Châssis de rampes Orbital

Les huit rampes d’accès et les sept rampes du réacteur possèdent un châssis décoratif rectangulaire. Le dessous des grandes rampes Helix utilise une autre structure sculptée, plus profonde, destinée aux travées suspendues.

La planche de référence générée le 17 novembre 2026 a guidé la forme des longerons bleu nuit, les quatre travées ajourées en X, la cassette octogonale centrale, les selles en titane et les inserts en laiton. SHA-256 de la planche PNG : `5b71477b0344bc1d5c157f5e06486322122f967ee11f56773fd7824f8e4ee8a9`.

Le modèle `orbital_access_chassis` est reproductible à partir de `tools/generate_original_remaining_structures.py` et de sa palette MTL. Il contient 2 352 triangles et sept régions de matériaux PBR, dans une enveloppe de 5,17 × 0,507 × 12,8 studs. Quatre attaches relient la cassette aux longerons. Le modèle est destiné à la sous-face et ne comprend ni collision ni signal lumineux.

Roblox a approuvé le modèle `106401955318567` lors de l’import [44064536419](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/44064536419).

Le montage utilise la boucle LOD existante. Les 15 rampes sont éligibles. En qualité basse, un châssis à moins de 65 studs peut prendre la place du casing décoratif dans le budget existant. En qualité moyenne et haute, les châssis partagent le quota des grandes rampes Helix. Le remplacement suit le rétrécissement de l’arène. Si un danger se déclenche ou si le maillage disparaît, la pièce native reprend sa transparence d’origine. La mesure `LocalOriginalOrbitalAccessChassis3DCount` indique combien de châssis sont affichés côté joueur.
