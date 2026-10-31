# Chaos Survival — cycle de vie audio et VFX entre manches

Date : 31 octobre 2026. Modifications du code client **sans audit visuel actuel des cartes, sans test moteur et sans publication Roblox**.

## Défauts identifiés

- `src/client/audio.client.lua` utilise `CharacterAdded` et `WaitForChild("Humanoid", 5)`. L’attente peut céder la main : un ancien avatar peut reprendre son initialisation après une réapparition plus récente. Avant ce changement, la fonction pouvait installer des abonnements audio sur un Humanoid obsolète ou remplacer des connexions encore valides. Le callback `HealthChanged` ne revérifiait pas non plus le propriétaire de l’avatar, contrairement à `StateChanged`.
- Des sons d'alerte (`Speed` après Overdrive, accents de désastre) étaient planifiés par `task.delay` sans vérifier au moment du déclenchement si la phase/manche avait changé. Un changement rapide de round pouvait donc jouer la signature sonore d'une manche passée.
- `src/client/round-celebration.client.lua` vidait les anneaux de son dossier `RoundCelebrationPulsesLocal`, mais ses `Attachment` de burst étaient rattachés au `HumanoidRootPart`. Ils survivaient à la sortie de l'écran de résultat jusqu'au timer `Debris` (1 seconde). Lors de transitions rapides, les particules de victoire pouvaient donc apparaître sur le début d'une nouvelle manche.

## Corrections

1. **Réapparitions audio** : le contrôleur de santé utilise un `healthBindEpoch` et une référence de propriétaire `boundHealthCharacter`. Une tâche initiale ou un événement de l'ancien avatar est rejeté **avant** de débrancher les connexions du nouveau personnage. Après un `WaitForChild` asynchrone, l'identité et l'epoch sont revérifiés avant d'abonner `HealthChanged` ou `StateChanged`. `CharacterRemoving` débranche les deux listeners du personnage réellement suivi. La santé du personnage est vérifiée avant toute annonce sonore de dégât.
2. **Sons de manche différés** : un `roundCueEpoch` augmente si la phase ou le numéro de manche change, et les deux familles de callbacks différés vérifient cet epoch et le fait qu'une manche est toujours en cours. Les sons immédiats, le mixage, les boucles et le volume utilisateur restent inchangés. Les snapshots `RoundState` malformés sont ignorés.
3. **VFX de fin de manche** : les `Attachment` émis sur le personnage sont suivis dans un registre à clés faibles, sans nouvelle boucle. La sortie de la phase `result` détruit immédiatement **et les anneaux et les bursts**, en laissant la gestion `Debris` de 1 seconde agir en filet de sécurité. Une transition direct résultat-vers-résultat avec numéro différent nettoie également les anciennes émissions. Les nouveaux effets restent limités par les règles de qualité et `ReduceMotion`.

## Ce qui n'a pas changé

Aucun changement serveur, aucune création de son ou asset, aucune modification des mécaniques de victoire, aucune variation des limites PBR/LOD, aucun nouvel événement distant et aucune boucle supplémentaire. Les effets valides de victoire continuent à jouer en phase `result`.

## Vérifications à effectuer uniquement au jalon majeur

- Build Validation et **cinq suites Roblox Open Cloud sur le SHA exact de `main`**, avant la prochaine mise à jour publique.
- En réel : 20 réapparitions rapides avec démarrage/arrêt de manches ; vérifier les sons de dégâts/sauts sans doublon et l'absence d'effets sonores provenant de l'ancien avatar.
- Enchaînement `ready -> round -> result -> vote` avec Overdrive et Double Chaos ; vérifier qu'aucun accent tardif n'arrive dans une autre phase et que les sons de résultat restent audibles.
- Vérifier les `LocalRoundCelebrationRing` et `LocalRoundCelebration` sur Android : un résultat valide reste visible ; aucune particule d'une victoire précédente n'accompagne la prochaine manche.
- Mesures audio/UI/VFX sur des sessions prolongées ; **ne pas revendiquer de gain FPS/mémoire sans mesure**.

Les captures réelles et l'audit visuel des cartes restent reportés sur demande. Aucune publication Roblox n'est déclenchée par ce changement.
