# Chaos Survival — stations périphériques : coques originales 3D conservées pendant le rétrécissement

Date : 13 novembre 2026. Dépôt : `dbrckk/chaos-survival-roblox`, branche `main`.

## Défaut identifié

`ApprovedPerimeterArmorMeshKit.lua` rejetait les quatre stations de toute arène dès que `Base.Size.X` ou `Base.Size.Z` descendait sous 318 studs. Or Shrinking Arena réduit **uniquement le plancher jouable** ; les stations de périphérie et leurs deux ailettes de service restent à leur emplacement serveur. Cette condition provoquait la disparition de sculptures créateur approuvées et la réapparition des WedgeParts natifs en cours de manche.

## Correction du rendu

Le même contrôle `authenticBase(base,arena)` est désormais partagé entre la vérification des quatre stations, le calcul de sélection caméra et le suivi événementiel de leur base. Il valide `OriginalSizeX/Z` signés par `MapBuilder` (au moins 318), la présence de la vraie Base ancrée, collidable, dans sa véritable arène, une taille live strictement positive et **aucune expansion au-delà de la taille de départ**. Le plancher peut se contracter sans invalider les sculptures fixes.

Les changements sont limités à la persistance de la sélection et au retrait des modèles invalides ; suivi de `Anchored` et des deux attributs d'empreinte pour retirer immédiatement les sculptures si la provenance physique change.

## Budget, couverture et restrictions

- **Low** : au plus **1 station** à ≤105 studs, soit **deux modèles originaux de sept MeshParts** pour les deux ailes de service, sans suppression des deux caps de signal.
- **Medium** : au plus **1 station** à ≤170 studs, avec quatre modèles de sept pièces pour les caps et les ailes.
- **High** : au plus **3 stations** à ≤245 studs, ramenées à **2 sur tactile**, avec réduction sous pression GPU comme avant.
- Les modèles, 7 MeshParts/source, provenance créateur/modération, exactitude de l'empreinte native, LOD, absence de collision, rétrocompatibilité et signaux de danger restent inchangés.
- Les cinq cartes contiennent **20 stations potentielles**, mais une seule arène existe à la fois. Ce correctif améliore leur **éligibilité visuelle pendant Shrinking Arena**, et n'affirme ni 20 modèles actifs ni un gain de FPS mesuré.

## Contrôles

L'audit source existant `tools/audit_visual_structure_sources.py` vérifie les garde-fous d'empreinte d'origine et de pression. La compilation et les vérifications Roblox Engine doivent être attribuées à l'**exact commit** de ce correctif après exécution. Les captures Android/PC, l'effet sur les FPS et la publication publique restent distincts et non certifiés par la seule analyse du code.
