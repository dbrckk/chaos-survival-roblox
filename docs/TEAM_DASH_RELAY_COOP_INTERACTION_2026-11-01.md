# Interaction réelle — relais DASH coopératifs (01/11/2026)

## Constat visuel qui déclenche ce changement

Captures Android du propriétaire : trois arènes affichent la même séquence (« courir / éviter la catastrophe / collecter / traverser un trajet »), avec plusieurs joueurs visibles mais presque aucune décision coopérative. Le HUD mobile reste très chargé sur la partie haute et au centre. La fenêtre flottante noire en haut à droite vient du téléphone / d'une autre application et ne fait pas partie du HUD Roblox. **Ne pas confondre cette fenêtre avec un bug du jeu.**

Les mécaniques de mobilité, transport, cachettes, relais de flux et fragments existent déjà, mais leur récompense est essentiellement individuelle. On complète le gameplay sans réinventer le DASH ni les dangers.

## Nouvelle interaction jouable

**Deux consoles physiques par arène**, installées sur des positions libres, contrôlées par `SpawnSafety.clearAt` (plusieurs emplacements de secours). Les consoles utilisent `ProximityPrompt` natif compatible tactile / clavier / manette ; appui long 0,65 s, rayon 9 studs ; contrôle du véritable root personnage côté serveur dans un rayon de 12 studs. Les stations ne bloquent aucune collision, aucune requête, aucun saut et sont supprimées avec la manche.

Quand un joueur active une console :
1. Le serveur vérifie : manche active, joueur participant vivant, données chargées, racine réellement proche, socle de l'arène encore solide et console encore dans sa **vraie** empreinte. Une arène qui rétrécit peut donc rendre le bouton inaccessible, sans téléporter l'utilisateur.
2. Il recherche uniquement les **autres vrais participants humains vivants** dans un rayon de **29 studs** ; aucun client ne transmet de liste de bénéficiaires. Le déclencheur en profite aussi.
3. Pour chacun, `PhaseDashService.recharge` touche le **véritable cooldown monotone** et l'attribut d'interface ensemble : si son DASH était en recharge, il devient prêt. Si son DASH est déjà prêt, il reçoit **une charge d'urgence en réserve**, non cumulable, qui sera dépensée à son prochain DASH réussi ; ce DASH donnera un second mouvement après **0,85 s** au lieu des neuf secondes habituelles. Toutes les règles normales de phase, santé, sol et direction restent appliquées.
4. **Une seule activation par console et par manche**, dont la réussite nécessite au moins un bénéficiaire qui a réellement reçu une recharge ou une réserve. Deux consoles maximum : il n'existe pas de boucle de farm infinie et aucun crédit/monnaie supplémentaire n'est ajouté.
5. La console change physiquement d'état (`RelayUsed`, `TeamBeneficiaries`, couleur et texte) et émet **une unique petite impulsion visuelle, 0,7 s**. Le DASH affiche `DASH +1` quand la réserve est réelle. Les bénéficiaires reçoivent une notification courte via l'événement `ArenaMechanicFeedback` existant ; pas de fenêtre permanente qui masque l'écran.
6. En solo, la même console recharge le joueur ou lui donne une réserve ; **aucun autre humain n'est obligatoire**.

## Budget / sûreté / économie

- 2 consoles au plus par carte et par manche. Chaque console = quelques `Part` natives, 1 `ProximityPrompt`, 1 `BillboardGui`, 0 nouvelle boucle `RunService`, 0 nouveau RemoteEvent, 0 son/texture téléchargé, 0 lumière et 0 pièce de physique. Le petit pulse n'est créé/animé qu'à l'activation, avec `TweenService`.
- Aucun serveur client ne peut déclencher une recharge arbitraire : `ProximityPrompt.Triggered` vérifie à nouveau les distances, l'état de la manche et des personnages. `PhaseDashService` est la **source de vérité** pour le cooldown et la réserve. `RoundTeamRelaysActivated`, `RoundTeamDashShared` et `RoundTeamDashReceived` sont des métriques de manche réinitialisées, pas un gain persistant.
- Les joueurs IA n'utilisent **pas encore** ces stations : c'est une première mécanique de coopération entre humains avec repli solo, et non une prétendue IA coopérative artificiellement annoncée.
- Il n'existe aucune économie nouvelle, aucune intervention sur les catastrophes, les récompenses, la santé ou les résultats de manche.

## Validation au prochain grand jalon de version publique

Avant une publication : Build Validation, cinq suites Roblox Open Cloud sur **le même SHA**, puis vraie session Studio/Android. Scénarios indispensables : solo DASH en recharge vs DASH déjà prêt, 2 humains à 10/27/30 studs, tiers de qualité, nombre de console 0–2 selon la géométrie, activation pendant Shrinking Arena, déconnexion d'un bénéficiaire pendant l'interaction, spam `Triggered`, mort du joueur, changement de carte, réserve consommée exactement une fois, RTT élevé, 15 captures/partie et notifications concurrentes des catastrophes. Les indicateurs d'usage doivent être basés sur de vraies interactions, pas sur des bots comptabilisés comme humains.

**État** : changement GitHub source uniquement ; aucune preuve Studio/Android, aucun déploiement Roblox revendiqués. Dernière version publique confirmée : `e8767c98c475a3efb39ed53ed7bbe16efa1865d2`.
