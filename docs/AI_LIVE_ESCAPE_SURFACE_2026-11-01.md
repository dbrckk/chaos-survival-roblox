# Chaos Survival — fiabilité des trajectoires de fuite des bots (2026-11-01)

## Problèmes observés dans les sources après la mise à jour publique

`AISurvivorService.saferThreatEscape` compare actuellement la hauteur du `HumanoidRootPart` avec `support.Position.Y` : **le centre du Part** renvoyé dans `RaycastResult.Instance`. Sur une plateforme épaisse, le centre est beaucoup plus bas que le vrai contact du rayon ; un trajet praticable est donc pénalisé comme un gouffre. Cela se voit surtout sur les terrasses et structures 3D volumétriques de l'arène.

La cible d'évitement météore/bombe est verrouillée durant 0,54 seconde pour éviter des zigzags à chaque tick. Mais si une deuxième vraie zone d'impact apparaît pendant ce verrouillage, le bot conserve temporairement une direction calculée **avant** le nouveau danger, bien que `saferThreatEscape` sache déjà scorer toutes les zones visibles.

## Correction

1. `AISurvivorRules.escapeGroundStepPenalty(rootY, contactY)` vérifie les différences de hauteur à partir de la surface touchée par le rayon (`RaycastResult.Position.Y`), pas du centre de la pièce. Seuils de sécurité conservés : perte de hauteur >8 studs = 65 points de pénalité, montée >4 studs = 45 points ; valeurs malformées = 100 points. Les deux raycasts existants par candidat et les six directions existantes restent inchangés.
2. Le cache événementiel des avertissements conservait déjà une liste faible de pièces depuis `workspace.ChildAdded/ChildRemoved`. Il conserve maintenant aussi un compteur **`warningVersion`** incrémenté uniquement pour les apparitions/disparitions effectives de `MeteorWarning`, `BombWarning`, `FreezeWarning` ou `JumpShockWarning`. Le code ne parcourt pas le Workspace en plus.
3. `AISurvivorRules.keepEscapeRoute` conserve un trajet sur sa courte fenêtre habituelle. Si la génération de danger change, `newImpactIntersectsEscape` vérifie d'abord uniquement les **nouveaux** anneaux Bomb/Meteor, via la géométrie de leur empreinte de dégâts finale et du trajet actuel. Seul un nouvel impact qui **croise réellement le trajet** invalide le verrou et force le recalcul parmi six directions. Un anneau lointain, une zone supprimée, ou un trajet déjà dirigé vers l'extérieur ne déclenchent pas de nouveaux raycasts. Les avertissements sont mémorisés dans une table à clés faibles pour ne pas s'accumuler en session longue.
4. Réinitialisation de la génération mémorisée au remplacement du rig ou au changement de menace. Les bots se déplacent toujours via `Humanoid:MoveTo` avec vitesse et puissance de saut inchangées ; pas de téléportation, pas de visibilité privilégiée sur des dangers cachés.

## Vérification

Deux cas de régression ajoutés à `tests/engine/ai-survivor-rules.spec.luau` :
- une dalle épaisse avec surface réelle proche du bot ne doit pas ressembler à une falaise ; une vraie marche/cliff reste pénalisée ;
- la réutilisation de la trajectoire tient pendant le même avertissement, s'interrompt sur changement de génération **lorsqu'une nouvelle zone croise le trajet**, et expire correctement à l'approche de l'objectif ou à la fin du délai ;
- les nouveaux anneaux lointains ou les routes sortant déjà d'une zone ne doivent pas provoquer de replanification coûteuse.

Pas de nouvel `Heartbeat`, `RenderStepped`, RemoteEvent, scan, son, VFX ou logique de dégâts. Ces tests ne seront exécutés **qu'au prochain jalon important**, conformément aux règles de développement ; les vérifications statiques du diff sont faites maintenant.

La version Roblox **déjà publique** est le SHA `e8767c98c475a3efb39ed53ed7bbe16efa1865d2`. Cette branche n'est **pas publiée**. Prochaine validation : tests réels sur une manche Bomb+Meteor et sur les terrasses épaisses, puis observation des trajectoires et du temps de survie humain/bot. L'audit visuel des cartes reste reporté.
