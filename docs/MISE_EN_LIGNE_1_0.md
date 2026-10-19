# Chaos Survival 1.0 — procédure de lancement public

Ce guide prépare la **mise à disposition réelle sur Roblox**. Il ne doit pas
être interprété comme une certification automatique : le code compilé n'est
pas nécessairement celui qui tourne sur le jeu public.

**Expérience Roblox publique déclarée par le propriétaire :**
- Universe : `10771083668`
- Place de départ : `95351659174730`
- [Tableau de bord Creator](https://create.roblox.com/dashboard/creations/experiences/10771083668/overview)
- [Place](https://create.roblox.com/dashboard/creations/experiences/10771083668/places/95351659174730/configure)

Vérifier ces identifiants dans le tableau de bord **avant** toute publication.
Ne jamais utiliser l'expérience publique comme cible de staging.

## 1. Récupérer le paquet exact (sans publication)

1. Ouvrir [Build Validation](https://github.com/dbrckk/chaos-survival-roblox/actions/workflows/ci.yml)
   et choisir une exécution **réussie sur `main`**, pour le même SHA que le
   commit candidat.
2. Télécharger l'artefact GitHub Actions `chaos-survival-place` :
   - `ChaosSurvival.rbxlx` : fichier de scène Roblox ;
   - `ChaosSurvival.rbxlx.sha256` : contrôle d'intégrité ;
   - `candidate-provenance.txt` : SHA exact et état **non certifié/non publié**.
3. Vérifier que `source_sha` correspond au commit choisi. Sous Windows :
   `Get-FileHash .\\ChaosSurvival.rbxlx -Algorithm SHA256`; comparer le
   résultat au digest du fichier `.sha256`. Sous Linux/macOS :
   `sha256sum --check ChaosSurvival.rbxlx.sha256`.
4. Ouvrir le `.rbxlx` avec un Roblox Studio **authentifié** pour l'examiner.
   Un fichier compilé n'est pas une version publiée, jouable sur Android.

## 2. Créer un staging véritablement privé

**Blocage actuellement identifié :** d'anciens déploiements de test ont
visé l'expérience publique (versions 64 et 65). Examiner son historique de
versions, sans restaurer à l'aveugle.

1. Créer une **autre expérience** Roblox privée avec un **autre Universe ID**
   et un **autre Place ID** (pas un lieu supplémentaire dans le jeu public).
2. Créer une clé Open Cloud limitée à cette nouvelle expérience uniquement.
3. Dans les paramètres GitHub Actions du dépôt, renseigner :
   `ROBLOX_STAGING_UNIVERSE_ID`, `ROBLOX_STAGING_PLACE_ID` et le secret
   `ROBLOX_STAGING_API_KEY`. Ne jamais divulguer la clé dans une discussion.
4. Vérifier que les deux IDs diffèrent des IDs publics et que seuls les
   comptes autorisés peuvent accéder au staging. Exécuter
   [Roblox Visual Staging (isolated)](https://github.com/dbrckk/chaos-survival-roblox/actions/workflows/roblox-visual-staging.yml).
5. **Seule** une publication staging réussie, avec `versionNumber` et
   métadonnées vérifiées, prouve que la version test est déployée.

Instructions détaillées :
[staging isolé](ROBLOX_VISUAL_STAGING.md).

## 3. Valider le jeu dans son vrai environnement

Utiliser le **même SHA** pour les preuves de validation :

- [ ] Authenticated Roblox Studio E2E : 4 clients, 4 arènes,
      lobby → vote → READY → ROUND → RESULT.
- [ ] Android Roblox natif : navigation tactile, HUD, réglages d'accessibilité,
      dangers et mode spectateur.
- [ ] Bureau : déplacements, captures, transitions, aucun message d'erreur bloquant.
- [ ] Au moins 30 minutes de jeu sur Android : FPS, chauffe, RAM,
      dégradation progressive et changements d'arène.
- [ ] Déconnexion/reconnexion : Coins, XP, quêtes, récompenses quotidiennes,
      cosmétiques, rapid rejoin et erreurs DataStore.
- [ ] Catastrophes simples et Double Chaos : avertissements compréhensibles
      même sans son et aucun avantage pay-to-win.
- [ ] Petit test réel avec des joueurs autorisés ; corriger les problèmes
      bloquants puis **refaire** les vérifications sur le SHA corrigé.

Rapports : [checklist de certification](../RELEASE_CHECKLIST.md),
[protocole Android](ANDROID_QA_PLAYTEST.md),
[rapport Studio](../studio/PLAYTEST_REPORT_TEMPLATE.md).

## 4. Compléter les exigences Creator Dashboard / visibilité

À confirmer sur le compte propriétaire et sur la fiche de jeu :

- [ ] Nom définitif, description exacte, genre, icône, miniatures, captures
      représentatives **du vrai jeu**, traduction et permissions de collaboration.
- [ ] Questionnaire **Content Maturity & Compliance** rempli fidèlement ;
      contrôler la classification attribuée et l'audience autorisée.
- [ ] Vérification/ancienneté du compte nécessaires pour publier, selon
      l'audience choisie ; pas d'hypothèse sur le statut du compte.
- [ ] Si l'objectif est **tous les âges**, confirmer les conditions
      supplémentaires Roblox (vérification d'identité adaptée, 2FA,
      ancienneté d'abonnement ou frais applicables, évaluation Kids/Select,
      maturité éligible) avant de sélectionner cette audience.
- [ ] Vérifier la conformité des récompenses et des offres cosmétiques.
      Les passes payants restent désactivés tant que leurs IDs et parcours
      d'achat/sauvegarde n'ont pas été testés.

Les conditions de mise à disposition varient selon l'audience (16+,
enfants, régions) et peuvent évoluer. Référence officielle :
[Roblox — Publish games and places](https://create.roblox.com/docs/production/publishing/publish-games-and-places)
et [Content maturity](https://create.roblox.com/docs/production/promotion/content-maturity).

## 5. Certifier puis déployer explicitement

1. Après réussite du Build, des **cinq suites Open Cloud** et du Studio
   E2E sur le SHA final, vérifier **toutes les preuves manuelles**.
2. Sur `main`, lancer manuellement
   [Release Candidate Gate](https://github.com/dbrckk/chaos-survival-roblox/actions/workflows/release-candidate-gate.yml).
   Saisir `CERTIFY` et `PASS` uniquement pour des étapes réellement
   effectuées. Archiver `release-evidence.md`.
3. Vérifier indépendamment que `ROBLOX_UNIVERSE_ID` et
   `ROBLOX_PLACE_ID` ciblent **la bonne expérience publique**, et que
   `ROBLOX_API_KEY` a les droits strictement nécessaires.
4. Depuis `main`, lancer **manuellement**
   [Publish Roblox Place](https://github.com/dbrckk/chaos-survival-roblox/actions/workflows/publish-roblox.yml)
   avec `PUBLISH`. Le flux refuse tout SHA sans certification exacte.
5. Vérifier le numéro de version publié, les artefacts de publication et
   la version effectivement servie aux joueurs. Faire immédiatement un
   contrôle sur Android et ordinateur.
6. Dans Creator Dashboard, **Publish settings → Manage Audience**
   (libellé susceptible d'évoluer), choisir l'audience autorisée et vérifier
   l'accès depuis un compte joueur non membre de l'équipe. Activer
   l'accès public **seulement après** validation.
7. Suivre erreurs, taux d'entrée, premières parties, retours des joueurs,
   fidélisation, performance et incidents. En cas de problème, utiliser
   le [runbook de récupération](../ROLLBACK_RUNBOOK.md).

## Ce qui ne remplace jamais une validation réelle

- Un Build vert prouve la compilation, pas la qualité graphique ni le
  fonctionnement du jeu public.
- Les tests Open Cloud prouvent des comportements moteurs, pas la fluidité
  ni l'ergonomie sur un téléphone donné.
- Une exécution staging échouée/ignorée ne constitue **aucune publication**.
- Un logo ou une capture simulée ne remplace pas les captures Roblox natives.
- Ne pas activer la monétisation tant que le jeu et la persistance ne sont
  pas acceptés.
