# V3 — direction physique d'ascension pendant la lave (Android/PC)

**6 novembre 2026 — amélioration du dépôt ; publication à valider au prochain jalon.**

## Défaut illustré par les captures Android

L'objectif « LAVE MONTANTE — MONTE VITE » explique le danger, mais les
arènes 320×320 font parfois apparaître la première plateforme d'ascension
à 50–100 studs du joueur. Le guidage habituel d'un débutant
(`JumpRouteCueRules.nearestEntry`) n'examine que les entrées à moins
de 48 studs ; les joueurs expérimentés ne reçoivent aucun guidage
contextuel s'ils ne sont pas bloqués sur une plateforme. Les quatre
panneaux « High Ground » existaient déjà, mais seulement **au sommet**.

## Travail intégré

- Ajout de `JumpRouteCueRules.nearestLavaClimbEntry` : sélectionne
  **une vraie plateforme tier 1** appartenant au dossier d'arène,
  collidable, ancrée, non translucide, à une hauteur physique de
  saut de 1,5–5,2 studs. Pour les quatre grandes routes extérieures,
  impose **PerimeterStep 1** et le marqueur serveur
  `ChaosPermanentRoute=true`.
- Portée d'urgence **106 studs** pour les grandes arènes. Cette portée
  accrue n'est utilisée **que** pendant la manche RisingLava ;
  la portée de 42/48 studs des autres conseils est inchangée.
- Exclut toutes les plateformes sous la **vraie** lave serveur,
  ainsi que celles en phase Warning/Gone ou sans collision, via
  `safeLandingTarget` et `lavaOnDeck`.
- Réutilise **l'unique** panneau depth-tested
  `RookiePhysicalJumpCue` pour tous les joueurs (y compris les
  vétérans), au lieu de superposer un nouveau HUD mobile.
  Le marqueur pointe vers l'étape physique et ses vrais changements
  de hauteur — « VERS LES HAUTEURS », « GRIMPE PLUS HAUT »
  ou « SUIS LA PASSERELLE », avec anglais équivalent.
- Les joueurs déjà sur des plateformes suivent la navigation physique
  normale ; Orbital reste sur ses véritables `HelixCircuit` et rampes.
  Les huit `EntryRamp` d'Orbital sont repérées jusqu'à 104 studs
  pendant la lave, en pointant leur vrai `HelixStart` et non leur centre.
  La traversée des jonctions H conserve son sens de progression.
- Les avertissements immédiats (bombes, météores, balayages) restent
  plus prioritaires. Un objectif situé dans une zone de danger est
  remplacé par un autre **vrai** premier palier si possible, sinon
  masqué. Aucun objectif fictif n'est créé.
- Aucune mutation serveur, de la lave, des collisions ou des pouvoirs.
  Pas de nouvelle `Part`, `BillboardGui`, boucle RenderStepped,
  requête réseau ni nouveau script client.

## Validation

Une suite de cinq scénarios Roblox Engine
(`tests/engine/lava-escape-physical-cue.spec.luau`) est ajoutée :
présence réelle d'une entrée de saut par arène ; hauteur/distance ;
rejet du palier qui avertit d'un effondrement ; rejet d'un palier
déjà sous la lave ; validité des entrées invalides et carte réinitialisée.

**Tests moteur non encore exécutés pour ce commit.**

Avant publication : exécuter les validations GitHub du SHA final
(Build Validation + Roblox Open Cloud Engine Tests), puis tester
sur Android la situation de démarrage éloigné pendant RisingLava,
les deux sens des promenades, les premières rampes d'Orbital,
la disparition de marqueur lorsque le palier est immergé, et les
superpositions avec le danger imminent.
