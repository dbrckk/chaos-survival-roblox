# Storm Harbor — quatre parcours d'avant-postes physiques (1er novembre 2026)

## Constat et objectifs

Le terrain fait bien 320×320 studs, avec 28 plateformes cargo centrales, 32 terrasses périphériques, 16 embranchements, 4 croisements et 14 passerelles nord/sud (soit 94 plateformes de base pour Harbor). Les nouveaux avant-postes desservent le **vide relatif des quatre axes cardinaux**, entre le cœur et les districts extérieurs, sans agrandir un sol vide et sans déplacer le patrimoine de 94 IDs existants.

## Réalisation de code

- `ArenaVariants.Definitions.Harbor.SpokePlatforms` contient **16 vraies dalles serveur**, quatre par direction Nord / Est / Sud / Ouest. Elles sont assemblées par la boucle de `MapBuilder.buildArena` **après les 94 plateformes** historiques, via les mêmes Parts ancrées/collidantes, système de budget de finition 3D, mécaniques de catastrophe, AI et collectibles.
- Chaque route démarre à 55 studs du centre, monte par 68, 81 et 94 studs, avec surfaces de hauteur 5, 8, 11, 14 studs. Les largeurs successives sont 12, 11,5, 11, 10,5 studs ; les espaces réellement vides entre plateformes sont 1,25 / 1,75 / 2,25 studs avec dénivelé de 3 studs, sous les limites `JumpRouteCueRules.MaxGap = 3.85` et `MaxRise = 4.05`. La première terrasse est à +4 studs depuis le sol, sous la limite du coach `nearestEntry` de 5,2 studs.
- Chaque vraie dalle possède les attributs `HarborSpokeRoute`, `HarborSpokeStep`, `RouteTier` et `ParkourGrade`. Seule la destination **physiquement suivante** d'un même axe peut être conseillée par `JumpRouteCueRules.nextPhysical`, et la règle vérifie collision, avertissement CollapsePhase et saut réel. Le flux serveur `ParkourFlow.legalJump` réutilise déjà exactement ce `nextPhysical`, donc les sauts légaux peuvent compter pour la maîtrise de manière autoritative, pas sur une déclaration du client.
- Décor natif intégré : plateau bois au début, métal corrodé dans la montée, couleurs dérivées de la palette propre à Harbor, finitions et habillages physiques de `addPlatformFinish`, quatre petits panneaux attachés à la **vraie** dalle terminale (`DOCK N/E/S/W`), visibles seulement à proximité et **masqués par les événements existants** lorsque la dalle reçoit un avertissement de disparition, perd sa collision ou devient transparente. Trois signaux de propriété par destination, aucune nouvelle boucle. Pas de `AlwaysOnTop`, 0 script de particules, 0 RemoteEvent, 0 RenderStepped, 0 son ajouté, aucun asset payant ni Model package requis.
- Les 94 anciens indices (y compris les passerelles skyway et les récompenses existantes) ne changent pas. Les quatre nouvelles destinations ne prétendent pas rejoindre un autre quartier en hauteur : elles offrent une **nouvelle sortie surélevée** depuis le sol. Les routes longues entre quartiers déjà présentes restent distinctes.

## Réception géométrique inspectable

| Direction | Centres X/Z des quatre étapes | Top Y | Gaps |
|---|---|---|---|
| Nord | Z -55, -68, -81, -94 ; X=0 | 5, 8, 11, 14 | 1,25 / 1,75 / 2,25 |
| Est | X 55, 68, 81, 94 ; Z=0 | identique | identiques |
| Sud | Z 55, 68, 81, 94 ; X=0 | identique | identiques |
| Ouest | X -55, -68, -81, -94 ; Z=0 | identique | identiques |

**Cette arithmétique ne vaut pas un test de franchissement dans Roblox.** Les tests moteur dans la suite existante `tests/engine/mapbuilder.spec.luau` ont été mis à jour pour protéger les anciens indices, l'identité des 16 nouvelles dalles, leurs collisions, la prochaine vraie étape, le point de départ et les quatre panneaux de fin. Tests non exécutés durant la phase d'amélioration.

## Prochaine grande validation (avant une seule publication publique)

1. Build Validation, cinq suites Open Cloud **au même SHA** ; ensuite Studio authentifié (cinq variantes).
2. Sur Harbor, jouer les quatre routes sol→plateforme1→2→3→4 en R15 Android et R6 desktop, vérifier chacune des douze transitions, notamment durant Moon Gravity / Lava / Shrinking Arena / Disappearing Platforms.
3. Aucun panneau n'indique une dalle supprimée ; la fin des routes offre réellement une nouvelle décision de hauteur. Vérifier que le coach dirige vers un point existant, et que l'IA n'obtient ni téléportation ni invulnérabilité.
4. Captures **réelles** centre, rue, points hauts et arène en conditions Nocturne/Tempête, Low/Medium/High ; comparer FPS, mémoire, occlusion des avertissements, collisions décoratives et intuitivité des destinations. Contrôler la bonne séparation des nouvelles plateformes et des bâtiments cosmétiques existants.
5. Mesurer taux d'utilisation et survie avec le correctif `Arena:Harbor` de la PR #517, sans confondre le temps mort des anciennes cohortes `Unknown`.

**Statut : nouveau code source ; aucune certification moteur, appareil ou publication Roblox n'est revendiquée.** La précédente version publique certifiée est le SHA `e8767c98c475a3efb39ed53ed7bbe16efa1865d2`.
