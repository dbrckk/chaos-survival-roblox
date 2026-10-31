# Chaos Survival — façades 3D locales, PBR cohérent et coût Android

31 octobre 2026. **Changement de source seulement** ; aucune capture de carte, Roblox Studio, benchmark Android ni publication Roblox n'a été effectué. L'utilisateur a explicitement demandé de poursuivre **sans audit visuel des cartes** tant que l'authentification Studio n'est pas possible.

## Constat technique ciblé (code, pas rendu)

La version précédente de `ArenaDistrictArchitecture.fixture` construisait 16 structures de secteur, chacune avec 8 `BasePart` de façade : deux gros volumes de porte visibles en Low, quatre accessoires Medium et deux accessoires High. Le client LOD masquait les accessoires, mais **les 8 Parts étaient toujours répliquées** à tous les appareils. Les accessoires optionnels représentaient donc **16 × 6 = 96 instances de géométrie serveur inutiles en Low et en distance**.

Les 16 bâtiments, leurs silhouettes de toit, les 4 monuments d'angle, leurs panneaux physiques, les chemins, dangers, joueurs, bots et collisions sont inchangés.

## Réalisation

1. **Propriété serveur stable** : seulement `ServiceEntryRecess` et `ServiceEntryDoor` demeurent dans chacun des 16 modèles. Les noms, dimensions, positions, matériaux natifs, couleurs et la porte candidate au PBR restent identiques. La géométrie noninteractive Medium/High n'est plus répliquée. Le serveur marque le modèle avec `FacadeVisualVersion=1`, `FacadeVariantId`, `FacadeDetailPieceCount=2`, `FacadeOptionalLocalPartBudget=6`.
2. **Un seul vocabulaire matériel** : `src/shared/DistrictFacadeStyles.lua` partage entre serveur et client la palette de matériaux existante des cinq arènes. Orbital conserve sa céramique, Harbor son bois et métal corrodé, Towers son alliage et diamond plate, Crossroads ses finitions béton/acier, Classic son acier.
3. **Détails réellement locaux** : `src/client/DistrictFacadeDetailKit.lua` restaure à proximité les quatre accessoires Medium (linteau, auvent, deux vérins) puis les deux High propres au profil (boîtiers radar, treuils, conduits ou turbines). Leur origine est reconstruite depuis la **porte originale et son CFrame** ; aucune copie du plan complet des bâtiments ni texture réseau n'est nécessaire. Les auvents des façades Towers/Harbor prennent une **forme en coin** à nombre de pièces constant.
4. **Coût contrôlé** : sur Medium, le seuil d'apparition est de 175 studs ; sur High, 230. L'hystérésis de 8 studs évite les recréations près du seuil. Low et les modèles invisibles libèrent ces détails. **0/4/6 Parts optionnelles par bâtiment**, selon profil, proximité et tier (moins encore si l'instance n'est pas disponible). Toutes sont `Anchored`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false`.
5. **Même propriétaire LOD** : le kit n'a aucun `RenderStepped`, `Heartbeat`, `RemoteEvent`, connexion propre par Part ni nouvelle boucle. Il est appelé depuis la boucle `scenery-lod.client.lua` déjà à 0,65/0,90 s. La distance s'appuie maintenant sur `BasaltFoundation` (origine serveur fixe) pour empêcher un déplacement du centre LOD lorsque les détails locaux sont ajoutés. `SceneryLodCache` et `PbrCandidateIndex` suivent les ajouts/retraits déjà reçus.
6. **PBR GPU** : les grands éléments conservent les quatre MaterialVariants d'origine (color, normal, roughness, metalness), soumis aux quotas déjà présents. Les vérins/conduits très fins et les auvents en bois/béton sont volontairement laissés avec leur matériau natif plutôt que d'occuper un emplacement de texture 2K. `LocalFacadeDetailCount` sur le Player indique le nombre de Parts **locales présentes**, pas des FPS ni des paquets réseau.
7. **Grands monuments existants** : `HeroArchitecture.lua` attribue désormais des familles de matériaux d'architecture propres aux cinq arènes (béton/ardoise, acier oxydé, diamond plate, céramique) **sur les mêmes Parts**. Aucune nouvelle instance, lumière, physique ou asset payant.

## Comparaison des allocations

| Surface | Ancien | Nouveau |
| --- | ---: | ---: |
| Façade, Parts serveur par bâtiment | 8 | 2 |
| Façade, Parts serveur pour 16 bâtiments | 128 | 32 |
| Détails Medium locaux par bâtiment proche | 0 | 4 |
| Détails High locaux par bâtiment proche | 0 | 6 |
| Détails Low locaux | 0 | 0 |
| Nouveau render/update loop | 0 | 0 |
| Nouveaux téléchargements de textures | 0 | 0 |

Les **96 Parts serveur économisées sont un décompte déterministe du code**, pas une mesure d'octets répliqués ou d'amélioration FPS. En High, si tous les bâtiments sont proches, jusqu'à 96 détails locaux pourraient encore exister. La création/destruction locale et les scans PBR peuvent également coûter du CPU lors des changements de tier : il faut mesurer le résultat en moteur avant toute promesse de gain de performance.

## Garde-fous et prochaine porte de sortie

- Aucun changement des parties de plateformes, de leur collision, des catastrophes ou des récompenses.
- Si une structure streamée manque sa porte ou possède une version visuelle inconnue, **ne rien créer** (repli natif lisible).
- Le kit refuse d'écraser/supprimer une instance non marquée `LocalFacadeDetail`. La suppression ne vise que les six noms optionnels approuvés.
- Un changement Low/Medium/High ou un stream-out ne conserve pas artificiellement les accessoires d'une autre arène.
- L'ancien scénario moteur de `mapbuilder.spec.luau` inclut désormais la protection des deux volumes serveur, de la version et de l'absence des six détails répliqués ; **scénario non exécuté pendant cette phase d'amélioration**.

À la **prochaine étape réellement importante**, exécuter Build Validation et les cinq suites Roblox Open Cloud **sur le même SHA** ; vérifier réellement sur Android en paysage/portrait : Low sans détails, Medium/High à courte/moyenne distance, passage de seuil aller-retour, streaming, reconstruction d'arène, matériaux PBR/natifs, avertissements de catastrophes, FPS/frametime et mémoire. Les **75 captures Studio** restent un jalon distinct, toujours bloqué par la connexion officielle. Aucune mise à jour publique ne doit être inférée de ces modifications GitHub.
