# CHAOS SURVIVAL — Direction artistique premium (version 1.0)

> **Statut : direction visuelle ciblée, non certification AAA.**
> Une compilation ou un test d'unité ne suffit pas à prouver qu'un rendu est « AAA ». La revue en jeu, les captures et les performances Android sont obligatoires.

## Proposition créative : « Chaos Signal »

Un monde de compétition techno-industrielle construit sur des infrastructures dangereuses, mais conçu pour être **compris en mouvement**. Une hiérarchie visuelle en trois temps : **lieu iconique → danger immédiat → récompense**. Le spectacle attire, la lisibilité permet de survivre.

**Signature globale :** métal profond mat, plans de silhouette lisibles, cadres techniques, détails mécaniques structurés, un accent lumineux dominant, une source lumineuse motivée, des animations de machine à rythme propre. Pas de « cube néon au hasard ».

### Palette, matériaux et éclairage

| Élément | Traitement |
| --- | --- |
| Corps | `VisualTheme.World.Deep/Surface/Metal` : masses foncées et mates ; variations de roughness par matériau |
| Cadres | `MetalLight`, `DiamondPlate` pour jonctions, nervures et pièces soumises à l'effort |
| Accents | UNE couleur dominante par zone + une couleur secondaire ; le néon ne doit pas dominer la superficie |
| Signaux | Les couleurs de dangers restent prioritaires sur les décorations ; distinguer aussi par forme/icône/animation |
| Lumière | L'éclairage doit sembler issu du radar, d'un moteur, d'un panneau ou d'un impact, pas de lumières gratuites |
| Atmosphère | Premier plan net, milieu structurel, horizon lisible, fond plus froid ou atténué ; éviter le voile uniforme |
| UI | `UITheme` reste maître des tokens, des contraintes de texte, des panneaux et des tailles tactiles |
| Accessibilité | Réduire mouvement/pulsations et contrastes agressifs sans masquer le danger |

Éviter le scintillement, les surfaces réfléchissantes partout, les post-process agressifs pendant le ROUND et les surcharges de particules. Aucun clignotement rapide sur les warnings critiques.

### Identité de chaque arène

| Arène | Silhouette en 2 secondes | Palette | Mouvement signature | Détail historique |
| --- | --- | --- | --- | --- |
| Classic | Halo de radar / mât, contreventements | Bleu signal + acier | Balayage horizontal lent | Réseau de détection |
| Towers | Rails verticaux, cage de service / contrepoids | Cyan technique + bleu | Cabine en va-et-vient | Infrastructure de manutention |
| Crossroads | Portique, flèches segmentées, feux | Violet transit + magenta | Pulse directionnel alternatif | Réseau de circulation |
| Orbital | Gyroscope suspendu et quatre pylônes | Menthe plasma + bleu | Rotation opposée des anneaux | Confinement énergétique |

**Règle de composition :** un héros fort par arène, un motif secondaire répétable, une zone de repos visuel et des volumes proches/éloignés. De nouvelles surfaces peuvent être ajoutées seulement si leur silhouette ou leur narration est distincte.

### Architecture obligatoire pour un « hero prop »

1. **Macro-silhouette :** reconnaissable à distance sans couleur.
2. **Structure :** la charge ou la fonction est crédible (supports, jointures, rail, motorisation).
3. **Sous-formes :** 2–4 groupes de détails de taille moyenne ; pas de bruit uniforme.
4. **Finition :** panneaux, gravures, numéros, finitions métalliques qui donnent de l'échelle.
5. **Vie :** mouvement identifiable mais lent et contrôlé ; une animation unique plutôt que tout faire tourner.
6. **Feedback :** variations motivées par le contexte ou la phase, sans masquer les avertissements.
7. **Performance :** pièces ancrées, non collidentes, jamais créées en continu ; nettoyage assuré entre les cartes.
8. **Preuve :** captures Low/Medium/High en mouvement et mesures sur Android.

### Motion et VFX : règles de signature

- **Anticipation → apparition → impact → décroissance**, avec durées bornées et easing cohérent.
- La forme doit indiquer le type de catastrophe avant que la couleur ne soit discernable.
- Les effets de réaction restent strictement cosmétiques ; jamais de modification client de dégâts, vitesses ou collisions.
- Aucun effet décoratif permanent n'est créé par événement répété ; utiliser Debris et plafonds simultanés.
- Une animation **Reduce Motion** doit revenir à une pose fixe intentionnelle, pas à un objet qui disparaît sans raison.
- À faible qualité, réduire segments, lumière et densité, mais préserver le héros et les indications vitales.

### UX et interface

- Un écran = un objectif visuel dominant : **Voter / Se préparer / Survivre / Observer / Rejouer**.
- Sur Android, pas de texte coupé, d'interaction cachée derrière les Settings, ni de boutons critiques trop petits.
- Le HUD de survie doit primer sur le décor ; les zones dangereuses ne peuvent être noyées dans les néons.
- Vignettes d'achievements et rewards doivent partager les mêmes tokens, mais avoir des formes et rythmes distincts.

### Pipeline d'assets authentiquement premium (futur)

Les primitives Roblox servent au prototype et au LOD, mais une qualité art de très haut niveau peut nécessiter :
- `MeshPart` optimisés avec UV et textures originales ou sous licence explicite ;
- `SurfaceAppearance` et normal maps maîtrisées ;
- motifs/decals propres au jeu ;
- animations d'avatar vérifiées sur R6 et R15 ;
- sons synchronisés sous licence ;
- revue des assets et de la mémoire mobile.

**Ne jamais inventer un AssetId Roblox, importer un élément sans droits, ou remplacer aveuglément une géométrie de collision.** Les assets doivent être documentés avec licence, auteur, provenance, LOD, budget et contrôles de sécurité.

### Définition de « terminé »

Une fonctionnalité visuelle est acceptée uniquement avec :
- tests moteur ciblés au vert + build exact SHA ;
- inspection des quatre arènes et de toutes les phases pertinentes en Studio ;
- captures côte à côte High / Medium / Low ;
- tests Android réels (fluidité, lisibilité, thermiques, tactile) ;
- vérification Reduce Motion, pas de fuite de pièces ni doublon après changements de cartes ;
- revue artistique indépendante du développeur du module.

La note visuelle doit être une **évaluation d'un rendu observé**, jamais une promesse issue du nombre de lignes de code.
