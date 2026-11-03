# CHAOS SURVIVAL — passe d'éclairage directionnel et de matières d'arène

**3 novembre 2026 — lot visuel n° 1**. Cible : `VIS-029`, `VIS-031`, `VIS-042`, `VIS-043`, `VIS-046`, `VIS-047`, `VIS-049`, `VIS-055`, `VIS-057`.

## Référence de départ et limites

Le dernier SHA Roblox public **vérifié avant ce lot** est `e488dc939b665dc32bed70d771b00ddfb8910d2c` : [build #41636302593](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41636302593), [cinq suites moteur #41636313905](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41636313905), [publication #41637010286](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41637010286). Ce baseline inclut les modèles de bâtiments et le vrai grand aéronef 3D. Les impressions d'éclairage et FPS Android n'ont toujours pas été vérifiés par une capture authentique.

Les cinq mondes avaient auparavant tous le soleil entre 13h85 et 15h30, donc une direction générale proche malgré des couleurs différentes. Certaines surfaces natives du premier plan étaient presque noires (`RGB 23,43,48` pour Orbital par exemple). Les lumières d'appoint des structures étaient très colorées au lieu de simuler des sources industrielles neutres. Le gestionnaire d'ambiance relançait des tweens sur chaque `RoundState`, même quand seule la seconde restante changeait.

## Direction solaire artistique, par arène

Ce changement agit directement sur le système Roblox natif `Lighting.ClockTime` et `Lighting.GeographicLatitude`, pris en charge officiellement par Roblox ; c'est une **modification réelle de la position du soleil**, pas une simple recoloration d'une source globale. <https://create.roblox.com/docs/environment/lighting>

| Arène | Heure solaire antérieure | Nouvelle heure | Latitude | Intentions de composition |
|---|---:|---:|---:|---|
| Classic | 15h10 | **14h25** | **36°** | acier neutre, volumes de côté éclairés, socles lisibles |
| Towers | 14h80 | **11h30** | **59°** | hauteur des cabines et poutres révélée, lumière froide de matinée |
| Crossroads | 15h30 | **16h15** | **27°** | profondeur des jonctions, contrejours contrôlés, lavande limitée aux accents |
| Orbital | 13h85 | **12h10** | **72°** | soleil haut et décentré, détails céramiques et structures vertes lisibles |
| Harbor | 15h00 | **10h75** | **44°** | lumière maritime douce, contrastes du fret, brume adaptée au bassin |

**Important :** ces horaires sont des `ClockTime` Roblox, pas de véritables heures locales. L'angle réel dépend du moteur. Les captures réelles des cinq arènes devront vérifier ombres, silhouettes, orientation, obscurité des catastrophes et lisibilité.

## Matières et lisibilité

- `VisualTheme.Arenas` : refaire les cinq valeurs `Surface` et `Structure` (les éléments de gameplay gardent les mêmes collisions et états), en supprimant les socles presque noirs. Les teintes et matériaux de chaque monde restent distincts.
- Towers Android Low : le panneau natif `Foil` au rendu miroir devient `Metal`, nettement moins chromé ; sur Medium/High les surfaces éligibles continuent d'utiliser **le vrai variant PBR original `ChaosBrushedTitanium`** sans changer ses textures source.
- `arena-lighting.client.lua` : augmente la part d'éclairage environnemental diffus surtout Low/Medium (`0.65 / 0.86 / 1.0` contre `0.48 / 0.76 / 1.0`) tout en abaissant les valeurs spéculaires des cinq scènes. Redonne du relief aux volumes sans surexposer par un énorme `Brightness`.
- Les cinq profils de brouillard sont ajustés pour que les nouveaux objets 3D restent discernables devant une scène de **320 studs**, sans supprimer l'atmosphère de Harbor.
- `arena-focal-lighting.client.lua` : les **projecteurs architecturaux existants** mélangent lumière blanche neutre et accent coloré (key/fill), plutôt que de saturer toutes les faces en cyan/violet. Leurs plafonds restent Low 0 / Medium 2 / High 3. Intensité de phase de manche `0.30 → 0.40`, tout en maintenant le **Final Rush à 0.08** et les réductions des catastrophes.

## Fiabilité de la lumière et comportement pendant les catastrophes

- Les `RoundState` d'une **même phase** n'enclenchent plus de tweens `Lighting`, `Atmosphere`, `Bloom`, `SunRays` et `DepthOfField` inutilement sur le seul changement du compte à rebours. Le changement d'arène, les tiers graphiques et `ReduceMotion` ont toujours leurs propres listeners.
- Les vrais effets de catastrophes continuent de posséder l'exposition/correction de couleur/fog pendant les phases `ready` et `round` ; ce lot ne remplace pas `juice.client.lua`, ne crée aucun autre `ColorCorrectionEffect`, n'envoie aucun RemoteEvent et ne désactive pas Blackout/Darkness.
- Les attributs client `LocalLightingArtVariant`, `LocalLightingSolarClock`, `LocalLightingLatitude` et `LocalLightingQualityTier` permettent d'identifier le profil affiché par une capture Studio/Android. **Ces métadonnées ne sont pas des mesures FPS ni des preuves de rendu.**

## Budgets matériels strictement préservés

Aucune texture PBR Roblox nouvelle ni aucun `MeshId` inventé. Les 14 Model IDs originaux approuvés, les quatre familles de MaterialVariant 2K du propriétaire et le réglage de leurs maps `Color/Normal/Roughness/Metallic` restent inchangés. Le sélecteur `PbrDistrictRules` conserve ses budgets globaux mobiles **Low 0 / Medium 32 / High 72** textures actives, son exclusion des MeshParts importés et des surfaces de danger, et ses priorités caméra. Le matériau natif amélioré sur Low est un fallback Roblox et non une nouvelle image PBR.

Aucune nouvelle lampe, rayon dynamique ou autre surcharge GPU ; le nombre de vrais SpotLight locaux reste 0/2/3. Les propriétés `Lighting` restent sous le propriétaire existant, aucun doublon de post-process.

## Garde de sortie

Ce lot est une modification réelle de source, **pas une certification d'image AAA**. Avant de dire que la version est publique, le nouveau SHA exact doit réussir `Build Validation`, les **cinq suites moteur Roblox Cloud**, puis la publication gardée vers le **même** Universe `10771083668` / Place `95351659174730`.

Après publication, contrôler physiquement les cinq arènes en **Low, Medium, High**, ainsi que le lobby, READY, manche normale, Blackout, autres catastrophes et résultat. Vérifier ombres directionnelles, rendu des modèles 3D, médianes de luminance (aucune cible dangereuse noyée dans le noir), signalétique et vrais FPS/mémoire sur Android. Ne jamais cocher `VIS-042` ou `VIS-057` comme visuellement résolus sans cette preuve.
