# P4 — véritables murs latéraux et noyaux structuraux 3D, source et import sécurisé

**12 novembre 2026** — source 3D originale produite, prête pour import sous le propriétaire Roblox ; **ne pas annoncer le modèle comme approuvé ou présent dans l'expérience avant résultat officiel**.

## Problème confirmé dans le dépôt

Chaque `ArenaDistrictArchitecture` fabrique 16 bâtiments cosmétiques par arène. Les **quatre profils 3D déjà approuvés** remplacent l'avant et le toit, mais laissent cinq pièces volumétriques Roblox de base :
`ServiceCore`, `ArmoredSupportL/R` et `SideCassette-1/1`. Les retirer sans géométrie de substitution créerait des trous, aussi la PR #865 s'est volontairement limitée à améliorer leurs finitions PBR.

## Véritable géométrie générée

`tools/generate_original_district_sidewall_shell.py` produit un **OBJ triangulé original** intitulé `chaos_district_sidewall_shell.obj`, puis le convertisseur standard `tools/obj_to_gltf.py` fournit un vrai **glTF 2.0** comportant `POSITION`, `NORMAL`, `TEXCOORD_0` et `TANGENT` pour chaque groupe de matière.

Ce n'est pas une collection de `Part`, un texte d'intention ou un `MeshId` inventé. Le maillage inclut :
- un noyau fermé biseauté avec bride de pied, bonnet de protection et panneaux forgés ;
- deux pilastres de grande hauteur (dimensions et positions natives exactes) avec colliers et vrais pieds au sol ;
- deux cassettes latérales volumétriques à sections chanfreinées, leurs joints, rails et contreventements ;
- des lucarnes latérales **laissées visibles** (étanchéité aux extrémités et sous/au-dessus des vitrages existants) ;
- des grilles de ventilation et de vrais renforts de paroi arrière avec ailettes, tirants et finition métal/céramique.

Le gabarit est **commun aux quatre profils** Observatory, Freight, Turbine et Aerial. Aucun nouveau shader spécial ni énorme collection de modèles distincts n'est nécessaire. Il emploie les **familles de matériaux métalliques approuvées déjà utilisées** dans `chaos_route_kit.mtl`, avec répartition UV et tangentes.

### Compatibilité spatiale exacte

Le maillage a son sol à `y=0` et utilise les positions **du serveur existant**. La porte est à `z=-4.36`, le noyau de remplacement commence à `z=-3.4`. Les surfaces de verre latérales natives s'étendent autour de `x=±4.22` : le nouveau panneau latéral ne dépasse pas `x=±4.105`. Aucun masque n'est ajouté sur les fenêtres, les vitres, la porte d'entrée, les panneaux de navigation ou les fondations de la structure.

Les surfaces sont visuelles et destinées à être non-collisionnelles en runtime ; la représentation et les paramètres de gameplay actuels restent autoritaires.

### Validation CI

`.github/workflows/p4-original-district-sidewall-source-gate.yml` :
- génère l'OBJ, convertit en glTF sans réseau ni import Roblox ;
- inspecte les véritables triangles, les enveloppes de la forme, les six groupes de matériau, le code d'origine et les buffers ;
- confirme la présence des attributs PBR/tangentiels, les coordonnées du sol, les dimensions et l'absence d'obstacle devant la porte ;
- conserve l'OBJ, le glTF et les métriques en artefact GitHub Actions.

Ce contrôle source **n'est pas un rendu Studio, une preuve de modération ou un benchmark FPS Android**.

## Import officiel — étape réservée au résultat réel

`.github/workflows/upload-original-3d-models.yml` accepte désormais uniquement la source déterministe `district_sidewall_shell`, sous le même validateur que les anciens modèles. La commande ne passe jamais d'OBJ venant d'un utilisateur et n'expose aucune clé. Le workflow ponctuel `one-time-import-district-sidewall-shell-20261112.yml` demande **un seul upload** propriétaire créateur `user:9774173158`, une fois lors de l'ajout du workflow sur `main`. Aucune place Roblox n'est mise à jour par cet import.

**Étape suivante conditionnelle (ne pas anticiper)** : recueillir dans GitHub Actions l'ID officiel du nouveau modèle **et** le statut de modération `Approved`. Alors seulement :
1. enregistrer cet ID réel dans `assets/source/roblox-asset-registry.json` avec la preuve du workflow ;
2. ajouter un loader serveur `PremiumDistrictSidewallAssets`, avec `GlobalApprovedImportGate.load`, assainissement `OriginalMeshScenery.sanitize` et vérification de l'enveloppe et du nombre de vrais MeshParts ;
3. ajouter un propriétaire client sur le **passage LOD déjà existant**, avec des budgets source contrôlés Low/Medium/High et caches sous le compteur visuel global ;
4. masquer les cinq Parts natives **uniquement après le montage, l'alignement, l'intégrité et la visibilité** du nouveau modèle, restaurer immédiatement en cas de perte de source/streaming/LOD/pression ;
5. qualifier le rendu et les performances réels sur Roblox Studio / Android, puis publier à l'aide du workflow de release existant.

**Règle** : ne pas modifier de Place ni annoncer une réduction d'un nombre de primitives en jeu avant l'intégration et le test moteur. Source originale et import approuvé sont deux étapes distinctes.
