# P4 — Réacteurs Orbital : nœud et contrefort original 3D sur Android Low

**12 novembre 2026.** Ce correctif agit sur le dépôt GitHub ; aucune publication
Roblox ni mesure réelle de FPS Android n'est présumée.

## Audit du jeu

`MapBuilder.lua` installe huit groupes `OrbitalReactorNodeN` +
`OrbitalReactorStrutN` autour de l'arène Orbital : la sphère réacteur
originale est un `Part` de **4,4 studs**, le support radial est un bloc
de **8,5 studs**. Les nœuds sont animés par le gestionnaire existant
`arena-identity-motion.client.lua` et les positions sont ancrées
aux dimensions initiales de l'arène, même pendant le rétrécissement.

Les sources **créateur originales approuvées** existent déjà :
- nœud sculpté `104654294187035` : 7 vrais MeshParts ;
- support radial ajouré `138666009076890` : 7 vrais MeshParts.

Le serveur fournit les deux sources en provenance validée
(`ApprovedOrbitalReactorLandmarkTemplates`, `OwnerVerified`,
`Original3DAssetId` exact, `CosmeticOnly`, dimensions contrôlées).
Les clients Medium/High utilisent déjà le kit, mais Android Low était
bloqué **deux fois** : `LIMITS.Low=0`, `RANGE.Low=0` puis la branche
tactile qui redescendait à zéro même si le plafond était augmenté.

## Implémentation

1. **Un seul couple réel**, soit **14 MeshParts** répartis en 2 modèles
   de 7, à **210 studs maximum** de la caméra en qualité Android Low.
   Hystérésis de 26 studs. La pression graphique doit être zéro.
2. Les deux sources sont validées, importées et montées **ensemble**
   avant de masquer les deux natives d'un même index. Si l'une des
   deux manque ou comporte un mauvais nombre de MeshParts, le
   nœud et son support primitifs restent disponibles.
3. Une pression `OptionalVfxPressure=1` fait tomber
   `floor(1×0,5)` à zéro ; pression 2 également. Le propriétaire
   du kit remet les formes natives immédiatement.
4. En cas d'éviction du modèle `SculptedOrbitalNodeAndStrut_N`
   par le budget partagé, `bucket.ChildRemoved` libère
   immédiatement **le couple complet**, sans attendre le
   prochain échantillonnage caméra, ni retirer d'autres modèles.
5. L'animation native du réacteur reste autoritaire : seule
   `LocalTransparencyModifier` et `SceneryLodHidden` sont
   temporairement forcées, puis restaurées dans l'entrée
   lorsque le modèle d'origine disparaît.
6. Les 14 pièces sont seulement cosmétiques :
   `CanCollide=false`, `CanTouch=false`, `CanQuery=false`
   et `CastShadow=false`. Aucune collision jouable, nouvelle
   lumière, boucle caméra, animation parallèle ou RemoteEvent.
7. Le dossier `ApprovedOrbitalReactorLandmarksLocal` était déjà
   inscrit une fois dans `VisualBudgetRules.LocalFolders` et
   reste soumis au quota commun Android Low de 440 Parts.
8. Les limites Medium/High **3/6 couples à 340/460 studs**
   et leurs plafonds tactiles **1/3** sont inchangés.
   Les améliorations Towers concurrentes déjà intégrées à
   `main` sont délibérément **préservées**, sans modification.

## Validation Roblox Engine / Android à effectuer

- Sur Orbital, Low, pression zéro et sources chargées, s'approcher
  d'un réacteur à moins de 210 studs. Vérifier exactement
  **une paire de modèles / quatorze MeshParts**.
- Vérifier l'animation du nœud, les huit directions,
  le rétrécissement de l'arène et les alertes.
- Vérifier `LocalOrbitalReactorSculptPairCount≤1` et
  `LocalOrbitalReactorNativePartsReplaced≤2` sur Low.
- Simuler source manquante, streaming partiel, pression 1/2
  et suppression d'un wrapper du dossier de budget : les deux
  primitives redeviennent visibles.
- Mesurer FPS/p95 et mémoire sur un vrai Android faible avant
  toute augmentation de quota.

Les tests GitHub portent sur les contrats de code source,
les modèles approuvés, les positions du serveur, les animations
et le budget, **pas sur le rendu réel dans Roblox Engine**.
