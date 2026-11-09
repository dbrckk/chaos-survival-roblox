# P3 — Les cinq arènes ont une progression de mobilité qui change la partie

**Date : 9 novembre 2026.** Lot source basé sur `main@6104fd36d2805b75c295d597a580bc5bd25114ae`. Les systèmes Classic et Crossroads existaient déjà dans `main`, non publiés sur Roblox. Ce lot finalise **Towers + Orbital + Harbor**, corrige les annonces dans le système de feedback commun et ajoute un unique indicateur personnel mobile non intrusif. Aucun test moteur, build, lint, Android ou publication n'a été exécuté par ce lot : l'utilisateur demande d'avancer pendant l'itération sans ces tests. **L'acceptation produit n'est pas une certification moteur.**

## Parcours réels — réutilisation des mécaniques autoritaires

| Arène | Épreuve réelle préexistante | Récompense P3 | Sécurité et limites |
|---|---|---|---|
| **Classic** | Quatre bornes `GridCircuit` dans l'ordre horaire sous 20 s | 1 boost `1,28×` sur un pad Classic | Contact serveur; limite `MovementSafety`, charge consommée une seule fois |
| **Crossroads** | 3 portiques Flux chargés en alternance dans la fenêtre de 12 s | 1 coupe latérale `26` au lieu de `20` sur aiguillage doré actif | Vitesse tangentielle, fenêtre active, cooldown, limite horizontale 48 |
| **Towers** | 3 ponts Skyrail distincts réellement parcourus en 16 s | Sur un **pont suivant**, une accélération Ace **jusqu'à 15** (base 12) avec pondération accrue pour garder un gain réel sur les ponts de 49 studs | Vraie vitesse de course, support physique intact, fenêtre de 4,5 s, frein de 4,5 studs vers le bord, plafond horizontal 42. Ne dépense pas sur un pont en phase `CollapsePhase` |
| **Orbital** | 3 traversées consécutives de rampes `HelixFlow` en 18 s, **chaque nouvelle rampe différente de la précédente** (la règle existante autorise A–B–A) | 1 pulsation `11` au lieu de `7` sur une **future** vraie rampe électrifiée | Pulsion uniquement si `HelixPulseActive`, unique par rampe et manche, physique `MovementSafety` limitée à 42. Aucun bonus fictif si `HelixPulseClaims` absent |
| **Harbor** | 2 **pads bleus différents** activés physiquement en 14 s | Sur le **second pad** (ou un suivant si overdrive), un transfert `1,28×` non cumulable | Pas d'activation répétée du même pad, cooldown réel, caps `MovementSafety` horizontal 60 / vertical -52 à 58, bonus unique et sans sauvegarde |

### Un seul contrôle serveur pour humains et bots

Le flux d'acquisition est vérifié par le serveur existant : `SkyrailSlipstream.tryTrigger`, `OrbitalHelix.tryFlow`, `ArenaMechanics.start`, et pour les bots leur physique `AISurvivorService.tryPadImpulse`. Les attributs `Round*` d'un `Player` sont des états **répliqués en lecture**, pas une entrée de gameplay client. Les modèles de bots utilisent les mêmes charges sur leurs vrais rigs et jamais des comptes de récompense `PlayerData`.

- `RoundSkyrailAceBoostEarned/Ready` (humain) et `SkyrailAceBoostEarned/Ready` (NPC). La troisième traversée **accorde** la charge ; elle ne la consomme pas simultanément. Les traversées suivantes sont physiquement plafonnées.
- `RoundHelixMasterPulseEarned/Ready` et `HelixMasterPulseEarned/Ready`. Le troisième franchissement reste à son impulsion normale ; une vraie impulsion chargée ultérieure consomme la charge.
- `RoundHarborTransferEarned/Ready`, `RoundHarborTransferStep`, `RoundHarborTransferDeadline` et `HarborTransferEarned/Ready` (NPC). `ArenaMechanics.advanceHarborTransfer` est la **même règle pure** pour `Player.Touched` et `AISurvivorService` ; les deux utilisations doivent concerner des pads physiquement distincts.
- `init.server.lua` remet à zéro toutes les charges humaines à chaque nouvelle manche, même si l'arène change. `AISurvivorService.setRoundState` fait de même pour les NPC réutilisés à READY et élimine l'état de route Harbor. Les enchaînements sont propres à chaque `ctx` de manche et ne sont jamais persistés.
- Un overdrive global n'utilise pas en doublon la charge Harbor ; elle reste disponible pour un pad suivant où la charge produit effectivement un bonus. Aucun nouveau RemoteEvent, HTTP, DataStore, collision, téléportation, rythme de cerveau IA ou boucle par frame n'est ajouté.

### Visuel et lisibilité réels

`src/client/arena-mastery-status.client.lua` présente **un seul bandeau** pour les seules charges personnelles Towers, Orbital et Harbor, au même emplacement mobile responsif que les mécaniques existantes. Il est **caché** quand une alerte prioritaire occupe le HUD, quand le joueur est éliminé, en dehors de ROUND ou sur une autre arène, et sur une fenêtre tactile trop petite. Il se rafraîchit sur les **attributs serveur**, la phase RoundState et le remplacement effectif de `GeneratedMap`, sans RenderStepped/Heartbeat ni polling. Harbor affiche le statut 1/2 jusqu'à la vraie échéance serveur, avec **un seul réveil différé**.

`arena-mechanic-feedback.client.lua` reçoit maintenant les nouveaux IDs `SKYRAIL ACE - SURGE READY`, `ACE SURGE`, `ORBIT MASTER - PULSE READY`, `MASTER ORBIT PULSE`, `SQUALL RUN 1/2`, `SQUALL RUN BOOST`, ainsi que `MASTER JUNCTION CUT` du précédent lot Crossroads. Sans cette adaptation les événements étaient enregistrés côté serveur mais **pas affichés** comme récompenses. `CoreLocalization.mechanicFeedback` traduit ces IDs dans le français existant. Les annonces Harbor n'apparaissent que sur un nouveau départ, un clear ou un boost consommé, pour ne pas spammer l'écran à chaque rebond.

## Limites honnêtes et scénarios de réception différée

1. Aucun FPS/latence/participation/rétention d'Android réel n'a été mesuré. Les nouveaux nombres sont des réglages, pas des gains observés.
2. Towers : sur un pont originel de 49 studs, montrer que le quatrième franchissement utilise une impulsion supérieure, tout en refusant la dépense sur un pont imminent à effondrement et sans franchir la marge de sécurité. Tenter un accessoire éloigné, un pont absent, et des collisions répétées.
3. Orbital : chaîne 1–2–1 ou 1–3–2 en ≤18 s, avec pulse activée, puis nouvelle rampe réellement active ; charge consommée **une** fois. Rounds débutant/Double Chaos, `HelixPulseClaims=nil`, départ de rig tardif.
4. Harbor : toucher 1 puis 2/3/4 (≤14 s), toucher deux fois 1, patienter >14 s, utiliser deux pads durant overdrive, puis hors overdrive. Confirmer même résultat pour sept bots et vrais humains, aucune collision inventée.
5. UI : Android Low/Medium/High, toute résolution, rotations de caméra, warning prioritaire, joueur mort, streaming tardif, arène suivante, charge consommée ; la jauge de survie et les boutons tactiles restent accessibles.
6. Avant **toute publication publique** les contrôles existants exigent Build Validation et Roblox Open Cloud Engine Tests réussis sur le **nouveau SHA exact**. Le souhait de ne pas tester pendant la phase de développement ne falsifie pas ces preuves et n'autorise pas à neutraliser le gate du workflow.

**État de livraison connu avant fusion :** dernière place publique certifiée `ae4ae044e991ef4ca28a991991f2e11b9df49c84` (P2, [publication #42650986552](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42650986552)). Classic + Crossroads sont sur `main@6104fd36...` mais **non publiés** ; le présent lot Towers/Orbital/Harbor est encore en branche.
