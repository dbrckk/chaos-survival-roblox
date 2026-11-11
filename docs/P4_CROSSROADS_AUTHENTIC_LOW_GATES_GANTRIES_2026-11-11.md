# P4 — Portails Crossroads : sculptures propriétaires sur Android Low

**11 novembre 2026.** Baseline : GitHub `f52215faa67cb3abdac169cdeea48b50f73a9207`. Cette modification n'a pas été publiée sur Roblox.

## Défaut confirmé

Les quatre portails intérieurs de Crossroads utilisent chacun trois formes natives (rail + deux poteaux). Les quatre portiques extérieurs affichent chacun une poutre primitive et un signal d'alerte. Deux modèles originaux modérés **Approved**, de **sept MeshParts** chacun, permettent déjà leur substitution, mais les modules clients imposaient `Low=0`. La réduction tactile réduisait également les éléments Low à zéro.

## Résolution

- Un portail intérieur à **180 studs** maximum de la caméra peut remplacer atomiquement ses trois natives par le modèle propriétaire `127067628128103` (7 MeshParts, 3220 triangles), sans supprimer les fonctions de l'animation locale du rail.
- Un portique extérieur à **180 studs** maximum peut remplacer son corps par le modèle propriétaire `90844491148907` (7 MeshParts) ; le signal `CrossroadSignal` demeure visible.
- Les deux familles sont indépendantes : **14 MeshParts optionnelles maximum supplémentaires** en Low lorsqu'elles sont simultanément visibles, dans le même budget d'instances Android `VisualBudgetRules.LocalFolders`.
- Sur écran tactile, le cap Low reste **1 par famille**. Medium/High conservent leurs restrictions tactiles existantes.
- Dès la première pression visuelle (`stress=1`), chaque cap Low est divisé par deux et arrondi à zéro ; les natives sont restaurées. Le second niveau coupe également toutes ces sculptures.
- Aucune nouvelle ID Roblox, aucune texture, collision, physique, boucle RenderStepped, événement réseau ou import côté client.

## Chargement réellement utile

Les deux anciens chargeurs attendaient 92 s (entrée) et 98 s (extérieur) même lorsque Crossroads était active. Avec le propriétaire événementiel existant `PremiumActiveVariantImportSchedule`, les demandes peuvent maintenant démarrer dès **44 s** et **46 s** uniquement si Crossroads est l'arène officielle. Hors variante active, les échéances restent 92/98 s. Les sources sont toujours contrôlées, nettoyées par `OriginalMeshScenery.sanitize`, chargées par le FIFO global à **2 AssetService maximum**, avec trois tentatives par source et un seul worker existant. Ces délais désignent une date de demande, pas un délai garanti de réception.

## Contrats préservés

Les régressions sources `tools/verify_variant_crossroads_gantry_runtime.py` et `tools/verify_crossroads_entrance_portal_runtime.py` vérifient les vrais assets, l'orientation, les dimensions, la source Approved, la restauration et l'exclusion des collisions. Les workflows actuels sont déclenchés automatiquement par ces fichiers. Aucune création de test unitaire.

La validation source n'équivaut ni à une capture Roblox Studio ni à une certification des FPS Android. Une **nouvelle publication** exige Build Validation et Roblox Open Cloud Engine Tests réussis sur le SHA exact de `main`, puis le workflow existant de publication de la Place publique.
