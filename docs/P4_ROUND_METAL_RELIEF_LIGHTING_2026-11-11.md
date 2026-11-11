# P4 — Reflets des métaux sculptés pendant les manches (sans lumière supplémentaire)

**11 novembre 2026.** Baseline GitHub `f54589f36fd804141d66145eb771b75745a3b2c9`. Aucun déploiement Roblox implicite.

## Problème réel identifié

Les modèles originaux de stations, sculptures d'arènes et surfaces
PBR 2K ont été améliorés sur les cinq mondes. En revanche, pendant
les manches **le module `juice.client.lua` prenait le contrôle**
de `Lighting.EnvironmentDiffuseScale` et
`Lighting.EnvironmentSpecularScale` avec des valeurs **identiques**
pour Classic, Towers, Crossroads, Orbital et Harbor.
L'identité lumineuse de l'arène n'apparaissait donc pas dans
la courbe de réflexion des matériaux pendant le gameplay.

Ajouter des `PointLight` ou `SpotLight` aurait augmenté le coût
GPU Android et risqué d'écraser les avertissements des catastrophes.

## Correction livrée

`ArenaLightingReadabilityRules.disasterLighting` reçoit un
cinquième argument facultatif : la variante réelle, lue seulement
dans `workspace.GeneratedMap.Arena.VariantId`, jamais dans un
champ arbitraire envoyé par le client.
Le contrôleur de danger existant continue de posséder l'exposition
et les deux paramètres d'environnement. Un petit gain de reflet
spéculaire, supérieur au gain de remplissage diffus, révèle
davantage les détails de métal forgé sans inonder les plateformes.

| Arène | Diffus additionnel | Spéculaire additionnel | Identité recherchée |
| --- | ---: | ---: | --- |
| Classic | +0,018 | +0,042 | armure et liserés usinés |
| Towers | +0,012 | +0,050 | trusses et acier brossé |
| Crossroads | +0,024 | +0,036 | métal oxydé, accès |
| Orbital | +0,010 | +0,060 | céramique et bagues métalliques |
| Harbor | +0,026 | +0,032 | acier portuaire, lumière diffuse |

**Plafonds absolus :** diffus 0,60, spéculaire 0,78.
Les profils d'identité ne changent ni les modèles ni
les ombres globales ni les sources lumineuses.
Les profils de qualité Low/Medium/High historiques,
la réduction Double Chaos (-0,025 de diffus)
et la valeur d'exposition restent en vigueur.

### Obscurité, gameplay et accessibilité protégés

La condition de **Darkness est vérifiée avant tout ajout**,
qu'elle soit première ou deuxième catastrophe.
Les niveaux `darknessReady`, `darknessRound`,
`darknessSpecular` sont **strictement inchangés**.
Le contrôleur des fenêtres de blackout et les effets
`ColorCorrection` sont inchangés.
Les paliers d'avertissement, les dalles destructibles,
les ennemis et les collisions ne sont pas touchés.
Si l'arène n'existe pas encore ou sa variante est inconnue,
la réponse lumineuse antérieure est conservée.

Le nouveau diagnostic `LocalRoundSpecularTarget` expose
**seulement la valeur paramétrée** et non un relevé des pixels.
Il ne déclenche aucune nouvelle boucle ni RemoteEvent.

## Validation et limites

Les cas **déjà existants** de
`tests/engine/arena-focal-lighting-rules.spec.luau`
ont été étendus pour vérifier cinq profils, trois niveaux de
qualité, Double Chaos, fallback inconnu et Darkness dans les
deux emplacements. Aucun nouveau fichier de test unitaire.
Le contrat existant
`tools/verify_premium_nearfield_pbr.py`
et son workflow surveillent la cohérence du propriétaire de lumière.

Un contrôle de code et de moteur ne certifie pas le résultat
visuel ni les FPS Android. Réexécuter Build Validation et Roblox
Engine sur le SHA de `main` avant la publication publique.
