# P4 — Correction de l'identité atmosphérique Harbor

11 novembre 2026 — Lot issu de l'audit
[`P4_PUBLIC_VISUAL_ASSET_AUDIT_2026-11-10.md`](P4_PUBLIC_VISUAL_ASSET_AUDIT_2026-11-10.md).

## Défaut confirmé sur la version publique précédente

`ArenaAtmosphere.server.lua` ne possédait pas d'entrée Harbor et
utilisait `THEMES[variantId] or THEMES.Classic`. Le décor central de
Storm Harbor héritait donc des teintes bleu/violet de Classic, et le
bloc de signalisation `ClassicHubGlow` était instancié à son centre.
Ce décor était incompatible avec les véritables lignes de quai déjà
créées dans `MapBuilder.lua` ainsi qu'avec le thème Harbor de
`arena-lighting.client.lua`.

## Correctif

- Extraction des quatre thèmes atmosphériques existants **sans
  modification des valeurs** dans `ArenaAtmosphereStyle.lua`.
- La cinquième entrée est construite directement à partir de
  `VisualTheme.arena("Harbor")` : seafoam, acier patiné et bleu
  maritime. Le pilier Harbor est dimensionné à 11 studs ; le cercle
  de périmètre conserve son rayon de 43.
- Les quatre beacons Harbor utilisent maintenant un profil cylindrique
  arrondi (poteau de quai + lanterne), au lieu des parallélépipèdes
  de Classic. Leurs lumières existantes **ne sont pas augmentées** :
  quatre `PointLight` de mêmes intensité et rayon.
- Les quatre silhouettes périphériques utilisent une colonne, deux
  colliers et un chapeau cylindriques en acier corrodé, dans la même
  enveloppe extérieure. **16 objets, comme avant**. Elles restent
  purement décoratives et non physiques.
- Harbor ne reçoit plus le `ClassicHubGlow` central : la vraie
  signalétique de quai joue déjà ce rôle sans un néon générique qui
  surcharge la plateforme.
- Les autres arènes conservent les mêmes couleurs, formes et capacités ;
  les pièces de secours restent disponibles sans chargement réseau.
  Aucun ID Roblox, modèle approuvé, signal de danger ou système LOD
  n'a été modifié.

## Contrats de performance et sécurité

La scène Harbor passe de **37 à 36 BaseParts atmosphériques** (12
segments de ring, 8 beacon/pole, 16 silhouettes, zéro hub) et conserve
**4 `PointLight`**. Les primitives cylindriques sont de qualité
fallback légère : **pas** de nouvelle sculpture `MeshPart` prétendue.
`CanCollide=false`, `CanTouch=false`, `CanQuery=false`,
`CastShadow=false` et `Anchored=true` restent inchangés.

Test moteur de `ArenaAtmosphereStyle.profileFor` ajouté dans
`arena-presentation.spec.luau` (suite Open Cloud existante).
Test de régression source dédié exécuté dans GitHub Actions.

## Critères de validation visuelle encore nécessaires

- Capturer Harbor en **Low / Medium / High**, de près et depuis
  les quatre côtés de la carte, puis comparer à Classic.
- Vérifier la visibilité des marques de danger, la transparence des
  lanternes et les alentours du spawn dans le jeu **réel**.
- Mesurer FPS/p95 sur Android lors du changement de carte.
- Ne pas déclarer une meilleure esthétique finale uniquement parce
  que le profil source ou les vérifications Python sont verts.

**Statut du lot :** code et tests de source ; publication publique
distincte uniquement après Build + moteur de release.
