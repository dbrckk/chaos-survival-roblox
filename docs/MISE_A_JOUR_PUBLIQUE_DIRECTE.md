# Mise à jour directe du jeu public existant — mode playtest (non certifié)

## Cible inchangée

- **Jeu Roblox public :** [Chaos Survival](https://www.roblox.com/games/95351659174730/Chaos-Survival)
- **Universe ID :** `10771083668`
- **Start Place ID :** `95351659174730`
- **Dépôt :** `dbrckk/chaos-survival-roblox`, branche `main`
- **Aucun nouvel univers, aucune autre place, aucun staging.**

Cette procédure répond au choix explicite du propriétaire de mettre à jour **le jeu déjà public**, sans configurer pour le moment un environnement de staging. Il ne s'agit **pas** de déclarer passée la certification 1.0 : le protocole complet dans [RELEASE_CHECKLIST.md](../RELEASE_CHECKLIST.md) et le workflow strict [Publish Roblox Place](../.github/workflows/publish-roblox.yml) restent inchangés.

## Préconditions vérifiées automatiquement

Le workflow dédié [Publish Existing Chaos Survival (Public Playtest Update)](../.github/workflows/publish-existing-public-playtest.yml) est **manuel uniquement**. Il refuse toute publication si :

- l'exécution ne part pas de `main` avec une confirmation explicite `PUBLISH_EXISTING_10771083668` et la case de consentement à la publication **non certifiée** ;
- l'univers/lieu configurés dans les variables du dépôt ne sont pas **exactement** `10771083668` et `95351659174730` ;
- le candidat `GITHUB_SHA` ne correspond plus à la tête actuelle de `main` ;
- les workflows `Build Validation` et `Roblox Open Cloud Engine Tests` ne sont pas **SUCCESS sur ce commit précis** pour des événements `push` de `main` ;
- la clé de publication `ROBLOX_API_KEY` manque ou ne possède pas les droits requis sur le jeu ;
- un marqueur réservé au staging se trouve dans les sources.

Aucune simulation d'un résultat Android/Studio `PASS`, aucun contournement de l'ancienne certification, aucune modification des prix, de la classe d'âge ni des pages Creator Dashboard. L'API officielle publie le **fichier Place issu de Rojo sur la place déjà existante**. Le workflow exige le numéro réel de version retourné par Roblox et archive l'empreinte SHA-256 du fichier publié et les métadonnées de publication.

## Sur smartphone Android

Une fois la PR de préparation fusionnée à `main` et les contrôles `Build Validation` / `Roblox Open Cloud Engine Tests` du **nouveau commit de fusion** tous deux verts :

1. Ouvrir **[GitHub Actions — Publish Existing Chaos Survival (Public Playtest Update)](https://github.com/dbrckk/chaos-survival-roblox/actions/workflows/publish-existing-public-playtest.yml)** depuis ton navigateur Android. Activer « Version ordinateur » si le bouton est absent.
2. Appuyer **Run workflow** et sélectionner la branche **main**.
3. Dans `confirm`, saisir exactement `PUBLISH_EXISTING_10771083668`.
4. Cocher `I understand this is a PUBLIC playtest update without physical-device/Studio certification`.
5. Appuyer sur **Run workflow**, attendre la conclusion. Ce clic déclenche **une modification du jeu public existant** ; ne pas faire un deuxième essai aveugle si le résultat est ambigu.

Si le job réussit, ouvrir son **Step Summary** et vérifier le `published_version` positif, le commit, et la preuve de publication. Cette preuve indique `certification=UNCERTIFIED_PUBLIC_PLAYTEST_UPDATE`.

## Contrôle réel immédiatement après publication

- Ouvrir [Chaos Survival](https://www.roblox.com/games/95351659174730/Chaos-Survival) depuis Android, rejoindre une **nouvelle session** ; ne pas supposer que les serveurs déjà actifs changent de code immédiatement.
- Contrôler le chargement du lobby et un parcours complet `vote → ready → round → result`.
- Tester au moins une manche contre 3 IA, y compris une pluie de météorites ou de bombes : leur recherche de trajet doit éviter les **rayons finaux** d'explosion, les bords sans sol et les changements incessants de direction.
- Vérifier que les bots sont toujours étiquetés **AI**, que les signaux ne remplissent pas le chat et que la sauvegarde, l'interface et le FPS Android restent corrects.
- Demander au vrai testeur qui avait jugé les bots trop simples de comparer : difficulté, naturel, interactions, envie de rejouer (chacune sur 5).

## Si le jeu se comporte mal

Ne pas tenter de corriger en envoyant des commits au hasard. Examiner d'abord l'historique des versions de la place dans le **Creator Dashboard du bon univers** et sélectionner une version précédemment connue comme fonctionnelle, conformément à [ROLLBACK_RUNBOOK.md](../ROLLBACK_RUNBOOK.md).

Un workflow `SUCCESS` avec un `published_version` prouve la réception de la publication. Il **ne prouve pas** le bon fonctionnement sur chaque appareil. Un workflow `FAILED` peut néanmoins nécessiter une vérification de l'historique des versions si une requête de publication a atteint Roblox avant un échec de réponse.

## Configuration et secrets

- Variables Github `ROBLOX_UNIVERSE_ID` et `ROBLOX_PLACE_ID` : seules les valeurs de la cible publique ci-dessus sont autorisées.
- Secret GitHub `ROBLOX_API_KEY` : permission **`universe-places:write` uniquement pour l'univers public sélectionné**, jamais coller son contenu dans le chat ni dans un fichier.
- Ne jamais utiliser les anciens identifiants `8998396328` / `101933452561772` pour ce jeu.
