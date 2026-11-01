# Storm Harbor — quatre mouvements mécaniques réels, propriétaires et accessibles

Date: 1er novembre 2026. Base source : `main` `f8ae9853152a71528443d07dc884927bac54279d`.

## Objectif

Les quatre avant-postes de quai de la PR #519 n'étaient jusqu'ici que des sculptures statiques. Leurs plateformes sont de vraies dalles de jeu et doivent le rester. L'amélioration ajoute un mouvement organique **à chaque instrument non collidant**, plutôt qu'une image animée ou une rotation dangereuse de plateforme.

| Route | Instrument | Mécanique originale | Durée avant inversion |
| --- | --- | --- | --- |
| Nord | Station radar | Balayage d'azimut +20° | 2,8 s |
| Est | Treuil de fret | Rotation limitée d'axe +14° | 2,2 s |
| Sud | Balise de marée | Balancement latéral +6° | 3,4 s |
| Ouest | Antenne de communications | Recalage -12° azimut et +9° inclinaison | 3,0 s |

Ces quatre gestes sont purement cosmétiques, doux et alternés. Ils n'imitent **aucun** avertissement de catastrophe, ne font pas tourner le sol, ne suppriment aucun chemin ni ne donnent de capacités physiques au joueur.

## Intégration : une seule autorité par propriété

- `HarborOutpostKit.build` expose l'unique instrument de chaque vraie plateforme terminale ; `HarborOutpostKit.motionTarget` définit la pose cible statique.
- Le **propriétaire déjà existant** `arena-platform-identity.client.lua` crée maximum un `TweenService` par avant-poste, donc **4 tweens au total** sur Medium/High, zéro sur Low. Aucune nouvelle boucle `Heartbeat`, `RenderStepped` ou `task.spawn`, aucun message réseau.
- Le tween anime seulement `PlatformIdentityWeld.C0` de l'instrument. `PlatformFinishKit.bindRouteFootprint` reste le **seul propriétaire de `Weld.C1`** pendant Shrinking Arena ; cette séparation protège le redimensionnement des ornements et évite les déplacements cumulés.
- `TweenInfo(...,-1,true)` inverse doucement l'oscillation entre l'origine et la pose cible. `Cancel`, `Destroy` et `C0=CFrame.identity` remettent l'instrument au repos au nettoyage.
- Les événements `CollapsePhase`, `CanCollide` et `Transparency` arrêtent le mouvement avant qu'une vraie dalle en avertissement, disparue ou non solide ne continue à faire bouger ses instruments. Ils reprennent proprement uniquement si la dalle redevient admissible.
- Le changement utilisateur `ReduceMotion` arrête ou reprend directement les quatre mouvements **sans reconstruire toutes les plateformes**. Le changement Low/Medium/High utilise déjà la reconstruction maîtrisée et son `clear()` qui annule les tweens et déconnecte les deux listeners.
- Les parties mobiles sont `Massless`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false` via la factory existante ; aucune modification des risques de jeu, de l'IA, de la progression, de la caméra, du budget PBR, de la lumière ou de l'audio.

## Contrôles de source et preuves exigées

**Vérifications de source pendant développement :** limites des poses, 4 profils connus, quatre joints maximum, absence de boucle ou de RemoteEvent, désactivation ReduceMotion, phase de disparition, conservation C1 lors du shrink, absence d'objets de physique supplémentaires. Ces vérifications ne certifient pas le comportement dans Roblox.

**Jalon moteur et réel avant publication :**
1. Sur **un même SHA**, Build Validation + cinq suites Open Cloud. Vérifier que `TweenService:Create(Weld,...,{C0=...})` s'exécute sans erreur client et que quatre tweens démarrent/finissent correctement dans Roblox Studio.
2. Pour les quatre quais, en Medium et High, inspection 15 images/partie et comparaison à vue fixe et en déplacement. Low : zéro sculpture supplémentaire et zéro tween.
3. 20 transitions `ReduceMotion` off/on, `CollapsePhase` Idle → Warning → Gone → clear, `CanCollide` et `Transparency` ; vérifier restauration exacte des poses et l'absence de tween après désassemblage.
4. Vérifier une contraction réelle de la plateforme durant l'animation et la restauration : aucune pièce ne reste suspendue ou ne se transforme en faux bord praticable.
5. Session Android physique 30 min, cadre caméra et 30/60 FPS selon profil, mémoire, chauffe, streaming et fatigue visuelle. Garder une seule version publique, pas de publication intermédiaire.

**Statut** : modifications source uniquement. Dernière publication publique certifiée par GitHub Actions : `e8767c98c475a3efb39ed53ed7bbe16efa1865d2`. Ne pas présenter ces animations comme visibles sur la version Roblox publique avant son déploiement.
