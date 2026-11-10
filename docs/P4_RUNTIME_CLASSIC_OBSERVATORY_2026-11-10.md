# P4 — Intégration du vrai observatoire Classic à deux paraboles

**10 novembre 2026 — source intégrée uniquement, pas de publication publique Roblox Place.**

## Preuve du modèle

Le générateur original `tools/generate_original_signature_classic_observatory.py` exporte un mât à douze facettes, une tête en relief, un pont ferroviaire profilé et deux authentiques réflecteurs paraboliques creux, chacun avec une surface concave, une coque arrière, une bague torique complète, douze renforts rayonnants et un moyeu réception. La source est un unique modèle sculpté avec **6 664 triangles**, **110 groupes de géométrie**, **sept matériaux PBR**. Ses dimensions OBJ sont **9,105 × 15,0875 × 1,03 studs source** (normalisation uniforme à l'échelle 1/4 pour respecter les limites de Sculpture). La source et les sept sous-meshes glTF/UV/normales/tangentes ont été validés par [GitHub Actions #42787663042](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42787663042), puis Roblox a renvoyé un Model propriétaire **112493873850364**, **Moderation: Approved**.

## Intégration sécurisée

Le serveur `src/server/PremiumClassicSignatureObservatoryAssets.lua` charge tardivement uniquement cet asset réel via `AssetService.LoadAssetAsync`, le passe par `OriginalMeshScenery.sanitize` et vérifie dimensions / nombre de vrais MeshParts / absence de collisions. L'import est cosmétique, ne bloque pas la première manche, les bots et les catastrophes.

Le kit `src/client/ApprovedClassicSignatureObservatoryMeshKit.lua` accepte uniquement `GeneratedMap/Arena` de variante **Classic**, la véritable `ArenaSignatureMegastructure` nord, un socle jouable de taille normale, **sept cibles natives** exactes (y compris dimensions, classe Cylinder et CFrame tourné à 90° pour les récepteurs) et la présence des cinq pièces encore utiles : les deux buttresses, les deux spars et `ServicePanel`. Aucune native n'est cachée si un de ces tests échoue.

Le Model est clonné, mis à l'échelle uniquement avec `Model:ScaleTo` et orienté au centre exact de l'union native, environ **36,5 × 60,35 × 4,2 studs**, avec sept MeshParts `Anchored`, `Massless`, `CanCollide/CanTouch/CanQuery=false`, `CastShadow=false`. Les sept natives passent ensemble à `Transparency=1` uniquement une fois le Model complet dans le dossier local. Aucun collider de joueur, RemoteEvent, RenderStepped ou Heartbeat supplémentaire.

## LOD et retour aux primitives

Le kit est appelé par la seule cadence caméra de `scenery-lod.client.lua`, et `ApprovedClassicSignatureObservatoryLocal` participe au budget 440/680/900 de `VisualBudgetRules.lua`. Low = 0 modèle ; Medium/High = au maximum 1 modèle original de sept MeshParts, portée 440/615 studs, rétention 26. En pression GPU 1 le modèle Medium est retiré, en pression 2 tous les modèles sont retirés. Le client restaure les sept Parts natives en cas d'import manquant, de rétrécissement du terrain, de streaming incomplet, de changement de carte, de destruction de Model ou de transformation inattendue. Compteurs réels : `LocalApprovedClassicObservatoryCount` et `LocalClassicSignaturePrimitivePartsReplaced`.

## Limites

**Ce modèle améliore sept pièces cosmétiques du monument Classic, et non 7/23 pièces des stations périphériques.** Le taux de 69,57 % déjà annoncé ne change pas. Les cinq grandes mégastructures disposent à présent d'une intégration source 3D approuvée, mais la validation Roblox Engine/Android, les screenshots du rendu réel, les mesures FPS et la publication publique sur un commit exact restent à effectuer.
