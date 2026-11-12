# P4 — Grandes ailettes Classic en 3D originale sur Android Low

**12 novembre 2026.** Modifications GitHub uniquement. Aucune mesure réelle de FPS ni publication Roblox n'est affirmée.

## Audit du code existant

Le générateur `MapBuilder.addVariantLandmarks` installe quatre grands mâts externes
`ClassicBroadcastFin1..4` (dimensions **1,8 × 16 × 5,5** et **5,5 × 16 × 1,8 studs**)
et leurs quatre bandes lumineuses indépendantes `ClassicBroadcastGlow1..4`.

Un vrai modèle créateur original existait déjà : **`123049626693705`**, produit par
`tools/generate_original_variant_classic_broadcast_fin.py` et modéré **Approved**.
Il comporte **3 052 triangles, sept matériaux et sept MeshParts** ; la source serveur
`PremiumClassicBroadcastFinAssets` vérifie la provenance, les bornes physiques et
l'absence de scripts avant réplication. Le client `ApprovedClassicBroadcastFinMeshKit`
vérifie aussi l'ID, le nombre de MeshParts, les deux orientations X/Z et chaque
`Part` native avant de masquer quoi que ce soit.

Deux blocages empêchaient son affichage Android Low :
- `CAP.Low=0` et `RANGE.Low=0` ;
- la branche `if touch` ramenait **de nouveau** toute limite Low à zéro,
  même si le quota principal était activé.

Résultat : les quatre formes rectangulaires de 16 studs restaient primitives
sur Android Low, même à proximité et lorsque le modèle original était disponible.

## Changement effectif

- **Low=1** vrai modèle original de sept MeshParts maximum,
  sur le seul mât Classic sélectionné à **≤195 studs** de la caméra.
  Marge d'hystérésis existante : **26 studs** pour un modèle résident.
- La branche tactile autorise désormais le **même** unique modèle Low.
  Les limites Medium (**deux modèles à 285 studs**) et High
  (**quatre à 415 studs**) restent identiques, y compris sur mobile
  (Medium tactile 1 ; High tactile 2).
- **`OptionalVfxPressure=1`** provoque `floor(1×0,5)=0` :
  le modèle facultatif est retiré et la vraie forme native
  revient. Pression 2 conserve ce repli.
- Si le propriétaire du budget Android retire le modèle du dossier
  `workspace.ApprovedClassicBroadcastFinLocal`, une nouvelle écoute
  `bucket.ChildRemoved` restaure immédiatement la forme native,
  sans attendre l'échantillon LOD suivant.
- Les **quatre bandes lumineuses `ClassicBroadcastGlow`** ne sont jamais
  masquées, déplacées, recolorées ni détruites. Le générateur serveur,
  les vrais chemins, la physique, les avertissements et les collisions
  ne changent pas.
- Tous les MeshParts du nouveau modèle restent `CanCollide=false`,
  `CanTouch=false`, `CanQuery=false`, `CastShadow=false`.
  Le dossier existe déjà **une seule fois** dans
  `VisualBudgetRules.LocalFolders` et continue de participer au
  budget partagé Android de 440 Parts.
- Aucun nouvel asset, import client, `RenderStepped`, `Heartbeat`,
  `RemoteEvent`, lumière ni boucle caméra supplémentaire.

## Recette de validation Roblox Engine et Android

1. Sur Classic, Android Low, `OptionalVfxPressure=0`, attendre que le
   modèle original soit chargé (import serveur non immédiat), puis approcher
   une ailette extérieure à **≤195 studs**. Vérifier une vraie sculpture
   de sept MeshParts et seulement **une** ailette native masquée.
2. Tester une ailette orientée sur X et une sur Z. Le model importé doit
   pivoter dans la bonne direction et conserver une forme aérodynamique.
3. Vérifier **chaque bande lumineuse** `ClassicBroadcastGlow` ;
   aucune ne doit disparaître, et les quatre restent indépendantes.
4. Vérifier les attributs `LocalClassicFinMeshCount≤1` et
   `LocalClassicFinPrimitivesReplaced≤1` sur Low.
5. Passer à pression 1 puis 2 et simuler l'éviction d'un modèle local,
   une source invalide, un retrait de MeshPart et la sortie de la caméra
   au-delà du seuil +26. Les `Parts` natives doivent revenir.
6. Comparer FPS p95, mémoire, temps de streaming et captures avant/après
   sur un vrai téléphone Android Low. Vérifier l'absence de chevauchement
   avec les autres modèles de skyline et les volumes de décor.

Les scripts `tools/verify_variant_classic_broadcast_fin_runtime.py`
et `tools/verify_original_3d_budget_census.py` testent les contrats
de source, de quota mobile et de restauration. Ils ne peuvent pas
attester du rendu moteur, du FPS Android ni de la publication de la place.
