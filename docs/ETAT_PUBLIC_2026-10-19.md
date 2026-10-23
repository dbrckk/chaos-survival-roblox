# Chaos Survival — état du lancement public (19 octobre 2026)

## Mise à jour vérifiée — 23 octobre 2026

Le workflow [Publish Existing Chaos Survival (Public Playtest Update), run 39979272056](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/39979272056) s'est terminé avec résultat **success**. Commit exact `2e3daaa97089b1e8d707ee383af5583438628442`, cible Universe `10771083668` / Place `95351659174730`. Les garde-fous (confirmation manuelle, destination, Build Validation, cinq suites Roblox, création du fichier place, requête de publication et archivage des métadonnées) ont tous réussi. L'artefact `chaos-survival-public-playtest-update` conserve les données de provenance et le `published_version`.

Ce résultat **prouve l'acceptation de la mise à jour de playtest par l'API Roblox**, pas une certification visuelle ou ergonomique Android. L'archive du run a été extraite et fournit **`published_version=67`** et **`published_utc=2026-10-23T15:33:30Z`**. Les captures originales et l'absence de régression doivent encore être contrôlées sur un appareil Android réel ; l'API de publication ne certifie pas les FPS ou l'expérience utilisateur. La version 65 précédemment citée est historique. N'inférer aucun déploiement supplémentaire des commits GitHub postérieurs à ce SHA.

> Journal factuel des opérations dans **Roblox Creator Dashboard**. **Rendre la fiche publique ne prouve pas que le dernier code GitHub tourne en production.** Ne pas confondre disponibilité et certification de la version jouable.

## Expérience publique vérifiée

- Propriétaire Roblox : `Drackk_08`
- Universe ID : `10771083668`
- Place ID de départ : `95351659174730`
- [Page du jeu pour les joueurs](https://www.roblox.com/games/95351659174730/Chaos-Survival)
- [Creator Dashboard](https://create.roblox.com/dashboard/creations/experiences/10771083668/overview)
- Nom : **Chaos Survival** ; genre : **Survie**
- **Accès au jeu : Public** (état constaté depuis le compte propriétaire le 19 octobre).
- Public actuellement éligible : utilisateurs **16+** remplissant les conditions de vérification d'âge de Roblox. Ne pas annoncer « tous âges ».
- Double authentification et vérification d'identité du créateur : terminées.
- Questionnaire de classification : soumis ; violence légère et occasionnelle déclarée.
- **Aucun frais de publication Kids/Select payé** et aucune ouverture aux moins de 16 ans confirmée.
- Le genre est défini, mais le sous-genre est `Aucun` et les changements sont bloqués par Roblox jusqu'au **12 novembre 2026**.

## Finition de la fiche

Description enregistrée dans Creator le 19 octobre :

> Survis au chaos ! Vote pour la prochaine catastrophe et affronte 11 dangers dans 4 arènes : lave, météorites, tornades, plateformes instables et bien plus. Joue entre amis ou lance un Solo Rush avec des survivants contrôlés par l'IA. Gagne des pièces et de l'XP, termine des quêtes quotidiennes et débloque des cosmétiques. Aucun cosmétique ne donne d'avantage en jeu. Combien de manches survivras-tu ?

**Mise à jour du 20 octobre 2026 :** une capture de la page du jeu fournie par le propriétaire montre que l'**icône Chaos Survival personnalisée est maintenant visible** sur Android. La **grande miniature reste le placeholder Roblox**, et l'API publique des médias de l'expérience retourne une galerie vide lors du contrôle du 20 octobre. Les deux **illustrations promotionnelles conceptuelles** Canva (1024 × 1024 et 1920 × 1080) existent toujours, mais aucune image de gameplay native n'a été vérifiée. Ne pas présenter ces concepts comme des captures réelles. Aucune nouvelle publication de place n'est requise pour corriger la miniature.

## Point de sécurité

Le 19 octobre, le réglage **Activer l'accès Studio aux services API** a été revérifié à **désactivé** sur l'expérience publique (aucun changement nécessaire). C'est la configuration préconisée par [Roblox pour éviter de toucher aux DataStores de production pendant les tests Studio](https://create.roblox.com/docs/cloud-services/data-stores).

## État du binaire jouable

Le commit `4f07961d6a786fd019ddac52854ec9dd5e361195` du 19 octobre avait **Build Validation** et les tests **Roblox Open Cloud Engine Tests** verts. Cela prouve seulement la compilation et certaines vérifications moteur. **Aucun lien audité entre ce commit et la version réellement servie aux joueurs n'a encore été établi.**

- Ne pas déclencher automatiquement la publication Rojo sur le place public.
- Respecter les contrôles du workflow `publish-roblox.yml` : certification du **même SHA** par le Release Candidate Gate, test Studio authentifié et vérifications manuelles réelles.
- Vérifier version publiée et comportements sur Android et ordinateur ; ne pas prétendre qu'ils ont été validés.
- Le nom antérieur « Visual QA » et l'historique des versions 64 et 65 imposent d'inspecter le place existant avant tout déploiement supplémentaire.

## Suite à donner

1. **Conserver l'icône personnalisée désormais visible** ; installer une miniature authentique et représentative du gameplay, puis vérifier son affichage public après modération.
2. Examiner le place actuellement servi, puis valider sur appareil physique et petit groupe réel ; consigner les preuves.
3. Mettre en place un staging séparé avant de certifier et pousser le dernier SHA GitHub.
4. Évaluer l'accès Kids/Select ultérieurement seulement après confirmation des conditions Roblox, sans engager de Robux sans décision explicite du propriétaire.

Références : [procédure de mise en ligne 1.0](MISE_EN_LIGNE_1_0.md), [checklist de release](../RELEASE_CHECKLIST.md), [ticket de certification #79](https://github.com/dbrckk/chaos-survival-roblox/issues/79).

## Mesure de conversion première session (code GitHub, non publié)

Sur la branche de suivi ouverte le 20 octobre, l'instrumentation `GameAnalytics` enregistre les latences jusqu'au HUD (`TimeToClientReadySeconds`), au premier vote, à la première manche et à sa première fin, ainsi que `SessionExitStage`. Le statut de publication de cette instrumentation doit être vérifié séparément. Ces événements Roblox ne démontrent pas l'absence de bugs et ne sont pas une mesure d'audience tant que des joueurs réels n'ont pas été observés.
