# P4 — Harbor : station héroïque et grues originales chargées plus tôt

**12 novembre 2026 — modification de la programmation des imports serveur, sans nouvel asset ni publication Roblox.**

## Problème constaté sur `main`

- `PremiumHarborHeroStationAssets.lua` attendait **96 s** avant de solliciter la source créateur approuvée `73237902371094` : **sept vrais MeshParts** dont radar/câble/poids animés.
- `PremiumHarborGantryAssets.lua` attendait **76 s** avant de demander séquentiellement les deux sources approuvées `75684193304551` et `98809955094422` : **sept MeshParts chacune**, avec chariot/câble/charge animés.
- Les manches durent 30 s en solo et 45 s en groupe. Ces trois monuments restent donc primitifs durant au moins la première manche, même en présence de ressources réseau libres, et malgré les kits locaux 3D déjà présents.

## Changement livré

| Source d'origine | Quand Harbor est actif | Sur les autres variantes |
| --- | --- | --- |
| Station monumentale `73237902371094` | Première tentative à **33 s**, au lieu de 96 s | Ancienne échéance de **96 s** |
| Première grue `75684193304551` | Première tentative à **58 s**, au lieu de 76 s | Ancienne échéance de **76 s** |
| Deuxième grue `98809955094422` | Suit la première dans **le même worker séquentiel**, avec l'intervalle préexistant de 4 s après la première | Inchangé |

Les deux chargeurs réutilisent `PremiumActiveVariantImportSchedule.waitFor` et peuvent être réveillés lorsqu'Harbor devient actif pendant leur délai de repli. Les durées indiquées sont **des débuts de tentative**, **pas** des promesses de visibilité. Le temps d'attente de la file mondiale, la disponibilité Roblox/CDN et le temps de réplication restent variables.

## Compatibilité et sécurité

- **0 nouvel asset Roblox ; 0 nouveau MeshPart créé côté serveur ; 0 nouvel appel simultané** : `PremiumApprovedAssetImportGate` conserve la limite globale de **deux imports simultanés**.
- **Une seule coroutine par chargeur** ; chaque grue conserve le traitement séquentiel et ses trois tentatives existantes.
- Les fonctions existantes `sanitize` et `geometryOK`/`check` continuent à vérifier les modèles, leur géométrie, l'absence de code injecté et les rôles d'animation.
- Le modèle 3D n'est monté côté client qu'après contrôle de source, caméra, LOD et pression graphique. Les **formes primitives natives restent disponibles immédiatement** si l'asset échoue, sous pression Android ou lors d'une éviction du budget local.
- Aucun changement des collisions, de la physique, de l'éclairage, des rounds, de l'IA ou des risques.
- En cas de pression globale avant 33/58 s, les imports peuvent encore être mis en file sans dépasser les limites existantes.

## Vérifications

Le vérificateur source existant `tools/verify_active_variant_signature_schedule.py` contrôle désormais les deux échéances Harbor, la présence des modèles réellement approuvés, l'unicité de la coroutine/de l'appel au gate, la validation de géométrie et la séquentialité des grues.

**À mesurer dans Roblox Engine avant une certification visuelle :** pour Harbor sur Android Low puis Medium/High, relever à 10/30/45/60/90/120 s le nombre de MeshParts réellement résidents, les parties natives masquées/restaurées, FPS moyen/p95, mémoire et les pics de file `PremiumApprovedImportDiagnostics`. Tester aussi le changement de variante pendant l'attente, la perte d'asset et le rollback Low lorsque `OptionalVfxPressure` monte à 1/2.

**Non revendiqué :** le temps de rendu observé, un gain FPS, l'aspect AAA certifié ou une publication Roblox. Les délais de tentative réduits n'établissent pas à eux seuls le rendu final.
