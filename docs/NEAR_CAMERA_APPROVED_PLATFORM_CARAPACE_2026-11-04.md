# Lot P0 — vrais habillages 3D des plateformes proches caméra

**4 novembre 2026 — modification de source uniquement, non publiée.**
Dépôt \`dbrckk/chaos-survival-roblox\`, base \`a89984307426fb8dfcf01ec082cab92b648d1374\`.

## Problème réel : mauvais choix des plateformes sculptées

Le client possédait déjà cinq modèles originaux et approuvés de **carapaces structurelles** (\`ApprovedPlatformSideTemplates\`, import #41798024000) : Classic 92590025262416, Towers 85204303404953, Crossroads 116452624086023, Orbital 118444100674717, Harbor 124136394128432. Leur géométrie réelle importée est limitée (1 à 12 MeshParts par modèle, vérification dimensionnelle). Ils ne sont pas des \`MeshId\` fictifs.

Cependant \`PremiumPlatformSideMeshKit.carapace\` choisissait *uniquement* les decks dont le numéro était congruent à 1 modulo 6 sur High ou 1 modulo 12 sur Medium. Cette sélection arbitraire pouvait laisser les gros decks du premier plan en \`Part/WedgePart\` tandis que des carapaces réelles couvraient des secteurs lointains. \`PlatformFinishKit\` conservait son budget natif de carapace modulo 3/4.

## Livraison source intégrée

1. Le propriétaire existant \`arena-platform-identity.client.lua\` sélectionne au rebuild de la carte / qualité les **16 plateformes sûres les plus proches en High, 8 en Medium** (Low = 0). Calcul basé sur la caméra **uniquement si elle est réellement proche de l'arène**, sinon le centre géométrique authentique. Tri déterministe par distance avec biais des vraies routes permanentes ; pas de nouvelle boucle.
2. Le constructeur \`PlatformFinishKit.buildCarapace\` accepte une sélection explicite uniquement pour le modèle source réel. Il ne fabrique **aucune nouvelle \`Part\` native** en cas d'échec. Les anciennes carapaces natives restent au même rythme fallback (1/3 High, 1/4 Medium, 1/8 Low). API historique préservée quand la sélection est absente.
3. \`PremiumPlatformSideMeshKit\` vérifie toujours provenance, géométrie, propriété et **vraie plateforme collidable serveur** avant de monter la carapace. Les pièces cosmétiques ne collisionnent jamais, restent soudées à la plateforme et utilisent les listeners existants de collapse/shrink ; les ornements natifs du même index sont masqués seulement quand l'authentique géométrie est déjà montée.
4. L'owner calcule un nombre de montages **effectivement réussis** \`LocalOriginalNearRouteCarapaceCount\`. Un candidat retenu dont l'asset ne se charge pas n'est pas compté. Le watcher \`ApprovedPlatformSideTemplates\` existant déclenche déjà un rebuild après chargement tardif (74 secondes ou plus), donc la sélection peut s'installer sans demander au joueur de rejoindre une deuxième fois.
5. Le kit \`PremiumRouteMeshKit\` **caméra-LOD**, qui contrôle déjà les surfaces UV des vrais decks et ponts, reçoit maintenant \`OptionalVfxPressure\` via son propriétaire \`scenery-lod.client.lua\`. Sous pression 1, il réduit les résidents : decks ~68 %, ponts ~70 %, underdecks 50 %. Sous pression 2, decks ~38 %, zéro pont/underdeck optionnel. Les budgets originaux s'appliquent à pression 0. Aucun collider / warning / DataStore / IA modifié.

### Coûts et limitations

- **Plafonds de carapaces importées par rebuild :** High 16, Medium 8, Low 0. Chaque vraie source peut compter jusqu'à 12 MeshParts : plafond théorique 192 / 96 / 0 nouvelles pièces résidentes pour ce seul habillage (en pratique les assets approuvés sont sculptés en un nombre limité de MeshParts). Les Parts se trouvent **dans \`ArenaPlatformIdentityLocal\` déjà compté** dans les budgets globaux 900/680/440.
- Les top-decks/skybridges restent limités à 12/3 High, 8/2 Medium, 2/1 Low en pression normale. Il s'agit de modèles cosmétiques supplémentaires, **pas** de surfaces physiques ou d'une multiplication du nombre de parcours.
- La sélection structurelle est un **snapshot à chaque rebuild de carte / tier / arrivée d'asset** ; les surfaces premium de route suivent toujours la caméra à chaque tick du sampler existant. Ne pas prétendre que les carapaces structurelles sont continuellement reclassées par caméra.
- Les modules d'éclairage, bruit audio, caméra, danger, avertissements et visibilité mobile ne sont pas touchés. Aucun nouvel upload, asset propriétaire ou coût en jetons.
- **Risque à vérifier sur vrai Android :** hausse de géométrie High/Medium près caméra, coupures de rendu lors des changements de tier et couverture réelle selon les tailles de chaque deck. Une limite d'instances seule ne mesure pas les draw calls.

## Critères de clôture de ce premier sous-ensemble du lot 1

- Build Validation + sept suites moteur Roblox sur le **même SHA source**, contrôle du suivi des sources approuvées.
- Captures authentiques au spawn, sur les routes verticales, au milieu des deux promenades et de Sky Spine sur les cinq cartes ; confirmer que les carapaces sculptées remplacent les \`WedgePart\`, sans s'empiler.
- Streaming, arrivée tardive d'assets, chasse aux objets fantômes pendant \`ShrinkingArena\` et disparition des plateformes. Le \`Part\` original conserve tout collision, dégât et décision d'IA.
- 30 min Android Low/Medium/High avec nombre de vrais clones, ralentissements p95, mémoire, budget global et qualité visuelle. **Aucune certification réelle ni publication** sans ces preuves.

Le chantier continue avec les **jonctions structurelles et sous-faces longues**, qui devront être traitées de la même manière et sans inventer de route ou de modèle.
