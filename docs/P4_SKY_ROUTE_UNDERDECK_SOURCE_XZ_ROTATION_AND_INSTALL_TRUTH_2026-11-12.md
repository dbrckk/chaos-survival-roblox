# P4 — Correction d'orientation et de montage réel des sous-châssis 3D des passerelles

**12 novembre 2026. Code GitHub uniquement ; aucune prétention de FPS mesurés ni de publication sur Roblox.**

## Diagnostic sur `main` après la PR #849

Les cinq arènes comprennent des **vraies dalles physiques** sur les promenades et la Sky Spine ; les nouvelles règles Low permettent deux segments 3D sur une passerelle et un châssis inférieur original de sept MeshParts (asset approuvé `84582262145054`) lorsque le GPU est sain.

Le kit `PremiumRouteMeshKit.lua` avait toutefois un défaut bloquant : il supposait que la source importée avait toujours une longueur de 20 à 26 studs sur l'axe **X** et une largeur de 8 à 13 studs sur **Z**. Or l'importeur Roblox peut échanger ces axes pour exactement le même asset approuvé. Le châssis peut donc être rejeté malgré une passerelle compatible. Le contrôle de dimensions après mise à l'échelle rejetait également arbitrairement les imports où Z était long, et le calcul du `yaw` ne dépendait que de l'orientation de la plateforme, pas de la source.

Un second défaut concernait les diagnostics : `entry.underdeck` était mis à `true` dès que la source était **demandée**, avant de vérifier si `addUnderdeckModel` avait réellement produit un modèle. En cas d'échec, la route restait comptabilisée comme équipée, sans sous-face visible, et le suivi de la propriété `LongCradle` pouvait provoquer un démontage superflu du rendu supérieur.

## Modifications

- Une seule fonction `fitUnderdeck(platform, sourceSize)` gère la sélection et le montage réels. Elle applique des **bornes d'asset identiques sur les axes longs/courts**, indépendamment de leur ordre Roblox : longueur 20–26, largeur 8–13 et hauteur 3–8 studs. Elle vérifie une vraie plateforme d'au moins 17 × 9,5 studs.
- Le facteur uniforme vaut `min(longueurDeck×0,88/longueurSource, largeurDeck×0,88/largeurSource, 1,06)`, et l'import est refusé si ce facteur est inférieur à 0,56. Le modèle s'inscrit donc dans la plateforme et reste sous le véritable plancher collisionnable.
- Le `yaw` est de **0 ou 90°** en comparant les deux orientations réelles de la plateforme et du modèle. Les deux cas Roblox (source longue sur X ou Z) sont acceptés, pour les promenades à axe X comme pour la Sky Spine à axe Z.
- Les dimensions du clone contrôlent désormais `max(X,Z)` et `min(X,Z)`, ce qui évite de rejeter le même asset simplement parce que l'importeur a inversé les axes.
- `entry.underdeckRequested` conserve la demande LOD ; **`entry.underdeck` est vrai uniquement si le montage a réussi**. La comparaison de résidence s'effectue sur la demande, évitant de reconstruire tous les modèles 3D du dessus à chaque échantillon si le châssis facultatif a échoué.
- L'écoute d'arrivée d'un `LocalOriginalLongCradleMounted` concurrent ne s'enregistre que si une vraie sous-structure a effectivement été montée. Le repli collision/hazard/sol natif reste prioritaire.
- Le helper géométrique est accessible à la recette Roblox Engine via `PremiumRouteMeshKit.underdeckFit` ; il ne crée aucun Part et ne modifie pas la physique ou les connexions du joueur.
- Les quotas **Low : 1 passerelle, 2 segments au plus, 1 châssis inférieur au plus** ; Medium/High, asset, PBR, pression GPU, streaming et dossiers de recensement Android **restent inchangés**. Aucune nouvelle lumière, texture, boucle `RenderStepped` ni requête `AssetService`.

## Vérification

La régression `tools/verify_original_3d_budget_census.py` démontre mathématiquement, à dimensions représentatives d'une véritable promenade (`22,85×12` studs), les **quatre cas source 24×10 / 10×24, plateforme X-longue / Z-longue**. Elle refuse les dalles de 12×12 et les assets trop grands/non conformes. Le code garde aussi des assertions sur le compte exact des MeshParts, la pression Low et la vérité du compteur réellement monté.

**À valider dans Roblox Engine :** sur Classic, Towers, Crossroads et Orbital en Low pression 0, inspecter une promenade puis la Sky Spine avec une source originelle dont les axes X/Z sont inversés. Comparer l'orientation et le dessin métallique du modèle au-dessous de la vraie plateforme, vérifier `LocalOriginalUnderdeckMeshCount` (0 ou 1 selon montage effectif), puis simuler import manquant, rétrécissement, arrivée tardive de LongCradle et pression 1/2. Vérifier les FPS/p95 sur appareil Android réel. Aucune publication directe n'est réalisée par ce lot.
