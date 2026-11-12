# Diagnostic concret — refus de publication Chaos Survival (12 novembre 2026)

## Preuves GitHub Actions, SHA public concerné

Candidat refusé : `db41c28e22d9f6691cf4e2a7678f2eac198e45fe`.

| Run | Constat |
| --- | --- |
| [Publication 43312357642](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43312357642) | Échec dans `Verify green build and real-engine tests for exact main SHA`. Aucune requête POST Roblox effectuée. IDs Universe `10771083668` et Place `95351659174730` confirmés. |
| [Build Validation 43310986429](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43310986429) | L'assertion sur le châssis sous plateforme attendait encore `underdecks=0` en Low, alors que l'implémentation approuvée et pilotée par pression autorise **un** maillage Low. |
| [Engine Tests 43311171571](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43311171571) | `gameplay_world` : **179/181** tests réussis ; échec du fixture de châssis (0 vs 1) suivi d'un probable échec en cascade sur le sol (0 vs 2), car le premier test avorté ne nettoie pas le dossier de source partagé. |
| [Readiness 43311418249](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43311418249) | Analyse read-only échouée, parce que les deux validations du SHA étaient rouges. |

## Corrections de source, sans raccourcir la sécurité

1. La Build Validation exige maintenant les **véritables** plafonds du `PremiumRouteMeshKit` : Low `1`, Medium `2`, High `4` châssis validés et budgétés, sans revenir au faux zéro.
2. Le scénario d'intégration Roblox Engine du sous-plancher utilise les **sept MeshParts de matériaux** qui représentent effectivement le package propriétaire approuvé `84582262145054`. Le scénario précédent n'avait **qu'une** MeshPart : le client rejetait donc correctement la source en Low (`pieces ~= 7`) mais le test prétendait attendre un montage. Le test vérifie toujours le montage réel d'instances Roblox, les pièces non physiques, la disparition au shrink et le retour de la géométrie d'origine.
3. Le deuxième échec du test moteur (sol 3D) peut être un **échec en cascade** : le premier scénario s'interrompt à son assertion `count() == 1` et **ne détruit plus** son dossier `ReplicatedStorage.PremiumRouteMeshTemplates`. Le scénario suivant crée un deuxième dossier avec le même nom ; `FindFirstChild` peut retrouver l'ancien dossier sans `PremiumGroundTile` et refuser de monter le sol. **On ne modifie pas le moteur de rendu du sol sur cette hypothèse.** On corrige d'abord le fixture invalide du premier scénario, puis on exige un nouveau run Roblox Engine réel pour confirmer le résultat.

## État et vérification requise

Ce correctif ne vaut pas publication. Après fusion, exécuter `Build Validation` et `Roblox Open Cloud Engine Tests` sur le **nouveau SHA exact de main**. Si les deux sont verts, le workflow existant `Publish Existing Chaos Survival (Public Playtest Update)` autorise la publication vers l'expérience **existante** : pas de nouvelle Place, pas d'alpha privée. Le workflow refuse toujours les SHA obsolètes et les vrais tests rouges.

Les 86 suites de test moteur existantes ne sont ni supprimées ni remplacées par une vérification factice. Les FPS Android et la certification Studio ne sont pas attestés.

## Relance contrôlée et nettoyage du workflow ponctuel

Le workflow ponctuel `one-shot-repair-and-public-playtest-20261112.yml` a réellement démarré lors du commit `8b7bdee` : [coordinator #43315373261](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43315373261). Il a déclenché la [Build Validation #43315387154](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43315387154), qui s'est arrêtée sur une **deuxième assertion périmée** : `assert len(models) == 102` à la ligne 650, alors que l'asset `district_sidewall_shell` est officiellement le **103e** modèle du registre. La coordination n'a donc **pas** lancé le test moteur ni publié l'expérience. Les garde-fous se sont comportés correctement.

La deuxième assertion est corrigée dans le workflow existant. Le workflow *one-shot* **est retiré du dépôt** après cet essai pour éviter une publication involontaire lors d'une modification ultérieure du fichier. Les trois workflows protégés et manuels d'origine restent inchangés et doivent être déclenchés sur le nouveau SHA `main` :

1. `Build Validation` — vérifier `success` sur l'empreinte exacte.
2. `Roblox Open Cloud Engine Tests` — vérifier les **sept suites de tests réelles**, pas des fixtures sources substituées.
3. `Publish Existing Chaos Survival (Public Playtest Update)` — seulement si les deux validations sont vertes au même SHA, avec les confirmations explicites de publication publique.

Le serveur publieur rejette toujours une nouvelle SHA non validée et un résultat moteur rouge ; les IDs propriétaire Universe `10771083668` et Place `95351659174730` restent inchangés. Le statut du jeu public demeure **non mis à jour** après les échecs documentés.
