# P4 — Murs latéraux premium sans trous, vrais maillages propriétaires et restauration immédiate

**12 novembre 2026.** Correction de l'architecture visible à hauteur des joueurs dans les cinq arènes, fondée sur les quatre modèles de façades/toitures approuvés et les pièces réellement créées par `ArenaDistrictArchitecture`.

## Audit de la géométrie

Les modèles créateur approuvés `district_observatory`, `district_freight`, `district_turbine` et `district_aerial` couvrent le bardage **avant** et le toit/monument. Le modèle serveur conserve des volumes natifs qui **ne sont pas dupliqués par une enveloppe 3D latérale** :

- `ArmoredSupportL/R` : deux piliers en profondeur ;
- `SideCassette-1/1` : surfaces métalliques des côtés ;
- `ServiceCore` : volume central et murs derrière l'entrée ;
- `SideGlass-1/1`, `DataVaneL/R`, `RecessedSignal` : fenêtres et navigation ;
- `ServiceEntryDoor` et `ServiceEntryRecess` : accès lisibles sur le parcours ;
- `BasaltFoundation` et `FoundationRim` : fondations.

Ces éléments **ne doivent pas être masqués** tant qu'un véritable maillage latéral créateur approuvé n'existe pas : cacher les supports ou le noyau produirait un bâtiment ouvert/transparent.

## Changements réels

### 1. Supprimer les doublons cachés, pas les murs légitimes

- `PremiumDistrictFacadeMeshKit` marque localement le bâtiment lorsqu'un véritable modèle validé est en place (`LocalApprovedDistrictFacadeMounted`).
- `DistrictFacadeDetailKit` ne recrée plus les **quatre petits détails Medium** (linteau, auvent, 2 colonnes hydrauliques) et les **deux détails High supplémentaires** déjà couverts par un vrai maillage. Il détruit ces six pièces locales lorsqu'une façade validée prend le relais.
- Dès que le modèle source est absent, la marque est effacée avant le retour des formes natives. Le kit de détails les recrée au prochain passage LOD si le profil est visible et proche. La porte serveur demeure constamment présente.

**Gain maximal théorique :** jusqu'à 4 pièces locales évitées par bâtiment remplacé Medium (5 modèles, 20 pièces) et 6 par bâtiment remplacé High (12 modèles, 72 pièces) — **pas des chiffres de FPS ou de résidence réellement mesurés**.

### 2. Matériaux des vrais murs latéraux, sans mentir sur la géométrie

Le sélecteur PBR existant donne priorité, quand la façade approuvée est résidente, aux surfaces latérales natives `SideCassette±1`, aux piliers `ArmoredSupportL/R` et au `ServiceCore`. Le matériau suit la surface : acier corrodé → finition oxydée, supports blindés → plaque d'armure, noyau métallique → titane brossé, céramique → céramique.

- Réutilise les **quatre MaterialVariants PBR approuvés** (aucun nouvel ID/image).
- Même quota global Android et par propriétaire : aucune allocation PBR en Low, pas de nouveaux MeshParts, Part, rendu par frame ni réseau.
- La sélection conserve le filtre de proximité, visibilité et pression GPU existant. Les panneaux de signalisation, les vitrages, les portes et les pièces physiques sont protégés par les règles existantes.

### 3. Corriger le défaut de fallback des propriétaires 3D

Les deux propriétaires `PremiumDistrictFacadeMeshKit` et `ApprovedCornerMonumentMeshKit` surveillent désormais l'ascendance et la suppression des véritables `MeshPart` sur le **clone actif et sa source approuvée**. En cas de stream-out, éviction par le budget visuel, perte d'une partie du modèle ou suppression du package source :

1. marquer l'entrée comme abandonnée **avant** de détruire les clones (sécurité réentrance) ;
2. déconnecter tous les événements du modèle ;
3. restaurer l'apparence du décor natif ;
4. supprimer le clone invalide sans laisser de vide architectural ;
5. respecter les quotas et la synchronisation existants pour un éventuel remontage ultérieur.

Les contrôles de modèle intégral et de source approuvée sont également relus à chaque passage LOD : un modèle avec des groupes manquants n'est jamais considéré comme une façade complète.

## Invariants et validation

Aucune mutation de collisions, d'IA, de météo, de lumières, d'ombres, de positions/rotations de portes, de texture ID ni de source Roblox. Les 16 bâtiments et les 4 monuments d'angle conservent leurs plafonds de résidence : districts 1/5/12 et angles 1/4/4 en Low/Medium/High. Toutes les nouvelles réactions sont déclenchées par événements de source, **pas par une nouvelle boucle**.

Contrôle source étendu : `tools/verify_original_3d_budget_census.py`. Vérifier aussi les workflows existants de finitions de quartier et de budget 3D.

**Validation restant à obtenir :** contrôle authentique Studio/Android des murs latéraux et des façades à différentes distances ; disparition d'un modèle approuvé avec restauration immédiate ; compteur `LocalFacadeDetailCount` réduit lorsqu'une sculpture est visible ; stabilité GPU/FPS et absence de silhouette coupée en Low/Medium/High. Le contrôle source CI ne remplace pas ce test moteur. Aucun déploiement de l'expérience publique ne découle de la fusion GitHub.
