# P4 — Finitions 2K sur les sculptures réellement visibles, après synchronisation 3D

**12 novembre 2026.** Correctif d'intégration visuelle dans le client Roblox, applicable aux cinq arènes, aux monuments signatures et aux grues Harbor.

## Problème vérifié dans le code

Lors des lots #859 et #860, les modèles approuvés Harbor et les cinq monuments ont été admis au sélecteur de matériaux 2K, mais deux limitations subsistaient :

1. `PremiumNearfieldPbrKit.reconcile` était exécuté **avant** l'installation/actualisation des cinq kits signatures et du kit de grues Harbor dans le même passage `scenery-lod.client.lua`. Un modèle nouvellement créé n'était donc pas éligible avant le prochain passage.
2. Le sélecteur utilisait le groupe de matériau, la provenance et la distance, mais **pas la visibilité effective**. Des sculptures cachées par le LOD (`LocalTransparencyModifier=1`) ou dont la surface était transparente pouvaient donc réserver le quota GPU global 2K ou recevoir des textures invisibles.

## Correctif appliqué

- Déplacer la synchronisation PBR **après tous les propriétaires de MeshParts** du passage LOD, notamment le torus Orbital, les grandes signatures Classic/Towers/Crossroads/Harbor, la station de contrôle Harbor, ses grues animées, et les structures héroïques.
- Ajouter `visibleFinish(part, variant)`, qui vérifie les mêmes groupes UV approuvés, ainsi que `Transparency < 0.98` et `LocalTransparencyModifier < 0.98`.
- Refuser les modèles sans **aucune** surface métallique/céramique admissible **visible**.
- N'installer les clones `SurfaceAppearance` qu'aux surfaces visibles. Lorsqu'une surface auparavant peinte devient cachée (ou l'inverse), la vérification `intact` déclenche le rollback puis une réinstallation cohérente à la prochaine réconciliation, sans état mixte.
- Garder le même ordonnanceur de caméra existant ; **aucune boucle/timer supplémentaire**.

## Invariants maintenus

- Roblox Android **Low : budget PBR 2K zéro**.
- Quota de modèles et politique pression Medium/High inchangés.
- Les 16 images approuvées et les quatre familles de cartes `SurfaceAppearance` existantes sont les seules utilisées.
- Aucune modification d'animation radar/câble/charge, des `MeshPart` sources, de physique, collisions, signaux de danger, shaders, lumière ou géométrie.
- Les matériaux importés d'origine sont restaurés au déséquipement, changement de carte, culling, opt-out ou pression GPU.
- Le correctif ne garantit **pas** qu'un modèle distant à plus de 175 studs (Medium) ou 245 (High) reçoive du PBR ; il ne contourne pas les budgets.

## Validation

Le contrôle source existant `tools/verify_premium_nearfield_pbr.py` vérifie désormais que les propriétaires 3D passent **avant** le sélecteur PBR et que le filtre de visibilité s'applique aux candidats, aux clones installés et au contrôle d'intégrité. Le workflow `original-nearfield-pbr-source.yml` tourne sur PR et push `main`.

À confirmer sur un client Roblox authentifié : textes et maillages réellement visibles en Medium/High, réapparition immédiate des finitions dès le montage 3D, suppression après culling/changement de pression, continuité de l'animation et des alertes, mémoire GPU et stabilité FPS Android.

**Les contrôles source ne sont pas une mesure de FPS ni un test de rendu Roblox Engine. Une fusion GitHub ne publie pas automatiquement la Place Roblox.**
