# Chaos Survival — P0: sous-cadres de plateformes et vérification réelle des 3D

**Branche :** `main` — **Date :** 13 novembre 2026

## Problème avant correction

Le recensement Roblox Engine des cinq variantes contient **520** pièces primitives `PlatformUnderFrameN` visibles dans les cinq définitions d'arène ; le stock serveur des cinq cartes *n'est pas* 520 objets simultanément visibles ni 520 modèles dépourvus de solution 3D.

Pour les longues plateformes `PromenadeStep` et `SkySpineStep`, le client possède déjà un authentique original 3D `LongCradle` (`128914328933863`), un châssis industriel ouvert approuvé, non physique et monté avec des `MeshPart`. Avant ce correctif, la fonction `selectNearRouteStructures()` sélectionnait sur **Medium/High** des plateformes de 19,5–34 studs sans vérifier les conditions de couverture de la véritable sculpture. `longCradle()` recalculait ensuite l'échelle, et refusait les plateformes trop longues, trop larges ou avec modèle trop haut. Ces réservations invalides pouvaient consommer les slots rares de sous-cadres premium et laisser visibles les briques rectangulaires natives.

## Correction livrée

1. Une fonction `PremiumLargeStructureMeshKit.cradleFit(size,sourceBounds)` unique, sans création de pièces ni appels réseau, calcule le facteur uniformément applicable depuis les **vraies bornes du modèle approuvé**.
2. La même fonction gouverne maintenant **la sélection et le montage** de toutes les qualités : longueur native 19,5–34, largeur 9–18, couverture structurelle ≥87 % de la longueur et ≥76 % de la largeur, hauteur finale ≤5 studs et absence de dépassement longitudinal.
3. Les slots existants restent **Low 1 / Medium 2 / High 4** ; les postes de supports conservent leurs budgets indépendants. Les clones de source sont cosmétiques, soudés aux colliders existants et soumis aux budgets Android.
4. Lorsqu'un modèle est absent, invalide, hors écran, détruit ou lorsque la plateforme passe en avertissement/collapse, la pièce native `PlatformUnderFrameN` reste ou redevient visible. `PlatformN` collidable, ses signaux et les itinéraires restent sous contrôle du serveur.

**Limite :** le correctif améliore l'utilisation des slots **dans les cas où la géométrie du monde comporte à la fois des plateformes compatibles et incompatibles** ; il ne crée pas de nouveau modèle et ne remplace pas d'un coup les 520 sous-cadres du catalogue.

## Tests de non-régression

- Source : `tools/verify_platform_trim_mesh_ownership.py`, [contrôle vert](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43417401515) ; la sélection et l'installation doivent utiliser `cradleFit` toutes deux.
- Build : [Build Validation vert](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43417326608).
- Moteur : `tests/engine/native-premium-fallback.spec.luau` reconstruit la **vraie carte Crossroads**, utilise les vraies plateformes `PromenadeStep` et `PlatformUnderFrameN`, et n'emploie que des **MeshParts de fixture** pour simuler les sources importées au test. Vérifications : deux vrais propriétaires de sous-cadres sélectionnés en Medium, bornes réalistes, source non collidante, sous-cadre masqué seulement après montage complet, repli sur `CollapsePhase=Warning` puis disparition du modèle. [Roblox Open Cloud Engine Tests](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43417398257) : statut à confirmer.

Ne pas confondre contrôle de source, exécution du moteur, essai FPS réel Android et publication publique Roblox. Aucune mise à jour publique n'est affirmée ici.
