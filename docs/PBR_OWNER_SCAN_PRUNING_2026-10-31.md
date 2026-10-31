# Chaos Survival — réduction du travail PBR des décors non autorisés

31 octobre 2026. **Source uniquement** : aucune connexion Studio, aucun audit de carte, aucun test moteur et aucune publication.

## Situation

Le client `src/client/pbr-district-materials.client.lua` met à jour les MaterialVariants 2K des surfaces approuvées et sélectionnées à distance de caméra. Son index `PbrCandidateIndex` est volontairement large : il répertorie les BaseParts de `Decor` pour supporter le streaming, les arrivées tardives et les changements de qualités sans perdre des composants.

Auparavant, **chaque** BasePart de cet index subissait d'abord les vérifications géométriques, de visibilité et de matériau, puis un calcul de distance caméra **avant** que le code ne rejette éventuellement son modèle non éligible au PBR. Sur les grandes arènes cela sollicite inutilement le CPU, même si l'instance n'est pas autorisée à utiliser les cartes 2K.

## Modification ciblée

- Lors de chaque réconciliation `scan()`, la provenance du parent est évaluée **avant** `eligiblePart()` et `withinDistance()`.
- Le résultat `PbrDistrictRules.eligibleOwner(owner)` est mis en cache **uniquement pendant le scan courant** : les nombreuses pièces du même bâtiment ne refont pas les contrôles d'owner. Les réponses négatives (`false`) sont aussi correctement mises en cache.
- L'index, ses observateurs d'ajout/suppression et les conditions d'éligibilité restent inchangés. Une modification de StreamingEnabled, des attributs de modèle ou de qualité est donc réévaluée lors du prochain scan ; aucun filtre irréversible au moment de l'indexation.
- Les matériaux, couleurs, scores de sélection, matériaux PBR 2K, quotas par propriétaire et quotas globaux sont inchangés.
- L'état `applied` des pièces dont les variantes ont été modifiées par un autre propriétaire est toujours invalidé **avant** sélection et sans tenir compte de l'approbation du parent, de façon à préserver la restitution existante.
- Aucun nouveau thread, RemoteEvent, boucle RenderStepped, MeshPart, particule ou texture.

## Contrôle actuel et vérification différée

Contrôle statique du code et des dépendances seulement. **Ne pas déclarer un gain FPS, RAM ou GPU sans mesure.** Les validations doivent être réservées au prochain jalon avant publication : Build Validation + les cinq suites Roblox Open Cloud sur le même SHA ; mesurer les scans PBR, les surfaces actives et les performances Android Low/Medium/High, en contrôlant les apparitions/disparitions de matériaux aux changements de qualité et de streaming. La validation visuelle des cinq cartes (75 captures) reste volontairement reportée.
