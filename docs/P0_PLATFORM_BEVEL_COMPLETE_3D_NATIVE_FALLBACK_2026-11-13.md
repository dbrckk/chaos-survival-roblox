# Chaos Survival — P0 : bordures de plateformes, remplacement 3D complet et restauration native instantanée

**13 novembre 2026** · Dépôt : `dbrckk/chaos-survival-roblox` · Branche : `main`

## Inventaire d'origine et portée réelle

Le recensement par `MapBuilder` déjà effectué sur les cinq variantes identifie **2 080 `PlatformBevel` WedgeParts** (dont **1 148** de grande dimension), **520 `PlatformUnderFrame`** et **800 `PlatformSupport`** non physiques. Ces valeurs décrivent le **stock initial dans cinq définitions de carte**, pas une scène simultanée, pas le nombre réel visible après LOD et pas le nombre définitivement non remplacé.

Le code disposait déjà de vrais modèles de créateur **Approved** pour les carapaces de plateformes : sept MeshParts par original, montés sous les vrais `PlatformN` sans toucher aux collisions. Un carapace authentique permet de masquer au plus **4 WedgeParts de bordure + 1 sous-cadre natif** sur son deck, uniquement quand le modèle a été vérifié et que le deck n'est pas en phase d'effondrement. Le plafond original reste Low **1**, Medium **8**, High **16** plateformes sélectionnées, avec d'autres familles de sculptures partageant les budgets existants.

## Défauts réparés

1. **Source 3D partiellement perdue** : `PlatformNativeTrimReplacementKit.bind()` pouvait conserver les cinq natives masquées tant qu'il subsistait **un** MeshPart d'un modèle initialement composé de sept (ou quatorze / vingt-et-un / vingt-huit pour les composites). La disparition d'un matériau pouvait donc laisser un trou 3D, sans native de secours. Dorénavant, chaque propriétaire vérifié capture le nombre total initial de MeshParts réellement soudés ; une native est masquée seulement si **tous** les éléments du modèle ont été retrouvés. Un matériau manquant restaure immédiatement **la seule plateforme concernée**. Le retour de la même source complète permet son remplacement de nouveau.
2. **Soudure détruite ou streamée** : le modèle pouvait rester dans `ApprovedOriginal3DScene` alors qu'un `ChaosPlatformTrimWeld` ou `OriginalSupportVisualWeld` disparaissait. La surveillance `DescendantRemoving` rétablit désormais la native immédiatement. Le code de révocation est idempotent avec `ChildRemoved` : une suppression simultanée d'un MeshPart et de son Weld ne décrémente jamais deux fois le même propriétaire.
3. **Réconciliation d'initialisation coûteuse** : le montage initial ne relance plus la traversée de la famille de natives après **chaque** matériau importé. Il réalise une seule passe de masquage **après** avoir analysé et autorisé toutes les pièces source authentifiées, tout en conservant une réconciliation par événement de streaming ultérieur.
4. **Emplacement 3D réservé à une plateforme incomplètement streamée** : `PremiumPlatformSideMeshKit.selectCarapaceDecks()` prend maintenant le dossier serveur `Decor` depuis `arena-platform-identity.client.lua`. Avant de réserver un slot, il vérifie la **présence effective** du `PlatformUnderFrameN` authentifié ainsi que des **quatre `PlatformBevelN_1..4` WedgeParts** ancrés, non collidants et tagués `OriginalStructuralBevel`. Une bordure manquante ou avec une provenance non valide ne peut plus consommer le précieux budget 3D ; l'owner redevient éligible dès le chargement du fallback complet.

## Recensement runtime exact, sans cadence supplémentaire

Le masque natif utilise le **même callback d'événement** existant, sans `Heartbeat`, `RenderStepped`, nouveau script ou `AssetService`. Sur le `LocalPlayer`, il expose maintenant :

| Attribut | Ce qu'il mesure |
|:--|:--|
| `LocalBevelNativePartsReplaced` | Bordures `PlatformBevelN_K` *actuellement masquées* par une sculpture approuvée |
| `LocalUnderframeNativePartsReplaced` | Sous-cadres `PlatformUnderFrameN` *actuellement masqués* |
| `LocalSupportNativePartsReplaced` | Supports `PlatformSupportN_K` *actuellement masqués* |
| `LocalOtherStructuralNativePartsReplaced` | Trusses Skybridge/Promenade/SkySpine *actuellement masqués* |
| `LocalNativeStructuralPartsReplaced` | Total de ces volumes primitifs masqués |

Ces métriques décrivent uniquement le **vrai propriétaire de carte actif et les instances natives répliquées sur ce client**. Ne pas diviser leur valeur par les 2 080 primitives présentes dans cinq variantes et qualifier le résultat de « pourcentage de remplacement AAA ». Aucune pièce serveur ou collision n'a été supprimée.

## Validation

- Régression `tools/verify_platform_trim_mesh_ownership.py` : obligation de conserver **tous les composants 7/14/21/28**, sources avec vrais Weld, restauration au premier élément manquant, rétablissement au retour, contrôle des quatre bordures et du sous-cadre, compteurs de familles et plafonds préexistants. [GitHub Actions](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43431735906) : **réussi** sur le code testé avant renforcement final du scénario.
- `tests/engine/native-premium-fallback.spec.luau` : deux scénarios complémentaires dans le **vrai moteur Roblox**. Le premier construit une vraie arène Crossroads et un `Platform2` physiquement collidable, ses quatre vrais `PlatformBevel2_1..4` et un sous-cadre ; il vérifie l'exclusion lors du streaming ou d'un mauvais attribut, puis les **cinq natives rétablies au retrait d'un seul des sept MeshParts** et lorsqu'un Weld est retiré. Le second crée quatre propriétaires distincts de modèles 3D sources de sept parties et exige la restauration **d'un seul propriétaire** sans perdre les autres, plus les comptes natifs exacts.
- La campagne Build Validation cible `945a7fc0fa134b2ac7d062e22fc9ab4e85b2a3f6`. Les [sept suites Roblox Open Cloud Engine](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43432014584) sont **toutes réussies** sur le commit de code et tests `945a7fc0fa134b2ac7d062e22fc9ab4e85b2a3f6` ; [Build Validation](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43431931031) également **réussi** sur cet exact commit. Le contrôle de propriété de source et des Welds [43431735906](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43431735906) est **réussi** sur le code précédent ; la dernière différence avant le build vert est l'ajout des assertions de moteur. Aucun test physique Android n'est affirmé.

**Limites** : cette livraison répare la sûreté de remplacement et évite le gaspillage des slots lorsque des natives manquent. Elle **n'invente aucun nouveau modèle 3D**, ne retire pas les milliers de primitives nécessaires au repli serveur, ne fournit pas de mesures FPS Android physiques et **ne publie pas le Place Roblox public**.
