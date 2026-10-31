# Chaos Survival — caches de rendu statique des avertissements

31 octobre 2026 — optimisation client des effets de danger **sans audit visuel actuel des cartes, sans Studio et sans publication Roblox**.

## Problème réellement constaté dans le code

Pendant un avertissement Bomb, Meteor ou Jump Shock, `hazard-warning-visuals.client.lua` évalue jusqu'à 30 fois/s les éléments 3D et l'outline facultatif. Lorsque `ReduceMotion` est activé, les positions, couleurs et formes finales sont **constantes** pour un même marqueur, et pourtant :
- `BombChargeKit.sync` reconstruisait chaque frame 1 à 5 recettes de charge et assignait plusieurs propriétés à chaque Part.
- `HazardGroundOutlineKit.update` reconstruisait chaque frame une recette de contour, alors que les marqueurs au sol restaient fixes et que la visibilité distance avait déjà un contrôleur séparé.
- `syncShockSignature` recalculait les géométries et affectait à chaque frame les 1 à 4 pièces angulaires Jump Shock.
- Les marqueurs serveur `Freeze`, `JumpShock`, `Meteor` et `Bomb` recevaient chaque tick des écritures `Size`/`Transparency` même lorsque les valeurs étaient inchangées (notamment sous `ReduceMotion`).

## Correction

1. **Charge Bomb** : après validation à chaque tick de l'existence du Part serveur, du rayon de visibilité et du slot de priorité, réutiliser la pose locale statique seulement si `ReduceMotion`, le palier de qualité, le nombre de pièces, la position serveur et l'appartenance des enfants restent identiques. Changement de qualité/mode/rang, mouvement du marqueur, disparition d'une pièce, nouvelle source : recalcul immédiat et recréation si nécessaire. Dans le mode animé, le décompte reste piloté par les horodatages du serveur. Les écritures aux propriétés déjà identiques sont évitées.
2. **Hollow outline Meteor/Bomb** : `syncVisibility` continue de vérifier la distance au même rythme et les warnings serveur restent intacts. Le rendu statique sous `ReduceMotion` est réutilisé uniquement si position, diamètre final et qualité n'ont pas changé. Le mode animé invalide ce cache et continue à utiliser le taux d'actualisation habituel.
3. **Jump Shock** : ne pas recalculer les aiguilles angulaires dans le mode immobile tant que le diamètre, la position et le tier n'ont pas changé et que toutes les pièces sont toujours présentes. Un enfant retiré hors du contrôleur est reconstruit à la prochaine synchronisation.
4. **Part serveur (rendu client uniquement)** : les mises à jour de `Size` et `Transparency` ne sont émises que lorsque la valeur calculée change. Le compte à rebours, les tailles finales de dégâts, les prompts `JUMP!`, les glyphes d'évitement et les signaux serveur ne sont pas modifiés.

## Risques et limites

- Ces caches sont par instance, jamais globaux, et remis à zéro quand une silhouette est retirée, le mode animé reprend, la qualité change ou une pièce devient invalide. Les profils ne sont pas mémorisés à travers les manches.
- Aucun changement de hitbox, de dégâts, d'horodatage, de priorités d'alerte, de mécanique de saut, d'audio ou de scripts serveur ; aucune nouvelle boucle RenderStepped ni RemoteEvent.
- Aucun FPS, mémoire ou gain CPU **mesuré** à ce stade. L'économie théorique concerne des écritures/allocations d'effets *facultatifs*, principalement Android avec `ReduceMotion`.

## Contrôle au prochain jalon avant mise à jour publique

Exécuter **Build Validation et les cinq suites Roblox Open Cloud sur le SHA exact de `main`**, puis sur Android/PC :
- Créer simultanément plusieurs Meteor/Bomb/Jump Shock, y compris en entrant dans la partie au milieu d'un timer.
- Activer `ReduceMotion`, puis modifier la qualité Low/Medium/High et désactiver `ReduceMotion` pendant le décompte : l'animation normale doit reprendre sans silhouette perdue.
- Déplacer ou retirer/recréer un warning ou un de ses enfants localement : la silhouette statique doit suivre la nouvelle position et réparer sa géométrie sans prolonger la durée de dommage.
- Vérifier que les contours activent/désactivent leur `SurfaceGui` aux distances existantes et que le HUD d'esquive reste prioritaire pendant Double Chaos.
- Mesurer le nombre de créations, d'assignations de propriétés, les FPS et la mémoire sur Android Low/Medium versus le SHA précédent.

L'audit visuel des cartes est toujours reporté. La fusion GitHub seule ne redéploie pas l'expérience Roblox publique.
