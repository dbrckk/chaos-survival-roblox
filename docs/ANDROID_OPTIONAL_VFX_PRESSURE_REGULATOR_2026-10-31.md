# Chaos Survival — régulation Android des décorations facultatives

31 octobre 2026. Base inspectée : `main` à `78b28cb6cdd02caf5d62044ce6feb29007e8038e`. L'audit visuel des cartes est reporté. Cette modification ne publie pas l'expérience Roblox.

## Problème vérifié dans le code

`VisualBudgetRules.collect` distingue maintenant les coûts d'instances par propriétaire (#505) et les utilisateurs voient les alertes de FPS/p95. Cependant, les budgets Low/Medium/High restent **diagnostiques** : aucun régulateur ne pouvait ralentir plusieurs décorations secondaires lorsqu'un ensemble de contrôleurs dépassait le budget local. Désactiver sans distinction des propriétaires serait incorrect : les limites de vent Tornado, les anneaux Meteor/Bomb, les indications de sécurité et les dégâts serveur ne doivent jamais être masqués.

## Implémentation sur Android uniquement

1. `VisualBudgetPressureRules.desired(tier, metrics, fps, p95)` combine le ratio le plus élevé parmi les compteurs Parts/Lights/Effects et leur budget de tier avec les mesures `ClientObservedFps` et `ClientObservedP95FrameMs` déjà établies. `>=1,05` du quota ou FPS `<43` ou p95 `>=50ms` propose le niveau 1 ; `>=1,20` ou FPS `<27` ou p95 `>=75ms` propose le niveau 2. Si le FPS est `>=55` et p95 `<=35ms`, la récupération est autorisée, sauf forte surcharge d'instances `>=1,35` où le niveau 1 reste conseillé. Les valeurs nulles/non-finies ne déclenchent pas de pression par elles-mêmes.
2. `VisualBudgetPressureRules.advance` exige **deux échantillons défavorables** pour descendre d'un niveau visuel et **trois échantillons favorables** pour remonter ; une seule étape peut changer à la fois. Le but est d'éviter l'oscillation lorsque le smartphone chauffe ou que la pression change.
3. `visual-budget-pressure.client.lua` est un **unique observateur Android**. Il dort 16 secondes entre contrôles, ne fait **aucun recensement du monde hors `phase="round"`**, réutilise `VisualBudgetRules.collect(workspace, checkpoint)` et cède la main tous les 160 éléments. Il ne crée aucune boucle RenderStepped et n'envoie aucun nouvel RemoteEvent. Les snapshots RoundState malformés ou numérotés plus anciens sont ignorés. Changement de manche ou de carte : effacement immédiat du niveau et invalidation du recensement en cours.
4. L'état est diffusé localement dans `LocalPlayer.OptionalVfxPressure` : **0 = nominal, 1 = atténuation, 2 = forte atténuation**. Chaque contrôleur ne se rafraîchit que lorsque l'attribut change ; pas de nouvelle géométrie ou timer de ces contrôleurs.
5. La réduction est sélective et ne concerne que les décorations : `ChaosAura` sur personnages humains et bots, et `AmbientMotes` ainsi que les particules de l'ambiance cinématique. Les émetteurs décoratifs appliquent un coefficient **1.00 / 0.65 / 0.30**. À partir du niveau 1, les seules `ChaosAuraLight` supplémentaires sont désactivées. Les traînées de mouvement, silhouettes, signatures de danger, anneaux d'avertissement, cratères, fragments de débris essentiels, frontières Tornado, caméra et logique des catastrophes ne changent pas.
6. Le panneau staging affiche le niveau `P0/P1/P2` sur sa ligne existante et `visual_phase_probe` Studio ajoute le champ de diagnostic. Aucune capture visuelle, publication ou mesure FPS réelle n'est revendiquée dans cette PR.

## Contrats de stabilité / limites

- Le prélèvement général est peu fréquent et coopératif, mais constitue **un scan supplémentaire toutes les 16 secondes pendant une manche Android** ; il n'est pas gratuit. Un profiler Android doit confirmer que son coût est inférieur au gain produit par la régulation. Les mises à jour de l'attribut ne sont pas faites sur chaque frame.
- Le recensement porte sur des **instances** (y compris certaines masquées), pas sur la charge GPU ni la quantité de particules déjà vivantes. Le régulateur ne cherche pas à supprimer les Instances ou à faire descendre artificiellement les chiffres `visualParts`. Il ajuste uniquement les débits et lumières facultatives. Avec un FPS sain, il permet le rétablissement même si la plupart des instances de décor persistent.
- Le mode ReduceMotion, la qualité Low/Medium/High et les réductions déjà appliquées à Double Chaos restent multiplicatifs.
- Le nouveau niveau ne doit **jamais** être utilisé côté serveur pour récompense, déplacement, collision ou dégâts. L'attribut est un signal local de cosmétique non fiable et non autoritatif.
- En cas d'absence de mesures FPS, les ratios d'instances peuvent déclencher la régulation, sans prétendre prédire les performances réelles.

## Prochain jalon majeur prépublication

Exécuter Build Validation, les cinq suites Roblox Open Cloud sur le SHA exact de `main` et les sessions Android/PC. Sur Android, provoquer plusieurs pics d'instances et de longs ralentissements avec Meteor+Bomb+Tornado. Observer les changements P0→P1→P2 et le retour P2→P1→P0, la fréquence des recensements, le p95 et le CPU du scan. Vérifier READY/RESULT, changement de carte, streaming, FPS et p95 invalides, économie de Rate, conservation des alertes, survie, contrôles et FPS. Ne pas publier avant cette validation ; l'audit visuel des cartes reste reporté.
