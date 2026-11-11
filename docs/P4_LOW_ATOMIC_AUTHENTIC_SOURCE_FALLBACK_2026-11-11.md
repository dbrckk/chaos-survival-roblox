# P4 — Repli 3D réellement monté, sans quota bloqué sur Android Low

**11 novembre 2026 — correctif source GitHub. Publication Roblox : non effectuée.**

## Cause racine vérifiée dans le code

La précédente sélection classait les quatre familles de vrais assets :
- treillis original Towers (deux sources de sept MeshParts) ;
- grand carénage authentique du hub (sept MeshParts) ;
- carapace de plateforme authentique (sept MeshParts) ;
- trappe de maintenance originale (sept MeshParts).

Cependant, le contrôleur réservait et vidait les autres tables **avant**
de tenter `Kit.install`, `Kit.bridgeGirders`,
`Kit.carapace` ou `buildServiceHatch`. Ces appels peuvent échouer
lorsqu'un modèle approuvé est absent au moment de la pose,
`ScaleTo` échoue ou que la boîte réelle du clone est incompatible.
Résultat : le joueur ne voyait que les formes natives alors qu'un
autre modèle original déjà validé aurait pu s'installer.

## Réparation

Le contrôleur `arena-platform-identity.client.lua` exécute désormais
une **préinstallation des sources** à l'intérieur de sa reconstruction
map/tier/streaming existante :

1. Réunir les seules familles créateur déjà validées par leurs
   kits d'origine et classer les véritables `PlatformN` /
   `SkybridgeN` selon distance et direction de la caméra.
2. Retenir en premier le meilleur modèle, puis **appeler sa vraie
   fonction de montage** dans l'unique dossier
   `ArenaPlatformIdentityLocal` compté par
   `VisualBudgetRules`, sans dossier temporaire nouveau.
3. N'accepter le candidat que si le tableau monté contient
   **exactement sept vrais éléments pour une structure simple**
   ou **quatorze pour les deux flancs d'une passerelle Towers**.
   Les garde-fous `OwnerVerified`, identifiant de source,
   `CosmeticOnly`, tailles, non-collision et soudures restent
   appliqués dans les kits existants.
4. Sur échec, détruire tout élément partiellement monté, rendre
   son quota disponible, **éliminer seulement cette famille**
   et tenter la meilleure famille restante. Quatre tentatives
   maximum, sans `task.wait`, `Heartbeat` ou `RenderStepped`.
5. Après un succès, inscrire une seule entrée
   `lowPreMounted[platform]` ; la boucle de rendu habituelle
   adopte **les mêmes instances** pour la visibilité des dangers,
   les soudures `RouteTier`, le suivi des collisions originales
   et le masquage local des primitives correspondantes.
   Les modèles ne sont ni clonés deux fois, ni conservés invisibles.
6. Quand aucun des quatre modèles ne peut se monter, revenir
   simplement à la présentation historique du profil Low.
   Les source-originaux ne masquent jamais une structure native
   sans montage et validation de leur propriétaire physique.

### Compatibilité et coût

- **Low :** au maximum un treillis Towers de 14 pièces, ou une
  famille au premier plan de 7 pièces plus une grande structure
  source de 7 pièces selon les quotas précédents.
- `OptionalVfxPressure >= 1` : aucune de ces sources facultatives.
- Medium/High : **aucun changement** de sélection, quota ou pose.
- Le `PlatformNativeTrimReplacementKit` continue de masquer
  uniquement après validation des véritables MeshParts installés.
- Aucune nouvelle collision, route, lumière, texture, asset ID,
  RemoteEvent ni boucle d'échantillonnage caméra.

## Vérification avant déploiement

1. Android Low / pression 0 / sous une vraie `SkybridgeN` Towers :
   source valide => 14 MeshParts, un seul propriétaire enregistré.
2. Simuler une source prioritaire qui se charge mais
   échoue pendant `ScaleTo` ou la vérification de bounds :
   **le second modèle original disponible doit être tenté**,
   sans pièce de l'échec résiduelle.
3. Faire échouer toutes les sources : les wedges/rails/underframes
   physiques et les avertissements originaux demeurent affichés.
4. Retirer temporairement le Model sélectionné lors du streaming :
   la reconstruction existante doit libérer puis réarbitrer le slot.
5. Forcer pression 1/2, `CollapsePhase`, `BridgeShutterPhase` et
   Shrinking Arena : aucun MeshPart ne doit fournir une collision
   fictive ou masquer les dangers.
6. Effectuer captures et mesurer FPS/p95/mémoire **sur Android réel**
   avant une éventuelle publication sur Roblox.

Les assertions `tools/verify_original_3d_budget_census.py`
contrôlent les quatre chemins de montage, le nombre maximal de
tentatives et l'adoption sans double clone. Leurs résultats sont
des vérifications **statiques**, et non un essai Roblox Engine.
