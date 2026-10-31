# Chaos Survival — budgets réels de résidus et effets d'après-manche Android

31 octobre 2026 — correction du code source, sans audit visuel actuel des cartes, sans test Roblox Studio et sans publication publique.

## Audit source : les coûts s'additionnaient après la création

- `disaster-residue.client.lua` appliquait le plafond local des Parts **après** chaque explosion. Un seul impact pouvait construire 1+5 pièces en High ou 1+3 en Medium, puis immédiatement évincer d'anciennes instances, augmentant le trafic de création/suppression pendant Meteor + Bomb.
- Les traces de `FreezeWarning` et `JumpShockWarning` pouvaient créer un disque plus quatre fissures avant le même nettoyage. Le résultat de manche, souvent composé de plusieurs familles de catastrophes, pouvait également construire des groupes complets de 2/3/4 pièces puis les évincer seulement une fois la totalité calculée.
- `disaster-residue` et `disaster-aftermath` utilisaient `VfxQuality.get(nil)`, dont le fallback High sur les appareils tactiles précédait temporairement la mesure de qualité dynamique.

## Correctifs

1. **Une limite par tier partagée** : `DisasterResidue.impactPartLimit(tier)` est la source de vérité des plafonds locaux de `DisasterResidueLocal` : Low 18, Medium 34, High 52 Parts. Les résidus de dégâts et les marques de résultat partagent ce même plafond ; la limite globale `VisualBudgetRules` reste indépendante pour les dizaines d'autres contrôleurs.
2. **Coût exact avant la construction** : `ImpactSurfaceScarKit.partCount(tier, reduced)` fournit 1 pièce Low/ReduceMotion, 4 Medium, 6 High, et la recette des fissures utilise exactement cette valeur. `trimBudget(reserve)` retire d'anciennes traces en premier pour réserver les emplacements avant `ImpactSurfaceScarKit.build`. Les couleurs et formes d'impact restent identiques.
3. **Impacts Freeze/JumpShock** : le disque est créé uniquement si une place locale existe ; ses fissures supplémentaires sont plafonnées à la capacité restante avant allocation. Ce sont des marques *après* danger : la marque serveur, le compte à rebours et l'action « JUMP! » ne sont jamais supprimés.
4. **Après-manche** : réutiliser une partie des emplacements d'anciennes cicatrices pour les effets de résultat (sans dépasser le plafond live). Avant chaque motif de quatre/trois/deux pièces, vérifier la capacité disponible ; ne pas créer un motif incomplet pour ensuite le supprimer. Les fissures/fragments additionnels sont aussi limités au nombre d'emplacements encore libres. Sans catastrophe à représenter, ne supprimer aucune marque simplement pour réserver un budget inutile.
5. **Android natif** : `VfxQuality.deviceTier(..., TouchEnabled)` choisit Medium avant le premier échantillonnage tactile, et High sur PC ; ensuite Low/Medium/High du régulateur graphique. Cela s'applique aux résidus du sol et à la teinte/flou de résultat, sans modifier les effets de jeu serveur.
6. `disaster-aftermath.client.lua` ignore les snapshots malformés sans écraser un état valide.

## Contrôle du prochain jalon majeur

- Sur le **SHA exact de `main`**, exécuter Build Validation et les cinq suites Roblox Open Cloud, puis Android et PC réels.
- Enchaîner de nombreux impacts Meteor/Bomb pendant Double Chaos : inspecter `DisasterResidueLocal:GetChildren()`, jamais plus de 18/34/52 au tier courant, y compris juste pendant une explosion.
- Vérifier les cas ReduceMotion, le passage High→Low pendant une manche, des impacts avec terrain rotatif/streamé et de multiples Freeze/JumpShock.
- Sur résultat avec un, deux puis plusieurs désastres, vérifier que les motifs restent distinctifs et sont correctement nettoyés à READY/round, sans groupes amputés par une éviction de dernière seconde.
- Mesurer nombre de créations/destructions, performance FPS et mémoire. L'économie d'allocations est une propriété du code ; **aucun gain FPS mesuré** n'est revendiqué sans cette recette.
- Vérifier que les avertissements, les collisions, le rayon de dégâts, la victoire et les actions Android ne changent pas.

Ce correctif est un **plafond effectif sur le contrôleur des résidus**, pas une preuve que le budget global de tous les contrôleurs de catastrophes est désormais consolidé. Les autres contrôleurs restent indépendants et doivent être mesurés lors du jalon QA.
