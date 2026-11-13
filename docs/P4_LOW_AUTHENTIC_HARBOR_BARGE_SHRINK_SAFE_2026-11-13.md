# P4 — Barge portuaire sculptée sur Android Low, résistante au Shrinking Arena

**13 novembre 2026 — modification source sur `main`.** Il s'agit d'un changement de code, **pas d'une preuve de publication ni d'une capture Android**. La dernière version publique vérifiée précédant ce lot a été publiée par le workflow GitHub Actions [43327970065](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43327970065), sur `8df38f97`.

## Défaut identifié dans les sources réelles

`src/client/arena-midground-mass.client.lua` crée **deux barges natives sur Low**, trois sur Medium et quatre sur High dans Storm Harbor. Le modèle original `CoastalFreightBarge`, asset approuvé `132891280963772`, existe déjà : **7 MeshParts / 3 718 triangles**. Néanmoins `HarborMidgroundBargeMeshKit.BUDGET.Low.models = 0` interdisait tout remplacement 3D Low : le premier plan maritime conservait obligatoirement ses coques et conteneurs rectangulaires. La source était aussi rejetée si `base.Size.X/Z < 318`, dès que la véritable arène de survie rétrécissait, alors que les barges situées hors arène ne rétrécissent pas.

## Correctif intégré

- **Low sain :** au plus **une barge approuvée / 7 MeshParts / 3 718 triangles** parmi les deux barges déjà présentes, à **145 studs** de la caméra, avec **18 studs d'hystérésis**. La sélection conserve la caméra, la vérification de source et le sampler LOD existants. Pas de nouvelle construction native ni de nouvel asset Roblox.
- **Low sous pression :** `OptionalVfxPressure >= 1` ramène immédiatement le quota à zéro. Les anciennes coques et conteneurs natives reviennent ; Medium reste à 2/1/0 et High à 4/2/0 modèles pour pression 0/1/2 respectivement.
- **Shrinking Arena :** authentification par `OriginalSizeX` et `OriginalSizeZ` signés à la création de la `Base` serveur (dimensions initiales >=318). Le plancher doit toujours être ancré, collidable, enfant de l'arène courante, non agrandi au-delà de l'original et de taille positive. Le rétrécissement normal ne fait plus disparaître les barges sculptées.
- **Résidence stricte :** vérification de la parenté du modèle source approuvé, de l'ID exact, de la légitimité de la barge, et de la présence des 7 MeshParts par `IsDescendantOf`, y compris si l'import Roblox comporte des sous-modèles. La perte de la source/piece rétablit la décoration native selon la logique existante.
- **Sécurité :** toutes les pièces sont ancrées, non physiques, non queryable, sans ombre ; aucune collision, trajectoire, spawn, danger, sonar, VFX ou état réseau modifié. Les 7 MeshParts sont déjà recensées dans `VisualBudgetRules.LocalFolders`, contre le même budget mobile partagé de 440/680/900 Parts.

## Critères de vérification avant publication

1. Dans Roblox Engine avec qualité Low et Harbor, approcher une barge à moins de 145 studs : `LocalOriginalHarborBargeCount == 1`, sept véritables MeshParts visibles et géométrie native de cette barge masquée uniquement après montage.
2. Rétrécir `Base` sous 318 studs : la même barge 3D reste visible. Sous pression 1 ou 2 : `LocalOriginalHarborBargeCount == 0`, natives restaurées sans collider fantôme. Revenir à pression zéro : réinstallation possible si le modèle est disponible.
3. Simuler streaming incomplet, source non approuvée et changement d'arène : aucune géométrie trompeuse ou permanente, aucun script chargé depuis l'asset.
4. Sur Android Low réel, mesurer FPS moyens/p95, mémoire, vitesse d'arrivée et qualité de silhouette en première manche et sous stress. Une réussite de la CI **ne suffit pas** à certifier le rendu premium.

**Statut :** changement de code intégré ; validations moteur, rendu Android et publication de ce nouveau commit à confirmer séparément.
