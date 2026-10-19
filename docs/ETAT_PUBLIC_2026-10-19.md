# Chaos Survival — état du lancement public (19 octobre 2026)

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

À la dernière inspection, **l'icône et la miniature publiques restent des illustrations par défaut de Roblox** ; leur présence dans la fiche ne signifie pas qu'elles sont finalisées. Deux **illustrations promotionnelles conceptuelles** de format `1024×1024` et `1920×1080` ont été importées dans les éléments Canva du propriétaire, mais **ne sont pas encore téléversées dans Roblox**. Avant import, vérifier qu'elles illustrent honnêtement des éléments présents dans le vrai jeu et que Roblox les accepte. Ne pas les présenter comme des captures natives du gameplay.

## Point de sécurité

Le 19 octobre, le réglage **Activer l'accès Studio aux services API** a été revérifié à **désactivé** sur l'expérience publique (aucun changement nécessaire). C'est la configuration préconisée par [Roblox pour éviter de toucher aux DataStores de production pendant les tests Studio](https://create.roblox.com/docs/cloud-services/data-stores).

## État du binaire jouable

Le commit `4f07961d6a786fd019ddac52854ec9dd5e361195` du 19 octobre avait **Build Validation** et les tests **Roblox Open Cloud Engine Tests** verts. Cela prouve seulement la compilation et certaines vérifications moteur. **Aucun lien audité entre ce commit et la version réellement servie aux joueurs n'a encore été établi.**

- Ne pas déclencher automatiquement la publication Rojo sur le place public.
- Respecter les contrôles du workflow `publish-roblox.yml` : certification du **même SHA** par le Release Candidate Gate, test Studio authentifié et vérifications manuelles réelles.
- Vérifier version publiée et comportements sur Android et ordinateur ; ne pas prétendre qu'ils ont été validés.
- Le nom antérieur « Visual QA » et l'historique des versions 64 et 65 imposent d'inspecter le place existant avant tout déploiement supplémentaire.

## Suite à donner

1. Remplacer les placeholders par une vraie icône et une miniature représentatives du gameplay ; vérifier l'issue de la modération Roblox.
2. Examiner le place actuellement servi, puis valider sur appareil physique et petit groupe réel ; consigner les preuves.
3. Mettre en place un staging séparé avant de certifier et pousser le dernier SHA GitHub.
4. Évaluer l'accès Kids/Select ultérieurement seulement après confirmation des conditions Roblox, sans engager de Robux sans décision explicite du propriétaire.

Références : [procédure de mise en ligne 1.0](MISE_EN_LIGNE_1_0.md), [checklist de release](../RELEASE_CHECKLIST.md), [ticket de certification #79](https://github.com/dbrckk/chaos-survival-roblox/issues/79).
