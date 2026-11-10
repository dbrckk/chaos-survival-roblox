# P4 — Verrou réel de concurrence des imports 3D sud

**Constat :** la PR #787 répartit les premières requêtes nominales des huit
sculptures sud, mais `task.wait` ne garantit pas l'absence de
chevauchement : une requête peut encore durer lors du prochain créneau.

**Correctif :** `PremiumSouthApprovedImportGate.load` est maintenant
l'unique chemin `AssetService.LoadAssetAsync` de ces huit chargeurs.
Un booléen partagé par `require` dans le serveur garantit qu'au plus
**une requête sud de ces huit sources** est en cours à un instant donné.
L'attente est asynchrone et uniquement côté serveur, après le délai
prioritaire existant. Les erreurs sont capturées via `pcall`, le
verrou est libéré avant de propager l'erreur vers la boucle de retry
originale. Aucun collider, asset ID, modèle, nombre d'essais,
source vérifiée ou limite LOD client n'a été changé.

Le module expose `snapshot()` (InFlight, Waiting, PeakInFlight,
Completed, Failed) pour un futur diagnostic Roblox Studio. Aucun
`RemoteEvent` et aucune boucle graphique ajoutés.

**Périmètre :** limite stricte pour ces huit chargeurs sud, **pas**
pour les autres chargeurs de scènes. Une requête Roblox qui ne
retourne jamais peut bloquer les sept autres imports optionnels ;
le gameplay n'attend pas le verrou. Les tests de source vérifient
la libération après erreur et l'utilisation exclusive du module,
mais ne constituent pas une mesure de FPS Android ou une validation
de la Place publiée.
