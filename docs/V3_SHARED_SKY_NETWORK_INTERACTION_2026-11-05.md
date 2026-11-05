# Chaos Survival — V3 : réseau de sauvetage aérien coopératif

**5 novembre 2026 — source intégrée sur branche ; non publiée sur Roblox.**

## Défaut produit visé

Le jeu possédait déjà trois immenses routes physiques élevées dans **les
cinq cartes** : une Sky Spine transverse de dix plateformes et deux
promenades de huit plateformes chacune. Le joueur ou un bot pouvait
actionner un véritable interrupteur qui remplissait les **neuf** espaces
entre les dix plateformes de la Sky Spine, mais les **quatorze** sauts
horizontaux des deux promenades restaient obligatoires. Une seule
interaction produisait donc un effet limité à un seul corridor.

## Interaction réellement ajoutée

- Un joueur humain ou un bot ayant atteint physiquement l'un des **quatre**
  postes de commande maintient `ProximityPrompt` pendant **0,7 seconde**.
  Deux consoles sont les stations historiques de la Spine (étapes 3/8) ;
  deux nouvelles consoles non-collidantes sont fixées aux **véritables**
  jonctions des promenades nord/sud (étape 4).
- Le serveur vérifie **les 23 gaps** au moment de l'activation :
  **9 sur la Spine** et **7 sur chacune des deux promenades**. Les bords
  sont calculés sur les colliders réels, les hauteurs doivent coïncider,
  l'espace physique doit être entre 1,8 et 3,0 studs et le parcours doit
  être identifié comme permanent et toujours vivant.
- L'activation est atomique, unique dans la manche et collective :
  les **23 petites passerelles physiques** deviennent immédiatement
  solides, consultables par les raycasts de déplacement et visuellement
  lisibles (avec 46 arêtes non-collidantes).
- Aucune grande dalle artificielle ni raccourci n'est créé : chaque
  nouveau `Part` couvre un interstice authentique de **2,4 studs**,
  avec seulement 0,4 stud de recouvrement à chaque extrémité.
- Le même mécanisme côté serveur autorise une action humaine ou un
  bot qui se trouve vraiment sur un deck voisin, en vie et dans la
  distance autorisée. Aucun bot ne peut contourner son déplacement
  physique, faire un téléport, déclencher un `RemoteEvent` inventé,
  recevoir une récompense payante ou forger un événement de prompt.
- Les anciennes clés `SkySpineConnected`, `SkySpineGapCount=9`
  et l'API `start() => 9` restent compatibles. Les nouveaux indicateurs
  sont `SkyNetworkConnected`, `SkyPromenadeGapCount=14` et
  `SkyNetworkGapCount=23`.

## Respect des catastrophes et de la sécurité

- **Shrinking Arena** exclut le mécanisme dès le début de manche.
- Juste avant l'activation, les 23 paires de colliders sont toutes
  revalidées : si un deck est déplacé/réduit/détruit ou si un des nouveaux
  gaps n'a plus la même géométrie, **aucun** connecteur ne devient solide.
- Les plateformes d'origine, avertissements de danger et physiques
  de catastrophe ne sont pas modifiés. Le service conserve l'autorité
  serveur et son nettoyage de fin de manche.
- Les ponts ne se rétractent pas pendant une manche active après
  activation ; ils sont supprimés avec le dossier de la manche.
- Aucune boucle Heartbeat/RenderStepped supplémentaire ni nouveau réseau
  de messages client. Effet de groupe à la source sur le même serveur.

## Recette au jalon majeur, avant publication publique

`tests/engine/mapbuilder.spec.luau` contient les vérifications sur les
**cinq cartes** : nombre réel de 23 gaps, 14 liaisons des promenades,
géométrie, orientation, collision/transparence initiales, absence de
connexion au cours de Warning, quatre consoles ProximityPrompt, absence
de tuyau transparent faussement utilisable.

À compléter en **vrai Roblox Engine** : déclencher une console avec un
humain, avec un bot arrivé physiquement au poste, vérifier instantanément
`CanCollide=true` sur les 23 connecteurs et que la deuxième commande ne
réactive pas le système ; traverser les promenades Android/PC et
appliquer un scénario catastrophes + cleanup. Ne pas annoncer ce résultat
avant son exécution.

### Impact attendu

Une interaction reconnaissable, visible à l'échelle d'une arène de
320×320, améliore **trois itinéraires** en commun. Les joueurs ont une
raison de rejoindre une commande, les bots peuvent aider réellement,
et l'environnement réagit physiquement à leur coopération — sans
réduire les grandes cartes, remplacer les collisions ni gaspiller des
modèles tiers.
