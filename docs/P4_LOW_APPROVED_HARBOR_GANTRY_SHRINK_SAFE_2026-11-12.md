# P4 — Une grue Harbor authentique près de la caméra sur Android Low

**12 novembre 2026. Source GitHub uniquement ; ni FPS Android réels ni publication Roblox revendiqués.**

## Audit de la scène et du propriétaire existant

Harbor possède quatre grandes grues originales extérieures, d'environ **44 × 22 × 36 studs**, actuellement composées de nombreux `Parts` natifs. Deux modèles créateur **Approved** sont déjà disponibles :
- `75684193304551` — `ContainerGantry` ;
- `98809955094422` — `CableGantry`.

Chaque modèle contient **sept MeshParts originaux** : quatre structures statiques et trois composants séparés `Trolley`, `Cable`, `Load`. Le serveur `PremiumHarborGantryAssets.lua` vérifie les dimensions, la géométrie, les rôles et l'absence de scripts. Le client `HarborGantryKineticMeshKit.lua` réutilise ces sources, non physiques et déjà recensées dans le dossier `OriginalHarborKineticGantryLocal`.

### Défauts identifiés

1. `BUDGET.Low.models=0` désactivait complètement ces sculptures sur Android Low. Les modèles natifs des quatre grues étaient également éliminés par le LOD Harbor sur ce profil : leur architecture monumentale était absente.
2. En Medium et High, le kit exigeait `Base.Size.X/Z >=318` même après le rétrécissement normal du sol de survie. Les grues extérieures, **qui ne bougent pas avec le bord de l'arène**, disparaissaient donc inutilement lorsque le sol se réduisait.
3. Un modèle facultatif évincé par le gestionnaire de budget ou amputé d'une MeshPart pouvait rester affiché partiellement jusqu'à l'échantillon caméra suivant, avec les natives masquées.

## Correctifs implémentés

- **Android Low : une seule grue originale de sept MeshParts** lorsque la caméra se trouve à **135 studs maximum** du `MainCrossgirder` sur Harbor, avec rétention de **18 studs** pour une sculpture déjà montée. Source complète, provenance exacte, secteur North/South correspondant, rôles statiques/dynamiques obligatoires et collisions désactivées.
- **La grue 3D Low reste volontairement statique** : `HarborGantryMotionRules.profile(Low)` conserve `Count=0` et `Range=0`. Aucune nouvelle animation, `RenderStepped`, `Heartbeat`, recherche réseau ni calcul physique. Sur Medium et High, l'animation native des trolleys, câbles et charges reste inchangée.
- **Pression graphique Low 1 ou 2** : `maxModels=0`, le modèle local est supprimé et le propriétaire natif est restauré suivant les règles de visibilité LOD. Medium conserve ses plafonds 2/1/0 et High 4/2/0 sous pression 0/1/2.
- Un seul prédicat `authenticBase` vérifie maintenant les valeurs immuables `OriginalSizeX` et `OriginalSizeZ` du vrai `Base` serveur : la réduction temporaire du sol n'invalide plus les grandes grues extérieures. La scène doit rester l'arène réelle et la base physique doit exister.
- `OriginalHarborKineticGantryLocal.ChildRemoved` et les événements `AncestryChanged`/`DescendantRemoving` des sources et MeshParts déclenchent un `unmount` immédiat. Le montage est retiré du registre **avant** la destruction et la restauration des natives pour empêcher les callbacks récursifs.
- Les entrées obsolètes sont évincées **après** le parcours des modèles, au lieu de modifier la table `mounted` pendant son itération.
- Les quatre vraies grues serveur, les sols, collisions, hazards, joueurs, bots et signaux de livraison ne sont pas modifiés. Aucune source, lumière, texture ou faux plancher ajouté.

## Contrôles et recette Roblox Engine

Le nouveau `tools/verify_harbor_kinetic_low_and_shrink.py` et son workflow vérifient la provenance et la géométrie à sept MeshParts, le plafond Low, le profil moteur statique, les dimensions initiales, la politique de pression, le nettoyage de streaming et la propriété du budget Android. `tools/verify_original_3d_budget_census.py` est également enrichi.

**Tests à exécuter en jeu :**
- Sur Harbor, Low sans pression, s'approcher d'une grue à moins de 135 studs : vérifier une sculpture authentique complète de sept MeshParts, sans deuxième grue 3D active.
- Sous pression 1 ou 2, ou source absente : le clone doit disparaître ; le LOD natif conserve son droit de masquer la grue sur Low. Aucun bras/charge de grue ne doit devenir un collider.
- Sur Medium/High, comparer l'animation trolley/charge avant et après, puis rétrécir l'arène à 200 et 120 studs : les grues dans leur zone de caméra doivent rester disponibles grâce aux dimensions initiales.
- Retirer une source, une MeshPart clonée ou le dossier de modèle ; vérifier la restauration native immédiate et l'absence de boucle de démontage.
- Tester StreamingEnabled, changement d'arène, mouvement réduit, FPS/p95, mémoire et charge graphique cumulée sur un Android Low réel.

Les contrôles GitHub restent des **régressions de source**, pas des essais visuels dans Roblox Engine. La publication publique n'est pas effectuée par cette PR.
