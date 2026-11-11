# P4 — Carapace 3D originale au premier plan sur Android Low

**11 novembre 2026 — modification GitHub, pas une publication Roblox.**

## Défaut visuel observé dans le code

`PremiumPlatformSideMeshKit.selectCarapaceDecks` excluait totalement
`Low`. Les plateformes sous le joueur restaient donc couvertes par deux
`WedgePart` de carapace (`PlatformFinishKit.carapaceCount`,
index `1 modulo 8`), même si les cinq véritables sources créateur
`ApprovedPlatformSideTemplates` étaient déjà présentes, modérées
`Approved`, et utilisées en Medium/High.

## Remplacement source réalisé

- Low peut maintenant substituer **une seule plateforme** à moins de
  **125 studs de la caméra** par le Model 3D authentique propre à
  Classic, Towers, Crossroads, Orbital ou Harbor.
- Le candidat doit être une vraie `PlatformN` ancrée, physique,
  visible, sans effondrement en cours, de dimensions compatibles ;
  son index doit valoir **1 modulo 8**, donc il possédait déjà les
  **deux WedgeParts** natifs à remplacer. On ne crée pas une forme
  supplémentaire sur une plateforme précédemment nue.
- Les vérifications préexistantes `OwnerVerified`, `CosmeticOnly`,
  `OriginalStructuralSide3D`, ID créateur exact, sécurité du Model
  et ajustement des dimensions sont maintenues. **Low exige en plus
  exactement 7 vrais MeshParts** ; sinon, retour aux deux formes natives.
- Un remplacement réussi produit au plus **7 MeshParts à la place
  de 2 WedgeParts**, soit au plus cinq BaseParts supplémentaires
  pour ce propriétaire, comptabilisés dans le
  `VisualBudgetRules.LocalFolders` déjà existant
  (`ArenaPlatformIdentityLocal`).
- **Dès pression graphique 1 ou 2, Low revient au décor natif** :
  le propriétaire regroupé (batch 0,12 s) est reconstruit par
  l'événement `OptionalVfxPressure`. Pas de nouveau RenderStepped,
  RemoteEvent, requête AssetService, texture PBR 2K ni boucle de polling.
- Medium conserve au maximum 8 modèles originaux, High 16.
  Low continue de préserver les collisions, le trajet, les signes
  de danger et l'effondrement des plateformes. Les modèles suivent
  les soudures et les callbacks de retrait existants.

## Contrôle avant publication

1. Vérifier que `LocalOriginalNearRouteCarapaceCount` passe au maximum
   à **1** en Low normal avec la bonne source chargée, et reste à
   **0** quand la source est absente/non approuvée ou la caméra éloignée.
2. Forcer `OptionalVfxPressure = 1` : vérifier la restauration des
   deux WedgeParts sous la plateforme et l'absence de MeshPart original.
3. Vérifier l'absence de route fantôme pendant `CollapsePhase` et
   pendant Shrinking Arena, avec `RouteTier` répliqué tardivement.
4. Contrôler FPS/p95 mémoire sur un appareil Android Low réel, avant
   de déclarer la nouvelle sculpture adaptée en production.

**Statut :** préparation de code GitHub. Les 3D sont conditionnelles
au streaming et à l'approbation effective. Aucun rendu Roblox Studio
ou FPS Android n'est déduit des contrats source.
