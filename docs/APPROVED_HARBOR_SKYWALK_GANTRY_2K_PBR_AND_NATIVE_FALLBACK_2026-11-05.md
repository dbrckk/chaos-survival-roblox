# VIS-027 — Harbor promenade: véritable portique original 3D, PBR 2K et secours natif

**5 novembre 2026**, base `8afd52a3f7d7b78fc015f9b5efd5f4db0b164df2`, source non publiée.

Le portique original approuvé Roblox **134157110756659** est déjà construit sur les **six vraies plateformes** Harbor `PromenadeLane=1/2`, `PromenadeStep=2/4/7`, mais contrairement aux ponts et portiques Sky Spine voisins, ne disposait pas de PBR 2K. Une suppression inattendue du modèle 3D pouvait également laisser jusqu'au prochain échantillonnage les neuf éléments natifs masqués.

- Finition de **un seul portique** voisin par passe caméra Medium/High sans pression, zéro Low ou pression, respect du paramètre utilisateur `PbrMaterialsDisabled`. Les seules images sont les templates approuvés déjà utilisés pour les ponts : **OxidizedSteel / BrushedTitanium / ReactorCeramic**, et leurs cartes 2K. Un slot supplémentaire maximum par rapport aux owners 2K voisins, à vérifier physiquement sur Android.
- Seuls les véritables `MeshPart` du modèle propriétaire vérifié reçoivent un `SurfaceAppearance` sur les groupes `ARMOR/ALLOY/BRUSHED/CERAMIC` ; **SIGNAL, GRIP, CARBON** restent natifs. Les textures importées sont récupérées après retrait, warning, shrink ou désactivation, sans sous-coller d'autre matériel.
- Un seul `Folder.ChildRemoved` rétablit **immédiatement** les neuf supports/bandes natifs non physiques si un modèle Harbor approuvé disparaît. Démontage normal protégé de la récursion ; aucun nouveau collider, Remote, asset Roblox ou RenderStepped.
- Diagnostics réellement mesurés `LocalOriginalHarborGantryPbr2KModelCount` et `LocalOriginalHarborGantryPbr2KAppearanceCount`. Aucun FPS ni capture Android inventé.

Jalon : moteur réel sur PBR original / groupes SIGNAL-GRIP-CARBON / copies tardives / rejet d'un asset non autorisé, plus le build et les sept suites Cloud sur un SHA commun. Puis vérification visuelle **Harbor** : transitions sol, portique et passerelle, catastrophes, streaming, Low/Medium/High.

**Publication publique : non.**
