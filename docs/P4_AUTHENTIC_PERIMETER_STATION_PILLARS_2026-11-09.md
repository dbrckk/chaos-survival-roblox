# P4 — vrais piliers 3D pour les stations périphériques

**9 novembre 2026 — code source, non publié.** Nouveau lot de refonte après la PR #714. La dernière publication Roblox attestée dans le dépôt est P2 (`ae4ae044e991ef4ca28a991991f2e11b9df49c84`) ; ni cette refonte P4, ni P3 ne peuvent être considérées comme livrées sur la place publique.

## Audit concret

`MapBuilder.addPerimeterStations` construit dans **chacune des cinq arènes** quatre stations `PerimeterStationNorth/East/South/West`, comportant deux énormes piliers **`LeftButtress` / `RightButtress`** encore créés comme de simples `Part` rectangulaires (1,5 × 9 × 2 studs). Ces huit blocs de premier plan sont un marqueur de style Roblox de base, visibles depuis les parcours périphériques. Le sol réel, les signalements lumineux et les autres formes conservent leurs responsabilités respectives.

La bibliothèque serveur préexistante `PremiumLargeStructureAssets` possède déjà **cinq vrais modèles verticaux sculptés 3D approuvés**, un par monde, de 13,4 à 15,1 studs de haut et de 1 à 12 `MeshPart`, d'origine créateur vérifiée :

| Arène | Modèle original approuvé (Model asset ID) |
| --- | --- |
| Classic | `91626128452597` |
| Towers | `107521411452905` |
| Crossroads | `93993697329658` |
| Orbital | `119010829781313` |
| Harbor | `76194593490199` |

Il ne s'agit **pas** de nouveaux `MeshId` fabriqués. Le client ne demande aucun asset au réseau : il clone uniquement les modèles sécurisés déjà publiés dans `ReplicatedStorage.ApprovedLargeStructureTemplates`.

## Implémentation

- `src/client/ApprovedPerimeterButtressMeshKit.lua` authentifie la provenance, l'identité par arène, les propriétés `CosmeticOnly`, les tailles et le contenu du modèle (uniquement de véritables `MeshPart`, sans scripts).
- Seules les **quatre vraies stations du monde actif** et leurs deux piliers natifs précisément identifiés sont candidates. Le modèle 3D est orienté suivant son axe horizontal le plus court et mis à l'échelle **uniformément**, dans l'enveloppe du pilier initial. Aucun nouveau collider, tremplin, mur invisible ou support de bot.
- Une station n'est substituée que si **les deux nouveaux piliers sont valides**. En cas d'asset partiel, de mauvais gabarit ou de source absente, les deux `Part` d'origine restent visibles.
- Après installation, seules les transparences des deux anciens piliers sont modifiées **localement** : `Transparency=1`. Le sol, les surfaces physiques, les signaux néon, les dangers et toutes les autres formes de la station sont conservés.
- Source/descendant/model retiré, sortie de carte, diminution de la vraie base de 320 studs, qualité faible, forte pression visuelle et streaming : restauration sûre des anciens piliers, destruction des clones et déconnexion des watchers. Aucun autre timer, Heartbeat ou RenderStepped.
- Le dossier `ApprovedPerimeterButtressesLocal` est inscrit à `VisualBudgetRules.LocalFolders`, donc chaque pièce est comptée dans le census graphique Android. `LocalApprovedPerimeterStation3DCount` et `LocalPerimeterPrimitivePillarsReplaced` remontent uniquement le nombre réel de stations installées et de piliers masqués, sans prétendre mesurer des FPS.

### Limites conservatrices

| Qualité | Stations 3D | Piliers primitifs remplacés |
| --- | ---: | ---: |
| Low | 0 | 0 |
| Medium, scène saine | 1 | 2 |
| High Android, scène saine | 2 | 4 |
| High PC, scène saine | 4 | 8 |

Une pression optionnelle de niveau 1 divise la capacité par deux (arrondi inférieur) ; niveau 2 retire toutes les substitutions. La priorité va aux stations physiquement les plus proches de la caméra, avec une petite hystérésis pour éviter le churn.

## Limites et réception ultérieure

**Ce lot est intégré en source, non testé dans Roblox Engine, non évalué sur Android et non publié.** L'absence de compilation/test de cette itération respecte la consigne de ne les exécuter qu'au jalon de publication. Les gardes d'exécution ne sont pas une preuve visuelle.

Au jalon final : contrôler les quatre stations des cinq arènes et les axes/tailles du modèle importé ; vérifier que le modèle en jeu ne traverse ni néon ni signal, qu'il reste derrière le joueur lors des catastrophes, que Low/Medium/High et les transitions de pression restaurent les piliers, que la destruction d'un des deux vrais `MeshPart` rétablit **les deux** anciens supports, que les compteurs correspondent aux vrais objets, puis mesurer FPS et mémoire Android. Les workflows Build Validation, Roblox Engine et l'upload exact-SHA restent obligatoires **avant de qualifier une version publique**.

## Prochaine famille primitive à remplacer

Les `CoreHousing` et `CompressorPodL/R` des mêmes stations utilisent encore des `Part` de base. Leur remplacement nécessitera des géométries authentiques **adaptées au gabarit** (le modèle vertical de ce lot n'est pas une coque de compresseur). Il faut conserver les petites surfaces de signalisation du gameplay et éviter de simplement poser un grand mesh incompatible.
