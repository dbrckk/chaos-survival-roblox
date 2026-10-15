# Chaos Survival — Windows distant gratuit depuis Android

## Objectif et limites

Ce guide prépare une **session Windows temporaire via GitHub Actions**,
accessible depuis Android avec Tailscale + Bureau à distance Microsoft.
Elle sert **une seule fois** à utiliser **Roblox Studio officiel** pour
créer une *nouvelle expérience privée* dédiée aux tests visuels.

**Ce workflow ne crée pas automatiquement un compte ou une expérience,
ne connecte pas Roblox à ta place et ne publie jamais vers la production.**
Tu te connectes *dans Roblox Studio* avec tes propres identifiants, sans
les envoyer au dépôt. L'API Open Cloud officielle sait automatiser des
actions sur un univers **déjà créé**, mais ne fournit pas actuellement
de création d'univers documentée.

Les runners standards GitHub Actions d'un dépôt public et Tailscale
Personal sont gratuits dans les limites des offres. Tailscale limite
notamment l'usage des ressources éphémères. Il ne s'agit **pas** d'un
ordinateur gratuit permanent. Une VM Windows GitHub peut aussi manquer
de capacités graphiques : la connexion à Roblox Studio reste **à tester**.

## Configuration initiale sur Android

1. Crée un compte Tailscale Personal gratuit :
   https://login.tailscale.com/start
2. Installe l'application **Tailscale** sur Android, connecte-la à ce
   compte et autorise son VPN. Tailscale reliera ton Android au
   Windows temporaire dans un réseau privé.
3. Depuis https://login.tailscale.com/admin/settings/keys,
   crée une **Auth key** Tailscale à durée courte. Si possible,
   sélectionne le caractère *ephemeral* pour le runner temporaire.
4. Depuis les paramètres
   https://github.com/dbrckk/chaos-survival-roblox/settings/secrets/actions
   ajoute **deux Repository Secrets** :
   - `TAILSCALE_AUTHKEY` = clé Tailscale générée ;
   - `CHAOS_REMOTE_RDP_PASSWORD` = un **nouveau mot de passe Windows
     aléatoire d'au moins 16 caractères**, différent du mot de passe
     Roblox. **Garde ta propre copie de ce mot de passe** : GitHub ne
     peut plus afficher un secret après son enregistrement.
5. Installe l'application **Bureau à distance Microsoft** sur Android
   (depuis Google Play), comme expliqué dans
   https://support.microsoft.com/fr-fr/windows/experience/connectivity-networking/how-to-use-remote-desktop

**Ne transmets jamais** la clé Tailscale, le mot de passe Windows,
le mot de passe Roblox, une valeur .ROBLOSECURITY ou un code 2FA
dans cette conversation.

## Démarrer le Windows distant

Le workflow est
[Chaos Studio Remote Bootstrap (Android)](../.github/workflows/roblox-remote-studio.yml).
Il s'exécute seulement sur la branche
`feat/visual-identity-hero-landmarks-20261008`.

GitHub peut ne pas afficher le bouton **Run workflow** pour un
workflow qui existe uniquement sur une branche non par défaut.
Il existe donc **un déclencheur explicite par commit** :

- Après avoir configuré les deux secrets, crée ou modifie le fichier
  `studio/REMOTE_STUDIO_TRIGGER` **sur la branche feature**, puis
  committe la modification depuis GitHub sur Android ; ou demande
  à l'assistant de le committer après confirmation de la configuration.
- Depuis GitHub → Actions, ouvre l'exécution **Chaos Studio Remote
  Bootstrap (Android)**.
- Si la préparation réussit, le résumé du workflow fournit **l'IP
  privée Tailscale** du Windows temporaire (format `100.x.x.x`).
  Si les secrets ne sont pas définis, le workflow échoue sans
  ouvrir l'accès RDP. **Ne devine pas l'adresse.**
- Sur Android, connecte Tailscale puis ouvre Bureau à distance.
  Renseigne cette IP, l'utilisateur Windows `runneradmin`, et
  le mot de passe `CHAOS_REMOTE_RDP_PASSWORD` que tu as conservé.

La session est **éphémère : au maximum 100 minutes**, jamais une
machine permanente. Le RDP est limité aux adresses privées Tailscale,
avec authentification réseau Windows (NLA) et TLS activés ; il n'est
pas exposé volontairement sur Internet.

## Créer l'expérience Roblox

Sur le bureau Windows temporaire, le workflow a généré
`ChaosSurvival_VisualQA.rbxlx` depuis **le SHA exact du dépôt**.
Ce fichier contient un marqueur visuel STAGING injecté seulement
sur le runner : les captures réelles afficheront l'identité du commit.

1. Ouvre `Official_Roblox_Studio.url` sur le bureau et installe
   Roblox Studio depuis **Roblox Creator Hub officiel**.
2. Connecte-toi dans **Roblox Studio**. Utilise ton système 2FA normal.
   Ne donne aucune information Roblox à GitHub Actions ou ChatGPT.
3. Studio → File → Open From File → sélectionne
   `ChaosSurvival_VisualQA.rbxlx` sur le bureau Windows.
4. Studio → File → Publish to Roblox As… → **Créer une NOUVELLE
   expérience**, appelée `Chaos Survival - Visual QA`. Conserve
   sa visibilité **PRIVATE** et ne sélectionne jamais l'expérience
   Chaos Survival publique existante.
5. Sur le Creator Dashboard Android, récupère les deux nouveaux IDs :
   **Universe ID** depuis le menu de l'expérience et **Place ID**
   depuis sa page Places. Vérifie qu'ils sont différents des IDs
   de production.
6. Déconnecte-toi de Studio, termine la session, et révoque la
   clé Tailscale éphémère si elle n'est plus nécessaire.

**Attention :** nous n'avons pas encore réussi un lancement graphique
Studio sur ce runner Windows. Un échec GPU ou RDP reste possible.
Ne contourne pas cet échec en exposant un RDP public ou en utilisant
un cookie Roblox dans un script.

## Après : GitHub + Open Cloud

Une fois l'expérience de test créée :

- Crée une API key Roblox **limitée à l'univers de test** avec la
  permission `universe-places:write`.
- Configure `ROBLOX_STAGING_UNIVERSE_ID` et
  `ROBLOX_STAGING_PLACE_ID` comme **Repository Variables**, et
  `ROBLOX_STAGING_API_KEY` comme **Repository Secret**.
- L'[automatisation de publication de test](../.github/workflows/roblox-visual-staging.yml)
  peut ensuite publier **uniquement cette expérience**, sur
  changement de code de la branche, sans Windows distant et sans
  autorisation de modifier le jeu public.
- Ouvre le jeu privé sur Android et utilise les outils PHOTO et
  VIDEO intégrés au jeu pour récupérer les **vraies images Roblox**.

## Références

- https://create.roblox.com/docs/studio/setup
- https://create.roblox.com/docs/cloud
- https://tailscale.com/docs/integrations/github/github-action
- https://tailscale.com/pricing
- https://docs.github.com/en/billing/concepts/product-billing/github-actions
