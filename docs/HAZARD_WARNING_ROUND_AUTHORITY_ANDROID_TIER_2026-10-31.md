# Chaos Survival — avertissements 3D fiables et qualité initiale Android

31 octobre 2026. Correction des contrôleurs client sans audit visuel des cartes, sans accès Studio, sans build moteur et sans mise à jour publique.

## Défauts identifiés

- `hazard-warning-signatures.client.lua` créait des colonnes de météore et des croix 3D de bombe à réception du `Part` et des attributs, sans vérifier la **phase serveur courante**. Ces éléments **facultatifs** pouvaient donc s’afficher lorsqu’un avertissement arrive avant la confirmation de la manche, ou après une annulation rapide.
- À l’inverse, si un Part d’avertissement était reçu avant le premier `RoundState` de phase `round`, sa tentative de présentation ne pouvait pas être reliée à une confirmation serveur ultérieure.
- Une transition directement d’une manche numérotée à une autre `round` ne libérait pas nécessairement les accessoires de la manche précédente.
- Les contrôleurs `hazard-warning-signatures`, `hazard-warning-visuals` et `hazard-route-readability` utilisaient `VfxQuality.get(nil)` à l’initialisation ; cette valeur par défaut est **High**, y compris sur Android avant que l’échantillonneur adaptatif ait défini `VfxQualityTier`. Cela surcharge les accessoires facultatifs au début d’une session sur téléphone.

## Comportement corrigé

- Les signatures 3D météore/bombe attendent `RoundState.phase == "round"`. Les watchers d’attributs des Parts déjà streamés restent en place : à la première phase de round, le système réinspecte les avertissements existants, puis affiche leurs signatures en utilisant la **durée et l’horodatage serveur conservés** ; aucun minuteur de dégâts ne redémarre.
- Les événements `RoundState` de manche numérotée plus ancienne sont ignorés ; au changement de numéro de manche, les anciennes signatures cosmétiques sont retirées avant la relecture des avertissements présents.
- La sortie de phase `round` nettoie ces signatures uniquement **une fois par transition**, au lieu de tenter le même nettoyage à chaque tick du serveur. Les Parts avertisseurs serveurs, leurs zones de dégâts, les marqueurs au sol et l’HUD d’alerte indépendant ne sont pas détruits.
- Les trois contrôleurs principaux d’avertissement utilisent `VfxQuality.deviceTier(tier, UserInputService.TouchEnabled)` : **Medium sur Android** jusqu’à la publication d’un palier adaptatif, **High sur PC**. Toute sélection ultérieure Low / Medium / High continue de fonctionner normalement.
- Aucun nouveau RenderStepped, RemoteEvent, Part serveur, son ou asset. Les budgets globaux de géométrie et les règles de gameplay sont inchangés.

## Validation différée (jalon avant publication)

1. Sur SHA exact : Build Validation et les cinq suites Roblox Open Cloud, plus vérification en partie Android/PC.
2. Faire apparaître un avertissement avant que le client reçoive `RoundState` : la signature attend la phase round, apparaît si le timer serveur est encore valide, et **ne réinitialise pas** le compte à rebours.
3. Annuler un round pendant une tempête météore/bombe ; vérifier l’absence d’ancienne croix/colonne en READY, result ou lobby.
4. Enchaîner deux numéros de manches sans intermission locale ; vérifier qu’aucun effet facultatif de l’ancienne manche n’est conservé.
5. Démarrer sur Android avec `VfxQualityTier` non défini, puis déclencher une baisse Low et une remontée Medium/High. Mesurer les objets locaux, les FPS et la visibilité des avertissements critiques indépendants. **Aucun gain de FPS ni score AAA n’est revendiqué sans mesure.**

L’audit visuel authentique des cartes demeure volontairement reporté.
