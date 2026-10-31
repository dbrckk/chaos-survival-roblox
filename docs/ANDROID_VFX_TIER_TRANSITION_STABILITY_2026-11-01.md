# Chaos Survival — stabilité du régulateur VFX lors des transitions Android

1er novembre 2026. Révision de base réellement consultée : `0ff38e62f6f2d784cd921061a67fa9b3a31982e9` (`main`). Audit visuel des cartes toujours reporté.

## Défaut de cohérence identifié dans le code

Le régulateur introduit en PR #506 et accéléré en #507 conserve pendant 20 secondes maximum un compte de Parts/Lights/Effects, alors que la comparaison utilise les plafonds du profil graphique **actuel**. Un changement automatique de `VfxQualityTier` (High → Medium → Low, ou promotion inverse) n'invalidait ni ce compte, ni la série `streak`. Exemple : 650 Parts équivalent à ~72 % du budget High (900), mais ~148 % du budget Low (440). Si les contrôleurs avaient déjà diminué leurs instances après une baisse de qualité, réutiliser l'ancien compte pouvait activer P1/P2 sans justification actuelle, puis le relâcher au relevé suivant. Les changements de `ReduceMotion` ont une problématique similaire.

Autre fenêtre : la reprise d'un Android suspendu était traitée avant le recensement, mais une suspension pouvait également survenir **pendant les yield coopératifs** du recensement. Le relevé aurait alors pu être utilisé après reprise sans renouvellement.

## Correction concrète

- Abonnement aux signaux **déjà présents** de `LocalPlayer.VfxQualityTier` et `LocalPlayer.ReduceMotion`, uniquement dans le contrôleur Android. Aucun nouveau polling, `RenderStepped`, RemoteEvent ou scan.
- Lors de leur changement, incrément du `generation` local pour invalider tout recensement en cours, suppression des anciennes métriques et du `streak`. Le niveau `OptionalVfxPressure` actuel **n'est pas remis arbitrairement à P0** pendant un changement de tier.
- Une fenêtre de stabilisation de **8 secondes** bloque uniquement la prise de décision P0/P1/P2, le temps que les contrôleurs cosmétiques s'adaptent au nouveau profil; les relevés comptables peuvent encore se produire. La logique de réduction progressive P0/P1/P2 déjà livrée est conservée.
- Détection `task.wait()` d'une reprise après plus de **18 secondes**, y compris dans les checkpoints `VisualBudgetRules.collect` ; invalidation de l'échantillon interrompu et du streak. Après une reprise longue hors recensement, la stabilisation de 8 secondes empêche de réinterpréter immédiatement des attributs FPS/p95 d'avant suspension.
- La règle existante demeure : décision légère toutes les **5 secondes**, recensement coopératif au maximum toutes les **20 secondes** environ en manche active, avec checkpoint tous les 160 descendants. Aucune collecte dans le lobby, READY ou résultats.

## Contrats non modifiés

La réduction concerne uniquement les auras et lumières facultatives des joueurs/bots et les particules d'ambiance. Sont intégralement conservés : signaux de danger, zones de vent Tornado, contournement, guidage du joueur, niveaux de dégâts, collisions et physique serveur. L'attribute `OptionalVfxPressure` est local et non fiable pour des décisions serveur.

## Vérification pré-publication différée

1. Alterner High→Low→Medium pendant une manche et un recensement coopératif : tout compteur ancien doit être abandonné, aucune décision basée sur des plafonds d'un autre tier, pas de clignotement rapide P0/P1/P2.
2. Basculer ReduceMotion : aucun ancien streak; les effets d'accessibilité restent respectés, et l'alerte de danger doit rester lisible.
3. Suspendre Android plus de 18 secondes, d'abord entre deux cycles puis pendant un recensement comptant plusieurs checkpoints : anciens échantillons rejetés, aucune application immédiate de FPS périmés.
4. Vérifier les transitions de manche (30 s solo, 45 s standard), les changements de carte, les collections avortées et les mesures manquantes.
5. Exécuter Build Validation, cinq suites Roblox Open Cloud et un vrai profilage Android/PC au jalon pré-publication, sur le SHA final de `main`. Mesurer FPS, p95, mémoire, cadence réelle des scans et changements de pression ; les contrôles de source ne prouvent pas le comportement moteur ou un gain FPS.

Aucune publication Roblox publique, aucun essai appareil réel et aucun audit visuel des cartes ne sont revendiqués.
