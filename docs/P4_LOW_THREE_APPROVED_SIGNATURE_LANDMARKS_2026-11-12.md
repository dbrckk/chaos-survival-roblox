# P4 — Trois signatures monumentales authentiques sur Android Low

**12 novembre 2026 — mise à jour du code source GitHub, pas de publication Roblox.**

## Structures primitives encore visibles

L'inspection de `ArenaSignatureMegastructure` et de ses trois clients
montrait trois pièces maîtresses déjà créées par le serveur, mais encore
affichées en formes `Part`/`WedgePart` sur Android Low alors que
les véritables modèles créateur approuvés étaient utilisés sur Medium/High.

| Arène active | Modèle original approuvé | Géométrie d'origine masquée après montage |
| --- | --- | --- |
| Classic | Double observatoire + récepteurs paraboliques — asset `112493873850364` | 7 primitives |
| Towers | Grand pont de service forgé — asset `126298311664881` | 2 énormes dalles |
| Harbor | Grand portique de grue/cabine/contrepoids — asset `124368710235343` | 3 gros blocs |

**Chaque modèle se compose d'exactement sept vrais MeshParts**, vérifiés
par `OwnerVerified`, `Original3DAssetId`, `CosmeticOnly`,
flag source propre à l'arène, dimensions et géométrie. Aucun
AssetService supplémentaire n'est lancé par les clients.

## Changement effectif

- Les trois kits conservent **`Medium=1`, `High=1`** et passent à
  **`Low=1`** avec un rayon d'affichage de **290 studs** autour de
  l'emplacement réel de la signature distante et une rétention
  préexistante de 24/26 studs.
- Sur Android Low, **seul un original de sept MeshParts**
  peut remplacer sa famille visuelle sur la carte courante.
  Les arènes Classic, Towers et Harbor ne sont jamais actives
  en même temps dans le même `Arena` de gameplay.
  Ce sont trois kits distincts déjà hébergés et référencés
  par `scenery-lod.client.lua`, sans nouveau pass caméra.
- `OptionalVfxPressure >= 1` : l'asset Low est démonté, les
  primitives natives exactes sont restaurées immédiatement.
  Medium et High conservent leurs limites et leur comportement
  sous pression antérieurs.
- Le code de montage existant reste atomique : il attend un
  `ArenaSignatureMegastructure` complet, vérifie les positions
  réelles et les compagnons, clone/ajuste le modèle approuvé,
  puis masque uniquement les pièces natives correspondantes
  **après** réussite. Streaming, disparition d'une MeshPart ou
  changement de base restaurent leurs silhouettes de repli.
- Le grand pont Towers ne masque pas `HangingSignal`,
  les deux vraies tours ou les rails de jeu ; la grue Harbor
  conserve ses jambes, treuils, charges et antenne ; Classic
  conserve les contreforts et la signalétique de service.
- Ces trois dossiers locaux sont **déjà recensés** dans
  `VisualBudgetRules.LocalFolders`, donc les modèles restent
  soumis aux limites globales d'instances et à la pression Android.
- Aucun nouveau collider, danger, source asset, texture PBR,
  lampe, requête réseau, simulation ou boucle `RenderStepped`.

## Vérifications de réception moteur

1. Dans chacune des arènes et sur un Android Low en pression 0,
   placer la caméra à moins de 290 studs de la signature.
   Contrôler au plus **un Model original de sept MeshParts**,
   sa géométrie et l'absence de double superposition native.
2. Compter les morceaux natifs remplacés via les attributs client :
   `LocalClassicSignaturePrimitivePartsReplaced` = 7,
   `LocalTowersSignaturePrimitiveSlabsReplaced` = 2,
   `LocalHarborSignaturePrimitiveBlocksReplaced` = 3,
   lorsque le montage est réellement réussi.
3. Forcer le niveau de pression facultatif 1 puis 2 :
   vérifier le démontage du modèle et la restauration native.
4. Modifier la source `Approved...` et simuler une réplication
   partielle : aucun masquage tant que provenance, taille et
   source d'origine sont invalides. Les colliders/joueurs
   restent inchangés.
5. Mesurer les FPS, mémoire, p95 et qualité de rendu sur un
   vrai smartphone Android Low avant une publication Roblox.

La vérification `tools/verify_original_3d_budget_census.py` contrôle
statiquement les trois limites Low, les asset IDs, le nombre de
MeshParts et la politique de repli. **Cela ne constitue pas
une mesure de FPS ni un test Roblox Engine.**
