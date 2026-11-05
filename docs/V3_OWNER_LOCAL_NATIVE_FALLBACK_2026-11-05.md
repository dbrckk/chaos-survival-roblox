# V3 Lot 1 — repli natif localisé, streaming et intégrité du premier plan 3D

**5 novembre 2026 — changement du code source, non publié dans Roblox.**

## Défaut concret corrigé

Dans `src/client/PlatformNativeTrimReplacementKit.lua`, la suppression
d'**un seul** `MeshPart` source-authentifié de `ArenaPlatformIdentityLocal`
déclenchait `table.clear(active)`, `table.clear(verifiedSupports)` et
`restore()`. Ce repli était global : toutes les structures 3D réellement
présentes sur les autres routes perdaient leur substitution de pièces natives
jusqu'à un prochain rebuild, alors même que leur géométrie restait intacte.

L'arrivée tardive et la disparition d'une pièce native de `Arena.Decor`
pouvaient aussi laisser un compteur diagnostique de pièces masquées périmé.

## Correction livrée sur la branche

- Chaque `MeshPart` authentique déjà monté est associé **une seule fois**
  à son vrai `PlatformN`, `SkybridgeN` ou `PlatformSupportN_K`, à
  partir du `Weld`/`WeldConstraint.Part1` et du dossier de propriétaire
  réellement répliqué. Ni nom de mesh inventé ni attribution fondée sur
  le seul index ne peuvent autoriser un repli.
- En cas de disparition d'une pièce d'origine : désactiver **uniquement**
  l'autorisation de masque de la structure concernée puis réconcilier le
  natif. Le reste des quartiers et leurs vrais MeshParts demeurent montés.
- Une pièce `Decor` déjà masquée qui sort du flux est enlevée immédiatement
  du suivi et du compteur. L'apparition de nouvelles pièces n'autorise
  toujours pas à masquer des hazards/physiques.
- Aucun nouveau Part, modèle, asset ID, remote, loop de rendu, budget GPU,
  collision ou logique serveur.
- Les protections `CollapsePhase`, `BridgeShutterPhase`, `CanCollide`,
  taille et transparence restent prioritaires et bloquent toujours un
  faux masque pendant un danger.

## Test d'intégration moteur ajouté

`tests/engine/native-premium-fallback.spec.luau` construit de vraies
Instances `Part`, `MeshPart`, `WeldConstraint` et dossiers Roblox.
Scénarios de recette au prochain jalon important :
1. Quatre substituts natifs de deux plateformes, un pont et une colonne
   sont masqués en présence de leurs quatre sources vérifiées.
2. La perte du premier mesh restaure **une seule** plateforme ; la perte
   de la colonne restaure **seulement** cette colonne.
3. Le pont retrouve immédiatement ses ribs natifs pendant `Warning`,
   puis peut reprendre sa vraie structure `Idle`.
4. La disparition d'un `PlatformUnderFrame` sans changement du dossier
   `Decor` décrémente le compteur ; pas de référence fantôme.
5. `Kit.reset()` restaure tout et aucune collision serveur n'est modifiée.

**Validation restante avant publication :** Build Validation et suites
Roblox Cloud sur le SHA final, streaming Roblox réel, captures Android et
confirmation in-game sur les cinq arènes. Les fixtures moteur vérifient les
contrats d'Instances mais ne remplacent pas une preuve de rendu physique.
