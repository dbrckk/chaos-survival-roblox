# P4 — Chargement anticipé des structures-signatures 3D

**Date :** 10 novembre 2026. Objectif : améliorer l'apparition des grandes
sculptures réellement approuvées dans l'arène actuellement affichée, sans
lancer les importations de toutes les arènes en même temps.

Avant : les quatre sources ci-dessous attendent un délai fixe même lorsque
leur variante est la première jouée. Elles sont toutes des assets Roblox
propriétaire déjà modérés **Approved**. Pas de nouvelle sculpture ni ID
inventé dans ce changement.

| Modèle original approuvé | Avant | Si variante active | Sinon |
| --- | ---: | ---: | ---: |
| Classic, observatoire à deux paraboles | 104 s | 44 s | 104 s |
| Crossroads, échangeur forgé | 77 s | 45 s | 77 s |
| Harbor, mégaportique | 91 s | 46 s | 91 s |
| Towers, pont de signature | 62 s | 47 s | 62 s |

Les quatre chargeurs utilisent maintenant
`PremiumActiveVariantImportSchedule.waitFor`, exécuté **à l'intérieur de
leurs boucles asynchrones existantes**. Après le délai court, le module lit
`workspace.GeneratedMap.Arena.VariantId` : si la variante correspond,
il poursuit l'import immédiatement. Sinon il attend le **solde** du délai
historique. Si `GeneratedMap` manque, le chargement reste classique.

Le modèle Orbital principal possède déjà une attente de 42 s et reste
inchangé. Le nombre de `LoadAssetAsync` par source, la limite de trois
essais, la validation de sept `MeshParts` approuvées, le contrôle de
collision et le fallback natif ne changent pas.

Le test de régression vérifie que **seule une** de ces quatre sources
peut être avancée pour une variante active, que les quatre sources
approuvées sont toujours utilisées et que les quatre variantes de
lancement ainsi que `Orbital` ou l'absence de carte sont traitées.

**Limite explicite :** ces chiffres correspondent à la première
*tentative*, pas au temps réel d'apparition. D'autres chargeurs du jeu
peuvent émettre des requêtes dans la même fenêtre et le temps d'API
Roblox peut varier : aucune sérialisation globale des importations,
FPS Android, capture Studio ou publication de Place n'est revendiquée.
