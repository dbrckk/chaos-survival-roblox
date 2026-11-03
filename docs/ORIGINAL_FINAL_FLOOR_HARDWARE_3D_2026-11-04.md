# Chaos Survival — finitions mécaniques de sol : remplacement 3D réel

**Livraison source du 4 novembre 2026.** Ce lot remplace les trois dernières familles de formes basiques contenues dans `arena-surface-relief.client.lua`, en conservant la géométrie de collision et les avertissements de danger du serveur.

## Trois sculptures 3D originales, identifiants réels

| Pièce à remplacer | Nouvel original | Asset Roblox Model vérifié | Provenance |
| --- | --- | --- | --- |
| `ReliefCornerBevel1..4` : quatre `WedgePart` aux angles, avec `ReliefCornerLens` | coin industriel **réellement incliné**, triangle authored, brides, nervures et signal de repère discret | `102215174919938` | [Upload source, Moderation Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41740585965) |
| `ReliefFastener1..12` : petits `Part` cylindriques | tête forgée multi-facettes, rondelle, joint et empreinte d'outillage, rayons réel en 3D | `92226531849432` | [Nouvelle géométrie large source, Moderation Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41740889677) |
| `HarborQuayTieDown1..4` : quatre `Part` carrés | anneau de fixation fermé, longerons et protection marine, relief métallique manufacturé | `135412901717584` | [Upload source, Moderation Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41740585965) |

Les trois modèles sont produits de façon déterministe par `tools/generate_original_floor_hardware.py` (OBJ triangulé, conversion glTF, UV/normales/tangentes, sept familles de matériaux). Les IDs sont également dans `assets/source/roblox-asset-registry.json`. Aucun modèle Marketplace ni forme magique `MeshPart.MeshId` ne sont utilisés.

### Cas particulier de la miniature

La tentative originale `floor_anchor_bolt` (dimensions de source ≈ 0,4 stud) a renvoyé une erreur Roblox HTTP **500 INTERNAL** après POST. Comme les créations d'assets ne sont pas idempotentes, **aucun retry aveugle ni ID fictif** n'a été effectué. Une **source géométrique différente**, `floor_anchor_bolt_large`, a été sculptée à 10× dans le fichier d'auteur, a passé le contrôle source, puis a reçu `Moderation: Approved`. Le client la remet aux dimensions de la vraie petite fixation via `Model:ScaleTo`. Le premier POST demeure de statut de création inconnu ; ne jamais inscrire cette première demande dans le registre des actifs approuvés.

## Intégration physique et visuelle

- Le serveur étend **le chargeur existant** `PremiumFloorReliefAssets.lua` au lieu d'ouvrir une voie concurrente d'AssetService. Les trois machines supplémentaires chargent après les six reliefs déjà approuvés ; elles sont sanitisées et strictement vérifiées (géométrie authentique en `MeshPart`, dimensions et asset IDs).
- Le client `PremiumFloorHardwareMeshKit.lua` monte la géométrie dans `ArenaSurfaceReliefLocal`. **Chaque MeshPart devient enfant direct du dossier avant le même snapshot `ArenaFloorFollowerKit.bind`**. Les petits rivets, coins et ferrures diminuent de taille et se déplacent avec le sol pendant Shrinking Arena.
- `Low` n'a aucune de ces trois formes natives dans son décor, donc **aucun nouveau mesh ni coût**. `Medium` monte les 6 fixations originales. `High` monte 4 coins, 12 fixations et, pour Harbor seulement, 4 anneaux : remplacement de **toutes les 16 à 20 primitives concernées** si les modèles sont effectivement présents.
- Les vrais meshes sont tous `Anchored`, `Massless`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false`. Il n'y a ni nouvelle lumière, ni RenderStepped, ni requête d'asset côté client, ni modification du terrain physique ou des dangers. Le rivet reste droit même si le cylindre natif a été tourné de 90 degrés.
- Les éléments natifs ne sont **cachés qu'une fois le modèle complet préparé et inséré**. Sans template source (ou après un changement de qualité ou de carte), les formes initiales restent disponibles et le client reconstruit le décor correctement.
- Le compteur `LocalOriginalFloorHardware3DCount` expose le nombre réel de pièces authentiques montées (pas le nombre de slots visés). Le budget global de Parts/effets Android connaît déjà `ArenaSurfaceReliefLocal`.

Ce lot n'implique pas de nouvelles cartes raster PBR haute résolution, même si les modèles ont leurs matériaux glTF/UV. Le jeu public **n'a pas été publié par les importeurs**.

## Critères de livraison visuelle

Le jalon de tests Build Validation et Roblox Cloud doit être vert pour le SHA exact. Le test Studio/Android doit ensuite vérifier les 4 angles High, les 6 rivets Medium et 12 High, les attaches Harbor High, la lisibilité des pictogrammes, la stabilité du shrink et la consommation des 7 parties de matériau par modèle. Aucun jugement « AAA certifié » sans captures et FPS réels. Les **plateformes/passerelles** et les **éléments natifs du lobby** restent un chantier visuel séparé.
