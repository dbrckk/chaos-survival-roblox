# P4 — Orbital sud : finition du monument et anneau déjà sculpté

**10 novembre 2026 — code de la nouvelle mise à jour ; Roblox Place publique non publiée.**

## Provenance 3D et validation

Le workflow [GitHub Actions #42844551858](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42844551858) a validé le véritable OBJ/glTF original **14 168 triangles**, **sept matériaux PBR**, dimensions **18,54 × 11,218 × 5,168 studs** à l'échelle source 1:2,5 ; normales, UV et tangentes. Le Model créateur authentique **`96266711661930`** est **Moderation: Approved**. Générateur : `tools/generate_original_south_orbital_finishing.py`.

Géométrie : double pilier industriel à douze facettes, plaques et nervures d'entretien, plancher et socle mécaniques, sphère géodésique réelle multicouche avec cercles de retenue courbes et bride à connexions forgées. La sphère conserve son volume et la structure centrale ne se transforme pas en panneau plat.

## Les six cibles exactes

Le kit client `ApprovedSouthOrbitalFinishingMeshKit.lua` masque seulement les six éléments du vrai `GeneratedMap/Arena/Decor/SouthHorizonMonument` de variante **Orbital** :
- `Foundation` — Part 47×2×13, position (0,−1,0)
- `FloorInset` — Part 39×0,3×10, position (0,0,16,0)
- `LeftRingSupport` et `RightRingSupport` — Parts 2,6×23×3, positions (±15,5,11,5,0)
- `SuspendedOrb` — **Part Shape Ball** de diamètre 6,4, position (0,23,0)
- `OrbClamp` — Part 9,5×0,8×2,4, position (0,23,−0,2)

Avant de monter le nouveau modèle, le kit exige aussi **les 14 arcs d'observation existants** (chord attendu et propriétés physiques contrôlées). L'anneau est géré *indépendamment* par `ApprovedSouthOrbitalObservationRingMeshKit.lua` et son Model propriétaire `124474310430876`.

## Contrat de runtime

Le chargeur serveur `PremiumSouthOrbitalFinishingAssets.lua` vérifie l'asset, l'absence de scripts, sept vrais `MeshPart` non physiques et des bornes strictes. Le client impose positions, tailles, formes, orientation, collisions et provenance. La géométrie de remplacement est montée **avant** masquage atomique des six natives. Le système restaure les transparences d'origine si le chargement échoue, si le monument est partiellement streamé, si la qualité baisse, si la pression GPU augmente ou si la carte change.

Ces MeshParts n'ont ni collision, ni touch, ni query, ni ombre ; aucun changement à l'IA, aux joueurs ou à la physique. Le montage utilise la cadence LOD déjà existante et partage le budget graphique. Aucun `RenderStepped` supplémentaire.

Le test source `tools/verify_south_orbital_finishing_fallback.py` vérifie la **couverture sans chevauchement des 20 éléments** : 14 arcs + 6 finitions.

**Portée :** 20/20 pièces natives de la famille *SouthHorizonMonument Orbital* ont une version originale approuvée. Le LOD Low continue volontairement à montrer les primitives. Ce chiffre n'est pas une couverture 3D de la carte entière, ni une vérification de rendu Roblox Studio/Android. Aucune Place n'a été publiée.
