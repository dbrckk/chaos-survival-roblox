# Crossroads — Flux Master donne un aiguillage d'or renforcé (P3)

**État :** développement source de la 2e arène P3 sur la branche `feat/p3-crossroads-flux-master-junction-cut-20261109`, basée sur `main@38ecd46b55bc633771a7ce25af9380d37a699395`. Le précédent lot P3 Classic est intégré dans GitHub mais **n'a pas été certifié dans Roblox Engine ni publié**. L'utilisateur a demandé de continuer **sans exécuter les tests pendant cette itération**. Cela n'autorise ni de présenter les résultats moteurs comme verts, ni de contourner les garde-fous de publication.

## Changement effectif de gameplay

Crossroads avait déjà deux systèmes de routes physiques : les `FluxRelay` extérieurs (trois passages de portes distinctes selon une paire alternée en 12 secondes pour `Flux Master`) et le `JunctionSwitchyard` central (deux aiguillages dorés sur quatre actifs à la fois, rotation toutes les 9 secondes, obligation de vraie vitesse latérale et délai de 4 secondes). La maîtrise Flux ne donnait pas de conséquence physique personnelle au joueur.

Le premier `Flux Master` **validé côté serveur** donne désormais une charge personnelle et **non persistante** de `MASTER JUNCTION CUT` :
- Le personnage doit traverser physiquement trois portes Flux chargées, distinctes et alternant les paires selon `FluxRelayRules.advanceWeave`, pendant la fenêtre normale de maîtrise. Les faux contacts, collisions d'accessoires éloignés, portes déchargées, combattants inactifs, enchaînements répétés et bot mort ne produisent aucune maîtrise.
- L'obtention est limitée **à une par manche** : `RoundFluxJunctionBoostEarned` et `RoundFluxJunctionBoostReady` sont écrits uniquement par le serveur sur le `Player` ; les NPC utilisent `FluxJunctionBoostEarned` / `FluxJunctionBoostReady` sur leur vrai modèle.
- La charge n'est accordée que si le vrai dossier `Mechanics/JunctionSwitchyard` existe. Quand le switchyard est volontairement désactivé (manche débutante ou catastrophe incompatible), `Flux Master` reste une réussite affichable mais aucun « boost prêt » inutilisable n'est promis.
- Pour dépenser la charge, entrer physiquement dans un **aiguillage réellement chargé** avec le seuil de vitesse tangentielle existant. Les validations `CrossroadsSwitchyard.tryTrigger` restent impératives : proximité du corps, joueur actif / bot en manche, Humanoid vivant, paire active, cooldown et revendication par fenêtre. Une touche invalide **ne consomme pas** la charge.
- La première activation valide applique **26** unités d'impulsion tangentielle au lieu de **20**, avec le même plafond de vitesse horizontale **48**, de vitesse verticale `[-52, 58]` et la physique native via `MovementSafety.addImpulse`. Pas de téléportation, collision modifiée, invulnérabilité, avantage de vitesse de marche ni pouvoir payant. Les activations ultérieures restent à 20.
- Les humains et les bots exploitent exactement le même `CrossroadsSwitchyard.velocity`, sans avantage NPC et sans effet sur les sauvegardes/récompenses. `OnArenaMechanicUsed` marque `MASTER JUNCTION CUT` sur une utilisation humaine réelle.
- Le **HUD Flux existant** affiche « BOOST • AIGUILLAGE OR » ou « BOOST • GOLD JUNCTION » après obtention, puis « CUT UTILISÉ / CUT USED » si le joueur a consommé sa charge. La détection du dossier réellement actif est locale et pas une valeur client transmise au serveur. L'affichage garde les mêmes règles de place sur écran Android et de priorité des avertissements.
- `init.server.lua` réinitialise les deux attributs joueur à chaque manche ; `AISurvivorService.setRoundState` fait de même pour les NPC réutilisés lors de READY. Ni une victoire, ni une mort, ni le passage à une autre carte ne permet de conserver la charge au-delà du round.

## Points de contrôle de réception pour une future publication

1. Crossroads + switchyard actif, joueur : compléter un vrai `Flux Master`, marcher vers un aiguillage doré, effectuer une vraie traversée tangentielle au bon moment ; un seul gain physique de 26 et feedback HUD « utilisé ».
2. Repasser par un aiguillage dans la même manche : l'impulsion revient à 20. Refaire un autre Flux Master après 12 secondes : pas de nouvelle charge parce que l'obtention est limitée à une par manche.
3. Aiguillage inactif, mauvaise paire, absence de vitesse latérale, cooldown, accessoire éloigné, joueur éliminé : ni bonus dépensé, ni mouvement forcé supplémentaire.
4. Manche débutante ou catastrophe où le switchyard n'est pas actif : `Flux Master` visible mais aucun boost fictif annoncé.
5. Un NPC qui maîtrise les vraies portes reçoit la même charge, qui se dépense sur son vrai corps à l'aiguillage, sans écriture Player/DataStore.
6. Un nouveau READY, une nouvelle carte et un rig NPC réutilisé : les deux drapeaux de maîtrise sont à nouveau faux ; aucun nouveau travail client en arrière-plan.

## Portée et limites

Seuls `CrossroadsFluxRelay.lua`, `CrossroadsSwitchyard.lua`, `init.server.lua`, `AISurvivorService.lua`, `flux-relay.client.lua` et ce document sont concernés. Aucune nouvelle tâche en boucle, boucle par frame, RemoteEvent, assets 3D, récompense économique ni test unitaire. **Aucun test Build/Roblox Engine/Android n'a été exécuté pour cette modification ; aucune publication n'est revendiquée.** Le workflow public actuel interdit toujours la publication d'un commit dont les validations exact-SHA sont absentes.
