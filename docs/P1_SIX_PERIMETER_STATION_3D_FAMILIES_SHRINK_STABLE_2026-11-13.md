# Chaos Survival — P0/P1 : six familles 3D des stations périphériques préservées pendant Shrinking Arena

**13 novembre 2026** · `dbrckk/chaos-survival-roblox`, branche `main`.

## Cause commune confirmée

Six kits 3D des quatre `PerimeterStationNorth/East/South/West` refusaient les vraies stations dès que `Base.Size.X/Z` descendait sous 318 studs. Ce changement de taille est pourtant le fonctionnement normal de Shrinking Arena. Les structures périphériques sont fixes, non physiques, et leur authenticité doit être validée à l'aide de l'empreinte **initiale** `OriginalSizeX/Z` créée dans `MapBuilder`.

Les kits corrigés sont `ApprovedPerimeterStructuresMeshKit` (poutres et boucliers), `ApprovedPerimeterButtressMeshKit` (contreforts), `ApprovedPerimeterStationDeckInlayMeshKit` (inserts de plateaux), `ApprovedPerimeterMachineryMeshKit` (machineries), `ApprovedPerimeterRotorMeshKit` (rotors), `ApprovedPerimeterVariantApexMeshKit` (couronnements propres aux variantes). L'habillage `ApprovedPerimeterArmorMeshKit` a été corrigé dans le commit précédent.

## Résultat attendu et critères de sécurité

- Toutes les vérifications live de largeur minimale 318 dans ces six modules sont remplacées par un contrôle commun local : vraie Base dans la vraie arène, ancrée et collidable, empreinte initiale X/Z numérique ≥318, taille courante strictement positive et jamais élargie au-delà du constructeur (+0,2 stud de marge).
- Le modèle original est toujours validé, modéré et monté **entièrement** avant masquage de ses primitives natives.
- Les limites Low/Medium/High, réductions GPU, distances caméra, nombre d'imports, budget Android, animations déjà présentes et gestion du streaming sont conservés.
- Les collisions, catastrophes, trajectoires, avertissements lumineux et éléments natifs de repli ne sont pas modifiés.

Ce lot touche les quatre stations fixes de chacune des cinq cartes (20 stations de définition, **pas** 20 stations simultanées). Il accroît l'éligibilité des MeshParts d'origine pendant la contraction du terrain ; ce n'est ni une preuve que toutes les sources sont présentes sur chaque client ni une mesure de FPS.

## Vérification

L'audit source existant `tools/audit_visual_structure_sources.py` impose désormais `OriginalSizeX/Z` et refuse la régression du seuil de largeur live sur ces six modules, en complément du contrôle de `ApprovedPerimeterArmorMeshKit`. Les tests moteur, captures PC/Android et publication du jeu public sont **distincts** et ne sont pas prétendus réussis tant que non exécutés sur ce commit.
