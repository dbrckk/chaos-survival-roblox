# V3 Lot 1 — habillage 3D original qui suit le joueur dans les cinq arènes

**Date : 5 novembre 2026. État : code source, non publié.**

## Défaut observé dans les owners existants

`PremiumPlatformSideMeshKit.selectCarapaceDecks`,
`PremiumPlatformSideMeshKit.selectBridgeGirders` et
`PremiumLargeStructureMeshKit.selectNearRouteStructures` classaient
correctement les vrais meshes importés autour de la caméra, mais seulement
à l'appel de `arena-platform-identity.client.lua:rebuild()`. Sans nouveau
streaming, chargement de source ni changement de qualité, le joueur
pouvait traverser l'arène de 320 studs et laisser les budgets de 8/16
carapaces, les girder et les colonnes alloués au quartier de départ.
Résultat : de grands parcours devenaient visuellement beaucoup plus
basiques, alors même que leurs modèles 3D originaux sont disponibles.

## Correction et budget

- Le scheduler déjà actif dans `scenery-lod.client.lua` relève la
  **translation horizontale** de la caméra dans le volume réel de
  `Arena.Base` ; aucune nouvelle boucle ni `Heartbeat`.
- Après **88 studs** de vraie translation **et** un intervalle minimal de
  **12 secondes**, il incrémente un attribut *strictement local* du joueur.
- Le propriétaire `arena-platform-identity.client.lua` écoute cet
  attribut et appelle son `scheduleRebuild()` déjà débouncé.
  Les importations sont ainsi resélectionnées à l'avant du personnage,
  avec le **même nombre maximal** de source MeshParts.
- Réinitialiser le point d'ancrage sur changement d'arène/qualité ;
  ne pas retarget en tier `Low`, sans caméra, en dehors du carré
  jouable, pendant une réduction forte de VFX, ou pendant Shrinking
  Arena si la base n'a plus sa taille complète.
- Ne toucher à aucun collider, chemin de bot, disaster, plateforme
  temporaire, asset Roblox, RemoteEvent ni budget serveur.
- Les modèles restent authentifiés et gérés par les contrôles de
  sûreté, de streaming et de repli déjà présents.

## Recette obligatoire avant la prochaine publication majeure

1. Sur Classic, Towers, Crossroads, Orbital et Harbor, avancer du centre
   à un district éloigné sans provoquer un changement de carte.
   Vérifier que le premier plan retrouve les vraies carapaces,
   colonnes et passerelles approuvées après translation de 88 studs.
2. Osciller autour d'un emplacement et faire pivoter la caméra :
   aucun rebuild déclenché uniquement par une rotation ou un écart
   inférieur à 88 studs. Ne pas dépasser un rebuild caméra/12 s.
3. Vérifier `Low` Android : aucun rebuild supplémentaire. Vérifier
   `Medium` Android et `High` PC : pas de pic FPS/GC problématique ;
   budgets 8/16, 2/4, 8/16 inchangés.
4. Faire streaming unload/reload et changement de carte/tiers :
   aucun masque natif orphelin et aucune passerelle fantôme.
5. Rejouer Warning / Gone, shutters et Shrinking :
   le server-authoritative danger est visible immédiatement.
6. Confirmer Build Validation, Roblox Cloud engine tests et contrôle
   visuel Android **sur le SHA retenu pour le release**, pas seulement
   sur ce commit source.

**Critère visuel visé :** le premier plan reste authentiquement 3D après
un déplacement important dans chacune des cinq cartes. Ce changement
ne prouve pas encore un niveau AAA ni un pourcentage de résidence 3D :
les captures/FPS du jeu public doivent être mesurés séparément.
