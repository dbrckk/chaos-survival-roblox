# Navigation au sol des sept bots — chemin vivant et virages physiques

**5 novembre 2026 — correction source ; aucune publication.**
Base auditée : \`754c3ddabcc31b6c170f9bd8952245849787d8e4\` (Build + 7 suites Roblox Cloud verts sur cette base).

## Défaut de source confirmé

\`AISurvivorService.requestGroundNavigation\` validait les points renvoyés par \`PathfindingService.ComputeAsync\` **une seule fois**. Ensuite, \`advanceGroundNavigation\` suivait ces coordonnées jusqu'à 11 secondes sans revérifier leur sol, ni la présence d'un nouveau mur ou d'un mécanisme bloquant. Un vrai obstacle pouvait donc apparaître après le calcul ; l'avatar continuait contre lui jusqu'à un blocage physique, puis replanifiait. La tolérance de passage d'un point à **3,8 studs**, même à angle droit, pouvait aussi faire couper les coins de grandes structures.

## Correction intégrée

- Après un cheminement réussi, l'owner mémorise le vrai \`Base\`, la position de départ, la destination initiale et la cadence de contrôle. **Aucun point de saut ou de plancher fantôme n'est ajouté.**
- Lors de la progression, le prochain segment est vérifié à **0,72 / 0,84 / 0,96 s** suivant le numéro de bot : une lecture physique de la vraie \`Base\` sous le milieu et la fin du segment, puis jusqu'à deux courts rayons de collision aux hauteurs des pieds et du torse, seulement si le segment est assez long. Si la base, sa collision, sa hauteur ou un mur solide ne correspondent plus, le chemin est **annulé** et la destination défaillante est mise en quarantaine pendant 7,5 s. Les autres décisions du bot choisissent un nouveau but réel. Le contrôle ne s'exécute que si un chemin asynchrone est actif et hors urgence : aucun scan de l'arène en continu.
- Les autres joueurs/bots ne sont pas traités comme des murs permanents : seuls les obstacles \`Anchored\` et \`CanCollide\` déclenchent l'abandon par les rayons horizontaux. Pas d'augmentation de vitesse, de saut, de physique, de chance de survie ni de téléportation.
- \`AISurvivorRules.groundNavigationArrivalRadius\` garde la tolérance normale de **3,8 studs sur les lignes droites** mais exige **2,25 studs** aux virages prononcés (cosinus inférieur à 0,76) pour limiter les raccourcis dans les angles. La règle est ajoutée à la **suite moteur IA déjà existante**.
- \`BotLiveRouteInvalidationCount\` est un compteur du rig serveur, remis à zéro par manche et incrémenté uniquement sur annulation d'un vrai corridor devenu invalide. Il ne représente **ni un FPS, ni une preuve de test sur téléphone**.

## Performance, sécurité, limites

Le plafond d'un cycle complet est de **quatre Raycasts** (deux vers le sol et deux vers les murs) chaque 0,72–0,96 s par bot ayant réellement une navigation au sol ; dans le pire cas artificiel, sept bots restent sous ~40 rayons de sécurité/s. Pas de nouveau \`Heartbeat\`, \`RunService\`, \`RenderStepped\`, timer, RemoteEvent, module dépendant d'une API externe ou recherche Pathfinding supplémentaire.

La vérification est volontairement stricte : lorsque le retour de terrain est incertain, l'IA abandonne le chemin au lieu de marcher dans le vide. La collision au sol réelle prime sur toute décoration 3D. Les menaces urgentes et les quêtes physiques préexistantes gardent priorité. Une vraie observation en partie doit vérifier que des objets simplement cosmétiques ne sont pas interprétés comme des murs.

## Validation avant une future publication

1. Jalon sur le **SHA final identique** : source gate, Rojo build, sept suites Roblox Cloud. Le test moteur des angles est dans \`tests/engine/ai-survivor-rules.spec.luau\`.
2. Captures Studio/Android : un bot sur le vrai sol après déplacement d'un obstacle, une route à angle droit, puis une catastrophe arrivant pendant \`ComputeAsync\`. Vérifier l'absence de téléportation, de traversée de murs, de faux arrêts massifs et la différence réelle de \`BotLiveRouteInvalidationCount\`.
3. Mesurer la FPS et la mémoire avec sept bots R15, avant/après, sur **les cinq arènes**, et s'assurer que les portiques \`SkybridgeShutters\` et sauts en hauteur utilisent toujours leur logique physique indépendante.

**État :** code source à valider ; rendu Android, situation en partie et publication publique non attestés.
