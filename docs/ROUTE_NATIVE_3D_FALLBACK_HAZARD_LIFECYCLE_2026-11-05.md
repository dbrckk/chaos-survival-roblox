# Vérité des routes : restauration des habillages pendant danger, shrink et streaming

**5 novembre 2026, suite au lot de châssis et passerelles `bf8001b`.** Travail source, non publié.

## Défaut réel corrigé

`PlatformNativeTrimReplacementKit.lua` masquait les `PlatformBevel`, `PlatformUnderFrame`, `PlatformSupport`, `SkySpine_Undercarriage/CrossStiffener`, `Promenade_UnderdeckTruss` et `SkybridgeRib` dès qu'un modèle approuvé était monté. Mais ce système ne suivait ensuite que la disparition du MeshPart. Lorsque `CollapsePhase` basculait vers `Warning` ou `Gone`, les ornements 3D étaient effacés ou dégradés par `PlatformFinishKit.applyCollapseVisibility`, tandis que les vrais blocs non-physiques restaient masqués. Une plateforme dont l'empreinte rétrécissait pouvait également conserver une ancienne substitution incompatible.

## Correction implémentée

- Résoudre obligatoirement un **vrai `Platforms/PlatformN`** ou **`Platforms/SkybridgeN`** pour chaque composant esthétique qui peut être masqué. Les IDs de décor seuls ne suffisent plus.
- Le masque du fallback n'est autorisé que si le Part physique est ancré, `CanCollide=true`, non transparent et en phase `Normal`/`Safe` ou sans phase. Un shutter doit être `Idle` s'il existe.
- Si `Size.X` ou `Size.Z` varie d'au moins **0,09 stud** depuis le montage complet initial, le masque est retiré et le vrai décor serveur apparaît. Cela évite de revendiquer une géométrie importée qui ne correspond plus aux dimensions exactes de sa plateforme.
- Réagir aux vrais événements `CanCollide`, `Transparency`, `Size`, `CollapsePhase`, `BridgeShutterPhase`, `Platforms.ChildAdded/Removed` et au streaming des dossiers. **Aucune boucle RenderStepped / Heartbeat, aucun nouveau collider, asset ou signal réseau.**
- Restauration sélective : réafficher uniquement les éléments natifs dont le propriétaire est devenu dangereux ; conserver les autres remplacements 3D et leurs modèles approuvés. Le callback existant `LocalNativeStructuralPartsReplaced` reflète les masquages réels, pas les souhaits.
- Les watchers sont déconnectés par `Kit.reset` à chaque reconstruction/changement de map. Une perte de MeshPart approuvé fait toujours `restore()` et désactive les remplacements, sans recréer une fausse plateforme.

## Garde-fous / limites

Ce module ne modifie ni les `CanCollide` physiques, ni `CollapsePhase`, ni la destruction, ni la vitesse ou les bots. Il ne peut pas prouver à lui seul qu'un `PlatformUnderFrame` natif visible pendant `Gone` est une géométrie jouable ; seul le collider serveur est autoritaire. Les anciennes géométries conservent les transparences que le serveur leur donne, donc un fallback n'est pas artificiellement rendu plus opaque.

Un client qui reçoit pour la première fois une plateforme déjà réduite peut établir une référence de dimensions à cet instant. La QA réelle devra comparer son état aux attributs du serveur (surtout join-in-progress et `ShrinkingArena`). Aucune capture Android authentique ni FPS mesurés ne sont revendiqués.

## Jalon de vérification

1. Source guard exact-SHA, Rojo build, les 7 suites réelles Roblox Cloud.
2. Android : observer les vrais `SkybridgeRib`, `SkySpine_Undercarriage` et `Promenade_UnderdeckTruss` pendant `Normal → Warning → Gone → Normal`, et `BridgeShutterPhase: Idle → Warning → Idle`.
3. `ShrinkingArena` : vérifier la taille et la position réelle du masque dans les cinq arènes, puis passage `High → Low → High`, streaming tardif et clone retiré.
4. N'accepter une mise à jour publique qu'après preuve d'accès public et d'une version publiée à SHA vérifiable.
