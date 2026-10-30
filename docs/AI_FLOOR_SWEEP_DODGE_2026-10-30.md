# Chaos Survival — IA et évitement physique des balayages (30 octobre 2026)

## Défaut corrigé

Le système serveur `AISurvivorService` calculait déjà une destination de fuite pour les bandes de `GridSweep` (Classic) et de `HarborCargoSweep` (Storm Harbor). Toutefois, la protection contre les petits décalages aléatoires de séparation sociale reconnaissait **uniquement `GridSweepPhase`**. Pendant un balayage portuaire, un bot pouvait donc recevoir un objectif d'évacuation exact puis voir cet objectif décalé latéralement vers la bande rouge/orange.

La gestion commune reconnaît à présent les **deux attributs authentiques**, et préserve les destinations calculées tant que la bande se trouve réellement en phase `Warning` ou `Pulse`. Aucun traitement spécial ne donne d'invulnérabilité aux NPC : ils continuent de subir la même impulsion que les joueurs s'ils restent dans la bande.

## Sorties géométriques plus crédibles

La nouvelle fonction `AISurvivorRules.floorSweepExitTarget` travaille dans le repère local de la **vraie Part serveur** de la bande et examine ses quatre limites. Le choix précédent utilisait systématiquement la largeur ; pourtant, près d'une extrémité d'une longue bande, sortir en longeant l'axe principal peut être beaucoup plus court.

La sélection :
- prend la plus courte **distance horizontale réelle** vers une zone de sortie, avec 5,5 studs de marge ;
- arbitre les quasi-égalités de manière stable en faveur de l'intérieur de l'arène ;
- conserve l'altitude courante, sans chercher une terrasse inaccessible ;
- conserve les délais de réaction individuels et la vitesse `Humanoid` habituels ;
- n'ajoute aucun saut forcé, physique, raycast, boucle, RemoteEvent, modèle ni texture.

L'IA continue d'abandonner ses objectifs secondaires en cas de danger immédiat. Les autres avertissements et chutes de plateformes gardent la priorité.

## Conditions de livraison

Source GitHub seulement. Aucun test n'a été lancé durant le développement. Avant la prochaine publication Roblox, exécuter les validations complètes sur le SHA final et observer des manches Classic + Storm Harbor sur Android : entrée près du milieu et près d'une extrémité d'une bande, sortie à temps, aucune cible sociale de repli dans la zone dangereuse, priorité des météores/bombes et retour normal à l'exploration après l'alerte.

Cette correction augmente la cohérence de déplacement mais **ne prouve pas à elle seule que les NPC ont un comportement indiscernable de celui des joueurs**.
