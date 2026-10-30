# Chaos Survival — arènes 3D : identités architecturales (30 octobre 2026)

## Intervention

Cette passe agit sur les **modèles 3D originaux déjà construits et streamés**, sans changer les chemins de saut, les collisions ni le fonctionnement du serveur de manche.

### 16 bâtiments par arène (fichier `src/server/ArenaDistrictArchitecture.lua`)

- **Classic Grid** : cadran radar métallique orienté et boîtier de réception au sommet de l'observatoire, en conservant l'ancien capteur et la pointe parafoudre (+2 pièces par bâtiment).
- **Tower Run** : rails de manutention épais et deux boîtiers de treuil, en plus des cabines suspendues existantes (+3 pièces).
- **Crossroads** : modules d'aiguillage inclinés et panneau de commutation de façade, sans signal lumineux trompeur (+3 pièces).
- **Orbital Ring** : protections en céramique de chaque côté du réacteur et collecteur supérieur (+3 pièces).
- **Storm Harbor** : remplacement de l'ancienne signature « observatoire Classic » par une petite grue de dock à cabine et cargaison suspendue (+2 pièces nettes).

Les 16 structures continuent d'avoir des volumes et profils de toit variés, des quatre couleurs de secteurs, des emplacements intérieurs existants et `ModelStreamingMode.Atomic`. Les nouvelles pièces sont entièrement immobiles, sans collision, sans ombre, sans toucher, sans requête spatiale ni nouveau `Script`. Le code existant de LOD par bâtiment masque automatiquement le décor distant suivant le niveau graphique Android.

### Grands monuments (fichier `src/server/HeroArchitecture.lua`)

- Classic : deux jambes de fixation de l'antenne et une traversée de girouette (+3 pièces).
- Towers : guidage structurel des deux cabines et finitions de la poutre supérieure (+4 pièces).
- Crossroads : sélecteur supérieur avec deux dérives industrielles (+3 pièces).
- Orbital : deux carters latéraux de stabilisation (+2 pièces).

Le **plafond existant de 32 pièces par monument** et la sélection explicite des formes indispensables en mode graphique Low restent en place. Storm Harbor conserve le gros cargo déjà enrichi et ses grues extérieures.

## Matériaux / performance

Aucun nouveau chargement réseau, ID Roblox, surface 2K, effet, physique, RenderStepped ou boucle client. Les surfaces métalliques/composites utilisent les matériaux Roblox existants. Les **16 images PBR 2K approuvées**, leur allocation locale par caméra et le plafond global par niveau Android restent inchangés. Les nouvelles pièces décoratives sont simplement candidates selon les règles préexistantes de sélection et priorité ; cela ne certifie pas leur affichage PBR sur chaque téléphone.

## Limites de validation

Conformément au workflow du projet, aucun test n'est déclenché au cours de cette passe d'amélioration. Avant une publication publique, passer les validations complètes exact-SHA Build Validation et Roblox Open Cloud, puis contrôler sur un vrai Android : présence des cinq signatures, silhouettes à distance, artéfacts de streaming, hauteur et occlusion, fluidité FPS/P95, contraste de danger et compatibilité qualité Low / Medium / High. Le code livré sur GitHub n'est **pas** une publication Roblox.
