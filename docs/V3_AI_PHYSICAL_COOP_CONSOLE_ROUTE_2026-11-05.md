# V3 — bots : parcours physiques vers les consoles coopératives

**5 novembre 2026 — changement du dépôt seulement, sans publication Roblox.**

## Défaut identifié

Les quatre consoles du réseau aérien coopératif existent physiquement
sur les cinq cartes. Les bots ne savaient pourtant les activer que
lorsqu'ils se trouvaient **déjà à moins de 7,5 studs**. Ils ne
planifiaient pas de marche jusqu'au boîtier ; plusieurs pouvaient
vouloir occuper la même commande.

Les bots effectuent déjà, parfois, une véritable ascension des routes
`PerimeterRoute` puis des quatre marches `BranchRoute` mais
s'arrêtaient systématiquement au belvédère, alors qu'une promenade
collidable rejoint réellement le relais d'équipe.

## Correction appliquée

**Approche sur le pont, sans téléportation :**
- La méthode `SkySpineSwitchyard.sameDeckApproach` accepte
  exclusivement une position R15 dans l'empreinte du **vrai PlatformN**
  portant `ChaosPermanentRoute=true`, avec collision vivante, hauteur
  de rig cohérente et sans phase d'effondrement.
- `botApproach` confirme avec **un raycast serveur** que le sol sous le
  bot est **exactement** la plateforme qui porte le boîtier. Aucune
  distance 3D seule ne suffit à déclarer un itinéraire franchissable.
- Une console ne peut être réservée que par **un seul bot pendant
  3,5 secondes**. La réservation est renouvelée uniquement tant que
  l'approche reste physiquement vérifiée et est libérée après
  activation, échec, danger, blocage, décès, changement de manche,
  retour au lobby ou nettoyage.
- Le rayon d'activation de l'IA passe de **7,5 à 4,5 studs** : le
  Humanoid doit marcher visiblement près de la commande, arrêter son
  mouvement, puis maintenir la commande **0,7 seconde**.
- La marche dédiée utilise les `Humanoid:MoveTo` habituels, sans
  force, boost, RemoteEvent ou faveur d'activation. Les animations
  sociales et les écarts aléatoires sont interrompus pendant cette
  courte approche, évitant de tomber du bord.

**Vrai itinéraire depuis le sol :**
- Certains parcours d'exploration déjà existants (max. **deux bots
  explorateurs**) se prolongent du **quatrième plateau de branche**
  jusqu'à la commande de la promenade correspondante.
- Le parcours traverse les vrais `PromenadeStep` 1→4 ou
  8→4 selon le côté. Le premier déplacement vers la promenade est
  un **passage par recouvrement**, puis chaque saut de 2,4 studs est
  garanti par les dimensions authentiques des deux Parts
  (`neighboringPhysicalDeck` et `promenadeGapBetween`).
- L'IA conserve les vrais sauts Humanoid/raycast du moteur et
  la logique de traversée déjà implémentée. Elle abandonne si la
  plateforme manque, se rétracte, change de collision, si la manche
  entre en catastrophe critique ou si un autre joueur a déjà ouvert
  les trois corridors.
- Le budget des explorateurs **reste à deux maximum**.
  Ces missions plus longues ont une limite de **54 secondes** et
  restent occasionnelles, jamais imposées aux huit participants.

**Sûreté :**
- Aucune commande supplémentaire n'est lancée pendant `FinalRush`
  ou `ShrinkingArena`. Les fonctions de validation côté serveur
  restent l'autorité finale ; un bot ne peut pas appeler une action
  d'un autre endroit.
- Les scripts conservent les API historiques et le nombre de
  consoles/passages de la PR #628 ; aucun modèle importé ni nouvelles
  ressources financières.

## Validations

Tests d'intégration Roblox Engine ajoutés (source uniquement) :
1. `sky-command-bot-approach.spec.luau` — cinq cartes ; **quatre
   consoles** et surfaces exactes ; refus des mauvaises coordonnées,
   hauteurs et plateformes en avertissement/ayant perdu la collision.
2. `bot-sky-command-route.spec.luau` — cinq cartes × **quatre
   ascensions**, continuation réelle depuis chaque belvédère vers
   la promenade, saut standard de 2,4 studs, arrivée à l'exacte
   plateforme de la console.

La revue statique du code et des contrats ne constitue pas une
exécution du jeu. Avant la prochaine mise à jour publique :
- Exécuter Roblox Cloud Engine Tests et Build Validation sur le **SHA
  exact**, puis faire une partie physique Android avec bots et dangers.
- Vérifier le nombre de bots qui achèvent réellement ces itinéraires,
  les activations via `BotSkyNetworkConnected`, les abandons sur
  Warning/final rush et les FPS de l'appareil.
- Ne pas publier avant cette validation. Les commandes du jeu
  public sont inchangées tant que le nouveau SHA n'est pas déployé.
