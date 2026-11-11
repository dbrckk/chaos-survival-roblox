# P4 — Treillis 3D authentique d'une Skybridge Towers sur Android Low

**11 novembre 2026.** Changement GitHub uniquement, non publié dans l'expérience Roblox.

## Déficit visuel identifié

Les quatre vraies `SkybridgeN` de Towers sont des passerelles physiques
49×4,5 studs. `MapBuilder` construit trois `SkybridgeRibN_K`
rectangulaires sous les ponts. Une source 3D authentique, propriétaire et
approuvée, `ApprovedPlatformSideTemplates.Bridge`
(**asset 122766792774607**) existait déjà pour Medium/High mais était
interdite sur Low. Les rails lumineux, les indices de danger
et le mécanisme de rétraction des ponts sont des objets séparés.

## Implémentation

- **Une seule Skybridge réelle**, choisie dans la zone de l'arène
  à **125 studs maximum de la caméra**, est éligible si le modèle
  approuvé a **exactement sept MeshParts**, toutes authentifiées :
  `OwnerVerified`, `CosmeticOnly`, `OriginalStructuralSide3D`,
  `Original3DAssetId=122766792774607`, et aucun script.
- Deux copies de la source (une par flanc), **14 MeshParts au total**,
  forment le véritable treillis ajouré ; l'échelle, l'orientation
  glTF, la largeur et la hauteur sont contrôlées avant la
  réservation et une seconde fois au montage.
- Les mesures de sécurité préexistantes restent obligatoires :
  vraie plateforme `SkybridgeN`, `ChaosSkybridge=true`,
  `Anchored`, `CanCollide`, visible, phase `CollapsePhase`
  normale/sûre, `BridgeShutterPhase` inactif. Aucun collider
  supplémentaire ni changement de mécanique Shrinking Arena.
- Le remplacement est **cosmétique et réversible** : les trois
  `SkybridgeRibN_K` natifs ne sont masqués localement que si les
  véritables `MeshPart` sont montés sur le pont réel et
  enregistrés par `PlatformNativeTrimReplacementKit`.
  Les `SkybridgeRailN_K` lumineux, les shutter warnings et
  les indications de saut restent visibles.
- Les snapshots `PlatformFinishKit.bindSkybridgeFootprint`
  continuent de raccourcir les modules avec le pont physique ;
  la phase de fermeture masque immédiatement les vrais MeshParts.
- Les passerelles d'indice pair peuvent recevoir cette source :
  le propriétaire conserve la politique de demi-densité Low
  pour les ornements ordinaires, mais ouvre l'unique sélection 3D.
- **Quota total partagé Low** : le pont choisi utilise deux
  modules originaux de sept MeshParts, à la place des deux
  familles précédentes de 7 + 7 pièces
  (carapace/hub et pilier/LongCradle). Ces deux groupes ne
  se montent pas pendant que la passerelle est sélectionnée.
  Aucun nouveau compteur d'objet, RemoteEvent, AssetService,
  PBR, lumière ou boucle caméra ajouté.
- Sur `OptionalVfxPressure>=1`, aucun pont 3D Low n'est
  sélectionné ; le propriétaire reconstruit les fallbacks
  natifs selon la surveillance de pression existante.
  Medium conserve 14 pièces maximum pour la Skybridge sélectionnée ;
  High conserve 28, sans changement de priorités.

## Contrôles nécessaires

1. Sur Towers, tier Low, pression 0, caméra proche d'une Skybridge
   entièrement répliquée : vérifier
   `LocalOriginalNearBridgeGirderCount <= 1` et **14 véritables
   MeshParts** si la source et le montage sont complets.
2. Si une Skybridge Low est effectivement montée, confirmer :
   `LocalOriginalNearRouteCarapaceCount=0`,
   `LocalOriginalLowHubHullCount=0`,
   `LocalOriginalNearSupportColumnCount=0`,
   `LocalOriginalNearBridgeCradleCount=0`.
3. Sous pression 1 puis 2, vérifier la disparition du treillis
   original et la restauration des `SkybridgeRibN_K` natives.
4. Réduire la longueur du pont pendant Shrinking Arena puis
   activer une `BridgeShutterPhase` de fermeture : aucune
   zone de saut fictive, aucun avertissement masqué.
5. Mesurer les FPS p95 et la mémoire d'un téléphone Android Low,
   et effectuer les validations Roblox Engine sur le SHA final.

**Statut :** validation CI source GitHub prévue avant fusion ;
la source approuvée peut ne pas être chargée dans une Place Roblox
non mise à jour. Aucun test moteur ni publication publique déduits
des contrôles GitHub.
