# P4 — lisibilité des vrais pads de maîtrise Classic et Harbor

**9 novembre 2026. Source seulement, sans publication ni validation moteur.**

## Problème observé dans le code

Les mécaniques P3 peuvent attribuer un boost individuel de mobilité, mais les pads physiques restent visuellement identiques avant et après l'acquisition de la charge. Le joueur ne sait donc pas, en regardant le monde, que son prochain contact avec un pad **Classic ou Harbor** consommera son bonus.

Les charges **Towers** (pont Skyrail), **Orbital** (rampe Helix) et **Crossroads** (aiguillage Flux) ne sont PAS dépensées sur ces pads ; les présenter comme des boosts de pads serait mensonger.

## Modification

`src/client/arena-pad-ambient.client.lua` réutilise le **SurfaceGui existant** sur la vraie surface du pad. Pour un joueur vivant et actif, pendant une manche de Classic ou Harbor uniquement :

- `RoundGridCircuitBoostReady` ou `RoundHarborTransferReady` allume une bordure personnelle or clair, un petit repère `BONUS PRÊT / BONUS READY` sur la plaque du pad et une légère variation de couleur de son highlight. La charge est **lue** depuis les attributs répliqués du serveur et ne peut être attribuée ou dépensée côté client.
- La mise à jour intervient sur changement d'attribut, changement de phase, modification de qualité et apparition réelle du pad. **Aucune boucle RenderStepped, Heartbeat, instance 3D, nouvelle lumière, RemoteEvent, HTTP, DataStore, texture ou mesh**.
- L'overdrive conserve sa couleur de signal prioritaire. Les dangers gardent leurs propres avertissements, les vrais pads leur physique/cooldown et la surface du pad reste visible.
- Le signal se retire immédiatement après consommation de la charge, élimination, fin de manche ou changement de carte. Les pads Towers/Orbital/Crossroads gardent la signalétique d'origine, sans faux bonus.

## Validation différée

Contrôler en Roblox Engine avec 1 humain et 7 bots : Classic, terminer le circuit puis regarder un pad ; Harbor, deux pads distincts en 14 s puis regarder un pad ; sur contact, la mention doit disparaître. Répéter sur Android Low/Medium/High et en overdrive ; vérifier qu'aucun indicateur ne se déclenche sur Towers/Orbital/Crossroads. La PR n'exécute pas de tests pendant l'itération, conformément à la consigne ; le workflow de publication exact-SHA reste obligatoire.
