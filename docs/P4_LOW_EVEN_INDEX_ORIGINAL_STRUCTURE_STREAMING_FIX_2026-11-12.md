# P4 — Correction des sous-structures 3D Low sur plateformes paires et en streaming

**12 novembre 2026 — code source GitHub ; aucune publication Roblox ni mesure FPS moteur.**

## Défaut visuel reproduit dans le code

`PremiumLargeStructureMeshKit.selectNearRouteStructures` sélectionne
la **vraie** sous-structure LongCradle ou la **vraie** colonne de support
`PlatformSupportN_K` à proximité de la caméra, notamment pour les
passerelles de `SkySpineStep` et `PromenadeStep`. Sur Android Low,
le kit réserve **un seul module original approuvé de sept MeshParts**.

Mais `arena-platform-identity.client.lua` ignorait toute plateforme
de numéro pair avec la condition de densité :
`if tier.Name ~= "Low" or visualIndex % 2 ~= 0`, à moins que la
plateforme soit un pont Skybridge ou une trappe de service déjà
sélectionnée. **Les plateformes paires sélectionnées pour LongCradle
ou supports restaient hors du bloc d'installation**.

Conséquences : une réservation source authentique pouvait être
consommée sans afficher de modèle, et l'arène conservait ses
grosses formes natives rectangulaires. Plus grave, l'exclusion
du support Low des callbacks `Decor.ChildAdded/ChildRemoved`
empêchait le rattrapage quand les supports natifs étaient
répliqués **après** les plateformes jouables.

## Correctif appliqué

1. Le gardien de sélection laisse aussi passer une plateforme paire
   quand `nearCradles[platform] == true` ou
   `nearSupports[platform] == true`. Les **vrais modèles approuvés**
   passent alors dans l'installateur déjà existant.
2. La construction des peintures natives Low garde son
   **ancien filtre impair**. Une plateforme paire peut donc
   recevoir le modèle authentique mais **pas de nouveau paquet
   de décorations 2D/3D primaires inutiles**.
3. Les MeshParts effectivement montées rejoignent le
   `registerVisual` normal : `CollapsePhase`, `RouteTier`,
   rétrécissement, masquage des primitives natives et budget
   local `ArenaPlatformIdentityLocal` continuent de s'appliquer.
4. Un support `PlatformSupportN_K` reçu tardivement provoque
   un `queueSupportRebuild()` uniquement si :
   le kit source approuvé de la variante est présent, le joueur
   est en Low à `OptionalVfxPressure==0`, aucun module Low
   de support n'est déjà installé, et la **vraie** plateforme
   correspondante est collidable et située à **125 studs
   maximum** de la caméra.
5. En cas de `Decor.ChildRemoved`, un petit registre local des
   **Parts de support réellement couverts** autorise la
   reconstruction seulement si le support retiré était celui
   d'un modèle monté. Cela supprime toute colonne visuelle
   orpheline lors d'un déchargement par streaming.
6. Les deux déclencheurs réutilisent les timers existants
   `queueSupportRebuild` à 0,18 seconde puis
   `scheduleRebuild` à 0,12 seconde ; **aucun nouveau RenderStepped,
   Heartbeat, polling, asset, lumière, collider ou RemoteEvent**.
7. Aucun quota n'est augmenté : **un seul module original de
   sept MeshParts** pour les grandes structures Low, sous
   réserve de la politique d'exclusivité sous-structures/colonnes
   et de la pression GPU. Medium/High inchangés.

## Vérification Roblox Engine / Android à réaliser

- Sur un jeu en Low à pression 0, faire arriver progressivement
  les plateformes et supports natifs en streaming. Tester un
  deck au numéro **pair** pouvant recevoir une source originale,
  notamment sur les routes Towers et Harbor.
- Vérifier `LocalOriginalNearBridgeCradleCount` et
  `LocalOriginalNearSupportColumnCount` : un montage
  **réel et complètement validé** doit être comptabilisé,
  jamais une sélection seule.
- Confirmer la disparition des `PlatformUnderFrameN` ou
  `PlatformSupportN_K` natifs **uniquement** lorsque le
  modèle authentique correspondant est monté.
- Décharger exactement le support natif qui porte un
  modèle approuvé ; le nouveau rebuild doit restaurer
  l'état natif et retirer le modèle local orphelin.
- Charger/décharger d'autres supports à plus de 125 studs :
  aucun rebuild Low coûteux ne doit avoir lieu.
- Forcer `OptionalVfxPressure` à 1/2 : les modules facultatifs
  doivent être démontés, tandis que la physique et les
  avertissements demeurent inchangés.
- Mesurer les FPS, mémoire et temps de streaming Android,
  puis comparer des captures en perspective sur les
  supports/longues sous-structures concernés.

Les assertions de `tools/verify_original_3d_budget_census.py`
contrôlent les embranchements, le filtre impair conservé,
l'enregistrement et les garde-fous du streaming.
**Ce sont des vérifications du code source**, pas une preuve
de rendu en Roblox Engine ni une publication publique.
