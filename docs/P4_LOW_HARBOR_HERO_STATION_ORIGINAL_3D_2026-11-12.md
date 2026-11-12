# P4 — Station de signalisation Harbor en 3D originale sur Android Low

**12 novembre 2026 — Code GitHub, pas de publication Roblox ni de mesure FPS Android.**

## Audit

La station monumentale `HarborHero` est assemblée avec des pièces
rectangulaires natives (fondations, deux jambes, traverse, cabine, toit,
mât, flèche, câble et contrepoids, renforts, rambardes et panorama).
`HarborHeroStationMeshKit.lua` contient déjà un modèle original
créateur approuvé `73237902371094`, 7 MeshParts, avec 4 pièces
statiques, 1 Radar, 1 Cable et 1 Weight. Il suit les animations
**réelles** `arena-hero-motion`, et conserve la lentille
`HarborHeroStormLens` native. Le modèle était réservé à Medium/High,
et Android Low n'affichait que les primitives.

## Livraison

- `BUDGET.Low={count=1,distance=170,retain=22}` : un seul
  original de 7 MeshParts à moins de 170 studs de la traverse,
  marge de maintien de 22 studs.
- `OptionalVfxPressure >= 1` désactive cette option sur Low
  et restaure les pièces natives ; Medium/High inchangés.
- `OriginalHarborHeroStationLocal.ChildRemoved` déclenche
  immédiatement `dismount()` si le gestionnaire de budget
  évince le modèle, sans attendre le sampler de scène.
- `dismount()` remet les transparences natives avant
  de détruire le modèle ; `entry=nil` et `disposing=true`
  empêchent les callbacks récursifs.
- Aucun nouvel import, source, collision, éclairage, boucle
  `RenderStepped` ni `RemoteEvent`. La station originale
  reste décorative ; les mouvements Radar/Cable/Weight restent
  pilotés par le système d'animation existant.

## Validation Roblox Engine / Android requise

1. Charger Harbor, qualité Low, pression zéro, se placer
   à moins de 170 studs de la station : vérifier 7 vrais
   MeshParts à la place des grandes pièces primitives.
2. Vérifier le radar, le câble et le contrepoids animés,
   ainsi que la lentille lumineuse native.
3. Simuler pression graphique 1 puis 2, suppression du
   modèle dans `OriginalHarborHeroStationLocal`, perte de
   source et streaming intermittent : les natives doivent
   revenir immédiatement ou au prochain échantillon pour
   les sources absentes.
4. Vérifier `LocalHarborHeroStationMeshCount` (si exposé
   dans la version de scène), les erreurs client, le nombre
   de MeshParts et l'absence de collision.
5. Mesurer FPS, p95, mémoire et captures sur un appareil
   Android Low réel. Les tests source GitHub ne prouvent
   pas ces performances.
