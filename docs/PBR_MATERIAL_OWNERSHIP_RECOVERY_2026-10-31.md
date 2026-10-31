# Chaos Survival — propriété exclusive des matériaux PBR et restauration sûre

31 octobre 2026. **Correctif du pipeline client, sans audit de carte ni capture Roblox Studio**. La version publique ne change pas.

## Défaut identifié dans le code

Le script `src/client/material-variation.client.lua` modifiait les `Color` et `Material` natifs de tous les décors éligibles, y compris les modèles dont `src/client/pbr-district-materials.client.lua` est propriétaire. Or la variation de couleur pouvait s'exécuter **avant** l'application de PBR, et `restore()` rétablissait ensuite inconditionnellement une couleur et un matériau mémorisés même si une variante PBR ou un autre auteur avait pris possession de la pièce.

Conséquences potentielles (non mesurées, à ne pas présenter comme bugs visuellement reproduits) : mauvaise famille de matériau pour les textures 2K, rendu erratique lors des changements Low/Medium/High, et rétablissement d'une matière obsolète sur des surfaces récemment streamées. Les nouveaux modèles de porte et l'architecture d'origine rendent cette frontière importante.

## Modification

- Le propriétaire de la variation interroge maintenant le **registre PBR déjà existant**, `PbrDistrictRules.eligibleOwner(part.Parent)`. Pour tout modèle explicitement approuvé, la variation **n'applique jamais** de changement de `Color` ou `Material` (même avant que le système PBR ne décide d'allouer un budget de textures).
- Les autres décors continuent à utiliser les variations légères d'origine. Aucune règle de matière, de texture, de zone dangereuse ou de plateau jouable n'est modifiée.
- La restauration conserve désormais un instantané de `MaterialVariant` et les **dernières valeurs effectivement écrites par le script de variation**. Elle ne restaure chaque propriété que si celle-ci correspond toujours à cette écriture, si aucun propriétaire PBR n'a pris la main et si aucune `SurfaceAppearance` ou protection de matériau natif n'est apparue.
- Les références aux pièces suivies utilisent des clés faibles, ce qui évite que des pièces streamées ou détruites soient retenues en mémoire jusqu'à une prochaine reconstruction complète.
- Aucun RemoteEvent, connexion, boucle de rendu, nouveau modèle 3D ni asset de texture n'est créé.

## Réception différée — jalon de publication

1. Sur le **même SHA**, passer Build Validation et les cinq suites Roblox Open Cloud.
2. En jeu Android, comparer les entrées Classic/Towers/Crossroads/Orbital/Harbor en Low/Medium/High et avec PBR activé/désactivé. Vérifier qu'une porte céramique Orbital n'est jamais remplacée par du métal et que les matériaux Harbor restent cohérents.
3. Alterner qualité graphique, caméra, chargement/streaming d'arène et arrière-plan Android. Vérifier aucune PBR variante bloquée après changement de palier, ni couleur/restauration intempestive.
4. Mesurer FPS, mémoire et présence réelle des cartes ColorMap/NormalMap/RoughnessMap/MetalnessMap. **Ne pas attribuer une hausse de score AAA ou FPS au correctif sans mesures.**

Les 75 captures authentiques et l'inspection visuelle globale des cartes restent volontairement reportées, conformément à la demande.
