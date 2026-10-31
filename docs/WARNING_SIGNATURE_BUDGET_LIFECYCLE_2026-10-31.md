# Chaos Survival — fiabilité des silhouettes de danger pendant Double Chaos

Date : 31 octobre 2026. **Correctif source, sans audit visuel actuel des cartes, ni test moteur, ni publication publique.**

## Constats dans `main`

Les explosions Meteor/Bomb possèdent déjà des marqueurs et des règles d'urgence **serveur** correctement séparés du décor graphique local. Le client `hazard-warning-signatures.client.lua` ajoute uniquement des silhouettes au sol (colonne de météorite, croix d'impact de bombe).

Deux problèmes de cycle de vie restaient possibles :

- La file `creationOrder` conservait une **référence forte** aux pièces d'anciens avertissements après `releaseWarning()`. Cette file n'était purgée qu'à la prochaine création d'une nouvelle signature ou à un changement de qualité. Après la dernière catastrophe d'une session, ces références pouvaient donc survivre inutilement.
- Quand une salve de Double Chaos saturait le budget de silhouettes (limites existantes : Low 6, Medium 10, High 14 ; mouvement réduit 4), l'éviction supprimait non seulement la décoration facultative, mais également l'inscription de l'avertissement. Un avertissement toujours actif pouvait donc **rester sans signature locale**, même si une autre silhouette expirait et libérait une place.

## Changement

1. Le suivi des silhouettes et sa file d'ordre sont séparés : `suspendSignature()` retire seulement le groupe 3D et son slot dans `creationOrder` lorsque le budget est plein, en conservant les listeners de la Part serveur. Les avertissements, dommages, rayons et collisions ne sont jamais modifiés.
2. `releaseWarning()` supprime systématiquement l'avertissement de `warningEntries` **et** de `creationOrder`, déconnecte ses événements d'attributs et détruit le seul groupe graphique qui lui appartient. Aucune référence forte d'une ancienne silhouette n'est conservée par la file après fermeture.
3. Un `task.delay` de fin de vie, borné par le **temps restant vérifié côté serveur** (`WarningRules.window`), libère également ces listeners même si la pièce serveur reste quelques instants dans `workspace` après l'impact. L'instance `entry` est vérifiée avant fermeture pour ne pas détruire un éventuel propriétaire plus récent. `Debris` demeure responsable de l'expiration des pièces visuelles.
4. Le **contrôleur visuel déjà existant** (0,12 seconde lorsque les plateformes sont concernées, sinon 0,35 seconde) réactive les avertissements suspendus **uniquement lorsqu'un slot graphique redevient disponible**, si le marqueur serveur est toujours présent et sa fenêtre encore active. Cette sélection ne touche ni le nombre maximal de décorations ni la priorité du HUD de fuite.
5. Aucune boucle supplémentaire, nouveau RemoteEvent, asset, son ou effet de gameplay. Le système de guidage vers une sortie d'explosion demeure inchangé.

## Validation au prochain jalon majeur

- Construire sur le **même commit** et exécuter la Build Validation ainsi que les cinq suites Roblox Open Cloud.
- Vérifier en situation réelle Android/PC l'enchaînement de plusieurs manches, le retrait/streaming d'avertissements et les salves Double Chaos au-dessus des budgets ; confirmer qu'une silhouette évincée ne réapparaît que lorsque le budget le permet et avant la fin du warning.
- Vérifier en mode ReduceMotion et après des passages Low/Medium/High : nombre maximal de silhouettes, synchronisation des timers, aucun faux indicateur de danger, aucun blocage des avertissements autoritaires.
- Mesurer le nombre d'instances, les callbacks restants, la mémoire et le coût CPU avant/après : **pas de gain revendiqué sans mesures**.

Les captures authentiques, l'audit visuel des cartes et la mise à jour Roblox publique restent reportés.
