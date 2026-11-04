# Correction globale des surfaces sombres en manche — 4 novembre 2026

**Code source uniquement.** Aucun effet, image, score FPS ou publication publique n'est certifié par ce document.

## Défaut identifié dans le code réel

Le lot de direction artistique du 3 novembre a rendu les cinq palettes plus claires et a ajusté le soleil, l'exposition, la brume et le rendu PBR. Mais pendant les phases \`ready\` et \`round\`, \`juice.client.lua\` conservait un écrasement global et constant :

- \`Lighting.EnvironmentDiffuseScale = 0.34\` en manche, quel que soit le niveau de qualité ou la carte ;
- \`Lighting.EnvironmentDiffuseScale = 0.38\` en READY ;
- \`Lighting.EnvironmentSpecularScale = 0.76 / 0.72\`, donc des surfaces brillantes mais des faces métalliques mal remplies.

L'intention de ce lot est de rétablir un éclairage diffus neutre sur les vraies géométries et les passages jouables, sans ajouter de SpotLight ni altérer les signaux de danger, ni transformer une catastrophe **Darkness** en scène lumineuse.

## Une source unique de calibration

Le nouveau \`src/shared/ArenaLightingReadabilityRules.lua\` fournit des profils en valeurs numériques, importés par les deux propriétaires préexistants :

- \`arena-lighting.client.lua\` conserve le contrôle des identités des cinq arènes, des changements de carte, du soleil et des phases non catastrophiques ; Low et Medium gagnent un peu de remplissage indirect : facteur de rendu \`0.84 / 0.94\` contre \`0.65 / 0.86\`, High reste à \`1.0\`. L'exposition d'ambiance Low passe de \`0.65\` à \`0.80\` fois la valeur originale de l'arène.
- \`juice.client.lua\` contrôle toujours les réglages prêts / manche, avec calibrage par tier, phases et présence de Darkness. Les corrections de couleur, blackout, FOV, UI danger, brume de catastrophe et voix ne sont pas modifiées.

| Qualité | Diffuse READY normale | Diffuse manche normale | Diffuse manche Darkness | Specular manche normale |
|---|---:|---:|---:|---:|
| Low | 0.56 | 0.53 | 0.26 | 0.54 |
| Medium | 0.54 | 0.51 | 0.25 | 0.63 |
| High | 0.52 | 0.49 | 0.24 | 0.70 |

En Double Chaos normal, la valeur diffuse du round baisse de \`0.025\` ; la présence de **Darkness dans n'importe lequel des deux IDs**, même secondaire, déclenche la voie sombre. Les niveaux de diffuse READY Darkness restent \`0.33 / 0.31 / 0.30\`. Le \`ColorCorrectionEffect.Brightness\` négatif et la fenêtre PowerReturn restent aux propriétaires existants et ne sont PAS annulés. Cette modification ne prétend pas disposer d'une métrique de contraste perceptuelle mesurée.

## Coût et sécurité

Aucune texture supplémentaire, aucun nouvel asset Roblox ou système de lumière locale ; aucun changement dans les budgets \`Low / Medium / High\` de Parts (440/680/900), Light (32/48/64), Effects (56/82/110), aucune boucle de rendu supplémentaire. Les valeurs identiques sont épargnées des écritures répétées dans \`juice\` ; seules deux métriques client \`LocalRoundDiffuseTarget\` et \`LocalDarknessLightGuard\` sont mises à jour lorsqu'elles changent.

**À vérifier lors d'un jalon de release** : build Rojo, compilation Luau, sept suites Roblox Open Cloud sur un même SHA, puis vrai rendu Android pour Classic/Towers/Crossroads/Orbital/Harbor, phases READY/round/results, Darkness primaire et secondaire, Blackout PowerReturn, pluie, brouillard, soleil, et 30 minutes de FPS/mémoire. Sans captures réelles, pas de certification visuelle ni publication.
