# Chaos Survival — effets de catastrophe et transitions de manches

Date : 31 octobre 2026. Travail de code source uniquement ; aucun audit visuel actuel des cinq cartes, aucune connexion à Roblox Studio, aucun test moteur ni publication publique.

## Problèmes isolés dans main

- `disaster-aftermath.client.lua` créait deux nouveaux tweens de neutralisation du ciel/blur **à chaque** mise à jour `RoundState` en phase round, ready, waiting ou intermission. Ces messages sont fréquents et leurs destinations ne changent pas : chaque snapshot annulait les deux tweens précédents pour les remplacer par des tweens équivalents, y compris lorsque l'effet était déjà revenu à zéro.
- `disaster-residue.client.lua` lançait `clearResidue()` à chaque snapshot non round, créant potentiellement de nouveaux tweens et des appels `Debris` sur les mêmes marques au sol. Une nouvelle manche arrivant sans changement de libellé de phase ne remettait pas à zéro les traces ni le jeton utilisé par les avertissements différés.
- `disaster-setpiece.client.lua` nettoyait ses dossiers et incrémentait son jeton à **chaque** snapshot non round ; ignorait les changements de numéro de manche pendant une phase round ; et, après activation de `ReduceMotion`, supprimait les pièces déjà présentes mais n'invalidait pas les pièces encore planifiées par `task.delay`. Les effets différés pouvaient également viser la base d'une ancienne arène encore parentée au workspace pendant un remplacement.

## Correction effectuée

1. `disaster-aftermath` : garder `lastDisasters` à jour pour les résultats, mais ne lancer la neutralisation des couleurs et du flou qu'à l'entrée en round, au passage vers une phase non-result différente, ou au changement de numéro de manche. Conserver l'impulsion unique `round -> result` et son relâchement naturel. Ignorer les snapshots malformés ou numériquement plus anciens.
2. `disaster-residue` : nettoyer les surfaces **une fois par vraie transition** ; en cas de nouvelle manche numérotée dans le même état round, nettoyer l'ancien résidu et invalider les `task.delay` de marqueurs de danger précédents. Les impacts acceptés pendant la manche conservent les mêmes budgets, formes et durées de vie.
3. `disaster-setpiece` : ignorer les snapshots obsolètes et relancer l'introduction seulement à l'entrée en round ou lors d'une nouvelle manche identifiée. L'activation de `ReduceMotion` incrémente désormais le jeton avant le nettoyage, annulant les sous-effets différés. Vérifier l'identité de l'**arène active**, et non seulement le parent de son ancienne base, avant d'émettre une pièce 3D. Assainir `disasterIds` avant `ipairs` / `forIds`.
4. **Aucun impact serveur** : les hitbox des catastrophes, les avertissements de danger, les dégâts, les collisions, l'IA, les quotas 2K PBR et les matériaux restent inchangés. Pas de nouveaux événements, boucles de rendu ou assets.

## Validation différée

Ces changements sont inspectés statiquement, mais pas certifiés en partie. Au **prochain jalon de publication**, lancer Build Validation et les cinq suites Roblox Open Cloud sur le SHA de main correspondant, puis valider en jeu Android et PC :
- 15 à 20 manches avec transitions `waiting/ready/round/result`, y compris `Double Chaos` ;
- `RoundState` répété à l'identique : aucune nouvelle impulsion, scintillement atmosphérique ou renouvellement de marques ;
- activation `ReduceMotion` pendant une introduction avec deux catastrophes : aucune pièce différée ne réapparaît après le nettoyage ;
- changement d'arène lors de l'introduction, streaming du `Base` et arrivée différée d'attributs : aucun effet associé à l'ancien `Base` ;
- comparaison CPU, mémoire, FPS et lisibilité des avertissements réels sans considérer une amélioration non mesurée comme acquise.

L'audit réel des cartes (captures authentiques) est volontairement reporté. Aucun déploiement Roblox n'a été déclenché.
