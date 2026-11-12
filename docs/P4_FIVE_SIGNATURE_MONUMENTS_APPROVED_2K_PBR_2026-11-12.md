# P4 — Cinq monuments d'arène : matériaux PBR 2K source-authentifiés

**12 novembre 2026 — code client, sans nouvel asset ni changement de gameplay.**

## Pourquoi

Les cinq principaux monuments `ArenaSignatureMegastructure` bénéficient
déjà de remplacements **vraiment sculptés** (sept MeshParts par source
originale), mais leurs modèles n'étaient pas éligibles à la finition
`PremiumNearfieldPbrKit`. Leurs matériaux importés ne récupéraient donc
pas les cartes 2K de normales, roughness et métal déjà approuvées pour les
surfaces proches.

| Monde actif | Modèle original de monument | Source Roblox approuvée |
| --- | --- | --- |
| Classic | Observatoire principal avec paraboles | `112493873850364` |
| Towers | Grand pont de forge non jouable | `126298311664881` |
| Crossroads | Échangeur à deux niveaux non jouable | `96622579843060` |
| Orbital | Tore de réacteur central | `125070862497818` |
| Harbor | Grand portique de quai | `124368710235343` |

Chaque modèle existe déjà comme source authentifiée côté créateur, et
comme clone non physique dans un dossier local propriétaire précis.
La carte collisionnelle, les routes jouables et les signaux demeurent
leurs propres objets originaux.

## Modification

Ces cinq dossiers et IDs autorisés sont ajoutés aux candidats `SOURCES`
du moteur PBR existant, **un seul monde étant actif à la fois**. Les
groupes de matériau `ARMOR`, `BRUSHED`, `ALLOY`, `CERAMIC` peuvent
recevoir temporairement une `SurfaceAppearance` déjà vérifiée.
Les surfaces `SIGNAL`, `CARBON`, `GRIP`, `GLASS` conservent leurs
finitions propres pour préserver l'identité lumineuse et la lisibilité
des dangers.

Le moteur :
- vérifie le modèle complet de **sept MeshParts**, l'ID précis,
  `CosmeticOnly`, le dossier réel et l'absence de scripts/physique ;
- ne sélectionne que les sculptures à distance caméra admissible,
  avec un classement orienté caméra ;
- prélève les nouveaux candidats sur **la même enveloppe PBR globale** ;
- restaure les apparences initiales au retrait du modèle, en Low,
  lors de l'opt-out ou de la pression graphique.

## Garde-fous

Aucune nouvelle image, aucun nouvel `MaterialVariant`, import réseau,
shader programmable, ombre, lumière ou boucle de rendu. Le budget
PBR 2K **Low = 0**, **Medium Android = 2 modèles sans pression**,
**High Android = 4 modèles sans pression** (High PC = 6) reste inchangé.
Les grands monuments rivalisent avec les autres sculptures proches :
ils ne sont pas garantis simultanément résidents. Rien ici n'augmente
la densité de triangles ni le coût de physique.

## Vérification et limites

Le vérificateur source existant
`tools/verify_premium_nearfield_pbr.py` est étendu à ces cinq
propriétaires. `original-nearfield-pbr-source.yml` doit réussir sur
la PR et après fusion.

Des contrôles réels restent requis : captures Roblox Studio comparatives
avant/après des cinq variantes, portraits Android Medium/High,
`LocalPremiumNearfieldPbrModelCount`,
`LocalPremiumNearfieldPbrSurfaceCount`, qualité UV en gros plan,
animation/réversibilité des modèles, stabilité de FPS/p95/mémoire et
absence de détérioration des alertes.

**Les tests de source ne certifient pas le rendu final, le gain
de performance ou la publication Roblox.**
