# Chaos Survival — densité d'ambiance Double Chaos et cohérence des manches

31 octobre 2026. Audit source et changement des contrôleurs client. Pas d'audit visuel actuel des cartes, ni Roblox Studio, ni publication Roblox publique.

## Défauts constatés dans main

- `arena-cinematic-disaster-atmosphere.client.lua` appliquait l'intégralité de ses 4/6/8 balises d'arène et de son budget d'émetteurs pour UNE catastrophe même avec deux ou trois catastrophes simultanées. En Final Rush, le taux de chaque émetteur augmentait de 45 %, pendant que les autres contrôleurs (traînées, impacts, clignotements et résidus) restent eux aussi actifs. Ces balises sont purement décoratives et **ne sont pas** des avertissements serveur.
- Le même contrôleur transformait les `RoundState` malformés en un snapshot d'attente, vidant l'ambiance valable. Les messages d'anciens numéros de manche pouvaient réinstaller les mauvais accents.
- `disaster-motion-vfx.client.lua` faisait également passer un snapshot malformé à `waiting`, n'excluait pas les numéros précédents et ne réinitialisait pas son décor personnalisé lors d'une nouvelle manche possédant la même phase et la même liste de catastrophes.
- En cas de suppression de `GeneratedMap`, les guides locaux de rétrécissement et d'obscurité pouvaient rester visibles jusqu'à la mise à jour suivante.

## Changements et limites

1. **Politique de densité commune à l'ambiance** : `DisasterAtmosphereLayout.beaconCount(tier, active, simultaneous)` préserve la compatibilité des appels à deux arguments et le design pour une catastrophe : Low 4, Medium 6, High 8. Pour deux catastrophes : Low 4, Medium 4, High 6. Pour trois ou plus : Low 4, Medium 4, High 4. Le joueur voit toujours les deux signatures de couleur principales. Ce plafond concerne les balises/volumes purement décoratifs et ne retire aucun avertissement d'impact.
2. **Particules sous pression** : `DisasterAtmosphereLayout.particleMultiplier(count, finalRush)` réduit le nombre de particules **par émetteur** quand plusieurs désastres coexistent : un seul (1,0 / 1,45 Final Rush), deux (0,85 / 1,0), trois ou plus (0,70 / 0,80). Le mode ReduceMotion et `VfxQuality.deviceTier` s'appliquent ensuite. Les fonctions n'ajoutent ni boucle ni allocation d'instance.
3. **États valides seulement** : les contrôleurs de l'ambiance et du mouvement ignorent les snapshots non-table, de phase non-string ou de numéro de manche inférieur au plus récent. Les identités cosmétiques sont dédupliquées ; l'ambiance garde au plus trois identités (deux décorées, la troisième utilisée uniquement comme signal de densité). Les vrais dangers et leurs annonces serveur ne sont jamais filtrés.
4. **Nouvelle manche sans READY** : une nouvelle valeur `roundNumber` force la reconstruction de l'ambiance et la remise en cohérence des effets de mouvement même si `phase="round"` et les identifiants restent inchangés.
5. **Rotation de carte** : quand `GeneratedMap` disparaît, les guides purement locaux `ShrinkPerimeterLocal` et `Blackout` associés à cette carte sont retirés immédiatement. La physique et les effets de Tornado serveur n'en dépendent pas.

## Contrôles pré-publication reportés

- Build Validation et les **cinq suites Roblox Open Cloud**, exécutées sur le SHA exact de `main`, puis parties réelles Android (Low/Medium/High) et PC.
- Double Chaos (Meteors + Bombs, ou Tornado + ShrinkingArena), comparer 1/2/3 catastrophes, les paliers de qualité et Final Rush : conserver les deux couleurs de danger et les avertissements prioritaires.
- Recevoir un `RoundState` ancien/malformé après un snapshot valide ou lors du passage à la manche suivante : aucune ancienne scène ou effet de personnage ne doit réapparaître.
- Remplacer la carte lors de la phase round et changer de type de catastrophe : aucune vieille balise, guide de rétrécissement ou panneau d'obscurité ne doit subsister dans le monde.
- Mesurer au profiler le nombre de Parts, ParticleEmitters, débit de particules, FPS et mémoire sur Android. La politique réduit les **quotas statiques d'ambiance** ; aucun gain FPS mesuré n'est revendiqué.
- Inspecter aussi les autres contrôleurs VFX et la télémétrie globale de `VisualBudgetRules` : cette PR ne met **pas** en place un plafond d'instances transversal pour tous les contrôleurs et ne prétend pas le faire.

L'audit visuel des cartes et le déploiement Roblox public sont reportés comme demandé.
