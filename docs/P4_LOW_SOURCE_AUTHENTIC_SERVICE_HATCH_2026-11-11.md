# P4 — Première vraie trappe de maintenance 3D au premier plan sur Android Low

**11 novembre 2026 — source GitHub, pas de publication Roblox.**

## Audit source

Dans `PlatformFinishKit.lua`, `buildServiceHatch()` interdisait
`Low`. Même le véritable modèle créateur `ApprovedFloorReliefTemplates`
n'apparaissait pas sur la face supérieure des decks de ce profil.
Les seules trois couches `Part` de secours étaient réservées à
Medium/High ; Low restait sans détail de trappe.

Il existe déjà cinq sculptures originales approuvées :

| Arène | Asset original approuvé |
| --- | --- |
| Classic | `102746904688141` |
| Towers | `74708751016233` |
| Crossroads | `84038993323581` |
| Orbital | `123089585720736` |
| Harbor | `94830155055482` |

## Remplacement

- Low peut maintenant installer **une seule trappe authentique de
  sept `MeshPart`**, sur une vraie `PlatformN` stable, ancrée,
  collidable, visible, sûre, avec indice `1 modulo 3`,
  surface horizontale de 8 à 36 studs et géométrie source
  compatible. La caméra doit se trouver dans l'arène, à
  **100 studs maximum**.
- Le dossier et le modèle doivent être `OwnerVerified` et
  `CosmeticOnly`, porter l'`Original3DAssetId` exact de
  l'arène et `OriginalFloorRelief3D`. Les sources ne peuvent
  contenir que de vrais `MeshPart` non collidables et aucun
  `LuaSourceContainer`. **Low exige exactement 7 pièces.**
- Ces sculptures sont déjà utilisées ailleurs dans le jeu : pas
  de nouvel upload/ID, texture, lumière ni appel réseau.
- Le propriétaire du deck conserve ses `Weld`, animations
  d'effondrement, suivi `RouteTier`, et les mêmes observateurs
  de modèles approuvés chargés tardivement.
- La trappe sur Low occupe **le même unique emplacement de 7 pièces**
  que les carapaces compactes et le grand carénage Crossroads.
  La priorité est donnée à une trappe dont le Model est répliqué
  et compatible ; `nearCameraCarapaces` et `lowHubDeck` sont
  alors désactivés.
- Si une passerelle Towers a déjà réservé ses **14 MeshParts**,
  la trappe Low n'est pas sélectionnée. Les quotas de la grande
  structure de sept pièces restent inchangés : aucune allocation
  supplémentaire due à ce lot.
- À `OptionalVfxPressure >= 1`, aucun modèle de trappe Low
  n'est ajouté et la reconstruction événementielle existante
  restaure les visuels standard.
- Si la source est absente, incomplète, rejetée ou échoue au
  montage, **aucune trappe native en trois `Part` n'est créée
  sur Low**. C'est le repli ancien. Les trois pièces natives
  et les quotas historiques Medium/High sont préservés.
- Une vraie `PlatformN` d'indice pair peut recevoir le Model
  sans réintroduire la demi-densité d'ornements primitifs
  écartée sur Low.

## Contrôles d'acceptation (moteur Roblox)

1. En Low à pression 0, placer la caméra proche d'un vrai deck
   `PlatformN` (indice 1 modulo 3) ; vérifier au plus une
   trappe source authentifiée avec 7 `MeshParts`,
   `LocalOriginalServiceHatch3DCount <= 1`.
2. Dans le même état, vérifier qu'une trappe Low montée exclut
   `LocalOriginalNearRouteCarapaceCount` et
   `LocalOriginalLowHubHullCount`; un pont Towers 3D exclut
   aussi la trappe.
3. Forcer la pression 1/2, supprimer la source approuvée, ou
   tester le streaming tardif ; la trappe Low disparaît sans
   créer trois faux `Part` de remplacement.
4. Tester `CollapsePhase`, Shrinking Arena, les avertissements,
   la mobilité R15 et le cas d'un index `PlatformN` pair.
   Aucun élément cosmétique ne doit changer les collisions.
5. Mesurer FPS, p95 et mémoire sur un appareil Android Low réel,
   comparer les captures de face supérieure, puis publier la
   Place seulement après acceptation Engine.

**Statut :** validation statique GitHub CI à effectuer ; ces
contrôles ne prouvent pas le rendu Engine, les FPS ni la publication.
