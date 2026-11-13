# P4 — Storm Harbor : réparer le véritable remplacement 3D de la station sur Android Low

**13 novembre 2026 — code source intégré sur `main`.** Le statut de publication publique Roblox et la performance sur un téléphone réel restent des vérifications distinctes.

## Régression structurelle observée

La station Harbor affiche au maximum **sept composants natifs structurels** (`HarborHeroPierFoundation`, deux jambes, traverse, cabine, mât et `HarborHeroRadarArm`) et une lentille sur Low. Dans `arena-hero-scenery.client.lua`, un `if tier.Name == "Low" then return end` évite volontairement la cabine de toit, les pièces de treuil, les renforts et les éléments High.

Le remplacement `HarborHeroStationMeshKit.lua` avait bien un budget `Low={count=1,distance=170,retain=22}`, mais **exigeait dans toutes les qualités** la présence des deux pièces natives `HarborHeroHoistCable` et `HarborHeroHoistWeight`, **absentes sur Low**. Il exigeait également **12** natives avant de masquer la scène, alors que Low n'en crée que **7** qui peuvent effectivement être substituées. L'autorisation Low était donc nominale, non fonctionnelle.

Indépendamment, les deux vérifications `base.Size.X/Z>=318` coupaient le modèle 3D pendant `Shrinking Arena`, bien que le monument soit installé à l'extérieur du plancher et reste fixe.

## Correctifs

1. **Vrai modèle original importé sur Low** : le modèle Approved `73237902371094` conserve ses 7 `MeshPart` authentiques ; le kit accepte les **7** natives structurelles réellement produites par Low. Aucune primitive ou `MeshPart` fictive n'est ajoutée au jeu pour satisfaire artificiellement la validation.
2. **Animation fidèle** : le radar importé continue de suivre la pièce `HarborHeroRadarArm` native. Les véritables MeshParts `Cable` et `Weight` restent à leur **pose d'origine** en Low, puisque leurs deux conducteurs natifs ne sont pas générés. En Medium/High, l'intégralité des trois mouvements Radar/Cable/Weight reste active.
3. **Berth fixe et arène rétrécissante** : le client vérifie `OriginalSizeX/Z`, l'ancrage, la collision originale et la parenté de la vraie `Base` de l'arène. Le modèle est aligné sur la traverse réelle `HarborHeroGantryCrosshead`, sans calcul à partir de la largeur actuelle du plancher. Sur changement de qualité pendant la manche, le constructeur Harbor réutilise `OriginalSizeZ` pour maintenir l'emplacement côtier initial.
4. **Rollback sûr** : pression graphique 1 sur Low, streaming, invalidation, budget ou disparition du modèle rendent immédiatement les formes natives. La lentille `HarborHeroStormLens` continue d'être gérée par le propriétaire de l'animation existant, jamais masquée par ce kit.
5. **Budget et sécurité inchangés** : maximum **un** modèle de sept `MeshPart` à **170 studs** sur Low sain, hystérésis 22 studs. Aucun nouveau chargement AssetService, script non approuvé, réseau, collision, boucle `RenderStepped`, physique ni hazard. Les pièces restent comptabilisées dans les plafonds **440/680/900 Parts** du budget visuel local.

## Vérifications

- Workflow existant `p4-low-harbor-hero-station.yml` et `tools/verify_low_harbor_hero_station.py` complétés pour prouver la compatibilité réelle de la scène Low et le positionnement fixe après shrink.
- Test `tests/engine/native-premium-fallback.spec.luau` avec vraies instances `MeshPart` et natives Low (faux contenu de source **réservé à la fixture de test**, jamais à la version publiée) : remplacement à sept meshes, mouvement natif du radar, conservation de la lentille, persistance sous shrink, restauration sous pression 1, disparition de l'original et rejet d'une `Base` artificiellement agrandie.
- Les anciens documents affirmant que Low fonctionnait ne constituaient que des vérifications statiques : ils n'avaient pas validé cette dépendance inatteignable sur les natives Low.

**Limites :** le succès des tests Roblox Engine valide les chemins testés, pas les FPS/p95, le rendu visuel final, ni la livraison de cette révision en production Roblox. Vérification finale recommandée : captures sur Android Low, pression 0→1→0, changement Low→Medium pendant `Shrinking Arena`, et métriques FPS/mémoire.
