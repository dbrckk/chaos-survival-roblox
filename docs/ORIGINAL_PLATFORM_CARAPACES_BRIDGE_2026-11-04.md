# CHAOS SURVIVAL — carapaces latérales et treillis de passerelle originaux

**Candidat source 4 novembre 2026. Pas de publication Roblox publique sur ce chantier.**
Validation d'import : [workflow #41798024000](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41798024000), six créations `Model` modérées **Approved**, six sources validées OBJ → glTF (triangles réels, normales, UV, tangentes, sept matériaux).

## Assets d'auteur importés et approuvés

| Variante | Modèle original | Roblox Model ID |
|---|---|---:|
| Classic | carapace forgée, rivets et évents de décompression | `92590025262416` |
| Towers | bouclier mécanisé, attaches verticales et amortisseurs | `85204303404953` |
| Crossroads | pare-choc segmenté, cartouches et patins de frottement | `116452624086023` |
| Orbital | écrans de flux, câbles d'alliage et dissipateurs | `118444100674717` |
| Harbor | traverses de quai, tirants forgés et anti-éclaboussures | `124136394128432` |
| Passerelles | poutre latérale treillis, longeron et traverses triangulées | `122766792774607` |

Source : `tools/generate_original_platform_carapaces.py`, sortie reproductible `assets/source/chaos_<model>.obj` et glTF à l'import. Les sept matières sont des groupes industriels **et non une revendication de sept nouvelles textures 2K** ; les textures PBR raster attendent encore un audit visuel séparé.

## Intégration réelle et mécanismes protégés

- `src/server/PremiumPlatformSideAssets.lua` conserve six **ID exacts** dans une allowlist, refuse les packages non-`MeshPart` ou hors dimensions, retire les scripts avec `OriginalMeshScenery.sanitize`, ne crée ni collision ni mécanique et charge en série, en différé, après les ressources essentielles.
- `src/client/PremiumPlatformSideMeshKit.lua` authentifie la réplication avant de cloner les véritables `MeshPart`. Chaque pièce est `CanCollide/CanTouch/CanQuery=false`, `Massless=true`, `CastShadow=false` et soudée uniquement au **vrai colliseur serveur de sa plateforme**.
- `PlatformFinishKit.buildCarapace` essaye d'abord la sculpture entière de dessous de plateforme ; seulement si elle ne monte pas, l'ancien habillage `WedgePart` est construit. L'ancien ensemble de quincaillerie visuelle n'est pas ajouté par-dessus une carapace 3D authentique.
- `PlatformFinishKit.buildSideRails` peut remplacer les rails locaux rectangulaires de certaines passerelles par des **treillis réels sur les deux côtés**. Les rails d'avertissement et les portes de danger côté serveur demeurent inchangés.
- `arena-platform-identity.client.lua` réutilise son **seul propriétaire de métadonnées / visibilité `CollapsePhase`** et les fonctions existantes `bindSkybridgeFootprint` / `bindRouteFootprint` ; aucune boucle de rendu, navigation ou physique ajoutée. Les nouveaux modèles n'impliquent aucune route sûre au-delà de la surface de collision autoritaire.
- Le nouvel attribut local `LocalOriginalPlatformSideMeshPartCount` est un compteur de MeshParts authentiques effectivement montées pour les contrôles du rendu, **pas une preuve que l'affichage sur Android est correct**.

## Budget et repli

Les nouvelles carapaces complètes ne concernent qu'un sous-ensemble déterministe de plateformes disposant de dimensions compatibles, en **Medium 1/20**, **High 1/12**, **Low 0**. Une carapace contient au plus 12 parties, réellement 7 groupes de matériaux. Les gros decks incompatibles conservent les anciens habillages jusqu'à une géométrie originale dédiée.

Les treillis de passerelle sont installés sur **Medium 1/6** ou **High 1/3** des passerelles éligibles, avec respectivement 2 ou 4 modèles par passerelle. Pas de nouveau polling ; les reconstructions se font sur les événements existants (streaming, tier, modèles approuvés, changement de carte), et le propriétaire actuel suit le rétrécissement.

**Repli automatique :** un modèle absent, hors limites, incomplet ou trop coûteux n'entraîne aucune disparition de l'ancienne finition. Aucune vraie plateforme, texture de danger, collision, bot ou événement de catastrophe n'est remplacé.

## Ce qui reste à vérifier

1. Build Validation et sept suites Roblox Cloud sur le SHA exact de ce candidat avant publication.
2. Captures Android Low/Medium/High : sculpture réellement visible à bonne échelle sur les petits decks, contrôle des côtés de passerelles, pas de traversée des protections ni de faux rebords accessibles.
3. Disparition/restauration et contraction de vrais decks et de la longueur des passerelles : vérifier que les MeshParts et les soudures ne créent pas de décor fantôme.
4. Budget FPS/mémoire 8 joueurs et priorisation du premier plan : réduire la densité de meshes si nécessaire.
5. Reste à remplacer à terme : bordures non éligibles, larges plates-formes dont le rapport longueur/largeur est incompatible, éléments natifs structurels de MapBuilder, modules déco lointains, textures PBR et finitions lumineuses. Les vieux modèles simples n'ont **pas tous** été supprimés.

L'enregistrement `publication.platform_side_models_inserted_in_game=false` signifie qu'aucune preuve de publication au SHA exact n'a encore été obtenue.

## Correction révélée par les contrôles moteur

Le premier candidat exact-SHA `bc449cf934` a réussi le Build Validation mais la suite Roblox Cloud `gameplay_world` a révélé que `PlatformFinishKit` est aussi requis en contexte de test pur **sans variable globale `script`**. Le nouvel import immédiat `require(script.Parent.PremiumPlatformSideMeshKit)` provoquait `attempt to index nil with 'Parent'` (log Cloud [#41799410064](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41799410064)). Cette erreur ne doit pas être ignorée même si les 100 autres assertions du shard passaient.

**Correction source `71259d19` :** import du kit 3D uniquement si le ModuleScript possède réellement `script.Parent` ; en contexte pur sans `script`, les fonctions traditionnelles sont disponibles avec la finition native. Sur le vrai client Roblox, le kit premium est chargé et la fonctionnalité reste active. Le jalon exact-SHA doit être relancé avant publication.

La suite Roblox Cloud corrigée [#41799738841](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41799738841) a finalement réussi sur SHA `17c301be` avec sept suites. Un audit supplémentaire a ensuite isolé un possible décalage latéral des treillis si Roblox inverse les axes importés X/Z : le code `PremiumPlatformSideMeshKit.bridgeGirders` adapte maintenant **les offsets de longueur et de flanc** à l'axe réel mesuré du Model, pas seulement sa rotation (`6b8d86a9`). Ce **dernier** commit doit donc recevoir sa propre validation exact-SHA avant publication ; le test réussi sur `17c301be` n'est pas transférable au SHA suivant.

## Extension — suppression effective des primitives structurelles déjà remplacées

**Constat du 4 novembre (avant modification) :** les carapaces/sculptures étaient bien montées sur certaines vraies plateformes, mais le serveur conservait **simultanément visibles** ses quatre bordures `PlatformBevelN_1..4` en `WedgePart`, le gros caisson `PlatformUnderFrameN` et les trois travées `SkybridgeRibN_-1/0/1`. Une vraie sculpture superposée à un vieux cube ne remplit pas l'objectif visuel.

La nouvelle couche client `src/client/PlatformNativeTrimReplacementKit.lua` résout **ce cas précis** :

- Ne modifie jamais les instances serveur ; marque uniquement `LocalTransparencyModifier=1` sur les éléments structurels **non physiques** correspondant à un **véritable** `MeshPart` dont la provenance a déjà été vérifiée.
- Reconnaît exactement les indices/noms du `MapBuilder` : bordures avec attribut `OriginalStructuralBevel`, sous-frame avec `PremiumArchitecturalSurface`, et traverses inférieures de la même passerelle. Refuse toute Part qui peut entrer en collision, être touchée ou interrogée.
- Ne masque **jamais** `PlatformPanel`, `PlatformGlow`, `PlatformCoreGlow`, `SkybridgeRail` (rails lumineux servant à la lecture du trajet), shutter warnings, surfaces jouables, supports de chute, ni les signaux d'alerte de catastrophe.
- Restaure la transparence initiale lors du changement de carte, du tier, d'un import défaillant ou de la déconnexion des watchers. Reprend automatiquement les éléments `Decor` répliqués en retard.
- Expose le compteur factuel `LocalNativeStructuralPartsReplaced` dans l'interface client à côté de `LocalOriginalPlatformSideMeshPartCount`. **Zéro** signifie qu'aucune substitution source-validée n'est actuellement visible ; un ID `Approved` seul ne suffit pas.
- Ne crée aucune `Part`, aucun `RemoteEvent`, ni aucun `RenderStepped` supplémentaire.

**Correction de shrink :** les vrais treillis de passerelle doivent aussi rétrécir sur leur **axe local X ou Z importé**, et pas uniquement sur l'axe du colliseur serveur. `PremiumPlatformSideMeshKit` attribue maintenant `OriginalBridgeLongAxis` à chaque `MeshPart` du modèle. `PlatformFinishKit.applySkybridgeFootprint` réduit cet axe, et garde les positions des pièces liées au colliseur réel. Le code existant suit déjà les déplacements et les phases `Warning/Gone`.

### Périmètre réellement couvert

Cette optimisation **ne remplace pas tout le décor Roblox de base**. Elle retire du rendu client les bordures/frames/traverses **uniquement sur les plateformes où une vraie sculpture a réussi à être montée** : sélection déterministe Android, dimensions compatibles, modèle existant et validé. Les autres structures (dont les gros supports verticaux, le grand sol et les rails de signalisation) restent visibles et devront recevoir un asset dédié avant suppression.

**Validation :** Build et sept suites Roblox Cloud au SHA final de cette extension à confirmer ; source branch `main` ne vaut pas publication Roblox. Le précédent jalon `306a4e9d` avait bien réussi [build #41800472413](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41800472413) et [sept suites #41800485331](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41800485331).
