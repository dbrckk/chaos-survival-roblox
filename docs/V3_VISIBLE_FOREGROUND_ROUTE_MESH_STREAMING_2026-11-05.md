# V3 Lot 1 — vrais meshes proches caméra : source, visibilité et streaming

**Date :** 5 novembre 2026. **Statut : code source proposé, non publié.** Les tests finaux Roblox Cloud, Studio authentifié et Android physique ne sont **pas revendiqués** par ce chantier. Le jeu public existant fonctionne selon le retour du propriétaire ; ces changements n'y sont pas encore appliqués.

## Défauts visuels concrets dans les owners existants

1. **Décor arrivé après le pont :** `PremiumRouteMeshKit.mount` trouvait `Arena.Decor` une seule fois au moment de monter un vrai `PremiumJumpDeck` ou `PremiumSkybridgeModule`. Si les vrais `Platforms` précédaient `Decor` sous `StreamingEnabled`, aucun écouteur n'était connecté à l'arrivée ultérieure du dossier. Le `PlatformPanelN` natif restait visible devant le vrai 3D jusqu'à une éventuelle éviction/remontage du mesh.
2. **Budget 3D gaspillé :** les quotas 2/8/12 plateformes étaient consommés par les N premiers candidats caméra avant de vérifier si les vrais MeshParts approuvés pouvaient épouser leurs proportions. Un vrai modèle incompatible pouvait occuper un slot sélectionné sans monter, tandis qu'une autre plateforme physique adéquate restait native.
3. **Structures hors champ :** les sélections source de carapaces, de poutres de pont et de grands supports étaient des instantanés de carte calculés par distance brute, même quand les modèles coûteux se trouvaient derrière la caméra du joueur. Elles conservaient correctement une répartition sur toute l'arène, mais leur partie foreground ne priorisait pas la vue.

## Modifications intégrées à la branche de travail

- `src/client/PremiumRouteMeshKit.lua` : attacher le `PlatformPanelN` **uniquement** après vérification de son nom, dossier `Decor`, empreinte, hauteur, index et absence de collision/touch/query. Suivre événementiellement la création/suppression/remplacement de `Decor` et la réplication tardive du vrai panel ; restauration atomique du `LocalTransparencyModifier` initial lors des suppressions. Toutes les connexions sont déconnectées à la suppression du mesh/LOD/changement de carte.
- Une vérification complémentaire par l'**unique sampler LOD existant** traite les panels dont dimensions/position ont fini de se répliquer **après** `ChildAdded` : aucune boucle, raycast ou clone supplémentaire. Une fois le panel reconnu, aucune traversée de tous les MeshParts à chaque cadence.
- Préqualifier chaque modèle de plateforme contre les **vraies dimensions de la template** avant de réserver les budgets existants. Dans les mêmes plafonds, préférer les modèles dont le vrai volume couvre les deux axes du panel, pour effectivement remplacer l'aspect rectangle natif. Un remplacement partiel reste candidat plus loin et ne cache jamais un panel qu'il ne couvre pas.
- `PremiumPlatformSideMeshKit.lua` / `PremiumLargeStructureMeshKit.lua` : priorité limitée au champ horizontal devant le joueur lors du même **snapshot de rebuild**. Aucune commande de déplacement caméra n'est ajoutée ; les plateformes sous les pieds (<30 studs) gardent leur proximité. Orientation facultative, API rétrocompatible avec les appels existants sans argument de vue.
- `arena-platform-identity.client.lua` : passer la direction de la vraie caméra existante aux trois sélectionneurs. Aucun changement de limites High/Medium/Low, de provenance des assets ou de nombre de gros modèles approuvés.

## Invariants à préserver

- Aucune pièce cosmétique ne devient `CanCollide/CanTouch/CanQuery`. Les vrais chemins, shutters et avertissements restent gérés sur le serveur.
- `CollapsePhase`, `BridgeShutterPhase`, `ShrinkingArena`, `CanCollide` et `Size` conservent leur priorité absolue : panel et décor natifs doivent revenir lorsqu'un passage n'est plus sûr ou qu'un modèle disparaît.
- Aucun ID d'asset, texture, PBR 2K, RemoteEvent, `Heartbeat`, `RenderStepped` ou serveur supplémentaire.
- Les décomptes `LocalOriginalRouteMeshCount`, `LocalOriginalRoutePanelsCoveredCount`, `LocalOriginalNearRouteCarapaceCount`, `LocalOriginalNearBridgeGirderCount` et `LocalOriginalNearSupportColumnCount` doivent rester des valeurs réelles, pas des quotas déclaratifs.

## Recette à la prochaine étape importante (pas à chaque petit commit)

1. `Build Validation` + les sept suites réelles `Roblox Open Cloud Engine Tests` sur le **même SHA de release**, avec résultats non vides.
2. Réseau/streaming lent : créer `Platforms` puis `Decor`, puis `PlatformPanelN` ; le vrai panneau natif disparaît **uniquement** si le modèle approuvé couvre effectivement l'empreinte. Refaire avec panel initialement mal aligné puis stabilisé. Retirer/recréer `Decor` et le modèle à chaud : 0 panel permanent masqué sans modèle.
3. Pour les cinq cartes, comparer le premier plan en vue avant/arrière et la part de grands modèles réellement présents, avec les mêmes plafonds de MeshParts et de `VisualBudgetRules`.
4. Déclencher Collapse/Warning, shutters, Shrinking, Low↔Medium↔High, streaming unload et retour : aucune plateforme dangereuse ne conserve un faux rendu de sécurité.
5. Vérifier en vrai Android Low/Medium/High (FPS/mémoire, paysages proches à 15/50/120 studs) et captures du jeu. Aucun gain FPS/qualité AAA n'est chiffré sans mesure.

**Critère de succès :** davantage de vraies structures 3D lisibles dans le champ de jeu, aucune perte d'authenticité en streaming, aucune régression physique ou performance, et repli natif instantané. C'est un sous-lot de la V3 : la couverture globale 90 % du foreground reste à mesurer et à compléter par les chantiers suivants.
