# P4 — Couverture réelle des sculptures Premium dans le relevé 3D

10 novembre 2026. Les sculptures d'origine Roblox Approved de six
familles de décor proche étaient intégrées au LOD du client mais leur
état réel n'entrait pas dans les événements
`ClientOriginal3DResidencyPulse`. La télémétrie pouvait annoncer un
résultat incomplet malgré des `MeshParts` montées.

## Nouveau contrat (sans nouvelle boucle ou RemoteEvent)

Une fois après 12 secondes de présence active, puis chaque 45 secondes
actives, `src/client/juice.client.lua` lit les **véritables attributs**
produits par le propriétaire visuel `scenery-lod.client.lua`, en plus
des relevés originaux (sol, chemins, horizon, trafic, halo).

| Famille | Compteur de montages | Pièces natives attendues masquées |
|---|---|---|
| Towers machines | `premiumTowers` | 2 par machine |
| Crossroads portiques | `premiumGantry` | 1 par portique |
| Classic broadcast fins | `premiumClassicFin` | 1 par aileron |
| Orbital réacteurs | `premiumOrbitalPair` | 2 par paire nœud/support |
| Crossroads entrées | `premiumEntrance` | 3 par portail |
| Classic/Towers identity | `premiumIdentity` | 1 par mât |

Le serveur borne ces 12 champs dans `PerformancePulseRules.sanitize`
avec les plafonds réels de chaque famille et rejette les valeurs NaN,
infinies, négatives ou non numériques. Ils sont **déclaratifs** et ne
donnent aucune récompense, autorisation ou avantage gameplay.

La valeur numérique de l'événement additionne les groupes décoratifs
réellement montés à ses anciennes familles. Un groupe est un montage
de kit, **pas** un triangle, un MeshPart isolé ou un pourcentage de
la carte. Le bit `S` signale la présence d'au moins un de ces groupes.
L'ancien bit `F` signale aussi maintenant une incohérence : un kit
se dit monté mais n'a pas masqué toutes les pièces natives attendues.
Les bits `P,C,T,H` gardent leurs significations existantes.

La clé Analytics reste de faible cardinalité : 6 arenas maximum,
3 qualités, 3 types d'appareil déclarés et 6 bits de présence/erreur.
Le système réutilise le même `PerformancePulse` déjà soumis au
`RateLimiter.new(45)`, sans nouveau `RemoteEvent`, événement
`AnalyticsService`, appel réseau ni boucle `RenderStepped`.

## Interprétation

Pour mesurer l'avancement, conserver séparément :
1. **Éligibilité statique** — combien de Parts sont ciblées par les kits ;
2. **Résidence client** — combien de groupes sources sont montés dans
   une manche réelle ;
3. **Visibilité graphique et FPS** — mesures Roblox Studio / Android,
   à confirmer avec capture et mesures d'appareil.

Ce changement améliore le second indicateur, **sans prétendre** que
tous les éléments primitifs des cinq arènes ont été inventoriés
ni que la version GitHub a été publiée sur la Place.
