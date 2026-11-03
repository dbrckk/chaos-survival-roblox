# Chaos Survival — réparation réelle de la release des 4 modèles 3D approuvés

**3 novembre 2026.** Cible : publication de l'architecture d'arènes 3D originale, sans masquer un danger ni enfreindre les budgets Android.

## Preuves avant correction

- Quatre véritables packages Roblox Model du propriétaire ont été importés et modérés **Approved** : [GitHub Actions #41629861517](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41629861517). IDs modèle : observatoire `132020956214241`, fret `88725004643299`, turbines `84217436280282`, communications `135791763112202`.
- L'intégration initiale a été fusionnée en `b84fcbf`, puis la tentative de publication a utilisé le SHA `edd1b2590110ca0342431803ac06d2054b35bdfe`.
- [Les cinq suites Roblox Cloud #41630970496 ont réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41630970496) sur cet ancien SHA, mais [Build Validation #41630960261 a échoué](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41630960261), au contrôle « Audit persistent local visual folders » : le dossier `ApprovedDistrictFacadesLocal` manquait dans `VisualBudgetRules.LocalFolders`. Le workflow public [#41630947226](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41630947226) a donc **refusé la publication**. Il serait incorrect d'annoncer la dernière architecture en ligne à ce stade.
- Une implémentation doublon plus ancienne, PR #586, a été fermée **sans fusion** après inspection de la version principale. Continuer uniquement les noms/module/profils utilisés par la vraie `main` : `PremiumDistrictFacadeAssets` et `PremiumDistrictFacadeMeshKit`.

## Corrections effectives du candidat

1. **Budget Android réel** : `ApprovedDistrictFacadesLocal` rejoint les conteneurs recensés par le contrôle visuel. Chaque MeshPart importée compte contre les caps du jeu, pas seulement le nombre de modèles. Pas de hausse des caps.
2. **Import serveur non bloquant** : une seule file asynchrone charge les quatre nouveaux modèles validés, plutôt que quatre appels AssetService simultanés venant s'ajouter à deux voies de skyline et trois imports de plateforme déjà concurrentiels. Trois tentatives progressives ; une défaillance ne bloque pas les autres profils ni l'entrée en jeu.
3. **Roblox provenance vérifiable** : le registre passe à 13 vrais modèles `Approved` avec preuve de source et de run. Le CI régénère les quatre sources originales, vérifie leurs UV, tangentes, bounds et compare les quatre véritables IDs actifs à ceux du registre, tout en gardant les vérifications des neuf anciens.
4. **Robustesse visuelle / StreamingEnabled** : les vrais volumes 3D sont cachés immédiatement si leur bâtiment, porte, rotation ou taille se désynchronisent ; le passage LOD nettoie les pièces. La première réduction de la surface de jeu déclenche un retrait immédiat des meshes, même avant le tick suivant.
5. **Vue Android** : les mêmes plafonds **Low 1 / Medium 3 / High 6** et distances d'entrée **130 / 190 / 255 studs** sont conservés. Sélection orientée vers l'avant et très légère hystérésis de sortie (16 / 22 / 28 studs) pour éviter les remplacements répétitifs de MeshParts. On traite les modèles **après** le LOD des bâtiments natifs, afin de respecter la visibilité déjà choisie.
6. **Aucun changement du gameplay** : les colis/surfaces serveur, textes de danger, bots, parcours, animations de catastrophe et DataStores ne changent pas. Les assets sont toujours contrôlés sur le serveur, dans l'inventaire du propriétaire, et les copies locales sont `Anchored`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`.

## Garde de publication

Pour l'exact nouveau commit sur `main` : **Build Validation complet** (vrais modèles 3D et registre compris), **cinq suites moteur Roblox Cloud**, puis le publisher propriétaire existant seulement si les deux workflows sont verts au **même SHA**. Si `main` avance ou qu'une validation échoue, refuser la publication.

**Limite permanente non contournée** : ces contrôles n'attestent pas la fidélité du rendu 3D, l'orientation des glTF, la lecture des signes, la fluidité, la température ou les FPS sur un véritable Android. Une campagne Studio/Android sur les cinq arènes avec Low/Medium/High reste nécessaire pour déclarer le niveau AAA final.
