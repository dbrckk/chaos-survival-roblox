# P4 — Sous-structures sculptées de vraies passerelles sur Android Low

**12 novembre 2026. Statut : GitHub source. Roblox Engine et la place publiée ne sont pas encore validés.**

## Audit réel du dépôt

- `ArenaVariants.lua` et `MapBuilder.lua` fabriquent **16 véritables dalles de
  promenades** et **10 dalles de Sky Spine** par arène, issues du serveur :
  plateformes physiques, attribut `ChaosPermanentRoute`, sauts R15 de 2,4 studs.
  Sur Classic, les dalles de promenade font environ **22,85 × 12 studs**.
- `PremiumRouteMeshKit.lua` couvrait au maximum **une passerelle d'un seul
  segment 3D** sur Low, et son sous-châssis `OriginalUnderdeckChassis`
  avait **`underdecks=0`**. Cela laissait la sous-face des vraies grandes
  traversées en blocs simples, même lorsque l'asset créateur approuvé existait.
- Le même asset d'underdeck `84582262145054` est approuvé, **3 072
  triangles / sept MeshParts** par import à sept matériaux. La source est
  déjà importée/sanitisée côté serveur dans `PremiumRouteMeshTemplates`.
- `UnderstructureBeamMeshKit`, autre propriétaire de poutres décoratives
  authentiques, gardait son modèle sur Android Low même sous
  `OptionalVfxPressure=1/2`. Une MeshPart supprimée et un clone éjecté
  pouvaient attendre le prochain échantillon LOD avant la restauration native.

## Modifications effectives

1. **Budget Low de la route : deux dalles-joints 3D maximum sur une passerelle
   et un seul châssis inférieur de sept MeshParts** sur une route physique
   sûre, proche de la caméra (distance Low de **100 studs**, rétention 18).
   Deux dalles 3D restent autorisées en parallèle ; il n'y a aucune
   augmentation du nombre de *passerelles* Low (une).
2. Le châssis de sous-face sur Low exige `OptionalVfxPressure=0` :
   le premier niveau de pression graphique fait tomber le plafond
   des passerelles et du châssis à zéro, sans modifier les vrais sols.
3. Le châssis est réservé à une vraie plateforme **allongée** :
   longueur au moins **19,5 studs**, largeur au moins **9,5 studs**,
   rapport longueur/largeur au moins **1,35**, source compatible
   avec une mise à l'échelle uniforme au moins **0,56**.
   Le précontrôle des dimensions et des **sept MeshParts d'origine**
   intervient **avant** que le seul emplacement Low soit dépensé.
4. Une plateforme `ChaosSkybridge` avec mécanisme de fermeture
   n'obtient pas ce sous-châssis Low ; son matériel d'origine reste
   prioritaire. La variante **Harbor n'obtient pas ce châssis Low**,
   car elle possède déjà un caisson portuaire original indépendant.
   Les coques carrées des grands decks restent réservées aux kits
   spécifiques `PremiumLargeDeckHullMeshKit`.
5. `LocalOriginalLongCradleMounted` reste le signal de propriété de
   la grande sous-structure sur les routes Sky Spine et Promenade.
   Le châssis de la route est rejeté avant montage lorsque le
   LongCradle existe déjà. **Si un LongCradle apparaît après coup**,
   l'écoute de ce signal retire immédiatement les MeshParts de
   la route, restaure le panneau natif et laisse le prochain
   échantillonnage du propriétaire de routes remonter seulement
   la couverture supérieure 3D, **sans doublonner les 3K triangles**.
6. Les sculptures sous plateforme sont soudées par les contraintes
   cosmétiques déjà existantes au **vrai collider serveur**. Aucun
   nouveau sol jouable, colliseur, danger, API, modèle source ni boucle
   caméra n'a été ajouté.
7. `UnderstructureBeamMeshKit` garde ses plafonds **1/4/12**
   pour Low/Medium/High sur les vraies poutres marquées, mais
   retire l'unique modèle Low dès `OptionalVfxPressure>=1`.
   Le kit exige désormais exactement **sept MeshParts** sur Low.
8. Retrait d'un modèle par `OriginalUnderstructureBeamsLocal`,
   disparition de la vraie poutre native, perte de l'asset source,
   retrait d'une MeshPart clonée ou source : chaque événement
   restaure immédiatement la transparence native, déconnecte
   ses abonnements et supprime le modèle facultatif.
9. Le tout reste dans les deux dossiers `PremiumRouteMeshLocal`
   et `OriginalUnderstructureBeamsLocal`, déjà comptabilisés une
   seule fois dans le budget de **440 Parts** sur Android Low
   et le contrôle coopératif `VisualBudgetRules`. Les règles
   Medium/High de densité de passerelles et d'underdecks sont conservées.

## Vérifications Roblox Engine / Android à réaliser

- Sur une vraie promenade non-Harbor, activer Android Low en pression
  zéro, approcher un pont de **20–23 studs** à moins de 100 studs.
  Vérifier dans `PremiumRouteMeshLocal` la présence éventuelle de
  **deux segments** et d'**un seul** `OriginalEngineeredUnderdeck3D`
  si la source et la couverture mesurée satisfont les préconditions.
- Vérifier **aucune** sous-face de route Low supplémentaire sur
  les 12×12 petites dalles, les coques 18×18, les `ChaosSkybridge`,
  Harbor, ni si la source n'a pas exactement sept MeshParts.
- Sur une promenade avec LongCradle 3D, déclencher ou retirer
  `LocalOriginalLongCradleMounted` et vérifier l'absence complète
  de deux sous-châssis 3D superposés. La surface de collision
  et les avertissements doivent rester visibles.
- Passer `OptionalVfxPressure` de 0 à 1 puis 2 :
  les modèles facultatifs route et poutre doivent être retirés
  et le rendu natif doit revenir. Tester aussi
  `CollapsePhase`, `BridgeShutterPhase`, rétrécissement
  et remplacement de carte.
- Sur un modèle de poutre `OriginalUnderstructureBeam`,
  décharger la pièce native, supprimer une MeshPart, retirer
  l'asset modèle source et éjecter le modèle local : aucune
  forme native ne doit rester masquée indéfiniment.
- Relever les vrais **FPS moyens/p95, mémoire et captures** sur
  Android Low avant/après. Les tests CI sont uniquement
  des contrats sur le code source et non des mesures moteur.

Les assertions de `tools/verify_original_3d_budget_census.py`
couvrent l'asset approuvé, le budget Low, la géométrie
des routes serveur, les priorités de propriétaires et la
restauration au premier niveau de pression graphique.
