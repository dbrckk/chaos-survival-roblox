# P4 — Deux grandes ailes de station périphérique authentiques sur Android Low

**12 novembre 2026.** Code GitHub uniquement : ni publication Roblox, ni mesures FPS en jeu.

## Audit des formes encore basiques

Les stations `PerimeterStationNorth/East/South/West` des cinq arènes possèdent
quatre `WedgePart` industriels non physiques encore natifs sur Android Low.

| Forme native | Dimensions | Modèle créateur approuvé |
| --- | --- | --- |
| `AngledServiceWingL` et `AngledServiceWingR` | 3,4 × 1,7 × **5,7 studs** | **Wing `138096293972093`**, 7 MeshParts réels par aile |
| `LeftAngledCap` et `RightAngledCap` | 2,9 × 2,2 × 2,4 studs | Cap `88962643359267`, 7 MeshParts par chapeau |

Les sources originales ont été approuvées par le pipeline d'import serveur
`PremiumPerimeterArmorAssets` ; aucune requête ou création d'asset nouveau
n'est effectuée côté client.

Activer les **quatre** modèles complets en Low aurait dépensé
**28 MeshParts** pour une seule station, en plus des poutres, piliers,
rotors et machines authentiques déjà visibles. Pour protéger le budget
Android (440 Parts locaux partagés), ce lot retient les **deux ailes
longues** les plus visibles ; les petits chapeaux restent sous leur
forme native jusqu'au profil Medium.

## Implémentation

- `ApprovedPerimeterArmorMeshKit.lua` : `CAPS.Low=1`, distance
  de caméra **105 studs**, rétention existante **16 studs**, seulement
  sur une vraie station périphérique de l'arène active.
- La vérification `genuineStation(...,tier)` sélectionne les natifs
  numéros 3 et 4 sur Low : **les deux ailes**. Elle conserve les
  quatre vérifications et substitutions d'origine sur Medium/High.
- La source obligatoire sur Low est uniquement la vraie
  `Wing` de 7 MeshParts, avec `OwnerVerified`,
  `CosmeticOnly`, `OriginalPerimeterArmor3D`,
  `Original3DAssetId` et limites de géométrie exactes.
  La source `Cap` ne conditionne pas l'affichage Low :
  les chapeaux ne sont **ni clonés ni masqués** sur mobile Low.
- Les deux modèles `Wing` sont préparés entièrement, vérifiés
  de type `MeshPart`, publiés ensemble dans le dossier
  `ApprovedPerimeterArmorLocal`, puis **et seulement ensuite**
  les deux `WedgePart` originaux deviennent transparents.
  Si l'une des deux sources ne peut être montées, les
  deux ailes natives restent visibles.
- À la pression GPU **1**, `math.floor(1×0,5)=0`
  désactive immédiatement le lot Low et restaure les
  deux ailes natives ; pression 2 garde la même repli.
- Le classement caméra cible désormais `natives[1]` sur Low
  (l'aile L de la sous-liste) plutôt que `natives[3]`, qui
  désignait l'aile L seulement dans l'ancienne liste complète.
- L'entrée mémorise `expected=2` en Low et `expected=4`
  en Medium/High ; les méthodes `Kit.count()` et
  `Kit.replacedNativeCount()` comptent exclusivement les
  modèles source complets **et les parties effectivement masquées**.
  Diagnostic attendu : un groupe / **deux wedges** remplacés
  au maximum sur Low, quatre wedges par station Medium/High.
- Les connexions existantes au retrait de la source, du modèle,
  des MeshParts et des éléments natifs déclenchent la
  restauration. Sol, avertissements, signaux lumineux, bots,
  déplacements et colliders ne changent pas.
- Les MeshParts restent `Anchored=true`, `CanCollide=false`,
  `CanTouch=false`, `CanQuery=false`, `CastShadow=false`.
  Le LOD et le census coopératif existants restent les seuls
  propriétaires du rendu et du budget, **sans nouvelle boucle**.

## Recette Roblox Studio et Android restant à exécuter

1. Sur chaque arène, en Android Low pression 0, approcher d'une
   `PerimeterStation` à **moins de 105 studs**. Constater
   **deux** sculptures Wing, composées de sept vrais MeshParts
   chacune, au lieu des deux grands WedgeParts.
2. Vérifier `LeftAngledCap` et `RightAngledCap` :
   ils doivent rester natifs et visibles en Low ; les lentilles,
   marques de route et avertissements restent inchangés.
3. Sur Medium/High, constater que le kit conserve son groupe
   complet de **quatre** modèles (28 MeshParts), selon le
   plafond de stations 1/3 et la portée 170/245 studs.
4. Rejeter une source Wing non approuvée, partielle ou
   composée de moins de sept MeshParts. **Aucune aile
   native ne doit rester cachée**.
5. Forcer la pression à 1 puis 2, franchir le seuil de
   distance +16 et tester StreamingEnabled/retrait source :
   les natives reviennent sans collision fantôme.
6. Examiner `LocalApprovedPerimeterArmorStationCount`
   (Low ≤1) et `LocalPerimeterPrimitiveWedgesReplaced`
   (Low ≤2 ; Medium/High jusqu'à quatre par station montée).
7. Mesurer FPS moyen, p95, mémoire, temps de streaming et
   captures avant/après sur un vrai téléphone Android Low,
   puis vérifier le montage de tous les autres propriétaires
   cosmétiques sans surallocation budgétaire.

`tools/verify_original_3d_budget_census.py` couvre désormais
l'existence des sources, le sous-ensemble Low, la vérification
7+7 MeshParts, l'atomicité, la pression et le comptage exact
des parties masquées. Les workflows GitHub vérifient le code
source ; ils **ne prouvent pas** le rendu dans Roblox Engine.
