# P4 — Grand cargo maritime 3D sur Android Low

**13 novembre 2026** — intégration sur `main`; publication Roblox distincte et non présumée.

## Déficit visuel identifié

`src/server/HarborScenery.lua` construit un grand cargo fixe, non physique, au nord de Storm Harbor. En qualité Low, le LOD conservait une silhouette de **14 grosses pièces natives**, et `src/client/HarborFreighterMeshKit.lua` interdisait complètement le remplacement par son vrai modèle 3D. Le modèle créateur déjà vérifié et Approved `128820723471019` contient **7 MeshParts source, 4 918 triangles**, avec cales, conteneurs et superstructure. L'import serveur existant reste borné à deux requêtes simultanées par `PremiumApprovedAssetImportGate`.

## Modification réellement intégrée

- **Low sain uniquement** : autorise **un** cargo source authentifié à une distance caméra inférieure ou égale à **295 studs**. Seuls **7 vrais MeshParts**, sans collision ni ombre, sont montés localement ; le modèle natif est masqué après validation atomique et restauré au retrait.
- **Low sous pression graphique `OptionalVfxPressure >= 1`** : rétablit immédiatement la silhouette native, sans toucher aux routes, aux collisions ou à l'IA.
- **Qualités Medium et High** : conservées à **440** et **610 studs**, avec recul natif à pression 2. Hystérésis de **45 studs** pour éviter les changements excessifs au bord du champ.
- **Shrinking Arena** : l'authenticité du plancher est vérifiée grâce à `OriginalSizeX/Z` signés et à sa parenté réelle ; son rétrécissement normal ne supprime pas les modèles de cargo au large.
- **Visibilité des formes natives** : chaque composant original reste disponible, avec restauration des valeurs d'origine. La qualité Low n'ajoute aucun navire, aucune plate-forme physique ni aucune nouvelle boucle de mise à jour.
- **Chargement** : en variante Harbor active, demande d'import à **48 secondes** au lieu de 66 ; autres variantes inchangées. C'est l'heure de **début de tentative**, non une garantie de résidence.

## Régressions automatisées

- Test Roblox Engine existant `tests/engine/native-premium-fallback.spec.luau` enrichi : montage de 7 MeshParts ; source/natifs intacts ; Low proche / Low loin / pression 1 ; arène rétrécie ; pression 2 High ; rejet d'un plancher artificiellement agrandi.
- Contrôles source `tools/verify_active_variant_signature_schedule.py` : limite Low, pression, distance, source approuvée, import sécurisé et retour aux formes natives.
- Le nouveau cargo reste recensé dans `VisualBudgetRules.LocalFolders` (budget **440 Parts Low**, **680 Medium**, **900 High**). La surveillance Android existante peut dégrader les effets sous pression de FPS.

**Limites de preuve :** ces contrôles vérifient le comportement prévu et la compatibilité source/moteur. Ils ne constituent pas des captures Android, des mesures de FPS/p95 réelles, ni une vérification de rendu AAA ou de publication publique. À mesurer sur un véritable téléphone Low : FPS p50/p95, mémoire, temps avant première apparition et bascule pression 0→1→0 pendant les manches.
