# P4 — Les vrais décors de maîtrise réagissent à la progression personnelle

**9 novembre 2026 • source seulement.** Départ `main@a73e6e326d25e34e3b107aaae43e39960deed149`. Les cinq arènes disposent déjà de mécaniques P3 en source ; ce lot améliore la **lecture dans le monde 3D** des trois récompenses qui ne se consomment PAS sur les pads normaux. P3/P4 restent **non publiés et non certifiés Roblox Engine** ; la dernière publication vérifiée est P2 (`ae4ae044...`, [workflow #42650986552](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42650986552)).

## Audit des mécanismes réellement jouables

- **Towers** : une vraie course sur trois ponts Skyrail donne `RoundSkyrailAceBoostReady`, dépensé seulement en traversant **un pont encore collidable et non averti**. Les anciens pylônes/courriers 3D client n'affichaient pas cette différence.
- **Orbital** : `RoundHelixMasterPulseReady` est dépensé uniquement par une traversée physique de la rampe dont `HelixPulseActive` est vrai. L'ancien effet de mouvement montrait seulement « pulsation active », pas la charge de maîtrise personnelle.
- **Crossroads** : `RoundFluxJunctionBoostReady` est dépensé sur un **aiguillage doré réellement chargé**, jamais dans les portiques Flux ni sur un pad de mobilité. L'ancien panneau de l'aiguillage disait en anglais « TURN TO BOOST » même en français et ne distinguait pas le prochain `MASTER CUT`.

## Travail source effectué

### Towers — signalisation sur les vrais quatre ponts

Le propriétaire existant `tower-skyrail.client.lua` utilise les **mêmes** colonnes, couronnes, petites ailes et courriers 3D. Tant que le serveur annonce `RoundSkyrailAceBoostReady` pour ce survivant vivant, les arêtes de chaque pont **praticable, sans CollapsePhase ni volet actif** deviennent or clair et le courrier se fait plus lumineux. L'identité cyan/ambre est restaurée dès la consommation. Une plateforme effondrée, un pont en préavis ou un volet en mouvement reste traité prioritairement par les anciens signaux de danger, sans fausse route sûre.

### Orbital — rampe chargée, et seulement elle

Le propriétaire existant `orbital-helix.client.lua` ne crée **aucun nouveau glyph** : son groupe de 8 à 24 glyphes animés devient or/blanc plus lumineux sur les seules rampes `HelixPulseActive=true` si la charge `RoundHelixMasterPulseReady` existe. La couleur est calculée une fois pour tout le lot, pour éviter les allocations de `Color3` dans les 75 ms de rafraîchissement existants. Les rampes déchargées restent cyan/vert, et les visuels du serveur donnent le repère Gold Low/ReduceMotion sans charger de nouvelle géométrie.

### Crossroads — une vraie sculpture 3D et un guidage honnête

`flux-relay.client.lua` réutilise ses **quatre vrais** `JunctionSwitch`, chevrons natifs et panneaux serveur, sans nouveau HUD. Sur les deux stations `JunctionActive`, un joueur qui a `RoundFluxJunctionBoostReady` voit localement l'indication bilingue **« COUPE MAÎTRE / MASTER CUT »** et des chevrons plus lumineux. Les stations inactives restent violettes ; la charge ne peut pas être fabriquée ou dépensée côté client.

Le nouveau `PremiumJunctionHardware3DKit.lua` monte un carénage acier forgé **genuine source-approved** près des seules stations actives, à partir du modèle original **`ApprovedFloorReliefTemplates.CornerGuard`**, `Original3DAssetId=102215174919938`. Il applique la même vérification de provenance/owner/modèle/flags/silhouette (4.7–5.6 × 4.7–5.6 studs, épaisseur 0.24–0.56, 1–12 vrais MeshParts, zéro script), et redimensionne pour tenir dans la vraie zone de 6.2 studs sans prolonger la physique. Les MeshParts restent entièrement ancrés, **CanCollide=false / CanTouch=false / CanQuery=false / CastShadow=false**. Le kit n'invente aucun asset ni MeshId.

- **Budget** : Low **0**, Medium **1**, High Android/PC **2** ; pression légère **1 maximum**, forte **0**. Les MeshParts résident sous le dossier déjà inscrit dans le budget global `VisualBudgetRules.LocalFolders` : `FluxRelayLocal`. Aucun census contourné.
- **Cycle de vie** : les vrais aiguillages sont réévalués seulement dans la **boucle de visualisation Flux déjà existante** ; l'arrivée tardive de l'asset est détectée sans nouveau polling ; à la rotation de la paire active, à la mort/changement de manche/carte, à la perte de l'asset ou à la pression GPU, les sculptures non valides sont retirées et les signaux serveur restent visibles. Le compteur `LocalApprovedJunctionHousing3DCount` mesure seulement des modèles locaux effectivement montés, **pas une réussite de chargement ni un FPS**.
- **Priorités** : aucun caractère spécial, MeshPart, panneau local ou effet artistique n'a autorité sur `CrossroadsSwitchyard.tryTrigger`, son cooldown, `JunctionActive`, les limites de vitesse, les warnings et les dégâts.

## Contrat de réception pour une future publication

1. Towers : 1 humain + 7 bots, terminer la chaîne de trois Skyrails sur les ponts 49-studs, distinguer les véritables ponts utilisables des effondrements/volets ; après dépense Ace, les couleurs reviennent au profil initial. Vérifier les trois qualités Android.
2. Orbital : bonus maîtrisé alors qu'aucun pulse n'est actif, puis rampe réellement chargée ; aucune fausse brillance sur les rampes inactives. Low/ReduceMotion conservent les rails serveur sans coût graphique supplémentaire.
3. Crossroads : en manche compatible, voir **uniquement** les deux véritables aiguillages actifs. Compléter Flux Master, observer l'indication localisée avant et après consommation ; rotation toutes les 9s sans faux signal. Vérifier présentation même si une arène ou un dossier se réplique en retard.
4. Source 3D absente/refusée/retirée, Low et pression GPU niveau 2 : vérifier aucun modèle, chevrons et physiques inchangés. Medium/High, cas sain : 1/2 sculptures au maximum, modèles originaux authentiques, aucune collision.
5. `Build Validation` et `Roblox Open Cloud Engine Tests` restent obligatoires **sur le SHA exact qui sera publié**. Conformément à la consigne de développement, **aucun test Build/Engine/Android n'est exécuté dans cette itération**. Cette documentation ne remplace pas une observation dans Roblox Studio ou sur Android.

**Limite :** ce lot améliore des signaux et carénages 3D source-authentiques existants ; il ne constitue pas encore une transformation visuelle AAA attestée par capture et FPS d'un vrai appareil.
