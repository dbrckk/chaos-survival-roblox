# Chaos Survival — cycle de vie du PBR lors des changements d’arène

31 octobre 2026. **Modifications du code uniquement.** L’audit visuel des cartes, les captures Roblox Studio, les mesures FPS et la publication Roblox restent exclus pour cette itération.

## Dysfonctionnements potentiels établis par lecture du code

1. `PbrCandidateIndex.watch()` reçoit les événements de suppression des descendants (`DescendantRemoving`). Quand Roblox retire un bâtiment `Model` contenant de nombreuses `BasePart`, le même événement peut être émis pour le modèle et ses descendants. L’ancienne fonction appelait `removeTree(instance)` (donc `GetDescendants()`) puis `onChanged()` **à chaque rappel**, y compris lorsqu’un ancêtre venait déjà de vider ce sous-arbre. Avec le streaming et les réinitialisations de manches, cela représente du travail redondant.
2. Le contrôleur `pbr-district-materials.client.lua` écoutait `Arena.ChildAdded` mais **pas `Arena.ChildRemoved`** pour son dossier `Decor`. La suppression ou le remplacement de `Decor` sans remplacement immédiat du modèle `Arena` ne déconnectait donc pas à cet instant l’index PBR associé au précédent décor ; l’état était seulement remis à jour à la prochaine construction/événement caméra.

## Travail effectué

- Le cache garde pour **un seul tour de planification** la liste des sous-arbres déjà retirés (`removedRoots`). Il supprime immédiatement la première hiérarchie détachée de l’index `parts`, mais ignore les notifications descendantes déjà couvertes par ce même retrait. Cela préserve le retrait immédiat nécessaire à la sécurité des sélections PBR et évite les parcours doublonnés.
- La notification `onChanged` est regroupée **une fois par salve de suppressions** au moyen de `task.defer`, sans nouvelle boucle de polling. `flushRemovals` vérifie l’état `alive` avant le callback ; la fonction de déconnexion vide toutes les tables temporaires et débranche les deux événements.
- Le client PBR écoute maintenant `Arena.ChildRemoved` en plus de `ChildAdded`. Quand le `Decor` réellement suivi est retiré, `bindDecor()` déconnecte immédiatement l’ancien index, vide ses références et planifie une réconciliation qui retire ses MaterialVariants si leur propriété appartient encore au client.
- Lors d’un remplacement complet d’arène, les connexions `arenaAdded` et `arenaRemoved` sont toutes deux débranchées. Cela empêche les anciens dossiers encore référencés d’appeler le contrôleur du nouveau décor.
- Les `MaterialVariant` actuels, les choix de texture, les quotas 2K globaux, les distances Low/Medium/High, les collisions, les bots et les mécaniques de désastre restent inchangés.

## Vérifications différées pour la prochaine version publique

La correction est **structurelle**, pas une mesure d’efficacité réelle. À l’étape importante précédant un déploiement, exécuter la **Build Validation** et les cinq suites **Roblox Open Cloud** sur le même commit `main`. En jeu, reproduire 15–20 changements d’arène en présence de streaming, basculer Low / Medium / High et PBR activé/désactivé, puis vérifier la stabilité de `PbrActiveSurfaceCount`, `PbrVisibleCandidateCount`, des matériaux et de la mémoire du client. Sur Android, comparer le temps de frame au début et après des manches répétées.

Les tests de moteur, les 75 captures officielles, l’inspection visuelle globale des cartes et la mise en ligne Roblox **n’ont pas été exécutés ici**. Ces opérations restent distinctes et ne doivent jamais être considérées comme déjà validées.
