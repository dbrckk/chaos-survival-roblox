# Chaos Survival — façades locales : streaming, viewport et parité PC/Android

Date : 31 octobre 2026. **Correctif source uniquement**, sans inspecter les cartes ni exécuter une partie Roblox.

## Défauts détectés après les PR #482–#484

La PR #482 a déplacé six éléments 3D optionnels par bâtiment du serveur vers le client, tout en réduisant le nombre de pièces répliquées de 96. Le kit client `DistrictFacadeDetailKit.sync` utilisait cependant **la même distance maximale de 230 studs en High** sur PC et sur Android. Avant la PR, ces éléments étaient disponibles sur tous les bâtiments côté PC High, même au-delà de 230 studs : cela introduisait une régression de niveau de détail pour les joueurs PC.

Le kit appliquait également ses détails optionnels tant qu'un point caméra de repli `Vector3.zero` était disponible. Lors du démarrage/retour d'arrière-plan Android, `workspace.CurrentCamera` peut être manquant ou son `ViewportSize` nul ; la création de décor optionnel avant l'affichage n'a aucune valeur et peut gaspiller des allocations. Enfin, si un modèle déjà décoré perdait son marqueur de provenance ou changeait de version lors du streaming, le kit renvoyait 0 **sans retirer** les composants locaux existants.

## Correctifs intégrés

- **Parité PC High** : si `TouchEnabled=false` et le profil est High, conserver tous les détails optionnels du bâtiment, sans plafonnement mobile de 230 studs. Le LOD de base demeure inchangé. Medium non tactile dispose d'une portée de détail de 245 studs.
- **Android mobile maintenu** : Low crée 0 pièce optionnelle ; Medium affiche quatre pièces à proximité (portée 175 studs) ; High jusqu'à six pièces (portée 230 studs). L'hystérésis existante de ±8 studs est préservée.
- **Viewport valide obligatoire** : une caméra Roblox réelle et un `ViewportSize` non nul doivent exister pour créer les pièces locales. L'absence de caméra provoque un repli sans ajout de décor ; les grands modèles serveurs et le gameplay ne sont pas détruits.
- **Nettoyage sur changement de provenance / streaming** : `clearOwned` retire uniquement les six noms approuvés dont l'attribut `LocalFacadeDetail=true`, même lorsque les métadonnées du modèle deviennent absentes, incorrectes ou obsolètes. Les volumes de porte, éléments de gameplay et pièces non marquées restent intacts.
- **Distances invalides rejetées** : les distances négatives, NaN et infinies ne déclenchent aucun décor optionnel. Les coordonnées et palettes sont toujours reconstruites à partir des volumes serveur, comme avant.
- **Aucune nouvelle boucle** : les changements restent dans le `scenery-lod.client.lua` existant (0,65 seconde Low / 0,90 seconde Medium et High), sans ajout de RenderStepped, Heartbeat, réseau, asset payant, VFX ou collision.

## Critères à vérifier à la prochaine étape importante

1. Sur PC High, contrôler que les 16 bâtiments continuent de conserver les six accessoires optionnels, même quand la caméra s'éloigne. Sur PC Medium, vérifier la transition à 245 studs.
2. Sur Android Medium et High, passer lentement les seuils 175/230 studs en aller-retour : pas d'oscillation ni de parties du bâtiment qui persistent à distance. En Low : aucun détail optionnel, mais portes toujours visibles.
3. Au chargement et au retour d'arrière-plan du téléphone, vérifier que les pièces locales apparaissent après un viewport valide, sans pics CPU durables ni erreurs.
4. Lors de changements de map/StreamingEnabled, confirmer que les détails de l'ancienne zone ne subsistent pas après déchargement ; les panneaux, collisions, récompenses et dangers conservent leurs propriétaires serveurs.
5. Avant tout nouvel envoi au jeu public, exécuter **Build Validation puis les cinq suites Roblox Open Cloud sur le SHA exact de main** et effectuer des vérifications de performance sur vrai appareil. Ni FPS, ni 75 captures Studio, ni audit de cartes ne sont certifiés par ce correctif.

Le dernier état public Roblox n'a pas été modifié. Aucune authentification Studio ni intervention utilisateur n'est nécessaire pour ces changements GitHub.
