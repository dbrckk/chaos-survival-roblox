# Storm Harbor — remplacement du cargo natif par un vrai navire 3D original

**Statut :** source d'art originale créée, Model propriétaire Roblox `128820723471019` modéré **Approved**, import [Actions #41851214739](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41851214739). **Non publié dans l'expérience publique.**

## Pourquoi

`HarborScenery.buildCargoVessel` dessinait un grand cargo de 88 studs dans `Decor/StormHarborGantryFleet/HarborCargoVessel` avec des `Part`, `WedgePart`, cubes de conteneurs, garde-corps et un radar en primitives. C'est une silhouette distante, **jamais un parcours ni une collision**. Les grands portiques et les caissons de quai sont déjà des modèles 3D originaux approuvés, source-only avec QA moteur réussie au commit `4494482`. Le cargo natif restait un défaut visuel majeur.

## Modèle fabriqué

- `tools/generate_original_harbor_freighter.py` : coque à neuf sections réellement profilées et fermées, quille, ligne de flottaison, 20 conteneurs ISO avec nervures et twistlocks, pont, passerelle, radar, ventilation, équipements de sécurité et sept matériaux.
- **172 groupes d'objets, 4 918 triangles, sept matériaux UV/normales/tangentes**, glTF 2.0 autonome. L'importeur Roblox réunit les groupes par matériau en sept MeshParts.
- Le source est volontairement à l'échelle **1:3,5** : X=29.25, Y=9.77, Z=6.4 ; la copie locale passe à `Model:ScaleTo(3.5)` avant placement sur le **vrai pont du cargo natif**. Cela reste un navire à silhouette reconnaissable, pas un skin de véhicule aérien recyclé.
- Source, glTF, métadonnées et import modéré : [workflow de génération/import](../.github/workflows/one-time-original-harbor-freighter-20261104.yml).

## Contrat runtime

- `PremiumHarborFreighterAssets.lua` importe et assainit **l'ID approuvé exact** ; exige 7 MeshParts, sans scripts, et une bounding box conforme, puis publie le template dans `ReplicatedStorage.ApprovedHarborFreighterTemplates` après 66 secondes sans bloquer le jeu.
- `HarborFreighterMeshKit.lua` accepte uniquement la vraie arène Harbor, le `HarborCargoVessel` original, le pont `MainCargoDeck` de 88 × 19, l'identité et les dimensions du Model. Le navire 3D est placé sur le pont natif avec orientation corrigée si l'import inverse X/Z.
- Les anciens composants du navire sont **conservés** : le client les masque par `Transparency` locale seulement lorsque les sept MeshParts du modèle sont présents. Cette méthode évite de contredire le contrôleur existant `SceneryLod` qui utilise `LocalTransparencyModifier`. Les pièces natives réapparaissent sur Low, au changement de carte, en l'absence de modèle ou après streaming incomplet.
- Android **Low : natif**, **Medium : un modèle dans 440 studs**, **High : un modèle dans 610 studs**. Pression 2 : repli natif. Pas de lumière, de collision, de RemoteEvent, de serveur de rendu, de tâche par frame ni de faux pont.
- `scenery-lod.client.lua` réutilise le sampler existant ; `VisualBudgetRules` comptabilise les sept MeshParts supplémentaires. Diagnostic `LocalOriginalHarborFreighterCount` : 0/1 Model monté, **pas** une preuve de rendu Android.

## Critères de sortie

1. Build Rojo et **sept suites moteur** au SHA exact.
2. Vue Android réelle de l'ensemble du port : vérifier silhouette de coque, superstructure, conteneurs, radar et eau/ciel, sans chevauchement visible avec les pièces natives.
3. Low/Medium/High, streaming entrant/sortant, pression GPU, rotation caméra : aucun navire double, disparition persistante ou fuite de transparence.
4. Navire uniquement **décoratif** et éloigné de l'arène : aucune collision, interaction, faux objectif ou modification du jeu.
5. Ne pas déclencher de publication avant captures comparatives, stabilité et contrôle FPS/mémoire.

**Cette intégration source ne vaut pas publication du jeu.**
