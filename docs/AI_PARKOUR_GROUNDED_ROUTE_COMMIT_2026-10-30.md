# Chaos Survival — fiabilité du parkour des survivants IA (30 octobre 2026)

## Défauts corrigés

Les quatre routes de huit terrasses et les quatre embranchements latéraux de quatre terrasses existent déjà comme **vraies plateformes serveur**. Jusqu'ici, l'IA protégeait contre ses décalages latéraux aléatoires et les replanifications intempestives uniquement les deux premières étapes de la route principale. Sur les terrasses 3 à 8 et les embranchements, un NPC en pleine expédition pouvait donc changer légèrement de direction alors qu'il franchissait un saut étroit.

L'autre défaut venait de la validation d'étape par simple proximité horizontale : cette distance n'utilisait qu'une demi-dimension X et pouvait classer comme « atteint » un palier alors que le NPC était encore en l'air à côté du véritable plateau.

## Changement exact

- `AISurvivorRules.committedWorldRoute(..., activeExpedition)` conserve l'engagement du bot pour les huit `PerimeterStep` et quatre `BranchStep`, **uniquement lors d'une expédition active**. Un bot en promenade libre n'est pas bloqué indûment sur une terrasse supérieure inaccessible.
- `allowRouteStrafe` et `shouldReplanTarget` reçoivent ce contexte réel, sans modifier les appels existants qui ne le précisent pas. Le délai d'engagement reste borné : cinq secondes de grâce après l'échéance prévue, avec abandon pour les dangers, blocages et sorties de route.
- `landedOnRouteDeck` exige maintenant une position **dans l'emprise réelle X/Z du plateau**, calculée dans son repère `CFrame` (fonctionne aussi s'il pivote), une hauteur de `HumanoidRootPart` plausible et un `Humanoid.FloorMaterial` non aérien. Le script ne progresse vers le plateau suivant qu'une fois ces trois conditions réunies.
- Rien n'est ajouté aux boucles : l'IA réutilise son contrôle d'étape déjà cadencé à ~0,42 s. Aucun nouveau raycast, aucune téléportation, vitesse supplémentaire, collision artificielle, récompense, texture, IA externe ou réseau.

## Vérification au jalon

Les assertions du scénario moteur existant `tests/engine/ai-survivor-rules.spec.luau` sont actualisées pour couvrir l'engagement **sur stage tardif**, les embranchements et la position réelle sur plateau incliné ou tourné. **Les tests ne sont pas lancés pendant cette itération**, conformément à la règle générale du projet.

Avant la prochaine publication Roblox : exécuter les validations exact-SHA, vérifier les huit sauts successifs dans chacun des parcours, la transition vers les embranchements et l'abandon immédiat en cas de pluie de météores, sol disparu ou réduction de l'arène. Mesurer également la fluidité des bots sur Android avec des captures réelles ; aucune mesure de performance ni réussite en jeu n'est attestée à ce stade.
