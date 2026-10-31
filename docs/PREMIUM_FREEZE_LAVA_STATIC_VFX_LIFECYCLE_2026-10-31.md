# Chaos Survival — durée de vie de Freeze et VFX statiques de lave (Android)

31 octobre 2026 — correction du contrôleur `disaster-premium-vfx.client.lua` sur l'état réel de `main` (base `98f100e6`). Aucune vérification visuelle des cartes, partie Studio ni publication Roblox.

## Défaillances confirmées dans le code

- Le propriétaire client de `FreezeWarning` recalculait toutes les recettes angulaires et écrivait chaque `CFrame`, `Size` et `Transparency` des facettes à chaque intervalle décoratif, même sous `ReduceMotion` où le motif ne varie pas au cours du compte à rebours.
- Le propriétaire local de `RoundLava` réécrivait à chaque tick la géométrie, les teintes, la transparence et la luminosité, y compris à position/taille/couleur inchangées.
- Le renderer Freeze plafonnait l'animation visuelle à `alpha=1` mais continuait à maintenir ses facettes 3D et son émetteur de brouillard tant que le marqueur serveur restait parenté à Workspace. Un `Warning` expiré mais temporairement répliqué persistait ainsi dans les coûts graphiques, jusqu'à `ChildRemoved`.
- Lors de la reconfiguration `ReduceMotion`, l'émetteur brouillard appelait `Clear()` même sans particules précédemment émises (ex. tier change répété en mode réduit).

## Modifications

1. **Pose Freeze immobile mise en cache** : pour `ReduceMotion=true`, réutilisation des facettes tant que la position du marqueur, son diamètre final, le tier et le nombre de pièces restent identiques. Les règles de `DisasterCosmeticRules.reusableFreeze` vérifient toujours la présence des objets. Dès que le mode animé reprend, la pose statique est invalidée et l'horodatage serveur continue à contrôler les étapes.
2. **Lave : écritures conditionnelles** : Size, CFrame, Color, Transparency et Brightness ne sont transmis aux instances Roblox que si la valeur change. La progression réelle de la lave (taille, hauteur, CFrame) est recalculée à chaque cycle ; aucune dérive de la surface par rapport au véritable danger serveur n'est autorisée.
3. **Expiration Freeze exacte** : dès `workspace:GetServerTimeNow() >= startedAt + duration`, retirer **uniquement** les facettes, l'Attachment et l'émetteur cosmétiques. Conserver le marqueur serveur et ses propriétés intacts. Si ce même Part réplique ensuite un nouveau départ, les abonnements existants aux métadonnées peuvent permettre sa réactivation.
4. **Brouillard réduit** : appel à `mist:Clear()` seulement lors du passage depuis un débit non nul vers le mode réduit ; un changement de qualité répété à débit déjà nul ne déclenche pas de nettoyage GPU supplémentaire.
5. **Aucun coût transversal ajouté** : pas de nouveau RenderStep, boucle, Part, Attachment, RemoteEvent, raycast, réseau ni effet sur collision, dégâts, avertissements, récompenses ou contrôles. L'implémentation réutilise la seule boucle adaptative décorative en place.

## Validation différée avant la prochaine publication publique

- Build Validation et les cinq suites Roblox Open Cloud sur le commit exact de `main` ; essai Android Low/Medium/High et PC.
- Pendant un Freeze, activer/désactiver `ReduceMotion` et modifier le tier : les facettes doivent se figer puis reprendre leur taille/animation sans disparaître.
- Déplacer le marqueur `FreezeWarning` et faire évoluer `RoundLava.Size`, `CFrame` ou sa hauteur pendant une manche : les éléments locaux doivent suivre le serveur même en mode réduit.
- Observer un warning Freeze expiré mais toujours présent dans Workspace : ses éléments locaux doivent disparaître à l'horodatage serveur. Réarmer le warning via une nouvelle métadonnée en environnement contrôlé : le renderer doit rebinder sans dupliquer de pièces.
- Mesurer CPU/frame, écritures de propriétés, Part/ParticleEmitter visibles, FPS et mémoire, particulièrement pendant Double Chaos. Aucun gain de performance chiffré n'est revendiqué sans mesures.

Le budget global des dizaines de propriétaires VFX reste télémétré via `VisualBudgetRules`. Cette PR n'affirme pas appliquer un plafond d'instances transversal. Le déploiement Roblox public et l'audit visuel actuel des cartes sont reportés.
