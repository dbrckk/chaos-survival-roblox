# Chaos Survival — lisibilité Double Chaos et cycle de vie des récompenses d'esquive

31 octobre 2026 — audit **statique du code**, sans inspection visuelle actuelle des cinq cartes, sans Roblox Studio ni publication publique.

## Constat de départ

La dernière intégration (#494) protégeait les explosions et la caméra de spectateur, mais deux autres clients continuaient à représenter des dangers après les transitions :

- `near-miss.client.lua` ne suivait pas `RoundState` : la carte de combo, le halo plein écran éventuel et les `NearMissWorldPulse` locaux pouvaient rester jusqu'à leurs délais propres, même après passage au résultat, élimination ou nouvelle manche. Les combos visuels pouvaient aussi se prolonger d'une manche à l'autre. Les objets étaient parentés à `workspace` ou à l'ancienne racine du personnage, donc masquer la carte UI n'effaçait pas les effets dans le monde.
- Une alerte plus prioritaire (`MobileHudNotices`) masquait le toast, mais **pas** la pulsation 3D de l'esquive, qui pouvait obscurcir les empreintes de dangers pendant Double Chaos.
- Le rendu d'esquive commençait sur `VfxQuality.get(nil)` = High, même avant la première mesure Android.
- `hazard-route-readability.client.lua` appliquait tous les `RoundState` sans vérifier les numéros de manches et appelait un nettoyage réitéré sur les snapshots non-round ; un ancien paquet pouvait restaurer une flèche ou une consigne d'une manche précédente.

## Corrections apportées

1. **Récompenses visuelles sous contrôle du cycle de manche** : suivre phase et numéro de manche ; ignorer les snapshots numérotés plus anciens. Lors d'un changement effectif de phase/numéro, masquer le toast, annuler les tweens, invalider les callbacks différés, libérer son statut de notification et supprimer immédiatement les pulsations et éclairages locaux. Les compteurs de combos visibles reprennent à zéro à chaque manche ; la progression, XP et récompenses du serveur sont **inchangées**.
2. **Streaming/respawn** : un `CharacterRemoving` et l'attribut `RoundEliminated` invalident l'ancienne présentation. Les callbacks individuels de durée de vie suppriment uniquement leurs propres instances, sans toucher à de nouveaux effets. Un événement d'esquive arrivé avant le premier `RoundState` reste accepté afin de ne pas perdre un retour valide sur réseau lent ; la première phase confirmée non-round le nettoie immédiatement.
3. **Priorité aux vrais dangers** : lorsqu'un avertissement plus urgent prend la voie HUD mobile, le toast et la géométrie d'esquive purement optionnelle disparaissent ensemble. En écran très étroit, la pulsation optionnelle est également retirée. Sur mobile, au maximum deux anneaux de récompense d'esquive peuvent coexister ; le toast de combo accepté reste lisible.
4. **Qualité/accessibilité** : le rendu décoratif démarre sur Medium Android grâce à `VfxQuality.deviceTier`, puis suit Low/Medium/High. Le passage à `ReduceMotion` retire la géométrie en mouvement, sans supprimer le texte de la carte en cours.
5. **Guidage de survie** : `hazard-route-readability` rejette les snapshots plus anciens, masque ses flèches à chaque transition réelle et n'efface plus systématiquement les mêmes accessoires sur chaque heartbeat non-round. Les vrais avertissements et leur logique de distance restent inchangés.
6. **Aucune modification serveur** : hitboxes, dégâts, déclenchement de near miss, récompenses et RemoteEvents existants restent inchangés. Aucune boucle de polling ni de rendu n'est ajoutée.

## Vérifications différées au jalon de mise à jour

- Sur le **SHA exact de main**, exécuter Build Validation et les cinq suites Roblox Open Cloud, puis valider dans le moteur sur Android et PC.
- Sur Double Chaos (Meteor/Bomb/JumpShock), produire plusieurs événements d'esquive pendant un danger imminent. Vérifier que le toast et les anneaux optionnels laissent la priorité au guidage d'évitement.
- Émettre un événement d'esquive juste avant résultats et pendant `CharacterRemoving` : la carte et le dernier anneau doivent disparaître sans perturber la victoire.
- Observer un changement de manche sans intermission locale et des `RoundState` anciens arrivant en retard : aucun vieux combo, flèche offscreen ou « JUMP! » ne réapparaît.
- Démarrer Android sans attribut de qualité, puis passer Low/Medium/High et `ReduceMotion`. Vérifier les budgets d'effets et la lisibilité des commandes.
- Mesurer réellement FPS, mémoire, nombre d'instances locales, concurrence des messages HUD ; les bénéfices ne sont pas présentés comme mesurés tant que cette recette n'a pas été exécutée.

L'audit visuel réel des cartes est volontairement reporté. La version publique Roblox n'est pas modifiée par cette fusion GitHub.
