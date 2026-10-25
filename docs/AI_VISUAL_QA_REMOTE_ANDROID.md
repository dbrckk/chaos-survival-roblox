# Chaos Survival — 15 captures IA avec Android et GitHub Windows

## But

Ce système complète [AI Visual QA](AI_VISUAL_QA_15_FRAMES.md). Il élimine le
blocage du **runner Windows auto-hébergé absent** en créant temporairement un
Windows GitHub Actions (`windows-latest`). Il y installe la vraie version
officielle de Roblox Studio et la copie du jeu issue du commit vérifié.

Depuis un téléphone Android, le propriétaire peut se connecter à cette session
avec **Tailscale + Microsoft Remote Desktop** (déjà utilisés par le projet).

Une connexion dans **l'interface officielle Roblox Studio** est indispensable
une fois par **nouvelle session Windows éphémère**. Le script attend la preuve
locale de connexion `Authenticated: YES`, puis démarre de lui-même :

1. Une partie locale Roblox Studio avec un personnage spectateur.
2. L'IA des trois survivants existants pilote leurs vraies animations et
   leurs déplacements ; aucun mouvement n'est inventé pour faire une image.
3. La caméra filme les bots, en vue poursuite, latérale et première personne.
4. Quinze PNG réels sont capturés, environ toutes les 3 secondes.
5. Un contrôle vérifie les quinze prises, les horodatages, l'activité du
   moteur, les signatures PNG et le changement entre images.
6. Une mosaïque 5 × 3 et les alertes de luminosité/contraste sont archivées
   sur GitHub. Les originaux sont conservés.

**Ce test ne représente pas les FPS du vrai Redmi Android**, mais ce sont bien
des captures issues du rendu Roblox Studio, pas des images générées.

## Déclencher la machine temporaire

[Workflow GitHub Android/Windows](../.github/workflows/roblox-ai-remote-windows.yml)

Le dépôt doit contenir les deux secrets GitHub déjà utilisés pour l'ancien
Windows distant :

- `TAILSCALE_AUTHKEY` : clé d'adhésion temporaire au réseau privé.
- `CHAOS_REMOTE_RDP_PASSWORD` : mot de passe Windows distant, distinct de
  Roblox ; n'est jamais affiché par le workflow.

Les secrets sont vérifiés par GitHub sans être imprimés. Il n'est jamais
nécessaire de copier un mot de passe Roblox dans une commande, un dépôt ou
ChatGPT.

Une fois le workflow démarré depuis `main`, attendre l'étape
**Show private IP and temporary instructions** : le résumé GitHub affiche
l'IP Tailscale privée, le nom `runneradmin` et les consignes Android.
La machine temporaire est protégée par RDP avec NLA/TLS, le port 3389
n'est pas ouvert publiquement et seules les adresses Tailscale sont autorisées.

Sur l'Android déjà connecté à Tailscale, ouvrir la connexion RDP
`runneradmin` avec le mot de passe Windows enregistré auparavant. Se
connecter à Roblox Studio dans Windows. Si Roblox propose la connexion
rapide, l'autoriser dans l'application Roblox Android déjà connectée.
Selon la géolocalisation des deux appareils, Roblox peut refuser cette
fonction : se connecter alors directement **dans Roblox Studio**.

Le bureau ouvre un surveillant de connexion. S'il ne démarre pas
automatiquement les 15 images après l'authentification, double-cliquer
`START_CHAOS_AI_CAPTURE.cmd` sur le Bureau. Rien d'autre n'est demandé :
le lancement local, la prise des captures et l'archivage sont automatisés.
Ne pas fermer la session RDP pendant l'enregistrement.

## Limites et sécurité

- **Sans la connexion Roblox** dans le Windows éphémère, il est impossible
  de produire des prises authentiques avec ce chemin officiel.
- GitHub Hosted Windows est une machine **jetable**. Une nouvelle exécution
  nécessite de se reconnecter. La prise des quinze images demeure
  automatisée après cette étape.
- Les minutes de GitHub Actions peuvent être imputées sur le forfait du
  compte GitHub. Le workflow ne crée aucun serveur permanent ou abonnement
  tiers, et il s'arrête lorsque les PNG ont été vérifiés.
- Les captures sont réalisées dans une copie locale de Chaos Survival,
  jamais dans la version publique ; aucune publication n'a lieu.
- L'ancien workflow Windows autonome auto-hébergé reste disponible si
  un ordinateur persistant connecté à Studio devient accessible.
- Une exécution qui expire, qui ne trouve pas de fenêtre graphique ou
  dont l'IA n'a pas terminé ne produit **aucun succès artificiel**.
  Les fichiers de diagnostic incomplets peuvent être archivés, mais
  ils ne sont pas présentés comme un jeu testé.
