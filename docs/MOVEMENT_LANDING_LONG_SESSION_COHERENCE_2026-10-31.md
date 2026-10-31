# Chaos Survival — cohérence des réceptions, réactions et vitesse à l'écran

Date : 31 octobre 2026. Travail de code source client, sans audit visuel des cartes ni publication Roblox.

## Constats sur la version précédente

Le système produit déjà des animations d'accélération, de freinage, de réception et des mouvements de caméra, notamment via `body-feel.client.lua`, `movement-feel.client.lua` et les contrôleurs de réaction. Le défaut était dans la **gestion temporelle des effets**, pas dans l'absence d'une nouvelle caméra :

- `character-contact-vfx.client.lua` vidait `CharacterContactLocal` et tous les historiques aériens **à chaque** message `RoundState` lorsque la phase n'était pas `round`, même si elle n'avait pas changé ; une nouvelle manche numérotée en phase `round` n'était pas distinguée.
- `character-danger-reactions.client.lua` effectuait la même opération sur les pièces et historiques de réception, créant du travail inutile entre parties.
- `body-feel.client.lua` appelait `LocomotionGroundFx.clear()` sur chaque message hors manche, alors que les marques de course sont temporaires et doivent s'éteindre selon leur propre durée de vie pendant la manche.
- `speed-feel.client.lua` contrôlait les streaks par le statut `RoundParticipant` sans vérifier **la phase `round`**, l'état vivant du `Humanoid`, l'accessibilité `ReduceMotion`, ni si la caméra suivait réellement l'avatar local ; ces streaks pouvaient masquer une scène de résultat, un joueur spectaté ou une transition de caméra cinématique.
- Les deux couches de réactions installaient deux abonnements `CharacterAdded` / `CharacterRemoving` pour chaque joueur rejoint, sans débrancher ces abonnements lors de `PlayerRemoving`. Sur de longues sessions, les références se libéraient alors moins explicitement que nécessaire.
- Les effets de réception utilisaient `VfxQuality.get(nil)` (par défaut High), même avant que l'échantillonneur Android ne publie la première qualité dynamique.

## Corrections

1. **Historiques et VFX de réception** : `character-contact-vfx` et `character-danger-reactions` ignorent les snapshots malformés ou numériquement antérieurs, conservent les pièces actives lors d'une répétition de `RoundState`, et invalident les historiques de saut et les cosmétiques uniquement lorsque la phase ou le numéro de manche change. Cela couvre les transitions directes entre deux numéros de manches sans intermission visible.
2. **Cycle de vie des joueurs** : les connexions de personnages de ces deux contrôleurs sont répertoriées par `Player`, avec déconnexion explicite et suppression des timestamps associés au départ.
3. **Qualité Android** : les budgets d'impact/réception et de vitesse se basent sur `VfxQuality.deviceTier(..., TouchEnabled)` : Medium avant la première mesure sur Android, High sur PC, puis suivi des paliers adaptatifs.
4. **Réactions au sol** : `body-feel` nettoie ses effets de sol au changement effectif de phase/numéro de manche, plutôt que de réclamer le même nettoyage sur chaque message hors manche. L'effet `SpeedSurge` et `LowGravity` continue à suivre la liste serveur actualisée à chaque snapshot.
5. **Streaks de vitesse** : `speed-feel` montre ses huit effets GUI existants seulement pendant la phase `round`, pour un humain vivant, réellement en jeu, non éliminé, sans `ReduceMotion`, avec une caméra non scriptée possédant un viewport valide et suivant le propre `Humanoid`/personnage. Dès la sortie de manche, `hideStreaks()` masque immédiatement tous les éléments. La caméra Roblox native et le véritable contrôle tactile restent intacts.

## Ce qui n'a pas été modifié

Aucun saut, vitesse, accélération, hitbox, collision, état `Humanoid`, avantage de coyote time, suivi spectateur ou autorité serveur n'a changé. Aucune nouvelle boucle RenderStepped, RemoteEvent, texture, musique, modèle ou animation payante n'a été créée. Les effets humains et bots utilisent leurs budgets antérieurs et leurs durées d'origine.

## Recette de validation au prochain jalon important

- Build Validation et les cinq suites Roblox Open Cloud sur **le même SHA de `main`**, puis tests Android réel/PC.
- Exécuter 20 sauts avec réceptions à différentes durées de chute, y compris sur matériaux métal, béton, bois ; vérifier empreintes, audio et posture, sans doublons ni disparition avant leur propre durée de vie.
- Enchaîner des manches avec de nombreux `RoundState`, `ready/round/result/waiting` et deux manches numérotées directement ; vérifier nettoyage au changement et maintien pendant l'état inchangé.
- Faire entrer et sortir de nombreux joueurs/bots dans une longue session ; surveiller le nombre de connexions, la mémoire et le budget de traces.
- Sur Android, alterner spectateur, caméra scriptée, retour d'arrière-plan, réglage `ReduceMotion`, Low/Medium/High ; aucun streak de vitesse ne doit rester visible sur le résultat ou la caméra d'un autre joueur.
- Mesurer réellement FPS et mémoire ; **ne pas présenter une amélioration de performance comme mesurée** en l'absence de benchmark.

L'audit des cartes par captures Roblox Studio reste reporté sur demande et n'est pas requis pour cette modification source. La version publique Roblox reste inchangée tant que les jalons moteur/release ne sont pas passés.
