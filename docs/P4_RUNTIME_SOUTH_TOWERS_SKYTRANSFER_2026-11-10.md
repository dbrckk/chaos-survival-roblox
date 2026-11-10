# P4 — South Towers : intégration du transfert suspendu original

**10 novembre 2026 — code source intégré, aucune Place Roblox publiée.**

Le workflow [#42833322096](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42833322096) a validé le générateur OBJ/glTF original : **3 172 triangles**, sept matériaux PBR, dimensions **19,65 × 4,42948 × 2,94874 studs** à l'échelle 1:2. L'import authentique créateur a retourné le Model **`120959181274080`**, modération **Approved**.

`PremiumSouthTowersSkytransferAssets.lua` charge ce Model sans bloquer la partie, puis vérifie sa nature 7 MeshParts non physiques et son enveloppe. `ApprovedSouthTowersSkytransferMeshKit.lua` vérifie la carte `GeneratedMap/Arena` Towers, le monument sud, la base, et les deux formes natives `SkyTransfer` (40×2,1×6) et `UnderslungLift` (7×7×6), à leur emplacement et orientation attendus. Les deux fûts, couronnes, rails, suspensions et le signal doivent rester présents et ne sont pas remplacés.

Le modèle sculpté est mis à l'échelle uniformément, puis ses sept MeshParts non collisionnels sont montés **avant** le masquage atomique des deux natives. Les natives sont restaurées si la source manque, si la carte change, si des éléments disparaissent, si la base est réduite, si le profil est Low ou si la pression GPU impose un repli. Le kit utilise l'échantillonnage existant `scenery-lod.client.lua` et `VisualBudgetRules.lua`, sans nouvelle boucle graphique. Les compteurs clients reflètent les deux remplacements réellement actifs.

**Non vérifiés :** compilation Luau Roblox Engine, capture visuelle de la cabine et des renforts, FPS Android, rendu en StreamingEnabled et publication du jeu public. Le code source intégré ne prouve pas le rendu en jeu.
