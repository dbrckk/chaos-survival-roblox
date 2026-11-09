# P4 — Substitution des WedgeParts périphériques par 3D authentique

9 novembre 2026. Code source intégré, NON publié sur Roblox.

## Provenance vérifiée

L'asset original perimeter_wing produit 568 triangles, 18 groupes d'OBJ, sept MeshParts par matériau glTF et un volume source de 3,277 × 1,64 × 5,62 studs. Son Model Roblox appartient au créateur et porte l'ID 138096293972093, Moderation Approved. L'asset perimeter_cap fournit également 568 triangles, sept MeshParts, 2,7699 × 2,14 × 2,34 studs, Model ID 88962643359267, Moderation Approved. Les deux imports sont explicitement prouvés par les logs de GitHub Actions #42694744112. Aucun MeshId ne provient d'une supposition.

## Intégration actuelle

src/server/PremiumPerimeterArmorAssets.lua charge, assainit et vérifie les deux modèles indépendamment, après le démarrage du gameplay. Seuls des MeshParts originaux non collisionnels peuvent être publiés dans ReplicatedStorage.ApprovedPerimeterArmorTemplates.

src/client/ApprovedPerimeterArmorMeshKit.lua monte **deux Cap et deux Wing** sur les quatre WedgeParts natifs LeftAngledCap, RightAngledCap, AngledServiceWingL/R des véritables stations de chacune des cinq variantes. Les quatre pièces doivent toutes être présentes et authentifiées. Les quatre nouveaux modèles sont clonés, ajustés uniquement par échelle uniforme et orientation, puis installés avant qu'une quelconque primitive soit masquée. Les vrais pivots natifs, lumières, machines centrales, rotors, sols, capteurs et signaux ne sont jamais supprimés. Streaming partiel, source manquante, retrait d'un MeshPart, base qui rétrécit ou changement de carte restituent les quatre formes primitives.

src/client/scenery-lod.client.lua réutilise la seule cadence de sélection caméra existante : aucune boucle RenderStepped, Heartbeat ou réseau supplémentaire. src/shared/VisualBudgetRules.lua compte les vrais MeshParts dans le census de rendu partagé 440/680/900. Les clones sont tous Anchored, Massless, CanCollide=false, CanTouch=false, CanQuery=false, CastShadow=false.

| Profil | Stations simultanées au maximum | WedgeParts masqués au maximum | MeshParts source montés au maximum |
| --- | ---: | ---: | ---: |
| Low | 0 | 0 | 0 |
| Medium | 1 | 4 | 28 |
| High Android | 2 | 8 | 56 |
| High PC | 3 | 12 | 84 |

Pression optionnelle 1 : limite divisée par deux, arrondie à l'inférieur. Pression 2 : disparition des modèles cosmétiques, restitution des natifs. Portée 170 studs Medium et 245 High, avec hystérésis 16. Les compteurs clients LocalApprovedPerimeterArmorStationCount et LocalPerimeterPrimitiveWedgesReplaced indiquent uniquement les objets réellement montés, pas un FPS simulé.

## Réception à la prochaine publication

Aucune compilation Luau, test Roblox Engine ou capture/mesure Android n'est revendiquée à cette itération. Il faudra vérifier l'orientation des deux pentes sous glTF, l'absence de recouvrement avec lumières et rotors, la remise en place sous StreamingEnabled et Shrink, les pressions GPU, les 5 variantes et le FPS réel avant toute mise à jour publique. Dernière Place publique attestée : P2 au commit ae4ae044e991ef4ca28a991991f2e11b9df49c84, action #42650986552. La fusion de code P4 n'est pas une publication Roblox.
