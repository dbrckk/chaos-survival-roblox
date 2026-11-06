# Chaos Survival V3 — Android : différencier le métal praticable de la lave

**6 novembre 2026 — correction du dépôt pour les 5 arènes, avant publication.**

## Diagnostic

Sur les captures du 5 novembre (notamment Rising Lava), la surface
principale en acier rouillé orange se confond avec la couleur de la
catastrophe **Lave montante**. Le niveau reste grand, détaillé et
jouable, mais le contraste danger/refuge est insuffisant au premier
coup d'œil. Le sol natif est notamment couvert par
`ArenaDeckInset` (source `MapBuilder.addArenaFoundation`) et, près
de la caméra, par les vrais `PremiumGroundTile` importés, UV/PBR 2K
approvés par l'auteur.

Le contrôleur de détails `ArenaCrisisSurfaceRules` tirait aussi
des couleurs de la catastrophe : pour la lave, il pouvait accentuer
en orange **des détails de sol non dangereux**.

## Correction visuelle sans changer le jeu

- `LavaGroundContrastRules` est la palette fonctionnelle du sol :
  gris-bleu acier désaturé pendant les manches comportant
  `RisingLava`, y compris fusion double catastrophe ; elle conserve
  **exactement** les couleurs originales lorsque le danger se termine.
- Uniquement les Parts **non physiques**, strictement authentifiés
  du dossier `Arena.Decor`, peuvent être retouchés localement :
  `ArenaDeckInset` et `PremiumGroundModuleN` avec les attributs
  source attendus. On ne recolore ni le vrai `Arena.Base`, ni
  `PlatformN`, ni les avertissements, ni `RoundLava`.
- L'actuel `arena-surface-detail.client.lua` a déjà un propriétaire
  de cadence et les événements de manche. Il applique ces couleurs
  **sans RenderStepped, lumière, particule ni nouvel objet**. Les
  références d'originals sont faibles et sans accumulation inter-cartes.
- `PremiumGroundMeshKit` réutilise son registre borné de vrais
  MeshParts auteur (Low 2, Medium jusqu'à 12, High jusqu'à 36 avec
  pression FPS) et restaure le Color3 original importé en fin de lave.
- Les Atlas PBR source déjà autorisés sont conservés. Pendant la
  lave, les petites îles PBR 2K près de la caméra peuvent employer
  la famille authentique **BrushedTitanium**, plus froide que
  **OxidizedSteel** ; aucun nouveau `MeshId`, aucune nouvelle
  texture, aucune modification des surfaces `SIGNAL/CARBON/GRIP`.
  Le même LOD existant gère leur remplacement et restauration.
- Le coloriste `ArenaCrisisSurfaceRules` neutralise seulement le
  biais orange de ses propres décorations dans les manches de lave.
  Les vraies surfaces de danger gardent leur palette chaude.

## Contraintes et acceptation

**Aucune modification de l'autorité du serveur** : dégâts, hauteur
de la lave, physique, sauts, navigation des bots, récompenses,
et limites de rendu Android sont inchangés.

**À valider lors du jalon de publication :**
1. `tests/engine/lava-ground-visual-contrast.spec.luau` sur cinq
   variantes avec le vrai `ArenaDeckInset`, exclusions Base/hazards,
   original couleur exacte et famille PBR préapprouvée ;
2. Roblox Engine Tests et Build Validation sur le **SHA final** ;
3. Capture Android Low/Medium/High pendant la lave pour vérifier
   visuellement l'écart couleur réelle, et le retour au matériau
   original après la manche ;
4. Contrôle FPS/mémoire à l'approche et après rechargement de carte.

Aucun test runtime, capture Android ni publication Roblox n'est
présumé réussi avant vérification explicite.
