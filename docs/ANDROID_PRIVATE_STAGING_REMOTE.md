# Chaos Survival — créer une expérience de test Roblox privée depuis Android

La prochaine mise à jour publique ne doit pas servir de banc d'essai.
L'expérience de production attestée reste Universe `10771083668` /
Place `95351659174730`. **Ne jamais utiliser ces IDs comme staging.**

## Poste Windows distant temporaire — lancement manuel uniquement

Le workflow [Chaos Studio Remote Bootstrap (Android)](https://github.com/dbrckk/chaos-survival-roblox/actions/workflows/roblox-remote-studio.yml)
fonctionne désormais sur la branche `main` actuelle, uniquement depuis
`Actions → Run workflow`. Il ne se déclenche pas par `push` et ne publie
pas de place automatiquement.

Prérequis déjà configurés dans le dépôt :
- `TAILSCALE_AUTHKEY` : clé Tailscale dédiée au workflow.
- `CHAOS_REMOTE_RDP_PASSWORD` : secret Windows RDP fort (16 caractères
  minimum), **différent** de tout identifiant Roblox.

Le job refuse de démarrer si ces deux secrets manquent. Il n'affiche jamais
leur contenu. Il utilise un Windows GitHub temporaire, installe Roblox Studio
officiel signé, et construit `ChaosSurvival_VisualQA.rbxlx` depuis le SHA
GitHub exact en y ajoutant un marqueur `STAGING` propre au build local.
Ce marqueur n'est jamais commité ni publié sur la place publique.

### Depuis un téléphone Android

1. Ouvrir le lien du workflow ci-dessus dans GitHub, choisir **Run workflow**,
   branche **main**, puis lancer manuellement.
2. Ouvrir le run → **Summary** ; relever l'adresse IP Tailscale privée.
   Se connecter au même réseau Tailscale sur Android puis ouvrir un client
   RDP compatible. Utilisateur Windows : `runneradmin` ; mot de passe :
   la valeur déjà définie du secret RDP, **pas le mot de passe Roblox**.
3. Dans Windows, ouvrir `ChaosSurvival_VisualQA.rbxlx` sur le Bureau avec
   Roblox Studio ; se connecter à Roblox **dans Studio uniquement**.
4. **File → Publish to Roblox As → Create NEW experience**. Nom recommandé :
   `Chaos Survival - Visual QA`. Garder cette nouvelle expérience **PRIVATE**.
   Ne pas choisir l'expérience publique existante comme cible.
5. Depuis le Creator Dashboard, relever les **nouveaux** Universe ID et
   Place ID, puis se déconnecter de Studio dans la session temporaire.

Pour permettre le déploiement automatique **uniquement vers le staging**,
les GitHub Actions variables `ROBLOX_STAGING_UNIVERSE_ID` et
`ROBLOX_STAGING_PLACE_ID` devront utiliser ces nouveaux IDs. Une clé
`ROBLOX_STAGING_API_KEY` doit être limitée à la nouvelle expérience privée,
jamais à celle du public. Conserver les variables de production et la clé
de production séparées ; ne jamais copier des secrets dans une issue ou un chat.

## Validation

Depuis l'application Roblox Android sur ce staging, contrôler les quatre
arènes, les onze catastrophes, le HUD, la caméra, Solo Rush, la persistance
dans l'expérience privée et les FPS / la mémoire en sessions prolongées.

Les captures natives du mode `PHOTO + HUD` peuvent afficher
`3D S4/C4` : `S` = nombre de modèles montés par le serveur, `C` =
géométries originales effectivement répliquées au client. Ces chiffres
ne prouvent pas la visibilité des textures ou la fluidité. Seules les
captures vidéo et mesures Android sur le **même SHA** peuvent certifier le
rendu. Voir `docs/ANDROID_QA_PLAYTEST.md`.

Si la session RDP, l'authentification Studio ou la création de l'expérience
échoue, arrêter sans publier ; ne jamais réutiliser le Place public comme
solution de contournement. Le workflow Windows n'est pas une preuve de
certification tant qu'il n'a pas été exécuté et contrôlé.
