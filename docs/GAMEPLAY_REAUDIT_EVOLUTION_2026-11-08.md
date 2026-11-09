# Chaos Survival — nouvel audit et plan d'évolution (8 novembre 2026)

## Référence et honnêteté des preuves

- Dépôt réel : `dbrckk/chaos-survival-roblox`, branche de référence `main`, SHA `86f11878767a30295b46260d3cb9ac73fe875d2e`.
- Nouvelle branche de réalisation : `feat/bot-showdown-finale-20261108`.
- En parallèle, PR **#702** (`fix/ai-collapse-state-lifecycle-20261108`, tête observée `a3e8a4919d64473397e97a035c93b104f30926da`) est ouverte : Freeze, JumpShock, évacuation de plateformes, reprise de navigation et couverture d'avertissement.
- Audit **source**, pas une nouvelle session Android ou Roblox Engine. Aucune mesure FPS, p95, CPU, survie effective de bots, D1/D7 ou succès de publication n'est disponible pour cette branche. La dernière place publique ne doit pas être présumée à ce SHA.

## 1. Constats confirmés dans le code

**Base fonctionnelle :**
1. Le projet possède la boucle lobby → vote → ready → manche → résultat → récompenses → lobby (`src/server/init.server.lua`, `RoundResultState.lua`, `RoundSettlement.lua`).
2. Cinq variantes Classic/Towers/Crossroads/Orbital/Harbor, onze catastrophes, parcours physiques, mécanismes par arène, progression/collectibles et spectateur existent en source. Leurs qualités perçues et temps de chargement ne sont pas prouvés par cet inventaire.
3. Les sept sièges de bots sont pris en charge dans `RoundResultState.lua` (`MAX_AI_SEATS=7`). L'ancienne restriction à trois sièges mentionnée dans l'audit du 6 novembre est **corrigée**.
4. Les compromis entre catastrophe, navigation physique, pression visuelle et nombre de bots sont détaillés dans `docs/GAMEPLAY_AUDIT_ACTION_PLAN_2026-11-06.md` et `docs/PERFORMANCE_AUDIT_EVOLUTION_PLAN_2026-11-06.md`.

**Défaut gameplay confirmé, corrigé dans cette branche :**
- `runDisasterSet` stoppait la simulation après disparition du dernier humain, même si des survivants IA restaient, après un seul affichage et une attente de 2,25 s.
- Le spectateur voyait la promesse « WATCH THE SURVIVORS » sans finale réelle ; la victoire IA finale ne pouvait pas émerger des derniers dangers. Une échéance de partie coupée n'est pas équivalente à une vraie compétition.

**Risques encore ouverts :**
- P0 : PR #702 non fusionnée / tests moteur sur son dernier SHA manquants. Ne pas confondre succès du code et validité en jeu.
- P1 : timing physique des sauts JumpShock, concurrence Meteor/Bomb/collapse et Freeze à confirmer en vraie session 1 humain + 7 bots.
- P1 : lisibilité du premier objectif et de deux choix tactiques par arène, sur Android portrait et paysage.
- P1 : charge GPU des meshes/PBR/couches cosmétiques ; aucun FPS Android observé pour ce lot.
- P2 : actualisation des documents très nombreux et consolidation des workflows historiques, sans supprimer un chemin actif.

## 2. Lot appliqué — finale de bots et spectacle court

**Fichiers modifiés :**
- `src/server/init.server.lua` : après la dernière élimination humaine, conserver la même manche serveur et ses vrais dangers pendant **4 secondes maximum en solo**, **6 secondes maximum en multi**, bornées par le temps restant. Une échéance `os.clock()` empêche qu'un cycle serveur retardé n'allonge artificiellement la finale ; la dernière attente est plafonnée au temps restant. Quitter immédiatement si plus aucun bot vivant ou plus aucun joueur connecté. Le mode Studio d'analyse IA garde son comportement actuel.
- `src/server/init.server.lua` : conserver l'horloge officielle `RoundState.seconds=t` pour le rendu des catastrophes et ajouter `botShowdown=true`, `botShowdownSeconds` (4/6 s) pour la finale. Aucun nouveau passage de boucle, RemoteEvent, Part, collision, accélération ni invulnérabilité.
- `src/client/spectator.client.lua`, `src/client/init.client.lua` et `src/shared/CoreLocalization.lua` : annoncer « FINALE DES BOTS » / « FINAL BOT SHOWDOWN » dans le HUD principal FR/EN ; la carte spectateur Android, très étroite, garde le nom de la cible + survivants + temps, sans répéter un titre long qui réduirait fortement la taille du texte.
- L'économie, les conditions de survivant/champion, le roster serveur, les durées initiales de manche, l'intermission et le résultat restent inchangés.

**Objectif produit :** transformer une sortie abrupte en séquence courte de compétition visible, sans bloquer la prochaine manche. Les bots sont tuables par les vraies catastrophes pendant cette fenêtre. La finale ne simule pas une mort ni un classement.

## 3. Plan d'évolution après le lot courant

| Ordre | Lot | Conditions de réception |
| --- | --- | --- |
| P0 | Vérifier la finale spectateur et les résultats IA sur moteur Roblox | Un humain éliminé voit les bots jouer réellement, changement de cible possible, fin bornée, résultat serveur exact, aucun gel de manche |
| P0 | Relire et valider puis fusionner #702 | Freeze/JumpShock/collapse concurrentes en moteur, aucun faux saut défensif, aucun bot bloqué sans récupération active, pas de régression de coût |
| P1 | Navigation/IA mesurée à 1+7 bots | 5 arènes × changements de route et dangers; aucune immobilité inexpliquée >3 s; réponse aux menaces et CPU serveur documentés |
| P1 | Deux décisions tactiques par carte, vraiment utiles | Le joueur peut choisir deux routes/actionnements physiques et comprend leur conséquence sans texte complexe |
| P1 | Lisibilité Android et LOD priorisant gameplay | Dangers et sols de saut restent lisibles; FPS médian cible ≥30/p95 ≤40 ms sur appareil réel, à mesurer et non présumer |
| P2 | Rejouabilité et progression | Résultat, raison de défaite, conseil utile, maîtrise et défi secondaire vérifiables; métriques de retour réellement observées |

## 4. Matrice d'acceptation du lot finale

1. **Solo, 1 humain + 7 bots** : humain mort avec au moins un bot vivant et ≥4 s à jouer → jusqu'à 4 secondes d'action physique réelle des IA et timer de finale exact; puis état `result`.
2. **Multi, 4 humains + 4 bots** : dernier humain éliminé avec bots survivants → jusqu'à 6 secondes d'action réelle, compteur cohérent côté spectateur, aucune réapparition d'un humain dans le roster actif.
3. **Tous les bots meurent** pendant la finale → résultat avancé sans attendre la fin inutilement; `survivorsAlive` et champion dérivés exclusivement du serveur.
4. **Le timer normal est presque terminé** → finale plafonnée par `t`; aucune prolongation de `RoundEndsAt` ou de la durée d'un danger.
5. **Tous les clients quittent** → sortie anticipée sans immobiliser le serveur. Un retardataire spectateur ne peut pas rallonger l'échéance.
6. **Mode Studio IA visuel** → fonctionnement historique de l'observation complète.
7. **Mobile FR/EN, portrait/paysage** → carte de spectateur existante lisible, affichage de la finale + survivants + temps, caméra sur un vrai Humanoid vivant.
8. **Résultats** → slots IA 1–7, dernier bot vivant, zéro survivant, ancien joueur éliminé et joueur tardif sans fausse récompense.
9. **Performance** → 1/4/7 bots avec mêmes scènes et Android de référence ; absence de nouvelle boucle/Instance en source ne remplace pas la mesure FPS et temps serveur.

## 5. Publication et sécurité

- Les remplacements ont passé des contrôles structuraux ciblés de source : points d'insertion uniques, ancienne coupure supprimée, compte à rebours visuel séparé et attente bornée par une échéance monotone. **Ces contrôles ne sont pas des tests Roblox Engine.**
- Pas de nouveaux tests unitaires pendant l'itération, conformément à `AGENTS.md`. Avant fusion ou publication importante : utiliser la validation moteur et le jalon release exact-SHA existants, puis vérifier la caméra et le résultat sur Android réel.
- **Aucune publication Roblox exécutée** par ce document / ces commits. Fusion de PR et publication de place sont deux opérations distinctes.
- Retour arrière : revert des quatre fichiers modifiés ou revert du commit de fusion si le jeu a une régression ; préserver les releases publiques existantes jusqu'à preuve de réussite.

## 6. Lien de test

Place publique connue dans le dépôt : https://www.roblox.com/games/95351659174730/Chaos-Survival

Ce lien identifie la place publiée, **pas** la version de la branche en attente de validation. Vérifier le SHA effectivement publié via les workflows avant tout test de la nouvelle finale.

### Correction complémentaire — horloges et HUD cohérents

Le premier jet remplaçait `RoundState.seconds` par le compte à rebours 4/6 s. Or le client utilise ce champ pour présenter le rythme réel de la manche et ses dangers : l'écrasement pouvait provoquer une régression de lisibilité. Corrigé : `seconds` reste la durée physique originale, `botShowdownSeconds` est un champ distinct pour la présentation de la finale.

Dans `src/client/init.client.lua`, la finale est détectée avant `CoreLocalization.hazardTitle` : auparavant la traduction de son titre était remplacée par le nom de la catastrophe. Le HUD affiche maintenant le compte à rebours court, comme la carte spectateur, sans changer la durée officielle. `round-focus.client.lua` masque déjà sa barre aux joueurs éliminés.

**À vérifier dans Roblox Engine :** catastrophe toujours calée sur son horloge serveur, transition finale/résultat sans flash de HUD et décompte cohérent en FR et EN.

### 9 novembre — durée monotone et lisibilité Android

La version précédente comptait 4/6 **tours de boucle** espacés par `task.wait(1)`. Sous contention serveur, `task.wait` peut reprendre après plus d'une seconde et la finale durer plus que promis. Désormais, l'entrée dans la finale pose une seule échéance monotone `os.clock() + min(remainingRoundTicks, solo ? 4 : 6)`. Chaque tick calcule le compte à rebours avec `ceil(deadline - os.clock())`, sort dès que l'échéance est atteinte et plafonne l'attente finale au budget encore disponible. Les manches ordinaires gardent leur boucle et attente historiques ; aucune boucle, RemoteEvent ni coroutine supplémentaire.

Le top HUD restant visible pendant `phase="round"`, il annonce la finale et son titre FR/EN. Répéter `FINALE DES BOTS` dans le `TextScaled` de la carte spectateur compressait le texte sur Android étroit. La carte donne désormais l'information utile non dupliquée : **cible suivie + survivants + secondes**. Le HUD affiche l'identité de la phase séparément.

**Limite des preuves** : `os.clock()` empêche de prolonger délibérément la finale sous charge, mais l'exécution et le scheduling réels doivent encore être validés sur Roblox Engine. Les horloges UI sont échantillonnées une fois par tick ; elles ne garantissent pas une résolution visuelle milliseconde.
