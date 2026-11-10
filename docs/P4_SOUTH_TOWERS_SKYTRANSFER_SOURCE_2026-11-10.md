# P4 — South Towers, échangeur suspendu sculpté

**État : générateur source initial. Import Roblox et montage non effectués.**

Le modèle `SouthHorizonMonument` de la variante Towers conserve actuellement une poutre `SkyTransfer` (Part 40×2,1×6, CFrame local 0,36,0) et une cabine suspendue `UnderslungLift` (Part 7×7×6, CFrame local 3,5,31,5,0). Le nouveau générateur `tools/generate_original_south_towers_skytransfer.py` crée une alternative géométrique originale, avec deux poutres profilées en dix facettes, 24 diagonales, 24 contreventements, revêtement à relief, cage d'ascenseur réellement ajourée, montants, grilles et signalisation 3D.

La source est normalisée 1:2 autour de l'enveloppe native 40×9,05×6 studs (centre local 0,32,525,0). Sept matériaux industriels sont employés. Aucun `MeshId` n'est inventé.

**Important :** ce lot ne remplace **aucune** primitive dans le jeu tant que la validation OBJ/glTF et l'import Roblox propriétaire modéré Approved n'ont pas abouti. Le montage futur doit vérifier les deux formes et préserver les fûts WestLift/EastLift, couronnes, suspensions et signalisation. Il doit utiliser le sampler LOD existant et restaurer les deux natives si la source est absente, la carte change ou la pression GPU augmente. Aucun comportement physique, bot ou partie n'est modifié.
