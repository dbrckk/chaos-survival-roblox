# CHAOS SURVIVAL — structures de parcours 3D d'origine : passerelles panoramiques + restauration de la publication

**3 novembre 2026 — lot visuel n°2, premières structures de gameplay à forte visibilité.**

## Incident réel du lot précédent, rectifié

`main` `a2812144095e73c3b0bb70ccc8601e7972fe5b26` a réussi le [Build Validation #41639154856](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41639154856), mais le [Roblox engine #41639166067](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41639166067) a échoué avec **353 tests réussis et 1 échec** ; l'[automate de publication #41639140940](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41639140940) a alors correctement refusé de publier. Cause précise : le nouveau `VisualTheme.Arenas.Towers.PanelMaterial = Enum.Material.Metal` était attendu comme ancien `Enum.Material.Foil` dans `tests/engine/mapbuilder.spec.luau`. Le contrat de rendu a été mis à jour vers la **nouvelle valeur réelle** sans ramener le chrome `Foil` ni supprimer la vérification d'unicité des cinq matières. **Public confirmé précédent :** `e488dc939b665dc32bed70d771b00ddfb8910d2c` ([publication #41637010286](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41637010286)).

## Nouveau passage des primitives 3D aux véritables meshes approuvés

Les packages propriétaires approuvés par Roblox existent **déjà** et sont chargés de manière sécurisée par `PremiumRouteMeshAssets`, via un seul serveur : `premium_jump_deck` Model **98478693994864**, `premium_skybridge_module` Model **94023662427980**. Chaque package original est un vrai ensemble triangulé **MeshParts/UV/tangentes**. Rien n'est inventé ni téléchargé par le client.

### Défaut confirmé en code

Le kit `PremiumRouteMeshKit` habillait les plateformes ordinaires et les quatre ponts gated `SkybridgeN` de Towers, mais **ignorait les deux véritables passerelles panoramiques de 8 paliers chacune et les dix marches permanentes Sky Spine** des **cinq** arènes. Elles restaient physiquement de simples `Part`/native materials sans les MeshParts de pont pourtant disponibles. Ses quotas 3D pouvaient également être épuisés à afficher des plateformes *derrière* le joueur pendant que le prochain saut visible conservait une apparence native.

### Nouveau comportement

- Réutilise désormais les **vrais modèles de pont 3D** sur les **26 paliers physiques permanents** du grand réseau de promenade + Sky Spine de chaque arène, parmi les autres routes ; **26 éligibles** ne signifie pas 26 modèles actifs à la fois.
- Attestation stricte des `PlatformN` par **`ChaosPermanentRoute`** ET soit `PromenadeLane=1..2 / PromenadeStep=1..8`, soit `SkySpineInterchange=true / SkySpineStep=1..10` ; `ChaosSkybridge` sur les vrais `SkybridgeN` reste indépendant, sans reclasser les passerelles en ponts gated ni toucher aux systèmes de pression.
- **Sélection dirigée vers le saut réellement visible** à partir du `cameraLook` déjà connu du système LOD. Les vraies plateformes à moins de 48 studs sont prioritaires quelle que soit l'orientation ; la résidence existante conserve son hystérésis. Aucun nouveau RenderStepped ni échantillonneur.
- **Quotas actuels inchangés** : Low jusqu'à **2 pontons + 1 module de pont**, Medium **5 pontons + 3 modules pour 1 pont**, High **9 pontons + 5 modules pour chacun de 2 ponts**. Le même `PremiumRouteMeshLocal` est déjà inclus dans les plafonds adaptatifs des clients Android.
- Tout reste **cosmétique** : aucun nouveau chemin fictif, pas de collision/touch/query sur les MeshParts, ni mouvement d'un vrai `PlatformN`. Les vraies colliders et la mécanique de saut, les codes de danger et les éléments natifs de secours continuent à fonctionner. En cas de `CollapsePhase`, `BridgeShutterPhase`, `CanCollide=false`, changement de taille/retour d'arène et rétrécissement sous 318 studs, le kit retire ou masque les meshes et restaure le revêtement de secours.
- Une vérification moteur EXISTANTE a été prolongée au **jalon de sortie** pour établir l'habillage des vrais paliers permanents, le changement Promenade→Sky Spine, le rejet d'une fausse passerelle sans `ChaosPermanentRoute`, et l'absence de changement de collision. Un garde CI statique bloque une dérive de contrat de matériaux ou de MeshParts/quotas.

## Ce qui reste réellement incomplet

Le kit ne remplace pas encore **toutes** les sous-faces mécaniques, grues, consoles, colonnes et architecture du lobby par des modèles importés spécifiques. Les MeshParts utilisés sur la promenade et le Sky Spine réemploient la même famille géométrique plutôt que 26 nouvelles formes indépendantes ; la variété visuelle AAA exige encore plusieurs nouveaux ensembles d'assets originaux. Les textures de ces MeshParts sont celles des modèles approuvés, pas de nouveaux PBR 2K artificiellement inventés.

La réussite de CI et des tests Roblox **ne prouve pas** le rendu final : vérifier les cinq cartes sur Android, au moins Low/Medium/High, les ponts dangereux et les routes en shrink, l'absence de panneau surnuméraire, le montage et la modération des vrais MeshParts, les FPS et la mémoire.

## Conditions de publication

Ne déclarer le lot public qu'après **Build Validation + cinq suites moteur Roblox réelles + workflow `Publish Existing Chaos Survival (Public Playtest Update)` réussis** sur le SHA exact de cette fusion, pour le même Universe `10771083668` et Place `95351659174730`. Pas de place privée, d'assets non approuvés ni de fausse validation Android.
