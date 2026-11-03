# Chaos Survival — véritables portails 3D sur les 16 bâtiments des districts

**Jalon source du 3 novembre 2026.** Priorités : VIS-011 (architecture et façades), VIS-029 (éliminer les primitives génériques visibles) et Android. **Ce jalon n'est pas encore publié ni certifié visuellement sur téléphone.**

## Situation de départ vérifiée

- Le jeu possède déjà 16 bâtiments de districts par carte, avec vrais volumes mais beaucoup de faces et entrées construites avec `Part` et `WedgePart`.
- Les portes `ServiceEntryDoor` sont des éléments architecturaux **non collisionnels**, préservés sur Low et nécessaires comme ancre stable pour l'habillage local.
- Le dépôt contient un **véritable modèle 3D original de portail industriel** `perimeter_gate` (source `assets/source/chaos_perimeter_gate.obj`, matériaux `chaos_perimeter_gate.mtl`) déjà importé dans l'inventaire du créateur Roblox et approuvé sous le Model ID **137284215564363**. Ce n'est ni un identifiant inventé ni une primitive Roblox ; le registre `assets/source/roblox-asset-registry.json` confirme son origine et sa modération.
- Le loader `OriginalMeshScenery` charge déjà ce package pour le décor extérieur. Le réutiliser évite **un second import Roblox, une nouvelle demande réseau AssetService et toute dépense payante**.
- La dernière version publique prouvée avant ce lot est `c297b2a34384d2c169e9123b2939df4d19f7386d`, publiée par [l'action #41624914108](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41624914108). Le changement de caméra-sol `f9ea994` est dans `main` mais n'a pas encore de publication confirmée.

## Intégration réelle

1. `src/server/OriginalMeshScenery.lua` : **après la même sanitisation existante**, un clone unique du portail approuvé est transmis dans `ReplicatedStorage.ApprovedDistrictGatewayTemplates`. Le modèle doit contenir uniquement des MeshParts, avoir des bornes architecturales attendues et conserver l'ID 137284215564363. Les scripts/contraintes/sons/effets sont déjà éliminés par le sanitizer d'origine. En cas de refus de modération, d'indisponibilité ou d'échec réseau, aucun clone n'est créé : l'architecture existante reste visible.
2. `src/client/DistrictGatewayMeshKit.lua` : instancie des copies **purement cosmétiques** du portail 3D à partir de ce template vérifié, précisément sur les portes de modèles `ArenaDistrictArchitecture3D` au bon propriétaire. Chaque copie est ancrée, sans collision, toucher, requête spatiale ni ombre ; aucune route réelle, bot, hauteur de saut ou pictogramme de danger n'est modifié.
3. Placement au niveau d'une entrée : géométrie centrée horizontalement sur la porte d'origine, largeur visible plafonnée à 10,8 studs, hauteur 11,8 studs, façade avancée pour éviter la coplanarité avec la porte native. Le portail n'est jamais présenté comme une entrée jouable supplémentaire.
4. Trois plafonds stricts pour le **nombre de modèles originaux montés simultanément** : **Low 1 à 112 studs**, **Medium 2 à 180 studs**, **High 4 à 245 studs**. Au maximum quatre des seize bâtiments reçoivent cette finition importée au même instant. Marges de sortie 16/22/28 studs **réservées aux modèles déjà montés**, sans élargir la distance d'entrée de nouvelles copies.
5. Priorité aux véritables entrées proches et devant la caméra. Les portails masqués derrière le regard sont déclassés, sans empêcher le portail sous le regard ou juste à côté d'apparaître.
6. Les changements de parenté et de `CFrame` d'une porte cachent la copie importée immédiatement. Le passage LOD suivant détruit les clones périmés, la reconstruction de carte vide toutes les anciennes copies. L'état natif reste intact.
7. `src/client/scenery-lod.client.lua` reste **l'unique ordonnanceur LOD** : aucune boucle `RenderStepped`, nouvelle requête réseau client, timer par modèle, ni RemoteEvent ajouté. `OriginalDistrictGatewaysLocal` est déclaré dans `VisualBudgetRules.LocalFolders` : toutes les MeshParts comptent pour la pression graphique et ne peuvent pas échapper au suivi adaptatif.

## Limites assumées

Il s'agit d'un **premier remplacement réel du rendu des portails**, sans prétendre que les 16 bâtiments disposent déjà de façades MeshPart uniques ou que les onze catastrophes sont photoréalistes. Le reste des volumes natifs de bâtiments existe toujours. Cette version reprend un portail *authentique, original et préapprouvé*, avec ses formes et matériaux originaux ; elle ne crée pas frauduleusement de nouveaux IDs de texture ou de géométrie.

Le résultat final perceptif doit être contrôlé dans Roblox Studio (orientation originale du package, ouverture centrale du portail, alignement avec la porte et zone de sécurité) et **sur Android natif**.

## Livraison et validation finale

Avant toute publication publique du nouvel exact SHA :
- compilation de l'intégralité des scripts Luau et build Rojo complet ;
- exécution de l'audit global du budget Android et des cinq suites moteur Roblox Cloud, sur **ce même SHA** ;
- vérification de la présence effective du template `ApprovedDistrictGatewayTemplates.OriginalDistrictGate` côté serveur/client ;
- vérification réelle de l'orientation et de l'absence de blocage du guidage et des dangers sur les cinq arènes et les quatre secteurs ;
- déplacement / caméra 180° / entrée-sortie portée / StreamingEnabled / shrink / changement d'arène ;
- captures Android Low/Medium/High avec nombre de modèles `LocalOriginalGatewayMeshCount`, FPS, temps de frame et mémoire, sans prétendre que les compteurs prédisent le rendu ;
- publication avec le workflow public existant **uniquement après succès**. Aucun déploiement n'est attesté par la présente documentation.

**Pas de nouveaux tests unitaires** pendant cette phase d'amélioration ; les suites d'intégration existantes sont réservées au jalon de publication.
