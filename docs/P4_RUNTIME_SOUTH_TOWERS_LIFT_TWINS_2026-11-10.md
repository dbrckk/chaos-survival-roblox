# P4 — South Towers : deux ascenseurs industriels sculptés

**10 novembre 2026 — code source de mise à jour, Place publique non publiée.**

Le workflow [#42835512896](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42835512896) a terminé avec succès la validation OBJ/glTF : **6 672 triangles**, **sept matériaux PBR**, **17,82996 × 20,046 × 2,811 studs source** (normalisation 1:2,5). L'import authentique du créateur a retourné le Roblox Model **`114886409893890`**, modération **Approved**.

`PremiumSouthTowersLiftTwinsAssets.lua` charge tardivement et valide sept MeshParts cosmétiques. `ApprovedSouthTowersLiftTwinsMeshKit.lua` vérifie le contexte `GeneratedMap/Arena` de Towers et les quatre formes natives exactes : `WestLift` (6,5×37×7), `EastLift` (6,5×46×7), `WestCrown` et `EastCrown` (WedgeParts 9,5×4,5×8,5), leurs CFrames et leurs propriétés non physiques.

Le kit exige la présence des deux natives `SkyTransfer`/`UnderslungLift`, déjà couvertes par un autre asset, ainsi que des rails, suspensions et signal. **Aucun chevauchement de remplacement entre les deux kits**. Le modèle est monté avant masquage atomique des quatre formes. Le système restaure les formes si le Model manque, si la carte ou le profil change, si le streaming est incomplet, ou si la pression GPU augmente. Le compteur `LocalSouthTowersLiftPrimitivesReplaced` reflète le remplacement actif. Un seul sampler LOD existant ; pas de nouvelle boucle `RenderStepped`.

**Bilan de la famille sud Towers :** 6 grosses formes disposent maintenant d'un remplacement MeshPart approuvé (2 sur le pont/cabine et 4 sur les tours/couronnes). Les rails, suspensions, signal et socles sont encore des primitives et ne sont pas comptés comme remplacés.

**Reste à valider :** compilation Luau dans Roblox Studio, rendu en streaming, géométrie réelle des couronnes et FPS Android. La fusion GitHub n'est pas une publication Roblox Place.
