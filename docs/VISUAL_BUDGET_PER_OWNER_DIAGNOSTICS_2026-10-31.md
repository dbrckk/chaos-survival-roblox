# Chaos Survival — diagnostic global du budget graphique par propriétaire

31 octobre 2026. Le dépôt `main` a été inspecté à `6122aa8474b4e9b10874c6bd73620587e88d6733` avant modification. L'audit **visuel** des cartes demeure reporté, mais la mesure logicielle des instances est désormais plus exploitable.

## Défaut constaté dans le code

`VisualBudgetRules.collect(workspace)` calculait correctement les totaux de Parts, Lights et Effects alloués par les propriétaires graphiques reconnus (plus certains effets client attachés à des éléments serveur), mais retournait uniquement les trois totaux et le nombre de dossiers inspectés. Impossible de distinguer une surcharge de cinématique de celle d'impacts temporaires ou de décorations de personnage lors des pics Double Chaos.

La capture de validation et le contrôle Studio disposaient **déjà** de leurs propres relevés (respectivement toutes les 4 secondes en staging et aux jalons Studio). Ajouter une nouvelle boucle ou un deuxième balayage serait une régression sur Android.

## Changement intégré

1. **API rétrocompatible** : `VisualBudgetRules.collect(root, checkpoint)` renvoie maintenant `metrics, auditedFolders, byOwner`. Le troisième résultat facultatif est une table des propriétaires réellement observés : chacun a ses propres `Parts`, `Lights`, `Effects`. Les appels préexistants qui ne récupèrent qu'une ou deux valeurs restent inchangés. Le callback de yield tous les 160 éléments est conservé.
2. **Attribution sur le même parcours** : chaque dossier de `VisualBudgetRules.LocalFolders` garde son nom exact; les facettes du projectile Meteor et les émetteurs/lumières de lave et de Freeze (attachés à des pièces serveur) sont regroupés sous `AttachedMeteorCosmetics` et `AttachedLavaFreezeCosmetics`. Les pads de lobby, pads de mobilité et éléments de personnages/joueurs IA utilisent des groupes locaux explicites. Les objets serveur eux-mêmes ne sont pas comptés.
3. **Classement déterministe** : `VisualBudgetRules.rankOwners(tier, byOwner, maxResults)` classe jusqu'à dix propriétaires en calculant leur contribution normalisée : `Parts/PartsBudget + Lights/LightsBudget + Effects/EffectsBudget`. Égalités départagées par nom. C'est un classement **du nombre d'instances attribuées**, pas une métrique GPU ou un signal de désactivation automatique.
4. **Intégration réelle en staging** : `visual-review-capture.client.lua` affiche les deux premiers propriétaires à partir du même collecteur à 4 secondes, sans nouveau `GetDescendants` ni horloge. Le widget est étendu de 15px pour laisser place au texte.
5. **Studio E2E** : `studio-e2e.client.lua` ajoute `visualTopOwners` aux sondes `visual_phase_probe` et indique les trois plus gros propriétaires dans le message de dépassement du budget. La mesure est celle déjà réalisée par Studio.
6. Aucun changement d'instances de décor, d'animation, de collisions ou dégâts, ni de mécanisme de tri des avertissements de sécurité.

## Limites et validation importante

- Le relevé identifie les **instances présentes dans les propriétaires reconnus**, même si un effet est désactivé/masqué ; il ne mesure pas le coût GPU, la texture, le nombre de particules effectivement rendues ou les assets serveur de décor. Il ne prétend pas limiter automatiquement les propriétaires.
- En QA pré-publication, vérifier sur le SHA exact de `main` que la somme de tous les `byOwner.*` égale exactement les compteurs globaux, avec dossiers, pads, avatars et effets attachés; vérifier que les anciens appels à une/deux valeurs retournent les mêmes nombres.
- Vérifier les top 2 en capture staging, les top 5 dans `visual_phase_probe`, les top 3 dans le rapport d'échec Studio, puis exécuter Build Validation et les cinq suites Roblox Open Cloud. Ne pas publier si des budgets sont dépassés ou si des avertissements disparaissent.
- Effectuer ensuite un vrai profilage Android/PC des FPS, du p95, de la mémoire et de la consommation GPU avant de modifier la sélection des effets. Les impacts, l'UI de sécurité et le contour de tornade ne doivent jamais être désactivés par une réduction automatique.

Les validations moteur/Android et la publication Roblox publique ne sont **pas** effectuées dans cette itération. Aucun audit visuel des cartes n'a été réalisé.
