## P4 — Ailettes de diffusion Classic : vraies sculptures 3D sur Android Low — 12 novembre 2026

Le [remplacement des grandes ailettes extérieures de Classic](docs/P4_LOW_APPROVED_CLASSIC_BROADCAST_FINS_2026-11-12.md) active le **modèle créateur original approuvé de sept MeshParts et 3 052 triangles** (`123049626693705`) sur **une** ailette de 16 studs à **≤195 studs** de la caméra Android Low sans pression. Les deux blocages Low ont été corrigés : quota à zéro et condition tactile ramenant tous les modèles à zéro. Les quatre bandes `ClassicBroadcastGlow` restent visibles ; le modèle est démonté dès la pression 1 et son bloc natif revient immédiatement si le gestionnaire de budget l'évince. Medium/High et la physique restent inchangés. Rendu dans Roblox Engine, FPS mobile et publication non encore validés.

## P4 — Correction des sous-châssis 3D tournés et fantômes sur les passerelles — 12 novembre 2026

Le [correctif du châssis original sous les vraies passerelles](docs/P4_SKY_ROUTE_UNDERDECK_SOURCE_XZ_ROTATION_AND_INSTALL_TRUTH_2026-11-12.md) résout un défaut de la modernisation Low : le modèle `OriginalUnderdeckChassis` (`84582262145054`, sept MeshParts) était rejeté si Roblox importait sa longueur sur **Z plutôt que X**, ou orienté sans tenir compte de l'axe source. Un **unique calcul de couverture réelle et de rotation X/Z**, partagé entre la sélection et le montage, permet de conserver la vraie sculpture sous une promenade ou la Sky Spine lorsqu'elle est géométriquement compatible. Le modèle n'est désormais compté comme **installé que si la création a réussi** ; un châssis demandé mais absent n'entraîne plus de reconstruction répétée du plateau 3D supérieur. Les contrôles couvrent les quatre orientations (deux source × deux plateforme), les petits planchers et le repli de budget Android. Aucun nouvel asset, collider, PBR ou boucle de rendu. Tests Roblox Engine, FPS Android et publication toujours requis.

## P4 — Vraies passerelles sculptées et sous-châssis sans doublons sur Android Low — 12 novembre 2026

Le [lot de sous-structures de routes authentiques](docs/P4_LOW_SAFELY_OWNED_SKY_ROUTE_UNDERDECKS_2026-11-12.md) porte la couverture 3D d'une **vraie passerelle** Android Low à **deux segments originaux maximum** et autorise, uniquement en pression zéro et à **≤100 studs**, **un châssis inférieur créateur de sept MeshParts / 3 072 triangles** sur une plateforme réellement allongée et compatible. Sur Low, **Harbor, les caissons carrés et les LongCradle déjà montés sont exclus** ; un LongCradle arrivant après coup supprime la sous-face concurrente via un événement, sans second polling ni fausse collision. Les vraies poutres sous l'arène gardent leur budget Low d'un modèle, mais celui-ci est désormais retiré dès la première pression graphique ou disparition d'un MeshPart/asset/support natif, avec retour à la forme native. Medium/High inchangés ; budgets 440/680/900 locaux partagés. Rendu Roblox Engine, FPS Android et publication non validés par la CI.

## P4 — Fondations extérieures : 11 formes primitives remplacées par un vrai châssis 3D sur Android Low — 12 novembre 2026

La [modernisation des fondations extérieures authentiques](docs/P4_LOW_APPROVED_EXTERIOR_FOUNDATION_CHASSIS_2026-11-12.md) autorise **un seul châssis approuvé de sept MeshParts / 3 072 triangles** (`84582262145054`) à **≤128 studs** d'une grande fondation originale sur Android Low et sans pression graphique. Le modèle n'est monté que si les **11 formes natives sont complètes** et si la géométrie couvre au moins **80 % × 78 %** des deux axes du socle ; cela évite un remplacement étroit ou partiel. Les sept vrais MeshParts résident désormais dans le dossier local `ApprovedFoundationChassisLocal`, explicitement recensé dans le budget Android partagé de 440 Parts. Sous pression graphique 1/2, source absente ou LOD masquant la fondation, les onze natives sont restaurées. Aucun nouveau modèle, collider, shader, lumière ou boucle de rendu ; Medium/High conservent leurs limites. Validation Roblox Engine/FPS réels et publication non effectuées.

## P4 — Deux grandes ailes industrielles sculptées par station sur Android Low — 12 novembre 2026

Le [lot d'ailes périphériques authentiques](docs/P4_LOW_TWO_APPROVED_PERIMETER_WINGS_2026-11-12.md) peut remplacer les **deux grands `AngledServiceWingL/R`** (WedgeParts de **5,7 studs**) par **deux vrais modèles créateur approuvés de sept MeshParts** (`138096293972093`) sur **une station réelle ≤105 studs** de la caméra Android Low, sans pression graphique. **Seules les deux ailes sont remplacées en Low** (14 MeshParts au lieu des 28 du groupe complet), et les deux petits chapeaux restent natifs. Les compteurs reflètent **2 WedgeParts effectivement masqués** sur Low, **4** sur Medium/High, avec montage complet avant masquage et restauration native en cas de perte d'asset ou de pression GPU 1/2. Le rendu Medium/High, la physique, les lumières et les hazards restent inchangés. Tests dans Roblox Engine, mesures FPS Android et publication toujours nécessaires.

## P4 — Stations périphériques : traverse forgée et écran de générateur en 3D sur Android Low — 12 novembre 2026

Le [remplacement authentique des deux derniers grands blocs structuraux des stations](docs/P4_LOW_APPROVED_PERIMETER_BRACE_SHIELD_2026-11-12.md) autorise **une station périphérique réelle** à afficher **deux modèles créateur originaux approuvés de sept MeshParts chacun** sur Low sans pression graphique, à **≤112 studs** de la caméra : la traverse `CrossBrace` (asset `108452611210970`) et le `GeneratorShield` (asset `113687802206554`). Les **deux** modèles sont vérifiés et montés avant de masquer les blocs ; un seul asset manquant ou la pression graphique 1/2 restaure immédiatement les formes natives. Les limites Medium/High et les marqueurs de danger, lumières et sols originaux restent inchangés. Aucun nouveau collider, asset, PBR ou boucle de rendu. Tests Roblox Engine, FPS réels et publication publique toujours requis.

## P4 — Mâts d'identité authentiques Classic/Towers sur Android Low — 12 novembre 2026

Le [nouveau remplacement des grands mâts primitifs](docs/P4_LOW_AUTHENTIC_CLASSIC_TOWERS_IDENTITY_MASTS_2026-11-12.md) corrige les **deux verrous** qui empêchaient les grands `GridMarker` Classic (12 studs) et `TowerSpine` Towers (20 studs) d'afficher leurs **vrais modèles approuvés de sept MeshParts** sur les smartphones Android Low. **Un modèle maximum à ≤165 studs** de la caméra, avec restauration du bloc natif dès la première pression graphique ou si le gestionnaire de budget retire la sculpture. Les couronnes lumineuses Classic et les bandes animées Towers restent intactes. Aucun nouveau modèle, collider, éclairage, réseau ni boucle de rendu. Tests Roblox Engine et FPS Android encore requis ; pas de publication publique dans ce lot.

## P4 — Supports et grandes sous-structures 3D : correction Android Low — 12 novembre 2026

Le [correctif de rendu des vraies structures 3D sélectionnées sur plateformes paires](docs/P4_LOW_EVEN_INDEX_ORIGINAL_STRUCTURE_STREAMING_FIX_2026-11-12.md) répare deux problèmes des plateformes Android Low : les **LongCradle originaux et les colonnes de support authentiques de sept MeshParts** étaient parfois ignorés **après leur sélection** si le deck portait un numéro pair, et les supports natifs arrivés tardivement via `StreamingEnabled` ne déclenchaient aucun rattrapage Low. Désormais, ces vrais modèles passent l'installateur existant et le système normal de collapse/shrink/masquage, tandis que le filtre de **demi-densité des simples décorations Low est conservé**. Le suivi des supports natifs réellement montés permet également de retirer proprement une sculpture 3D si son support original disparaît. **Un seul module authentique Low, source et pression GPU inchangées ; pas de nouveau modèle, collision ou boucle de rendu.** Tests Roblox Engine et FPS Android non revendiqués.

## P4 — Sous-face sculptée des plateformes Harbor sur Android Low — 12 novembre 2026

Le [remplacement 3D authentique des caissons portuaires](docs/P4_LOW_ORIGINAL_HARBOR_DOCK_UNDERDECK_2026-11-12.md) active **un caisson original créateur** de 7 MeshParts (asset approuvé `101457508594609`) sous une véritable plateforme Harbor située à **≤108 studs** de la caméra sur Low sans pression graphique. Le kit conserve la surface supérieure et la collision du plateau serveur, positionne le dessus de la sculpture **0,14 stud sous le sol** et maintient les soudures et avertissements de catastrophe existants. Une source non conforme ou `OptionalVfxPressure > 0` retire le modèle ; Medium/High inchangés. Aucune nouvelle lumière, texture PBR, collision ou boucle graphique. Vérification Roblox Engine, FPS Android et publication non effectuées.

## P4 — Monument sud Towers : remplacement des 13/13 primitives sur Android Low — 12 novembre 2026

Le [dernier lot sud Towers](docs/P4_LOW_SOUTH_TOWERS_COMPLETE_13_OF_13_2026-11-12.md) active la véritable finition `ForgedFinishing` créateur approuvée (**asset `79666240429608`, sept vrais MeshParts**) à **≤106 studs** de la caméra sur Android Low sans pression graphique. Elle remplace **sept dernières formes natives** (fondation, plancher, rails, suspensions et signal), **sans chevaucher** les 2 pièces du pont SkyTransfer ni les 4 des ascenseurs déjà modernisés : **13/13 formes de décor sud Towers couvertes par trois modèles originaux distincts**. Jusqu'à 21 MeshParts au total pour ce monument en Low de proximité, comptabilisés dans le budget Android existant ; sous pression 1/2, tous les kits restaurent les primitives. Aucun nouvel asset, collider, lumière, PBR ni frame loop. Les tests Roblox Engine/FPS Android et la publication restent à effectuer.

## P4 — Deux structures mécaniques géantes originales sur Android Low — 12 novembre 2026

Le [nouveau lot de sculptures mécaniques authentiques](docs/P4_LOW_SOUTH_TOWERS_LIFTS_ORBITAL_MACHINERY_2026-11-12.md) autorise **une paire d'ascenseurs Towers** (deux colonnes de 37/46 studs et deux couronnes) et la **structure interne de l'anneau Orbital** (socle, deux appuis, sphère et pince) à utiliser leurs modèles créateur **7 MeshParts** sur Android Low à **≤152 studs** de la caméra. Le premier ensemble remplace **4 primitives** et le second **6 primitives**, sur des variantes de cartes distinctes. Leur source est authentifiée, les vrais MeshParts sont montés avant tout masquage, et la pression graphique 1/2 restaure les formes natives. Aucun nouvel asset, lumière, boucle ni collider ; Medium/High et leurs distances restent inchangés. Roblox Engine, performances Android et publication restent à vérifier.

## P4 — Quatre monuments authentiques de l'horizon sud sur Android Low — 12 novembre 2026

Le [lot de remplacement des quatre grandes silhouettes du sud](docs/P4_LOW_FOUR_APPROVED_SOUTH_HORIZON_2026-11-12.md) permet à **Classic, Towers, Crossroads et Harbor** d'afficher, sur Android Low sans pression graphique, une **véritable sculpture originale approuvée de sept MeshParts** à ≤290 studs de la caméra. Selon l'arène, celle-ci remplace **13, 2, 13 ou 14 primitives non physiques**, avec un seul modèle d'horizon sud par arène active. Provenance et montage complet contrôlés avant masquage ; si l'asset manque ou si la pression GPU augmente, les formes natives sont restaurées. **Orbital était déjà couvert** ; Medium/High inchangés. Aucun nouveau collider, asset, lumière, PBR ou boucle de rendu. Validation Roblox Engine, mesures Android et publication restent nécessaires.

## P4 — Trois signatures géantes sculptées 3D pour Android Low — 12 novembre 2026

Le [lot des trois monuments originaux](docs/P4_LOW_THREE_APPROVED_SIGNATURE_LANDMARKS_2026-11-12.md) remplace les grandes formes primitives des silhouettes lointaines de **Classic (observatoire à deux paraboles, 7 pièces primitives), Towers (pont de service, 2 grandes dalles) et Harbor (grue industrielle, 3 blocs)** par **un vrai modèle créateur de sept MeshParts approuvés par arène active**. Le montage reste à moins de **290 studs de la caméra**, uniquement sur Low hors pression visuelle ; pression 1/2 restaure les originaux natifs. **Pas de modification de collisions, de physique, de gameplay, de PBR ni de cadence de rendu.** Les tests Roblox Engine/Android et la publication de la Place restent à effectuer.

## P4 — Grande arche Harbor réellement sculptée 3D sur Android Low — 12 novembre 2026

Le [lot d'arches Harbor authentiques sur Android Low](docs/P4_ANDROID_LOW_ORIGINAL_HARBOR_CARGO_GANTRY_2026-11-12.md) autorise **un vrai portique industriel créateur 3D (asset `134157110756659`) de sept MeshParts** sur une vraie Sky Promenade à ≤118 studs de la caméra. Son montage vérifié remplace localement **neuf blocs structuraux natifs** (pylônes, renforts, traverse et grue/cargaison), soit une amélioration majeure de silhouette à coût limité. La source et son origine sont vérifiées ; `OptionalVfxPressure>=1` restaure les neuf éléments primitifs. Même propriétaire LOD, census Android, collisions et warnings ; aucun nouvel asset, lampe ou frame loop. Medium/High inchangés. **Validation Roblox Engine, FPS Android et publication publique restent à effectuer.**

## P4 — Repli 3D authentique lorsque le premier modèle échoue sur Android Low — 11 novembre 2026

Le [correctif de montage atomique et de repli des modèles authentiques](docs/P4_LOW_ATOMIC_AUTHENTIC_SOURCE_FALLBACK_2026-11-11.md) empêche un modèle 3D sélectionné mais impossible à poser de **bloquer les autres améliorations visibles**. Le propriétaire Low tente un vrai montage créateur de **7 MeshParts**, ou de **14 pour les deux flancs Towers** ; en cas d'échec, il retire les pièces éventuelles et essaie jusqu'à trois autres familles déjà approuvées. Le gagnant est **réutilisé sans double clonage**, sous le même owner de collision, collapse et shrink. **Budget inchangé : 7+7 MeshParts au maximum en Low, pression adaptative conservée.** Medium/High et la physique serveur restent inchangés ; tests Roblox Engine/Android et publication restent nécessaires.

## P4 — Priorité aux véritables modèles 3D visibles devant le joueur — 11 novembre 2026

Le [correctif d'arbitrage de la scène Android Low](docs/P4_ANDROID_LOW_CAMERA_HERO_VISUAL_PRIORITY_2026-11-11.md) compare désormais **la distance caméra réelle** entre les sources approuvées du grand carénage, des carapaces, des trappes 3D et des ponts Towers, plutôt que de réserver automatiquement les deux slots 3D Low à un pont éloigné ou le seul slot de premier plan à une trappe. Le grand carénage central reste prioritaire à distance égale ; une caméra plongeante privilégie les sculptures sur le dessus. **Quotas inchangés (7+7 MeshParts Low ou 14 pour un pont)**, pression adaptative conservée, aucun nouveau rendu/collider/asset. CI du budget Android renforcée ; publication et mesures Roblox Engine non réalisées.

## P4 — Trappe de maintenance réellement sculptée au premier plan sur Android Low — 11 novembre 2026

Le [lot d'habillage authentique de surface des plateformes](docs/P4_LOW_SOURCE_AUTHENTIC_SERVICE_HATCH_2026-11-11.md) autorise **une vraie trappe de maintenance 3D créateur, 7 MeshParts**, sur un deck physique et sûr à ≤100 studs de la caméra, et exige l'asset original approuvé propre à chacune des **cinq arènes**. **Budget partagé : la trappe remplace le slot Low carapace/hub de 7 pièces ; une vraie Skybridge Towers de 14 pièces l'exclut**. Sous pression GPU, le profil Low revient au deck standard sans trois nouvelles formes primitives. Les quotas Medium/High, collisions et ownership des catastrophes restent inchangés. Tests Engine/Android et publication de Place non encore effectués.

## P4 — Treillis 3D d'une passerelle Towers sur Android Low — 11 novembre 2026

Le [lot de remplacement du treillis de Skybridge](docs/P4_LOW_TOWERS_APPROVED_3D_SKYBRIDGE_TRUSS_2026-11-11.md) permet, sur une seule **Skybridge Towers réelle** à ≤125 studs de la caméra et hors pression GPU, de substituer les anciennes nervures rectangulaires par **deux modèles 3D originaux approuvés, soit 14 MeshParts**. La provenance, la taille, les soudures, les shutters et les avertissements restent vérifiés. **Ces 14 MeshParts occupent exclusivement les deux budgets Low précédents de 7+7 pièces** : ils ne s'ajoutent pas aux carapaces/hubs ni aux grandes colonnes/LongCradle de la même arène Low. Retour aux natives dès pression 1 ; Medium/High inchangés. Tests Roblox Engine, FPS Android et publication de Place non encore effectués.

## P4 — Vrai châssis ajouré 3D sur une grande passerelle Android Low — 11 novembre 2026

Le [lot de remplacement des sous-structures Sky Spine / Promenade](docs/P4_LOW_ORIGINAL_SKY_SPINE_UNDERCRADLE_2026-11-11.md) autorise un **vrai Model créateur LongCradle (128914328933863), de sept MeshParts**, sur une plateforme physique proche de la caméra (≤125 studs), si la provenance, l'échelle et l'empreinte sont validées. Il **partage l'unique quota Low de grande structure avec la colonne 3D** précédente : pas de cumul. Dès pression graphique Low 1/2, retour aux châssis et piliers natifs. Medium/High inchangés. **Il reste à valider dans Roblox Engine/Android et à publier sur la Place.**

## P4 — Pilier de plateforme sculpté authentique sur Android Low — 11 novembre 2026

Le [lot de remplacement d'une colonne structurale primitive](docs/P4_LOW_AUTHENTIC_NEAR_SUPPORT_COLUMN_2026-11-11.md) autorise **un vrai Model créateur de sept MeshParts pour un seul pilier `PlatformSupportN_K`**, à 125 studs de la caméra et uniquement sans pression graphique. Sur Low, un support de **5–16 studs** n'est substitué qu'après vérification de la provenance, de la largeur, du nombre de pièces et de la vraie plateforme porteuse. Le repli natif est automatique sous pression 1/2. Medium/High et la géométrie LongCradle ne changent pas ; **aucun upload du jeu n'est revendiqué**, mesures Roblox Engine/Android encore nécessaires.

## P4 — Grand carénage 3D authentique du hub Crossroads sur Android Low — 11 novembre 2026

Le [lot du véritable dessous de plateforme centrale](docs/P4_LOW_CROSSROADS_AUTHENTIC_HUB_HULL_2026-11-11.md) réutilise le Model créateur approuvé **125929150866282** sur les decks compatibles 18×18, en premier lieu le vrai **Platform1 central Crossroads**. Low consacre le **même unique emplacement** au grand carénage **ou** à la carapace compacte de la précédente évolution, jamais aux deux ; 7 MeshParts authentiques remplacent les 2 wedges natifs sous conditions strictes de provenance, distance caméra ≤125 studs et pression graphique zéro. Aucun nouveau modèle, physique, PBR ni boucle. La publication publique Roblox et les mesures Engine/Android restent à effectuer.

## P4 — Une carapace de plateforme en vraie 3D sur Android Low — 11 novembre 2026

Le [lot de remplacement des carapaces au premier plan](docs/P4_LOW_CAMERA_AUTHENTIC_DECK_CARAPACE_2026-11-11.md) autorise **une seule sculpture 3D originale Approved de 7 MeshParts à moins de 125 studs** sur Low, pour remplacer les **2 WedgeParts natives** d'une plateforme réellement jouable déjà décorée. Sur pression graphique 1/2, les primitives reviennent via le propriétaire visuel existant ; le budget High 16 / Medium 8 ne change pas. Le nouveau coût maximal sur Low est de **+5 BaseParts**, déjà compris dans le recensement adaptatif global. Aucun asset, PBR 2K ou boucle supplémentaire. Le code doit encore être testé dans Roblox Engine/Android, puis publié sur la Place.

## P4 — Les sculptures 3D se montent après leurs attributs de provenance — 11 novembre 2026

Le [correctif de streaming des Models approuvés](docs/P4_STREAMED_AUTHENTIC_DECK_READINESS_2026-11-11.md) reconnecte les vrais MeshParts des trappes de maintenance, carapaces, grands dessous et supports lorsqu'un Model arrive **avant ses attributs OwnerVerified / Original3DAssetId**. Les trois événements `RouteTier` / `HarborSpokeRoute/Step` utilisent désormais le batch de rebuild existant au lieu de lancer des reconstructions individuelles. Il n'y a aucune nouvelle requête d'asset, Part, boucle ou augmentation de budget Android ; les fallbacks natifs sont conservés jusqu'à provenance complète. Cette modification doit encore être validée en Engine/Android et publiée sur Roblox séparément.

## P4 — Trappes de maintenance 3D désormais aux vrais points de vue — 11 novembre 2026

Le [lot de remplacement des trappes de maintenance](docs/P4_CAMERA_SELECTED_AUTHENTIC_SERVICE_HATCHES_2026-11-11.md) réaffecte les créneaux existants de vrais reliefs métalliques 3D (cinq assets créateur approuvés), autrefois réservés à un indice de plateforme sur 9 en High et sur 18 en Medium. Ils remplacent désormais les trappes primitives à **trois pièces sur les plateformes visibles proches du joueur**, dans la même enveloppe de modèles originaux et sans nouvelles formes natives. Les collisions, les phases de disparition, les éléments de navigation et le suivi des plateformes mobiles restent inchangés. Android Low reste sur l'art natif. Cette modification GitHub n'est pas une publication Roblox.

## P4 — Finitions PBR 2K orientées vers les structures visibles — 11 novembre 2026

Le [correctif de priorité PBR](docs/P4_CAMERA_FACING_NEARFIELD_PBR_2026-11-11.md) applique le même principe de visibilité aux **sculptures métalliques et céramiques proches** des cinq arènes : à budget identique, les matériaux 2K sont réservés en priorité aux modèles devant la caméra, avec une rétention des finitions déjà montées pour limiter les changements de textures. Android Low conserve zéro surcouche, Medium 2 et High tactile 4 au maximum sans pression. Les 16 images existantes et les protections des matériaux SIGNAL/CARBON/GRIP/GLASS ne changent pas ; aucune publication Roblox automatique.

## P4 — Architecture 3D de l'horizon priorisée face caméra — 11 novembre 2026

Le [lot de sélection visuelle](docs/P4_CAMERA_FACING_AUTHENTIC_SKYLINE_2026-11-11.md) privilégie, dans les quotas 3D déjà limités, les **vraies sculptures situées devant la caméra** : quatre tours extérieures, quatre silhouettes principales et huit masses de toitures lointaines par arène. Auparavant, une sculpture derrière le joueur pouvait occuper l'unique emplacement 3D Android Low tandis que l'architecture regardée devant restait en `Part`/`WedgePart` primitive. Les assets originaux approuvés, quotas de pression, rayons de chargement, collisions et signaux ne changent pas. Aucun modèle, texture, nouvelle boucle ni publication Place n'est ajouté.

## P4 — Reflets métalliques différenciés en pleine manche — 11 novembre 2026

Le [lot d'éclairage des métaux sculptés](docs/P4_ROUND_METAL_RELIEF_LIGHTING_2026-11-11.md) donne à chacune des cinq arènes une petite signature de **reflet spéculaire et diffusion** pendant les phases ready/round, sur les propriétés Lighting déjà pilotées par `juice.client.lua`. Les gains sont bornés à **0,60 de diffus / 0,78 de spéculaire**, sans aucune nouvelle lumière, texture PBR ni boucle ; **Darkness**, y compris en deuxième catastrophe Double Chaos, est intégralement exclu. Les trois profils GPU et les contrôles Engine existants sont conservés.

## P4 — Finitions métalliques PBR 2K sur les vrais socles de station — 11 novembre 2026

Le [lot de finition PBR des inserts de stations](docs/P4_APPROVED_STATION_DECK_NEARFIELD_PBR_2026-11-11.md) relie les **vraies dalles triangulées originales** de socles à la whitelist existante des **quatre familles de textures PBR 2K déjà approuvées**, sur les cinq arènes. Aucun nouveau téléchargement ni quota GPU : la surcouche partage **2/3 modèles Medium ou 4/6 High**, reste désactivée sur Low et est supprimée sous pression. Les six voyants et repères natifs restent inchangés ; la finition est optionnelle et ne garantit pas un rendu permanent à l'écran. Aucune publication Roblox dans cette PR.

## P4 — Socle de station authentique, navigation préservée — 11 novembre 2026

Le [lot de socles forgés 3D](docs/P4_APPROVED_STATION_DECK_INLAYS_2026-11-11.md) ajoute à la base décorative de chaque station un **vrai insert triangulé de sept MeshParts**, réutilisé depuis le modèle original de sol **déjà approuvé** `72507987666671`. Les **six voyants, lentilles et repères de navigation** restent natifs. Les coûts sont limités par proximité : 1 station Low, 2 Medium, 2 High tactile ou 4 High PC. Au premier palier de pression Low, l'insert disparaît et la base native revient. Aucun nouvel asset, texture, collision, VFX ou render loop.

## P4 — Plus de sol sculpté au premier plan sur Medium — 11 novembre 2026

Le [lot d'amélioration des dalles 3D originales](docs/P4_MEDIUM_GROUND_FOREGROUND_VISIBILITY_2026-11-11.md) augmente la couverture **Medium de 12 à 16 vraies dalles 3D approuvées** parmi les 36 sols natifs de chaque arène, tout en gardant **Low=2**, **High=36** et les plafonds PBR 2K inchangés. Le classement privilégie légèrement les dalles devant la caméra sans retirer la priorité aux dalles sous les pieds ; les budgets Medium redescendent à **10 puis 4** lorsque la pression monte. Aucun nouveau modèle, lumière, collision, texture, RenderStepped ou publication Roblox.

## P4 — Logements mécaniques 3D sur Android Low, sans cumul avec les turbines — 11 novembre 2026

Le [lot de remplacement des trois logements mécaniques](docs/P4_LOW_PERIMETER_MACHINERY_EXCLUSIVE_ROTORS_2026-11-11.md) active **une station à 125 studs** sur Low avec de véritables modèles approuvés à **7 MeshParts par logement**, substituant **3 cubes** par **21 MeshParts**. La passe caméra existante **ne permet jamais de cumuler** ces 21 MeshParts avec les 21 rotors Low : les logements ont priorité lorsqu'ils sont montés, sinon les turbines conservent leur remplacement 3D. Au premier palier de pression, toutes les primitives sont restituées. Medium/High, assets, import réseau, collisions et budget Android restent inchangés. Publication Roblox distincte de ce code GitHub.

## P4 — Turbines forgées authentiques des stations sur Android Low — 11 novembre 2026

Le [lot des trois rotors originaux](docs/P4_LOW_AUTHENTIC_PERIMETER_ROTORS_2026-11-11.md) autorise sur Android Low **une station proche à 130 studs** à remplacer ses **trois cylindres de turbine** par les vraies sculptures Roblox Approved (`133526819668194`), soit **21 MeshParts maximum**, déjà comptabilisées dans la limite globale de 440 Parts locales. Le premier palier de pression restitue les trois cylindres ; Medium/High, collisions, signaux et chargeur serveur sont inchangés. Ce correctif ne publie pas la Place et nécessite une validation Roblox Engine après fusion.

## P4 — Deux contreforts forgés en vraie 3D sur Android Low — 11 novembre 2026

Le [lot des contreforts de stations](docs/P4_LOW_AUTHENTIC_PERIMETER_BUTTRESSES_2026-11-11.md) permet désormais à **une station proche (150 studs)** de remplacer atomiquement ses deux blocs `LeftButtress` / `RightButtress` par les modèles 3D originaux **déjà approuvés** et spécifiques aux cinq arènes. Les imports, les collisions, la limite globale Android et les profils Medium/High restent inchangés. Le premier palier de pression restitue automatiquement les blocs. Aucun asset nouveau ni test unitaire supplémentaire ; ce changement GitHub demande une validation Engine et publication Roblox ultérieures.

## P4 — Deux vrais portiques Crossroads sur Android Low — 11 novembre 2026

Le [nouveau lot Crossroads](docs/P4_CROSSROADS_AUTHENTIC_LOW_GATES_GANTRIES_2026-11-11.md) rend visibles sur Low **un portail intérieur approuvé** (remplacement de trois primitives) et **un portique extérieur approuvé** (remplacement d'une poutre), dans un rayon de 180 studs, même sur écran tactile. Le signal extérieur et les animations intérieures restent intacts ; chaque modèle ne compte que sept MeshParts non physiques dans le budget Android global. Les deux charges sont priorisées à **44/46 secondes sur la carte Crossroads active** (92/98 secondes ailleurs) et la pression graphique rétablit les natives. Cette modification GitHub n'actualise pas la Place Roblox publique.

## P4 — Grandes signatures sculptées Classic et Crossroads sur Low — 11 novembre 2026

Le [lot des silhouettes d'arènes authentiques sur Android Low](docs/P4_LOW_AUTHENTIC_CLASSIC_CROSSROADS_SIGNATURES_2026-11-11.md) autorise un vrai modèle original de **sept MeshParts** à remplacer **cinq formes primitives Classic** ou **quatre formes Crossroads** à moins de 320 studs. Le premier palier de pression rétablit les natives. Les IDs créateur approuvés, le budget GPU partagé et les collisions sont conservés. Le modèle complémentaire Classic est demandé dès 56 secondes uniquement lorsque cette carte est active, contre 119 secondes de repli sur les autres variantes. Cette modification GitHub ne publie pas le jeu.

## P4 — Sommets 3D de stations importés plus tôt sur l'arène active — 11 novembre 2026

Le [correctif du chargeur de sommets propriétaires](docs/P4_ACTIVE_PERIMETER_APEX_EARLY_IMPORT_2026-11-11.md) demande dès **60 secondes** la source 3D approuvée de l'arène effectivement active (Classic/Harbor partagent Relay). Les trois autres sources conservent leur calendrier à 132 secondes. Le **même** chargeur série, le quota AssetService global de deux requêtes, les trois essais maximum par modèle et les repli natifs sont conservés. Aucun nouvel asset, aucune boucle ni publication Roblox n'est impliqué.

## P4 — Colonnes et silhouettes 3D : sélectionner les candidats réellement montables — 11 novembre 2026

Le [correctif de sélection atmosphérique](docs/P4_ATMOSPHERE_COLUMN_ELIGIBLE_LOD_2026-11-11.md) évite qu'un pilier trop large une fois agrandi monopolise le seul emplacement 3D **Android Low** alors qu'une silhouette compatible pourrait être affichée. Les huit cibles sont désormais préfiltrées par les dimensions du véritable modèle propriétaire **avant** leur classement caméra, et `mount()` conserve un contrôle final de géométrie stricte. Même quota, même patrimoine d'assets approuvés, aucun import ni boucle supplémentaire, aucune modification des collisions.

## P4 — Sommets 3D propres aux arènes sur Android Low — 11 novembre 2026

Le [lot des sommets de stations périphériques](docs/P4_ANDROID_LOW_AUTHENTIC_VARIANT_APEX_2026-11-11.md) autorise **un sommet original à sept MeshParts** à proximité de la caméra sur Low (150 studs), remplaçant éventuellement **deux formes primitives**. Selon l'arène, il s'agit de l'antenne Orbital, de la couronne Towers, de l'aiguillage Crossroads ou du relais Classic/Harbor. Le quota revient immédiatement à zéro dès le premier palier de pression. Les sources sont les **quatre Models propriétaires déjà approuvés** ; aucun import, collision, boucle ou atlas graphique supplémentaire n'est ajouté. **À publier séparément sur Roblox après validation exacte du commit.**

## P4 — Finitions PBR des stations authentiques et correction de proximité — 11 novembre 2026

Le [nouveau lot de finitions des stations périphériques](docs/P4_PERIMETER_NEARFIELD_PBR_BOUNDS_2026-11-11.md) rend éligibles les modèles 3D authentiques des apex, armures, poutrelles, rotors, machines et contreforts à la finition **PBR 2K existante**, sans nouveau modèle, texture ni hausse de budget GPU. Le choix des sculptures proches se base désormais sur leur **géométrie réellement positionnée** au lieu d'un pivot potentiellement conservé à l'origine. Low conserve zéro overlay PBR ; les signaux d'alerte restent protégés. Cette évolution du code doit être publiée séparément sur Roblox après validation.

## P4 — Importation du tore partagé sur Towers dès la fenêtre prioritaire — 11 novembre 2026

Le [correctif de chargement du véritable anneau](docs/P4_AUTHENTIC_ATMOSPHERE_RINGS_AND_CROWN_2026-11-11.md) autorise désormais le même modèle Roblox original `125070862497818` à être priorisé à **22 secondes sur Orbital comme sur Towers**, plutôt que d'attendre systématiquement 42 secondes sur Towers. Il n'ajoute aucune requête, aucun worker ni aucune ressource 3D : tous les chargements restent contrôlés par la file globale de deux appels au maximum. Le chargement effectif sur Android reste dépendant du serveur et n'est pas garanti à 22 secondes.

## P4 — Crêtes extérieures authentiques 3D sur Low et PBR — 11 novembre 2026

Le [lot de crêtes sculptées](docs/P4_AUTHENTIC_EXTERIOR_RIDGES_LOW_PBR_2026-11-11.md) autorise sur Android Low **une véritable crête 3D originale à sept MeshParts** à moins de 290 studs, remplaçant potentiellement trois `WedgeParts` primitives. Le repli natif est immédiat sous pression. Medium/High peuvent appliquer les quatre atlas PBR 2K déjà approuvés sur les quatre modèles de crêtes, **dans le quota partagé existant**, sans nouveaux assets, collisions ni requêtes Roblox. La disponibilité des modèles et le rendu réel sur Android restent à confirmer.

## P4 — Colonne atmosphérique 3D proche sur Android Low — 11 novembre 2026

Le [lot des colonnes atmosphériques Low](docs/P4_LOW_AUTHENTIC_ATMOSPHERE_COLUMNS_2026-11-11.md) autorise **une seule sculpture 3D originale et approuvée** à 175 studs maximum, contre zéro auparavant. Les huit corps candidats par carte restent non physiques et leurs balises sont conservées. Dès la pression graphique 1, la Part primitive revient ; si un clone disparaît entre deux passages LOD, la restauration est immédiate. Pas de nouvelle requête AssetService, texture, boucle ni budget graphique. Les FPS Android et la publication Roblox restent à vérifier.

## P4 — Anneaux Orbital Low et couronne Towers 3D — 11 novembre 2026

Le [lot des grands anneaux et couronnes premium](docs/P4_AUTHENTIC_ATMOSPHERE_RINGS_AND_CROWN_2026-11-11.md) active sur Low les deux vrais tores Orbital créateur-approuvés, éligibles à remplacer **16 + 14 segments rectangulaires** avec **7 + 7 MeshParts** quand les sources sont disponibles. Towers peut remplacer sa grande `TowerCrown` Neon primitive par un tore horizontal 3D à sept MeshParts, utilisant **le Model existant `125070862497818`**, avec le signal natif, sans nouvelle requête Roblox. Les trois kits restaurent les éléments originaux sous pression ou absence de source. La couronne compte dans la censure adaptative Android et le budget PBR 2K partagé. **L'intégration GitHub et les contrôles source ne valent pas publication sur Roblox ni validation visuelle Android.**

## P4 — Tour extérieure 3D sur Android Low et couverture suivie — 11 novembre 2026

Le [lot d'amélioration de la skyline Android Low](docs/P4_ANDROID_LOW_EXTERIOR_TOWERS_AND_SOURCE_COVERAGE_2026-11-11.md) active **une** tour extérieure originale à sept MeshParts sur Low, à 275 studs au maximum, avec retour immédiat des quatre blocs natifs dès le premier palier de pression visuelle. Les quatre modèles de tours déjà approuvés sont également éligibles aux finitions PBR 2K **dans le quota existant** sur Medium/High. Un diagnostic local agrège uniquement cinq familles non-collisionnelles de la skyline (**60 cibles par arène source**), sans prétendre mesurer tout le jeu ni la totalité des objets visibles. La nouvelle PR ne publie pas directement l'expérience Roblox.

## P4 — Sculptures 3D des colonnes atmosphériques — 11 novembre 2026

Le [lot P4 des colonnes atmosphériques](docs/P4_AUTHENTIC_ATMOSPHERE_COLUMNS_2026-11-11.md) ajoute une substitution locale de **huit corps primitifs par arène** (4 piliers et 4 silhouettes) par les **cinq modèles de colonnes 3D originaux déjà approuvés**. Les signaux, anneaux, lumières, bandes et collisions restent natifs. Budget instantané : **Low 0, Medium 2, High Android 3 et High PC 4**, réduit sous pression. Le serveur charge désormais la colonne propre à l'arène active en premier. Les colonnes proches réutilisent aussi les **16 cartes PBR 2K déjà approuvées** via le quota partagé, sans nouveau modèle, texture, requête ou boucle. **Statut : code sur PR #809, non fusionné, sans test Engine/Android ou publication de Place.**

## Refonte P4 : piliers 3D des stations périphériques — 9 novembre 2026

Le [nouveau lot de remplacement des piliers primitifs](docs/P4_AUTHENTIC_PERIMETER_STATION_PILLARS_2026-11-09.md) réemploie les **cinq grands modèles verticaux 3D originaux et approuvés**, adaptés aux deux supports rectangulaires de chaque vraie station périphérique des cinq arènes. Par station, les deux anciens `Part` ne sont masqués **qu'ensemble et seulement si les deux vrais modèles MeshPart sont montés** ; toutes les propriétés de contact, le sol et les signaux restent inchangés. Résidence caméra : **Low 0, Medium 1 station, High Android 2, High PC 4** ; pression graphique et absence/source rompue restaurent les formes natives. Les pièces entrent dans le budget local Android ; deux compteurs distinguent les stations authentiques et le nombre de piliers primitifs réellement remplacés. **État : fusionné en source, sans validation Engine, Android ni publication Roblox**. Les autres formes primitives de station nécessitent des sources adaptées et ne sont pas présentées comme remplacées.

## Plan directeur actif — 9 novembre 2026

Le [nouveau plan de production premium](docs/PREMIUM_MASTER_PLAN_2026-11-09.md) fixe désormais l'ordre **P0 publication exact-SHA → P1 première manche compréhensible → P2 IA crédible à huit → P3 interactions signatures des cinq arènes → P4 grande refonte visuelle du premier plan → P5 catastrophes, animation et audio → P6 performances Android/PC → P7 rejouabilité**. Les plans antérieurs restent des références techniques, mais n'imposent plus l'ordre d'exécution.

**État de livraison vérifié — 9 novembre 2026 :** P0, P1 et P2 ont été publiés sur la place publique existante (dernier envoi attesté : [GitHub Actions #42650986552](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42650986552), commit `ae4ae044e991ef4ca28a991991f2e11b9df49c84`, place `95351659174730` / univers `10771083668`). **P3 porte maintenant sur les cinq arènes en code source** : circuit Classic → boost unique, Flux Master Crossroads → aiguillage renforcé, Skyrail Ace Towers → élan de pont, Orbit Master → pulsation chargée, et deux pads Harbor → transfert bonus. Les trois derniers sont préparés dans le [lot P3 cinq arènes](docs/P3_SIGNATURE_MASTERY_ALL_FIVE_ARENAS_2026-11-09.md), avec état personnel visible sur Android et messages FR/EN. **P3 n'est pas publié ni certifié Roblox Engine**. **P4 démarre sur les surfaces de mobilité les plus proches des joueurs :** les cinq arènes peuvent maintenant monter un [vrai carénage acier 3D d'origine créateur approuvée](docs/P4_GENUINE_3D_MOBILITY_PADS_FIVE_ARENAS_2026-11-09.md) sur les pads physiques, avec signalétique localisée de proximité même sur Android Low et budget graphique décroissant selon la pression. Aucun autre asset n'est inventé : la forme sculptée originale existe déjà en import serveur. À la demande de l'utilisateur, aucun nouveau test n'est déclenché pendant l'itération. Cela ne transforme pas les contrôles non exécutés en validations réussies et ne neutralise pas le verrou de publication exact-SHA. La signalétique P4 inclut désormais [un indicateur personnel de charge sur les vrais pads Classic/Harbor](docs/P4_LIVE_CLASSIC_HARBOR_PAD_MASTERY_READABILITY_2026-11-09.md), déclenché uniquement par le serveur et retiré après utilisation. **Extension P4 source** : [Towers, Orbital et Crossroads signalent leur vraie prochaine destination de maîtrise directement dans leurs structures 3D](docs/P4_LIVE_WORLD_MASTERY_SCULPTURES_2026-11-09.md), avec un carénage acier `CornerGuard` approuvé sur les aiguillages Crossroads réellement actifs, uniquement selon le budget Android. Aucun de leurs pads de mobilité n'affiche de faux bonus. **P4 n'est pas publié.** Le rendu, la qualité gameplay et les FPS réels Android restent à qualifier.

**Suite P4, stations périphériques — source du 9 novembre 2026 :** les trois grands blocs mécaniques de chaque station (boîtier central et deux compresseurs) disposent maintenant d'une substitution 3D authentifiée à partir des modèles `ApprovedServiceEquipmentTemplates.Orbital/Towers` approuvés, décrite dans [le dossier P4 des machines périphériques](docs/P4_AUTHENTIC_PERIMETER_MACHINERY_2026-11-09.md). Seules les stations proches et complètes sont substituées (Low 0 / Medium 1 / High Android 2 / High PC 3) ; les voyants, les lentilles, les collisions et les catastrophes conservent leur contrôle natif. Ce code n'est **ni testé en Engine, ni publié**. Les meshes peuvent rester en fallback si leur provenance ou leur taille réelle ne convient pas.

**P4 — rotor 3D approuvé et branché en source :** import original confirmé **Approved**, Model ID `133526819668194` ([upload #42691052644](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42691052644)). Le vrai rotor source est maintenant réutilisé sur les trois cylindres des stations proches de la caméra, mais **aucun build, test moteur ou publication publique de ce nouveau code n'est encore attesté**. [Plan et limites de réception](docs/P4_RUNTIME_PERIMETER_ROTORS_2026-11-09.md).

**Historique P4 — source de vrais rotors 3D :** le [rotor de station sculpté de 1 304 triangles](docs/P4_ORIGINAL_PERIMETER_ROTOR_2026-11-09.md) et son workflow d’import vérifié sont maintenant dans le dépôt. Le chargement en jeu reste volontairement désactivé jusqu'à l'obtention d'un Model ID approuvé ; il ne faut pas qualifier cette étape de substitution publique ni de test moteur.

**P4 — ailes et capots désormais branchés en source :** [deux assets originaux modérés Approved](docs/P4_RUNTIME_PERIMETER_ARMOR_2026-11-09.md), modèles Roblox 138096293972093 et 88962643359267 (workflow #42694744112), remplacent de manière conditionnelle les quatre WedgeParts de chaque vraie station proche ; cadence LOD et pression Android déjà existantes. Le code est intégré, **pas encore testé Roblox Engine ni publié**.

**Historique P4 — prochaines grandes surfaces primitives :** deux modèles 3D originaux, [ailes profilées et capots mécaniques](docs/P4_AUTHORED_PERIMETER_WINGS_CAPS_2026-11-09.md), sont préparés pour les 80 WedgeParts des quatre stations sur les cinq variantes. L'import sécurisé produit d'abord les assets approuvés, avant toute prétention de remplacement effectif en jeu.

**P4 — traverse et protection de générateur originales approuvées :** les deux Models [importés avec confirmation Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42696898936) (ID 108452611210970 / 113687802206554) ont désormais un montage 3D réversible sur les blocs exacts des quatre vraies stations. La [mesure de couverture 3D des stations](docs/P4_SOURCE_3D_COVERAGE_INVENTORY_2026-11-09.md) est **14/23 = 60,9 % de types de pièces source potentiellement substituables** ; elle ne constitue ni un pourcentage du jeu entier ni une vérification de rendu Android. Aucun nouvel upload public de Place à ce stade.

**P4 — sommet des stations, identité 3D par arène :** les quatre Model assets originaux ont été [réellement importés et approuvés](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42699542702), puis branchés en source pour les cinq variantes, avec restauration atomique des deux pièces natives. [Inventaire de couverture](docs/P4_SOURCE_3D_COVERAGE_INVENTORY_2026-11-09.md) : **16/23 = 69,6 %** des pièces-source de station ont une substitution 3D conditionnelle (Low et pression GPU conservent les primitives). Ce n'est pas le taux 3D global du jeu et aucune publication Roblox Place de ce commit n'est attestée.

**P4 — grandes tours extérieures premium 3D :** les quatre Model assets originaux de 1 232 triangles (hauteurs 21, 24, 27, 30) ont été [importés avec modération Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42702281053), puis branchés en source pour remplacer 4 grosses Parts natives sur chacune des quatre tours extérieures de la carte active (max Medium 2, High Android 3, PC 4). Les balises lumineuses/antennes sont préservées. [Plan et inventaire de la famille](docs/P4_EXTERIOR_SILHOUETTE_3D_2026-11-09.md). **Code non encore publié en Place, ni mesuré sur Android.**

**P4 — grand anneau-réacteur Orbital :** un [vrai tore métallique continu original](docs/P4_ORIGINAL_ORBITAL_SIGNATURE_RING_2026-11-09.md) de 7 232 triangles, Model Roblox `125070862497818` [vérifié Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42711150534), est maintenant intégré en source. Il remplace atomiquement les **16 arcs rectangulaires natifs** de l'énorme monument Orbital, sans toucher au cœur/socle, avec fallback streaming/qualité GPU. **Pas encore publié ni validé par Roblox Engine/Android.**

**P4 — vrai pont suspendu Towers :** un [pont forgé en géométrie originale](docs/P4_TOWERS_FORGED_SIGNATURE_BRIDGE_2026-11-10.md) de 3 042 triangles, Model Roblox `126298311664881`, [Modération Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42777274284), est intégré en source. Il remplace **les deux grandes Parts décoratives du pont suspendu dans le monument Towers** ; ni le Skyrail jouable ni ses collisions ne changent. Fallback streaming/qualité GPU et budget partagé; publication Roblox Place, vérification Engine et Android encore à faire.

**P4 — échangeur ferroviaire Crossroads :** le [nouvel échangeur original sculpté](docs/P4_CROSSROADS_FORGED_INTERCHANGE_2026-11-10.md) de **4 356 triangles**, Model `96622579843060`, est [Modération Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42778699782). Le kit source substitue **quatre grandes primitives** par un seul modèle 3D si ses sept MeshParts sont authentifiés. Les supports, signaux, rails de gameplay et bots restent intacts. **Source non encore publiée en Roblox Place et rendu Android non vérifié.**

**P4 — grande grue portuaire Harbor :** un [Model original entièrement sculpté](docs/P4_HARBOR_SCULPTED_MEGAGANTRY_2026-11-10.md) de **2 940 triangles**, Model Roblox `124368710235343`, a passé [l'import et la modération Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42780163672). Son kit source remplace atomiquement **trois énormes formes primitives** du pont de grue, du contrepoids et de la cabine, sans affecter les treuils, les câbles, les jambes, les spreaders ni le gameplay. LOD, pression Android, streaming et restauration des natives conservés. **Aucune publication de Place de ce commit ni validation Engine/Android.**

**P4 — observatoire Classic en vraie géométrie 3D :** les [deux paraboles originales concaves et le mât sculpté](docs/P4_CLASSIC_SIGNATURE_OBSERVATORY_2026-11-10.md), **6 664 triangles et sept matériaux**, ont été [importés et modérés Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42787663042) dans le Model Roblox `112493873850364`. Le kit source remplace **sept énormes primitives d'un seul coup** sur la vraie mégastructure Classic, sans changer les contreforts et le gameplay, avec retour aux originales en cas de LOD Low/pression/streaming. **Aucune publication publique Roblox Place ni mesure Engine/Android sur ce commit.**

**P4 — supports 3D de l'observatoire Classic :** les [deux contreforts, deux renforts inclinés et le panneau technique](docs/P4_CLASSIC_FORGED_SUPPORTS_2026-11-10.md) disposent maintenant d'un vrai modèle 3D original de **5 924 triangles et 7 MeshParts**, Roblox Model `91717127334369` [modéré Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42809450851). Le kit client remplace conditionnellement **5 primitives** et restaure les natives si nécessaire. Il est indépendant des **7 primitives** déjà couvertes par les deux paraboles et le mât. **Douze sur quatorze pièces natives de cette seule mégastructure sont éligibles à la 3D** ; les deux socles Foundation/InsetBase restent natifs. Ce taux local n'est PAS la couverture 3D de tout le jeu. Aucun test Engine/Android ni déploiement de Place sur ce commit.

**P4 — horizon sud Orbital :** 14 anciennes `ObservationArc` rectangulaires disposent désormais d'un remplacement par un véritable tore 3D creux de **7 048 triangles et sept matériaux** ([conception et garanties](docs/P4_ORIGINAL_SOUTH_ORBITAL_RING_2026-11-10.md)). Asset créateur `124474310430876`, [modération Roblox Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42821753995). Le kit source valide le modèle sud et chaque arc avant montage, conserve l'orbe/supports, et restaure les formes natives sur erreur, StreamingEnabled, qualité Low ou pression GPU. Le tore nord `ReactorArc` demeure indépendant. **Ce commit ne publie pas la Place, ni ne garantit le rendu Android.**

## Plan produit actif — 7 novembre 2026

Le [plan premium actualisé](docs/NEXT_PREMIUM_PRODUCTION_ROADMAP_2026-11-04.md#actualisation-opérationnelle--7-novembre-2026-priorités-de-livraison) fixe désormais l'ordre **G4 : version vérifiée → arbitrage IA multi-dangers → navigation physique des bots → interactions à huit → grands visuels 3D → performances Android → validation/publication exact-SHA**. Le correctif Harbor/Classic [#660](https://github.com/dbrckk/chaos-survival-roblox/pull/660) est fusionné en source ; l'IA multi-avertissements est en développement. **Le HEAD de GitHub ne prouve pas à lui seul l'état de la place publique Roblox.**

## Source-authentic Sky Spine gateway lighting — 5 November 2026

The four real Sky Spine gateway Models now add restrained, physically motivated local `PointLight` only on verified `SIGNAL` MeshParts from our creator-approved sculpture. Lights are disabled on Low and immediately under either primary or secondary Darkness, warning/shutter or visual GPU pressure. Caps Medium 1, High touch 1, High desktop 2; all Lights enter the existing `VisualBudgetRules` census. No extra geometry, collision or render loop. [Engineering and Android acceptance](docs/SKY_SPINE_GENUINE_SIGNAL_LIGHTING_2026-11-05.md). **Unpublished source until full exact-SHA Cloud verification.**

## Approved 2K PBR material continuity for real 3D bridges and Sky Spine portals — 5 November 2026

Genuine `PremiumSkybridgeModule` and `OriginalSkySpineCrown` UV/tangent imports now share the exact audited `OriginalGroundPbrTemplates` from the sculpted floors, instead of a flat material break between the real route and the main arch. Only identified ARMOR/ALLOY/BRUSHED/CERAMIC material groups are replaced; GRIP/CARBON/SIGNAL are preserved. Existing importer `SurfaceAppearance` instances are restored atomically when hazards trigger, PBR is disabled, pressure rises or geometry unloads. No new textures, unverified Roblox asset IDs, physics, timers or render loops. Mobile caps: one bridge + one gateway 2K on healthy Medium/High, zero on Low or when pressure rises. [Implementation and acceptance](docs/APPROVED_2K_PBR_BRIDGE_TO_SKY_SPINE_JOINTS_2026-11-05.md). Not publicly published.

## Authentic four-gateway Sky Spine silhouettes — 5 November 2026

Our creator-approved sculpted 3D Sky Spine gateway (`71492051540032`, 1,696 real triangles) now also replaces the primitive native porticos at the **two outer true physical Sky Spine steps 2 and 9**, completing the 2/5/6/9 family in each of the five arenas. Low/Medium/High caps are 1/2/4; source-authentic copies demote before native gameplay surfaces under Android pressure. An unexpectedly removed approved model immediately restores its server-authoritative native fallback, and no collider, asset import, render loop or remote is added. `LocalOriginalSkySpineOuterCrownCount` counts the real mounted outer models. [Milestone test and Android visual sign-off](docs/APPROVED_3D_FOUR_SKY_SPINE_GATEWAYS_2026-11-05.md). Not publicly deployed.

## Real near-camera 3D route shell coverage — 5 November 2026

Approved original `PremiumSkybridgeModule` and `PremiumJumpDeck` meshes now fit the actual source X/Z axes and physical decks, with adaptive segment counts to reduce repeated seams rather than the old forced 88%-length segment gaps. Medium now supports **three** nearby genuine bridge models and High **five** (each still limited to the original segments cap and Android Part census, aggressively demoted under VFX pressure). The real server `PlatformPanelN` is only hidden when authentic 3D geometry sufficiently covers the actual source footprint; incomplete, shuttered, collapsed, shrinking or late-streamed decks retain their honest original native floor paint. `LocalOriginalRoutePanelsCoveredCount` distinguishes installed source models from actually masked surfaces. [Details and device QA contract](docs/PREMIUM_NEAR_CAMERA_COMPLETE_ROUTE_SHELLS_2026-11-05.md). **No public deployment or unverified Android FPS claims.**

## Live-path verification for real grounded bot navigation — 5 November 2026

When a yielding Roblox pathfinding query returned, the NPC verified its physical base route only once and could continue walking a stale path for up to 11 seconds after geometry changed. Server bots now conservatively revalidate **only the immediate grounded segment** on a staggered 0.72–0.96-second cadence, looking for a truly collidable base and anchored new obstructions. Invalid routes are abandoned and their original objective quarantined, with per-rig `BotLiveRouteInvalidationCount` instrumentation. Turn waypoint tolerance is also stricter at real navmesh corners, preserving the original 3.8-stud straight-line arrival window. No extra expensive pathfinding task, polling loop or gameplay physics. [Engineering and acceptance contract](docs/BOT_LIVE_GROUND_PATH_CORRIDOR_AND_CORNERS_2026-11-05.md). **Source integrated; device, real round and public release evidence pending.**

## Anticipatory bot obstacle detection on real ground routes — 5 November 2026

A bot standing on a raised roof could previously select an unrelated ground-level spawn or Base waypoint despite lacking a real connecting route. Ground-only candidates now require real ground-network elevation. Ordinary grounded roaming also previews a short **10-stud physically collidable corridor** when choosing a distant target, throttled per bot (≥2.4 s) and restricted to the existing physical Base. Static obstruction triggers the existing seven-direction, five-floor-sample safe detour or the existing asynchronous validated pathfinder, rather than repeated wall collisions. Fleeing hazards, elevated parkour, committed world activities, player movement rules and spawn safety are unchanged. [Technical lifecycle and QA](docs/BOT_OBSTACLE_PREVIEW_REAL_GROUND_ROUTE_2026-11-05.md). **Source integrated; no public publish or observed Android performance claim.**

## Bot pathing respects real Towers skybridge shutter gates — 5 November 2026

The existing NPC navigation could choose physically colliding Skybridges while the real gate was Warning, Raising, Raised or Lowering. The existing shared `AISurvivorRules.platformAvailable` now takes the actual optional shutter phase at **16 existing server decision sites plus one own-footing safety check** (ordinary targets, disaster escape, social following, local recovery and committed goal validity). Closed gates are not valid destinations; NPCs already on bridges retain their existing humanlike shutter retreat. No new models, raycasts, physics, navigation loops or unfair moves. [Technical notes](docs/BOT_TRUE_SKYBRIDGE_GATE_PATHING_2026-11-05.md). **Source-only; device and public deployment QA pending.**

## Safe native 3D route restoration during collapse and shrink — 5 November 2026

Real imported 3D undercarriages and support columns now stop hiding the **original server-owned cosmetic girders** when the exact underlying physical platform enters collapse Warning/Gone, bridge shutters activate, the platform ceases being collidable or its true footprint shrinks. Event-based native mask reconciliation handles platform streaming without a new polling loop or physics change. [Failure mode and QA plan](docs/ROUTE_NATIVE_3D_FALLBACK_HAZARD_LIFECYCLE_2026-11-05.md). Source integrated; on-device validation and publication pending.

## Genuine long-skybridge undercarriage and near-camera support columns — 4 November 2026

A short 10–12 stud imported carapace previously could mask the entire primitive `PlatformUnderFrame` of a 26-stud route despite not covering it. The approved platform shell now requires ≥78% real long-axis / ≥72% cross-axis coverage; true 22-stud [owner-approved LongCradle](docs/PREMIUM_APPROVED_SKYBRIDGE_UNDERCARRIAGE_2026-11-04.md) underframes are prioritized on real nearby Sky Spine and promenade decks (maximum 4 High, 2 Medium, 0 Low). Up to the *existing* 16/8 original source support-column modules likewise prioritize nearby physical decks rather than modulo indexes. Exact-index nonphysical Sky Spine undercarriage bars and promenade underdeck trusses are reversibly hidden only when their actual large-scale source mesh is fully mounted. No extra route, collider, RemoteEvent, render loop or Roblox asset upload. **Source integrated; real mobile rendering and public deployment not certified.**

## Genuine sculpted route undersides nearest the player — 4 November 2026

The already approved five map-specific platform carapace meshes are now selected from **real safe jump decks nearest the actual play area**, rather than arbitrary `PlatformN % 6/12` index patterns that could leave foreground decks blocky. A single existing map/tier rebuild chooses up to **16 High / 8 Medium / 0 Low** authentic carapaces, with original server collisions, hazard paint, native fallback, and shrink-weld owner unchanged. The existing camera-ranked `PremiumRouteMeshKit` additionally reduces its optional 3D deck/bridge/underdeck residency when `OptionalVfxPressure` rises, without new loops or network calls. [Contract and Android QA criteria](docs/NEAR_CAMERA_APPROVED_PLATFORM_CARAPACE_2026-11-04.md). **Source integrated only; game public build and on-device visuals not certified.**

## New master improvement plan — 4 November 2026

The [post-3D and round-lighting premium production roadmap](docs/NEXT_PREMIUM_PRODUCTION_ROADMAP_2026-11-04.md) supersedes earlier task ordering while retaining the full VIS checklist, native Android/Studio gates and exact-SHA release policy. It prioritizes public access truth, true near-camera mesh routes, actual five-map playable depth, credible bots, material readability, 11 disaster reactions, original audio/motion, mobile UX and a single release-qualified public deployment. The baseline verified source is `d36f65157286`; its [Build Validation](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41923239283) and [seven Roblox Cloud suites](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41923254445) completed successfully. **No authenticated Android visual certification or publication of that source SHA is implied.**

## Five-arena round lighting readability pass — 4 November 2026

The disaster feedback controller was overriding the upgraded five-arena physical material lighting with an across-the-board 0.34 EnvironmentDiffuseScale during rounds, causing dark real floor/3D structural faces. One shared numeric calibration module now raises diffuse material bounce on Low/Medium/High (0.53/0.51/0.49 during standard rounds), keeps neutral specular under control and preserves disaster-specific color, exposure and blackout. **Darkness always uses lower diffuse (0.26/0.25/0.24), even when secondary in Double Chaos; its negative color-correction blackout still owns darkness.** The existing identity controller also improves Low/Medium ambient indirect scaling without new lights, effects, network or render loops. [Exact profile, safeguards and device QA](docs/ARENA_ROUND_LIGHTING_READABILITY_2026-11-04.md). **Source integrated, visual verification and public publication pending.**

## Orbital Ring: true compact station sculptures — 4 November 2026

The six Roblox-native spherical OrbitalStationMass placeholders are now eligible for authentic 3D replacements: alternating real seven-MeshPart satellite-solar-panel source (Roblox Approved Model 127850230318627) and magnetic-containment-service source (Approved Model 127295681925871). Both are already creator-owned and imported by the existing server machinery. Exact source IDs, source bounds, complete mesh mounting and outboard-only geometry safeguards precede locally hiding the original sphere and related solar fixtures. Android Low/Medium/High quotas are 1/3/6 and further decrease under GPU pressure; all clones count in the standard instance budget. No gameplay geometry, new network load or frame loop is added. [Source/QA details](docs/ORIGINAL_ORBITAL_STATIONS_COMPACT_3D_2026-11-04.md). **Source integrated, not public release or on-device rendering certification.**

## Genuine 3D Classic Grid / Crossroads outboard skyline — 4 November 2026

The four primitive broadcast blocks in Classic and the four native transit masses in Crossroads now have a **reversible true 3D substitution**, using the four already owner-approved Roblox district architectural Models (Observatory/Freight/Turbine/Aerial), with a different profile at each location. No new asset ID, API download, collision, render loop or fake route. Source provenance, outboard distance, native group ownership and bounded source geometry are required before mounting. Low/Medium/High show up to **1/2/4** different genuine Models when GPU pressure is healthy; pressure 1 and 2 demote them automatically. Original geometry stays as a safe fallback. The Orbital stations were intentionally excluded because larger architectural meshes near actual paths could obstruct play. [Source and QA contract](docs/APPROVED_MIDGROUND_SKYLINE_REPLACEMENT_2026-11-04.md). **No public publication or real Android certification has been performed.**

## Two complementary original Tower Run 3D cooling skyline architectures — 4 November 2026

Tower Run's **five formerly cuboid native cooling masses** now have **two distinct creator-approved original 3D industrial silhouettes**, not five identical copies. The large **6,380-triangle turbine spire** (`95543769387033`, [approved import](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41904066937)) forms towers **2 and 4**. The genuine **9,980-triangle hollow hyperboloid cooling stack** (`97498534364335`, [approved import](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41904135484)) with visible inner throat, real steel lattice, pressure manifolds, service ladder and radial louvers forms towers **1, 3 and 5**. Both sources consist of **seven MeshParts with UV/normals/tangents**, validated true mesh geometry and real Roblox owner moderation. Each original native noncolliding tower remains as a reversible fallback; Low up to 1 (only without FPS pressure) / Medium up to 2 / High up to 5 imported models with automatic GPU-pressure demotion, counted in the existing mobile visual budget. **62 approved creator Models** are registered. [Two-source architecture and Android verification requirements](docs/ORIGINAL_TOWERS_COOLING_VARIANTS_2026-11-04.md). **Source/runtime implementation is not evidence of public game deployment or real Android screenshots.**

## Complete sculpted maritime 3D water world around Storm Harbor — 4 November 2026

Storm Harbor now includes a **genuine original 960×960-stud sculpted marine sea** surrounding (never covering) the 320×320 playable arena, with a 329.6-stud dry central opening. Authored as a real 3D mesh with **6,152 wave/foam/current/glint triangles, 132 source objects and seven physically nonmetallic UV/tangent marine materials**, its Roblox Model **`111296950975600` is owner-approved** ([actual upload & moderation](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41889798492)). A deferred authenticated server loader and client-side LOD runtime mount all seven noncolliding MeshParts; no Terrain Water physics or false landing surfaces. The four nearby cargo barges have been lowered to their real waterline, preserving all native gameplay and fallback silhouettes. The sea is rendered on Low/Medium/High, is included in the same local performance budget, and remains visible as ShrinkingArena retracts its actual floor. **Source integrated, not a public update or Android rendering certification.** [Model proof, safety invariants & QA plan](docs/ORIGINAL_HARBOR_SCULPTED_SEA_2026-11-04.md).

## True chined 3D Storm Harbor nearshore freight craft — 4 November 2026

The **four remaining block-built cargo barges** now have a complete authentic original **3,718-triangle shallow-draft 3D source** with a tapered hull, six ribbed ISO containers, working deck hardware, a glazed wheelhouse and radar. The moderated **Approved creator-owned Roblox Model** is `132891280963772` ([real importer proof](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41862430789)); exact geometry is 28.35 × 11.18 × 13.30 studs and seven UV/tangent MeshParts. The actual optional server loader and four-client-model replacement are source-integrated. Each old noncolliding barge is locally hidden ONLY when its own complete real 3D source exists; Low and mobile pressure restore the original visible hulls without touching gameplay. All 7×4 cosmetic MeshParts count against the shared Android budget. **Source integration is not live-game publication or observed Android visual QA.** [Source/fallback and release checklist](docs/ORIGINAL_HARBOR_MIDGROUND_BARGES_2026-11-04.md).

## Real original Storm Harbor 3D hero signal station with live radar/hoist — 4 November 2026

The remaining **19 native decorative Part/WedgePart pieces** of the giant Harbor control tower are now replaced on eligible Medium/High clients with a uniquely modeled, creator-owned Roblox **Approved** seven-material 3D station (`73237902371094`; 2,816 true UV/tangent triangles, source and moderation [#41859877575](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41859877575)). The three *independent real MeshParts* for radar, cable and suspended cargo follow the already-running native hero animation; the emergency storm lens remains visible and reactive. Native geometry is preserved and restored on streaming, Low, missing asset or shrink; no new collision, lighting source, update loop or RemoteEvents. **This is a source/runtime integration, not a certified public deployment nor an observed Android rendering.** [Detailed geometry, quality caps and real device QA](docs/ORIGINAL_HARBOR_HERO_SIGNAL_TOWER_2026-11-04.md).

## Four authentic animated 3D Storm Harbor cargo cranes — 4 November 2026

Two NEW creator-owned, Roblox **Approved** original kinetic Models, container crane `75684193304551` (3,400 triangles) and cable-reel crane `98809955094422` (5,232 triangles), now have independently addressable real 3D structural, trolley, hoist-cable and suspended-load MeshParts. The client imports them on the four **existing** noncollidable Harbor skyline cranes and follows the already-running native trolley/hoist animations through event-driven CFrame changes — **no extra animation loop**, gameplay object, light or collision. Every model has seven UV/tangent-authored original material MeshParts, strict server source validation and a reversible native fallback. Android Low has no new crane models; Medium at most 2, High at most 4, both automatically demoted during FPS pressure and counted against existing local visual budgets. **Source integration is not yet live Roblox publication or Android visual certification.** [Two kinetic source imports and moderation](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41856104459) · [Technical and visual QA contract](docs/ORIGINAL_HARBOR_KINETIC_GANTRIES_2026-11-04.md).

## Original enclosing 3D lobby columns: Approved (4 November 2026)

A completely new, creator-authored **closed 3D pylon shell** now covers the four original 2.2×10×2.2 lobby colliders with an opaque manufactured octagonal body (2.84×10.36×2.84 source; 0.16 chamfer). The fully audited UV/tangent glTF was uploaded as Roblox creator Model **`75945454705246`**, moderation **Approved** ([source and moderation proof](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41825253849)). The client switches from the older open-column sculpt to this exact server-sanitized Model when available, hiding all four primitive pylon blocks **locally only** while preserving original collisions, lighting, signs and full native fallback. On a source failure the old verified 3D asset keeps the collision core 50% visible, so players never collide with an invisible pillar. Medium/High budgets and Android backpressure remain unchanged. **Source integration is not a public release or measured Android signoff.** [Technical details and acceptance checklist](docs/ORIGINAL_ENCLOSED_LOBBY_PYLON_SHELL_2026-11-04.md).

## Genuine approved 2K SurfaceAppearance PBR on the 3D UV arena floor (4 November 2026)

Four source-audited, creator-owned 2K texture families (16 approved Roblox Image IDs: albedo, OpenGL normal, roughness, metalness) are now pre-serialized as **Rojo SurfaceAppearance templates** and selectively mounted on the **real UV/tangent-authored original MeshParts**, not the 0.035-stud native underlay. Each of the five arena variants selects its themed finish: armor / brushed titanium / roadway weathered steel / reactor ceramic / maritime oxidized steel. The low-end phone budget is zero additional 2K mesh textures; Medium Android 2, High Android 6 near-camera genuine 3D floor modules, falling back under existing FPS pressure to 1/0 or 3/1. Existing original 2K materials are not redundantly allocated to native panels hidden behind the imported 3D art. Texture fields are never assigned by client scripts; genuine original MeshPart loss re-enables native art. This is a source milestone requiring real Android UV/FPS visual signoff, **not a public update**. [Full technical details](docs/ORIGINAL_GROUND_2K_UV_PBR_FIVE_ARENAS_2026-11-04.md).

## Adaptive full-arena original 3D ground coverage (4 November 2026)

The approved, creator-owned 2,976-triangle floor model can now occupy **all 36 real manufactured floor bays on healthy High clients** (up from 24); Medium increases from 8 to 12, while Low remains 2. The already-running Android frame-pacing/Parts pressure owner automatically lowers model residency to **High 24/16, Medium 8/4, Low 2/1** for pressure levels 1/2. Every real MeshPart is still counted by the same Android visual ledger and dismounted on shrink/streaming; collisions, playable platform topology and hazard warning overlays remain server-authoritative. No new timers, frame loops or asset upload. This is source-level coverage, not a claim of verified Android screenshots or public release. [Implementation and budget](docs/ORIGINAL_PREMIUM_GROUND_3D_2026-11-03.md).

## Original 3D tall supports and open long skyway undercarriage (4 November 2026)

Six additional **creator-owned, Roblox Approved** authentic 3D models are now source-gated and integrated: five arena-specific forged 14-stud column families plus one 22-stud open-frame cradle for elevated promenade/Sky Spine routes. Their genuine MeshParts mount on EXISTING server-owned noncolliding `PlatformSupportN_M` cosmetics or the real solid route deck; the matching native blocks are locally hidden only after each source model actually mounts. No fake collision/paths. Source support follows server ShrinkingArena, with one Size event per selected support, avoiding double shrink, no RenderStepped. Medium at most 8 source column segments + 1 long cradle; High 16 + 2; Low zero. The previous original 18-stud square hub hull is preserved. The creator registry now covers **50 Approved models**; public publication and real Android visual sign-off remain separate milestones. [Original source, imports, limitations and QA](docs/ORIGINAL_LARGE_SUPPORTS_AND_LONG_ROUTE_CRADLE_2026-11-04.md) · [Six approved imports](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41808940118).

## Source-backed replacement of old structural bevels and bridge ribs (4 November 2026)

After a **genuine** approved carapace or bridge girder is mounted, a client-only reversible substitution now masks the *matching* old server-owned visual `PlatformBevel`, `PlatformUnderFrame`, or `SkybridgeRib` Parts. This finally avoids layering real 3D models over toy-block fallback. The live colliders, surface hazards, luminous direction rails, and unaffected decks remain untouched. All visuals restore on streaming/map/quality changes. Imported X/Z bridge length axes now shrink along their true mesh-local direction. [Source contracts and remaining native visual backlog](docs/ORIGINAL_PLATFORM_CARAPACES_BRIDGE_2026-11-04.md).

## Sculpted original 3D platform undersides and bridge girders (4 November 2026)

Six NEW creator-authored, seven-material Roblox Model imports (all **moderated Approved**) now cover the next visual target: distinct machined **underside carapaces** for Classic / Towers / Crossroads / Orbital / Harbor and true **structural side girders** for permanent skybridges. The guarded runtime reuses existing platform welds, CollapsePhase/shrink listeners and Android tiers (no 3D on Low; Medium 1/20, High 1/12 eligible jump decks; selected bridges Medium 1/6 and High 1/3). Genuine mesh pieces replace rather than layer over the matching native wedge/brace/rail family; remaining decks retain fallback. The source-only build/publication status is tracked separately. [Six Approved model imports](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41798024000), [technical integration and unconverted areas](docs/ORIGINAL_PLATFORM_CARAPACES_BRIDGE_2026-11-04.md).

## Authored 3D replacement for every remaining small floor fitting (4 Nov 2026)

Three **Roblox Approved, creator-authored** 3D mechanical Models replace the remaining local floor WedgePart corner bevels + lens overlays, all native circular service bolts, and Harbor square tie-downs. Medium replaces 6 fasteners; High replaces 4 corner wedges, 12 fasteners, and Harbor's 4 tie-downs. Low does not create these props. No new physics, lighting, draw loops, or shrink listeners. The non-idempotent small-bolt upload received HTTP 500; instead a **new 10x source-geometry** model was created/imported and verified as approved. [Source and safety QA](docs/ORIGINAL_FINAL_FLOOR_HARDWARE_3D_2026-11-04.md). GitHub source integration is **not** evidence the public Roblox experience has updated.

## Six creator-approved original 3D floor relief families (4 November 2026)

Six newly sculpted true triangulated MeshPart Model packages are Roblox-**Approved**: the universal Android Low floor plate, Classic armored hatch, Towers expansion rail, Crossroads anti-slip tactile strip, Orbital flux track, and Harbor forged tie-down. They replace the matching first-layer primitive floor pieces with source-gated actual 3D meshes, native fallback, tier budgets (Low 6 / Medium 16 / High 28) and the **same existing shrinking Base.Size follower**. The actual floor/hazards/collision remain server-owned and unchanged. [Verified moderated source/upload workflow](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41736767816); [asset IDs, runtime and remaining visual QA](docs/ORIGINAL_FLOOR_RELIEF_3D_REPLACEMENT_2026-11-04.md). **Repository integration is not proof of game publication or Android display.**

## Original moving 3D scene machines — five arenas

All five formerly primitive client-side ambient machine families now have separate, owner-created, Roblox-**Approved** original 3D Model assets: Classic broadcast drones, Towers lift cabins, Crossroads beacons, Orbital microsatellites and Harbor suspended cargo. Their animated mesh replacements reuse the existing 10 Hz owner and ReduceMotion, have no gameplay collision, and respect Low/Medium/High 2/4/6-model residency. The [five-model source/approval workflow](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41733818047) succeeded. **This is merged source, not proof of public game deployment or Android visual certification.** [Technical audit and remaining work](docs/ORIGINAL_ANIMATED_AMBIENT_3D_REPLACEMENT_2026-11-03.md).

## Original premium service machines — five unique approved assets, source candidate

The five arenas now have purpose-built, fully triangulated original 3D models for Classic cameras, Towers industrial maintenance, Crossroads route sentinels, Orbital power canisters, and Harbor mooring bollards. All five Roblox owner MODEL assets were **moderated Approved** in [import #41729439190](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41729439190). They are integrated with a server asset allowlist, safety sanitizer, client camera-tier quotas (Low 1 / Medium 2 / High 4), no-collision replacements of native fixtures, and the existing shrink/LOD owners. **Approved assets and merged GitHub code do not establish public release or mobile visual QA.** [Exact source/asset and QA notes](docs/ORIGINAL_FIVE_ARENA_SERVICE_MESHES_2026-11-03.md).

# Chaos Survival — Roblox

## Nouvelle architecture 3D Sky Spine originale (3 novembre 2026)

**Vrai modèle triangulé approuvé par Roblox, ID `71492051540032` (1 696 triangles, 7 matériaux), import réussi : [action #41660854748](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41660854748).** Le premier import a été refusé pour un nom d'asset trop long ; la correction est vérifiée. Les deux ponts centraux réels de Sky Spine (`SkySpineStep=5/6`) reçoivent maintenant leur propre silhouette industrielle sculptée et authentifiée, et les anciennes poutres natives hautes sont masquées *seulement* pendant que les nouveaux MeshParts sont réellement présents. La structure, le colliseur, le routage des robots, le danger, les rails et les repères restent de source serveur.

**Qualité Android :** Low 0, Medium 1, High 2 nouveaux modèles simultanés, déjà inscrits au même plafond de Parts/effets, sans boucle LOD supplémentaire. Les modèles ne créent ni collisions ni faux itinéraires ; collapse, shrink, streaming tardif et changement de carte restaurent immédiatement l'original. **Statut de publication :** source fusionnée/import approuvé ; confirmer les cinq suites moteur + publication publique au SHA exact avant de déclarer cette mise à jour visible en jeu. [Source et critères QA](docs/ORIGINAL_SKY_SPINE_CROWN_3D_SOURCE_2026-11-03.md).

## Original underdeck 3D approuvé et intégré — lot 3 novembre 2026

Un modèle original de treillis, châssis industriel et groupes mécaniques de **3 072 vrais triangles**, en **sept matériaux**, a été créé puis approuvé par Roblox (Model **84582262145054**, [workflow #41644715829](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41644715829)). Le kit client existant fixe des copies purement visuelles **sous les vraies plateformes physiques** lorsque suffisamment grandes et sûres, en nombre strictement limité (Android **Low 0 / Medium 2 / High 4**). Aucun faux chemin, collision, lumière, API payante, nouveau polling ni téléchargement d'asset client.

**État de publication :** intégration de code réalisée ; ne pas supposer que l'asset est visible publiquement avant le build, les cinq suites moteur Roblox et le workflow de publication réussis **sur le SHA exact**. L'audit Android des textures, silhouettes et FPS reste ouvert. [Dossier d'intégration et preuve de modération](docs/ORIGINAL_UNDERDECK_CHASSIS_SOURCE_AND_IMPORT_2026-11-03.md).


## Vrais ponts 3D sur les 26 paliers des promenades et Sky Spine — 3 novembre 2026

**Grand lot de formes 3D :** les deux vraies passerelles panoramiques (16 paliers) et le Sky Spine (10 paliers) des cinq arènes peuvent désormais réutiliser les **véritables MeshParts de pont originaux approuvés Roblox**, et non seulement des cubes natifs. Le kit classe les objets à partir des vrais attributs serveur de route permanente et place les 3D en priorité **devant la caméra**, dans les quotas Android existants, sans modifier une seule collision ni créer de faux pont. Les quatre ponts Towers existants restent inchangés ; leurs dangers continuent de masquer immédiatement les habillages 3D.

**Correction de livraison essentielle :** [Build #41639154856](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41639154856) du précédent lot lumière a réussi, mais [Cloud #41639166067](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41639166067) a relevé une attente obsolète `Foil` pour Towers après remplacement voulu par `Metal` ; [publication #41639140940](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41639140940) a correctement refusé l'ancien candidat. La règle du test est corrigée sans revenir à l'aspect miroir. Le nouveau lot ne sera déclaré **public** qu'après validation du build, des cinq suites réelles et du publisher sur **le même commit**, puis la qualité visible devra être vérifiée sur un vrai Android. [Détails et protocole de sécurité](docs/ORIGINAL_3D_PERMANENT_SKY_ROUTE_ART_2026-11-03.md).


## Direction artistique de la lumière et des matériaux — cinq arènes

**Lot de production visuelle 3 novembre 2026 :** nouveaux véritables angles solaires différents par arène (`ClockTime` **et** `GeographicLatitude`, pas seulement une teinte), meilleure lumière diffusée sur les façades et sols de premier plan, neutralisation des couleurs trop saturées des projecteurs existants, et rehaussement des matières natives de secours Low Android sur Classic/Towers/Crossroads/Orbital/Harbor. La lumière ne relance plus de dizaines de tweens sur chaque mise à jour du compte à rebours. Le changement n'ajoute **aucune** lumière et conserve les plafonds PBR Android **0/32/72**, les projecteurs **0/2/3**, les IDs d'assets Roblox approuvés et l'autorité visuelle des catastrophes.

**Statut :** source modifiée, publication et rendu Android de ce nouveau lot à vérifier au SHA exact avant toute certification. [Plan, réglages, budgets et protocole Android](docs/AAA_LIGHTING_MATERIAL_ART_DIRECTION_2026-11-03.md).


## Correction bloquante : vrais bâtiments 3D approuvés et budget Android

**3 novembre 2026 :** quatre vrais MeshParts de façades et toits ont été importés et modérés [Approved #41629861517](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41629861517), puis intégrés au code source des 16 bâtiments des cinq arènes. La tentative de release sur `edd1b259` a pourtant **échoué** : [Build Validation #41630960261](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41630960261) bloquait le nouveau dossier graphique `ApprovedDistrictFacadesLocal` absent des budgets, même si [les cinq suites Roblox moteur #41630970496](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41630970496) ont réussi. Le jeu public **n'a donc pas été mis à jour par cette tentative**.

Le correctif inscrit les vrais meshes dans le budget partagé, réduit la concurrence des imports Roblox, masque instantanément le décor quand un bâtiment disparait ou que l'arène rétrécit et stabilise la sélection caméra sur Android. Les quotas originaux **Low 1 / Medium 3 / High 6** restent identiques. [Diagnostic, détails et garde de publication exact-SHA](docs/APPROVED_DISTRICT_3D_RELEASE_RECOVERY_2026-11-03.md). **La sortie publique de ce correctif doit être confirmée par la réussite d'un nouveau build, des cinq suites et du publisher sur le même SHA ; aucune capture native Android n'est encore certifiée.**


## Version publique vérifiée et prochaine amélioration du sol 3D (3 novembre 2026)

La version publique la plus récente **vérifiée au moment de ce relevé** est `c297b2a34384d2c169e9123b2939df4d19f7386d` : [Build Validation #41624260822](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41624260822), [cinq suites moteur Roblox #41624270887](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41624270887), et [publication publique #41624914108](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41624914108) confirmés. Les véritables dalles industrielles 3D sont donc publiées, **mais leur qualité perceptive et leurs performances Android ne sont pas certifiées par captures natives**.

Le prochain chantier cible [la sélection des vrais sols 3D visibles devant le joueur](docs/ORIGINAL_GROUND_CAMERA_PRIORITY_2026-11-03.md) avec un budget mobile inchangé. L'amélioration source ne devient live qu'après nouvelle validation et publication exact-SHA. Les sections historiques ci-dessous documentent des jalons antérieurs et ne doivent pas être prises pour le dernier statut de production.

## Quatre véritables modèles 3D de façades/toits — production 3 novembre 2026

**Nouveau jalon de géométrie originale :** quatre familles industrielles `observatory` (1 524 triangles), `freight` (1 740), `turbine` (2 256) et `aerial` (2 376), avec vraies surfaces 3D, UV et tangentes. Les quatre conversions OBJ → glTF ont **réussi** dans le [workflow source #41629230431](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41629230431). [Dossier complet](docs/ORIGINAL_FOUR_DISTRICT_ROOFLINES_3D_2026-11-03.md). Le workflow de l'importeur Roblox existant est étendu pour générer ces assets depuis le projet ; leur **import et modération ne sont pas présumés réussis** tant que la réponse Roblox n'a pas été vérifiée. Pas de changement de jeu public avant intégration et validation exact-SHA.

## Portails industriels 3D authentiques sur les bâtiments (chantier source, 3 novembre 2026)

Le dernier lot visuel réutilise le vrai portail `perimeter_gate` approuvé chez le créateur Roblox (Model `137284215564363`) pour habiller les entrées des **16 bâtiments de districts** au plus près de la caméra. Le serveur expose une seule copie saine du package chargé à l'origine ; le client monte uniquement **1 portail Low / 2 Medium / 4 High** à la fois, sans collision, réseau supplémentaire, faux AssetId ni boucle de rendu. Les façades natives restent toujours visibles en secours. [Source, restrictions, budget Android et validations à obtenir](docs/APPROVED_3D_DISTRICT_GATEWAYS_2026-11-03.md). **Ce changement reste candidat dans le code tant qu'une validation complète et une publication exact-SHA ne sont pas réussies.**

## Production de vrais assets 3D de plateformes / ponts — 3 novembre 2026

Deux **nouveaux assets 3D originaux triangulés**, et non des Parts natives, sont prêts à importer dans l'inventaire Roblox du créateur : **1 156 triangles** pour le plateau de saut industriel, **920 triangles** pour un tronçon de passerelle. Chaque mesh possède des normales, UV, tangentes et sept matériaux originaux. Source et procédure : [pipeline de vrais assets de plateformes et passerelles](docs/REAL_3D_PREMIUM_DECK_BRIDGE_ART_PIPELINE_2026-11-03.md). **Import Roblox vérifié et approuvé** : plateau original Model `98478693994864`, module de passerelle Model `94023662427980` ([preuve d'import](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41614704198)). Les vrais modèles sont intégrés par `PremiumRouteMeshAssets` et `PremiumRouteMeshKit` dans le code source ; les plateformes physiques et leurs catastrophes restent inchangées. Leur rendu public et leurs performances Android sont à confirmer après validation/publication exacte du nouveau commit.

## Registre urgent visuel AAA — 3 novembre 2026

**[Inventaire détaillé : 124 actions visuelles priorisées (33 P0 / 80 P1 / 11 P2)](docs/URGENT_AAA_VISUAL_BACKLOG_2026-11-03.md)** : assets 3D/2D, meshes originaux, textures PBR, ciel/lumières, météo, onze catastrophes, avatars/IA, UI mobile, caméra, LOD, vignettes et critères de livraison. **Ce registre ne certifie pas encore un rendu AAA.**

**État vérifié au 3 novembre 2026 :** le blocage historique des socles 3D (4 pièces attendues contre 11 générées) a été corrigé. Le commit `38f1a3b184b85848a479cfe8bd9d4a49a6b06540` a passé [Build Validation #41621176592](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41621176592), [les cinq suites moteur Roblox #41621187036](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41621187036) et [la publication publique #41621772081](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41621772081). **La validation visuelle sur Android reste à faire ; les changements postérieurs à ce SHA ne sont pas publiés.** Les anciens jalons « non live » détaillés plus bas sont des historiques, pas l'état courant de `main`.

Fast multiplayer disaster-survival game built with Luau + Rojo.


## Current premium visual milestone (3 November 2026)

**Live baseline:** the existing public Chaos Survival place was updated at exact main SHA `22308afc4dded7e84c165734cd72dbf40a7cc7bb` ([verified Roblox publisher](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41601949632)). The next art-direction milestone is tracked in [premium 2D/3D, PBR and lighting production notes](docs/PREMIUM_ART_PASS_2026-11-03.md). It changes rectangular landing lip Parts into four true sloping 3D wedges, displays a strictly bounded number of **already approved original imported MeshPart models** on Android, creates original resolution-independent machined UI frame artwork, reduces colored environmental wash, lifts mobile readability and expands the existing PBR allocation within unchanged Android global limits. This source milestone is **not confirmed live** until its new exact source SHA is built, tested on all five Cloud engine shards, and published through the guarded existing-place workflow. Physical Android capture and frame-rate validation remain separate from source/Cloud correctness.


## New original volumetric arena floors (source candidate; not live yet)

The [second major visual architecture pass](docs/FIVE_ARENA_VOLUMETRIC_GROUND_2026-11-02.md) gives **all five arenas 73 original, non-colliding floor/undercarriage details per active map**, including 36 original structural floor panels eligible for the existing licensed 2K PBR camera budget. The real shrink owner now scales this artwork with the survival floor: no phantom platforms, AI walls or hazard masking. The preceding [PR #564](https://github.com/dbrckk/chaos-survival-roblox/pull/564) structural corner cladding passed exact-SHA Build Validation and all five real-engine suites on 2 November (source SHA 2732da8), but neither the new floor treatment nor that cladding has been published to the public Roblox experience. Await full validation before deployment.


## Next major update — authentic eight-bot ground routing and five-arena Android quality

The [2 November large-release candidate](docs/MAJOR_RELEASE_2026-11-02_PHYSICAL_NAVIGATION.md) adds asynchronous, **physically supported ground-obstacle pathfinding** for bots which cannot escape major arena structures using local detours. Routes are server-owned, never teleport and are cancelled by real hazards or round changes. Combined with the **already merged** raised-deck AI escape corrections, this is the next substantial gameplay reliability milestone; the existing original 3D arena/lighting and mobile quality targets remain mandatory release gates. **This branch is not published to Roblox.** Compile, five real-engine suites, authenticated Studio visual review and physical Android testing are required before the guarded public-place update.


**Eight-participant round roster (published, awaiting physical playtest):** the owner has set the starting place to eight human visitor slots. The public build now contains the READY-time autofill logic for up to **seven original AI bots**, aiming for eight participants at the start of a round (not eight survivors at every instant). The exact-sha public publishing workflow succeeded on 1 November; Android and multiplayer observation must still confirm live spawns and performance. See [eight-seat autofill and validation](docs/EIGHT_PARTICIPANT_BOT_AUTOFILL_2026-11-01.md).

## Monumental original 3D escape gates — five visually legible physical routes (source candidate)

The next major premium visual milestone replaces a major weak point seen in the owner's Android captures: many bare repeated elevated blocks with no obvious route hierarchy. Each of the five genuine 320-stud arenas now has **12 new full-height original 3D climb monuments** (4 real routes × ENTRY / TRANSFER / SUMMIT): tall engineered exterior supports, angled fins, overhead gantries, metal undercarriages, sparse lit directional cues and **five different original world-specific mechanical crowns**. Every 3D part is **bound to the actual server-owned collision deck**; no false platforms, hidden barriers or excess floating HUD labels. Physical gameplay and the existing green AI-stall recovery are unchanged. This is source-only pending exact-SHA Roblox Cloud + real Android verification, not a live update. [Full architecture, mobile part budget and safe-collapse checks](docs/MONUMENTAL_ESCAPE_ROUTE_ARCHITECTURE_2026-11-02.md).

## Real AI navigation and wall-stuck recovery — source milestone

Android players reported bots turning in circles, walking into machines, standing still against obstacles and jumping erratically during actual survival rounds. A source investigation identified the real bug: the AI abandoned a blocked goal and reset its failure counter **before its own physical rescue logic could fire**. This pass corrects that underlying dead path, makes each real NPC select a new **grounded, collision-tested detour on the FIRST confirmed stall**, and avoids repeating the same impossible destination for 7.5 seconds. All changes keep normal Humanoid walking, real jump physics, interactive station claims and the eight-participant round contract. Android disaster lighting now also includes the previously reviewed midtone repair [#548](https://github.com/dbrckk/chaos-survival-roblox/pull/548). No claim of physical Android success or public publication is made for the new source. [Implementation and actual gameplay acceptance](docs/PHYSICAL_AI_STALL_RECOVERY_2026-11-02.md).

## Android gameplay remediation — brighter worlds, unsticking bots, visible survival goal (source only)

The owner shared a second physical Android evidence set: gameplay is **too dark**, bots oscillate or become **stuck** in world geometry, platforms appear **too plain**, and the true win condition is hidden behind optional shard progress. A new production corrective pass targets these weaknesses rather than just decoration: daytime high-visibility lighting across ALL FIVE maps; server-owned AI forward-progress and supported-ground detours; permanent mobile "SURVIS X s" guidance in the existing round-focus strip; and three-layer solid-looking 3D engineering detail on a tier-bounded subset of physical decks. All added platform detail is noncolliding and linked to existing shrinking/collapse logic. Prior core_a Cloud assertions were outdated following visual changes and are corrected in the existing test suites, but their corrected version **still requires fresh real-engine certification**. [Evidence and exact fixes](docs/ANDROID_GAMEPLAY_CORE_REMEDIATION_2026-11-02.md). **This corrective pass was source-only at its original milestone; the subsequently verified public update is exact SHA `79e73a2a5030e9cde0adf80e6f1a8fda51959728` (run 41489124289).**

## Physical Android playtest feedback — source readability repair

On 2 November the owner tested the **actually published** Sky Spine version: 4 physical Android landscape captures display **8/8 alive** with active game hazards, large 3D platforms and bot-like participants. Those captures refer to the earlier verified public publish [run 41428449036](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41428449036), exact SHA `a3e414bea21d6dec9e0d8bed7a454c8b42415699`; a newer publication has since been verified below. These captures reveal real issues: stacked oversized world signs, overlong FLUX labels obscuring the camera, distant AI name clutter, literal `\\n` in Sky Spine signs, and overwhelming noninteractive neon. The Android mini-window on the right is **from another app**, not Roblox HUD.

The new **source-only** polish cuts world 3D sign distance, renders Sky Spine sign line breaks correctly, moves short mobile FLUX text into a left status lane, hides unnecessary distant AI labels and attenuates *decorative* neon while retaining important hazard / parkour edge cues. See [real-capture findings and regression targets](docs/ANDROID_GAMEPLAY_CAPTURE_LEGIBILITY_2026-11-02.md). **The live game still shows the old labels until this newer patch itself passes Build/Cloud verification and the manual public publication workflow.**

## New AAA-scale Sky Spine interchange — developed source candidate

Every 320×320 arena now has a **third genuinely collidable 200+ stud sky bridge** crossing PERPENDICULAR to the previous twin sky promenades. Ten permanently safe 12-stud landing decks create an H-shaped elevated parkour network with two playable junctions. Each world has an **original monumental sky fortress** (radar, cargo hoist, routing fins, orbital core or storm crane), engineered trim and navigation.

**Real environmental interaction:** from either of two elevated command machines, a human or physically present bot can hold a Roblox prompt for 0.7 s to **turn nine previously open 2.4-stud sky gaps into an ACTUAL solid continuous rescue crossing** for ALL eight participants, for the rest of that round. Before activation, the ten permanent decks remain jumpable. No temporary walkway can vanish under a running player; no extra pay-to-win or teleport. [Complete design, safety and release criteria](docs/SKY_SPINE_COOPERATIVE_INTERCHANGE_2026-11-02.md). **Code is not public until next exact-SHA Cloud/Android release certification and actual publish.**

## Public experience status

[**Play Chaos Survival on Roblox**](https://www.roblox.com/games/95351659174730/Chaos-Survival) · [Creator Dashboard](https://create.roblox.com/dashboard/creations/experiences/10771083668/overview)

The experience is **public to eligible 16+ Roblox players** under the documented creator content rating. **Latest VERIFIED public publication: 2 November 2026**, exact source SHA `79e73a2a5030e9cde0adf80e6f1a8fda51959728`, existing Universe `10771083668` / Place `95351659174730`. The [authenticated public publishing run 41489124289](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41489124289) has a successful **Publish ONLY the existing public starting place** step and exact-SHA build/engine verification. The newer `main` SHA `b9a52815e696967d871d065cb5543519362e4a98` passed [Build Validation 41494260248](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41494260248) and [Cloud engine 41494359576](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41494359576), but is **not verified as deployed to the public place**. A green source or engine check alone never establishes live publication.

**What remains uncertified:** physical Android/desktop screenshots of all five maps, 8-seat bot-spawn observation and true co-op relay usage, touch accuracy, FPS/thermals, real-player behavior, DataStore handoff/rejoin under production failures, and actual D1/D7 retention. The next source-only gameplay refinement [moves cooperative DASH stations closer to genuine first-minute routes](docs/COOP_RELAY_ROUTE_DISCOVERY_2026-11-01.md); it is not yet deployed. This is a working **public playtest** and is not a verified 9/10 or AAA visual finish. Source improvements on `main` or other branches created *after* the last published SHA do not reach the public game until another explicit, gated publication.

**Visual audit in progress (source only):** the [existing 15-frame Studio bot-view pipeline](docs/AI_VISUAL_QA_15_FRAMES.md) now supports **all five real arena variants**, rejecting lobby, wrong-arena or forged PNG manifest identity. The [Android/temporary Windows workflow](docs/AI_VISUAL_QA_REMOTE_ANDROID.md) can capture **75 real PNGs / five 15-frame reports using one authenticated Studio session** (`arena=All`), while the persistent Studio runner selects any one arena. This functionality is prepared in code **but has not produced certified screenshots**. Official signed, interactively rendered and authenticated Roblox Studio is still required; it does **not** constitute actual Android FPS certification or automatically publish the public game.

**Public page visual update (20 October 2026):** the owner shared a screenshot from the Roblox Android game page showing a **custom Chaos Survival icon now visible**. The larger experience detail-page thumbnail still displays Roblox's default placeholder. The public game-media API also returned an empty list on 20 October. **Do not re-upload or replace the working icon just to clear an outdated checklist.** A real gameplay-based 16:9 thumbnail is still needed; existing Canva graphics are promotional concepts, not native game captures. Creator's Experience Detail Page image upload requires an authenticated creator session and a local media file. Thumbnail Personalization Open Cloud concerns Home Page thumbnails, not the main icon or detail-page gallery. Avoid changing API keys to bypass access checks.

For factual verification, see the [live status record](docs/ETAT_PUBLIC_2026-10-19.md), [launch runbook](docs/MISE_EN_LIGNE_1_0.md), and [release gate issue #79](https://github.com/dbrckk/chaos-survival-roblox/issues/79).

## Active Skyline Shield Network — new genuine linked co-op corridors (source)

Players and assisting AI operate four powerful 3D storm-defense machines per world. **When two different generators are active simultaneously, they now link with a large visible 18-stud-wide safe corridor across the real arena**: original energized floor rails, overhead conductors, crossing signals, world-space team guidance, and **real HP SAVED** readouts. Human and bot survivors crossing the route receive the SAME 58% reduction in Meteor/Bomb damage as the local fields. The link expires as soon as EITHER generator shuts off; no extra invulnerability or paid bonus and no protection against other hazards. This adds a genuinely coordinated movement choice for eight participant rounds without affecting the 52-deck sky parkour. **Source-only until same-SHA Build/Cloud/Studio/Android verification and authorized public Roblox update.** [Mechanics, safety and release acceptance](docs/LINKED_STORM_SHIELD_CORRIDORS_2026-11-02.md).

## Real co-op environment control — four active storm shields per arena

Players can operate **four monumental emergency defense generators** during Meteor/Bomb rounds in every world. A server-owned control creates a readable **48-stud-diameter protective cylinder** marked by eight distinct perimeter sections for **8 seconds**, protecting humans and simulated survivors from **58% of real explosive damage**, followed by **21 seconds** recharge. **AI survivors now also approach, hold and activate the SAME physical controls** when an actual human teammate can benefit, and must abandon the action to survive imminent hazards. Successful protection visibly displays REAL **HP SAVED** and an impact ripple; the field shuts off immediately when shrinking terrain leaves its station unsupported. There is no shield from other hazards, hidden invulnerability or pay-to-win reward. This is **source only**, with Cloud/Studio/Android verification and public Roblox publication still pending on the updated SHA. [Current complete gameplay & release contract](docs/REAL_COOPERATIVE_SKY_SHIELD_2026-11-02.md).

## Critical gameplay-fairness repair — source candidate

The two end-to-end sky promenades per arena must never become isolated because the *approach* collapses while the actual skybridge remains intact. All physical perimeter steps 1–5 and branch steps 1–4 now join the same **server-owned collapse-resistant backbone** as the 16 elevated crossing decks. This is protection from **random Disappearing Platforms only**, not immunity from meteors/lava or Shrinking Arena. Flat 2.4-stud gaps now have visible two-way chevrons on every real deck, since the old ascent-only jump hints do not apply to these level crossings. Existing engine-contract checks were updated. A one-time source-only release gate is configured to dispatch build, then Roblox engine checks, without publishing. Their **actual green results, physical Studio/Android verification and the public Roblox update are still pending**. [Verified source geometry and final release acceptance](docs/RELEASE_GATE_ROUTE_CONTINUITY_2026-11-01.md).

## Catastrophe-driven, destructible monumental skyline — source only

Actual Meteor/Bomb impacts and prolonged Tornado/Lava disasters now trigger **large staged 3D collapses** of the six monumental sky-promenade gateways in each of the five playable arenas. Existing native radar structures, maintenance lifts, transit switches, orbital reactors and Harbor freight machinery fracture, tilt and fall in synchronized **server-owned geometry**, with temporary quality-tiered debris and dust. The playable platforms remain real safe colliders; no new unsignaled danger or bogus world physics. This code is **not yet published or validated on Roblox devices**. [Structural Cataclysm architecture, fairness and acceptance](docs/STRUCTURAL_CATACLYSM_PREMIUM_2026-11-01.md).

## Major physical 3D world expansion — source only, not yet published

Five arenas now have a new **genuine high-altitude traversal loop**: each has two approximately 200-stud airborne sky promenades connecting existing distant physical lookouts. Sixteen new server-collidable, standard-R15-jumpable decks per map (80 authored among the five variants) create actual strategic route choices rather than background scenery. Six sculpted 3D structural portals per arena visually frame the walkways, with unique machinery for Classic/Towers/Crossroads/Orbital/Harbor. They have no blocking decorative collision; original spawn/hazard/AI systems continue to use the real `Arena/Platforms` parts. [Real geometry, deterministic route offsets and release acceptance](docs/MONUMENTAL_SKY_PROMENADES_2026-11-01.md). Source-only until a complete same-SHA Roblox engine/Studio/Android gate and explicit public publication.

## Colossal visual transformation — new source, not yet published

The upcoming major art update gives **all five arenas a unique fleet of enormous, moving 3D aerial machines**, with authored mechanical silhouettes and reactions to the real hazards. Unlike an image background, the airborne carriers, cargo gantries, rotating arrays, suspended lifts and reactor arcs are native 3D parts visible from the actual player camera. Low/Medium/High tier budgets and the existing distance LOD protect Android, while ReduceMotion restores static poses. [Scope, art direction and exact milestone acceptance](docs/COLOSSAL_SKYFLEET_PREMIUM_2026-11-01.md). This artwork is on the current repository source only until a future exact-SHA test and public publish; its appearance and FPS have **not** yet been validated on devices.

## Original 3D assets — no-PC Android upload option

**Runtime integration in the published code:** `src/server/OriginalMeshScenery.lua` now attempts **six** approved creator-owned Roblox Model packages in two bounded loading lanes, validates their contents and may place up to **eight** cosmetic skyline models beyond the playable perimeter. Native, noncolliding fallback scenery remains when a package cannot load; Android Low hides external models through the existing LOD. Whether all eight assets actually load and render on a particular client **has not been verified by real Studio/Android captures**. See [the integration guide](docs/ORIGINAL_3D_RUNTIME_INTEGRATION.md).

**Approved creator-owned Roblox assets (24 October 2026):** Reactor Spire `102992487644269`, Service Crane `119468460691888`, and Perimeter Gate `137284215564363`. Ownership, OBJ provenance, moderation and exact successful GitHub Actions run IDs are recorded in [the verified 3D asset registry](assets/source/roblox-asset-registry.json). All three are Roblox **Model packages** owned by `Drackk_08` (user ID `9774173158`). These model package IDs are **not** MeshPart.MeshId values. The current source dynamically **attempts** to mount approved packages into the live arena (with validation and fallback); successful loading and quality still need authenticated client evidence. Gameplay collision-safe native map structures remain authoritative.

The original Reactor Spire, Service Crane and Perimeter Gate OBJ/MTL sources live under `assets/source/`. The opt-in [Android 3D Open Cloud guide](docs/ANDROID_3D_CLOUD_IMPORT.md) describes a dedicated GitHub Actions workflow that validates and exports all three as embedded glTF 2.0. A **dry-run needs no Roblox key or creator ID**. Actual creation of a creator-owned Roblox `Model` requires a separate `ROBLOX_ASSET_API_KEY`, the correct creator ID and exact confirmation. **Generating or uploading a Model asset does not install it in the playable world;** integration needs a real approved Roblox asset ID, a separate staging review and Android visual QA.

**Automatic preview without any Roblox credentials:** every successful `main` **Build Validation** now archives `chaos-survival-3d-previews` alongside the playable place candidate. This artifact contains the three original glTF models and a `manifest.json` with source commit, byte sizes, triangle counts and SHA-256 checksums. Download it from the successful GitHub Actions run's **Artifacts** section on Android. This is **not** a Roblox upload or in-game integration.

**Android-only private staging:** use the manual-only [Remote Roblox Studio workflow](.github/workflows/roblox-remote-studio.yml) on `main` to prepare a signed official Windows Studio session and create a **new private test experience**, not another Place in the public universe. See the [Android private-staging guide](docs/ANDROID_PRIVATE_STAGING_REMOTE.md) for the minimum Android actions and the target-isolation rules. This does not publish the game automatically or certify gameplay.

## Implemented

- Runtime-generated lobby and arena
- Server-authoritative round loop
- 11 modular disasters
- 3-choice disaster voting
- Double Chaos combinations
- Coins, XP, levels, wins and games played
- DataStore persistence
- Mobile-friendly HUD
- Daily login rewards and streaks
- Daily quests with persistent progress and automatic rewards
- Server-side vote rate limiting
- Persistent cosmetic inventory with level unlocks
- Coin-funded cosmetic shop with server-authoritative purchases
- 25-item cosmetic catalogue with rarity tiers, four arena-mastery GOLD rewards, Founder cosmetics and Hyper Neon cosmetics
- Independent persistent trail + aura loadout slots with automatic migration from legacy saves
- Server-authoritative cosmetic equipment with combinable trails, auras, lighting and highlights
- Persistent long-term achievements with server-side rewards
- Persistent disaster + arena mastery with Rookie/Bronze/Silver/Gold/Elite tiers
- Weekly challenges, collection log and visible post-round next-goal progression
- Mobile achievements progress panel and unlock notifications
- Solo Rush mode with faster rounds, solo reward bonus, instant round end on elimination and AI Survivors that fill sparse servers
- Elimination tracking that prevents respawns from being counted as survival
- Server-side retention and gameplay analytics segmented by Solo/Multiplayer
- Economy analytics for Coins sources, daily rewards, quests and achievements
- Onboarding funnel tracking from join to first survival and first Chaos Shard pickup
- Contextual first-session coach covering vote, positioning, survival and optional shard collection
- 5 rotating arena layouts with no immediate repeat: Classic Grid, Tower Run, Crossroads, Orbital Ring and Storm Harbor
- After the October 30 feedback pass (pending release): the parkour waypoint will guide players from Orbital's low central hub back toward a real outer access ramp, place signs at the physical takeoff of long ramps, and defer to the actually visible cargo hint rather than hiding merely because a cargo shard is nearby. A server-confirmed route-tier landing will have a quiet existing reward chime and a brief tint in the existing mobile challenge bar, without extra client loops, currency or network events.
- Arena-specific high-ground mastery challenges on experienced rounds: Radar Ridge, Tower Summit, Crossroads Overpass, Reactor Lookout (tier 4) or Storm Gantry Lookout. The server verifies two consecutive stable landings on a real route platform; the existing round challenge awards capped Coins/XP without new client claims, loops or remote events.
- Mobile-first final result receipt shows the exact server-confirmed challenge bonus or the remaining arena mastery points toward the next rank. Pending receipts, spectators and unavailable rewards never display invented currency. The same result card remains available, preserving elimination tips and next-round countdown.
- Pending October 30 mobile hazard readability: Storm Harbor Cargo Sweep joins the existing meteor/bomb/JumpShock ACTION cue (no second warning overlay or loop). The server replicates each wave's authentic warning/pulse timestamps and durations; the client checks only the genuine four crane lanes and its own low-floor position before displaying a short FR/EN jump-or-exit instruction plus two locally rendered, non-collidable escape chevrons. Lethal impacts/shock always keep the foreground priority, raised parkour routes are correctly exempt, ReduceMotion fixes the visual pulse and adaptive Android quality limits geometry. This source branch is not yet published.
- Storm Harbor advanced cargo sweep: four alternating, server-owned crane-service lanes; 2.6-second orange warning, short red pulse and capped nonlethal push **toward the centre**, avoided by jumping or climbing above floor level. All rookie and incompatible-hazard rounds stay exempt. AI survivors now use the existing human-like delayed floor-sweep evasion behavior rather than ignoring the warning; nearby human runners receive one quiet local warning sound per real wave through the existing RoundState heartbeat. No extra client animation loop, network event or imported asset.
- Variant-specific hero landmarks, midground masses, understructures, focal lighting, material language and functional service props
- Animated personal round-result feedback with survival, streak, shard and close-call breakdown
- Compact live round-focus HUD with Chaos intensity and shard count
- Final-five-second danger timer feedback
- Server-side reward handling
- Per-disaster visual identities with Double Chaos color blending
- Progressive round-intensity director with solo/Double Chaos safety caps
- Veteran-only evolving Meteor/Bomb storm routes: scattered impacts → advancing sweep → alternating crossfire, with existing fair warning radii, mobile-stage labels and shrink-aware fallback
- Hazard cadence, arena VFX and audio mix react to escalating round intensity
- Dynamic neon arena beacon reacting to active chaos
- Procedural premium lobby hub with neon gate and title signage
- Premium procedural arena treatment with metal spawn pads, neon platform underglow and edge beacons
- Adaptive client-side world polish that rebuilds correctly across arena swaps and scales down on weaker devices
- Responsive body/camera game feel with landing, impact, launch, turn/brake feedback, READY anticipation, coyote time and jump buffering
- Live multiplayer vote counts and leading-choice highlight
- Mobile spectator mode after elimination with live survivor/time context, stable survivor switching and low-allocation hazard glyphs
- Chaos Shards: optional server-authoritative risk/reward pickups with daily-quest integration
- Close-call / near-miss feedback with per-round tracking
- Critical-health clutch-survival feedback and analytics
- XP progress bar and level-up celebration
- Session survival streaks with capped coin bonuses
- First-session onboarding banner
- Reactive music and SFX with a distinct audio cue for every disaster
- Map-specific 3D ambience plus material-aware local footsteps and landing treatment
- Automatic countdown, victory, elimination, reward, level-up and UI sounds
- Real-engine gameplay matrix: every arena × every disaster + every allowed Double Chaos pair
- Four-client Studio E2E harness with virtual UI clicks, movement, voting, joins and leaves
- AI Survivor animation state blending (idle/walk/run/jump/fall) and map-aware/hazard-aware navigation
- 86 engine specs assigned exactly once across Open Cloud CI shards
- **Published premium-platformer gameplay:** progressive physical route widths, server-verified airborne parkour mastery medals/records, daily/weekly mastery goals and veteran Tower Run's real timed rising bridge shutters alternating with collapsing bridge challenges. Both use authentic warnings, obstacle collision and fair Skyrail/AI safeguards. This gameplay is present in the latest verified public release described above; [the full premium quality benchmark and remaining acceptance plan](docs/PREMIUM_BENCHMARK_AND_COMPLETION_PLAN_2026-10-30.md) still require actual Android/PC certification.
- No paid assets required

## Current disasters

1. Rising Lava
2. Meteor Shower
3. Moon Gravity
4. Disappearing Platforms
5. Tornado
6. Freeze Pulse
7. Bomb Rain
8. Speed Surge
9. Blackout
10. Shrinking Arena
11. Jump Shock

## Run locally

1. Install Roblox Studio.
2. Install Rojo.
3. Clone this repository.
4. Run `rojo serve` from the repository root.
5. In Roblox Studio, connect the Rojo plugin to `localhost:34872`.
6. Press **Play**.

For DataStore tests in Studio, use a test experience and enable:

**Game Settings → Security → Enable Studio Access to API Services**

## Release candidate

- Final certification checklist: [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
- Authenticated Studio/device report template: [studio/PLAYTEST_REPORT_TEMPLATE.md](studio/PLAYTEST_REPORT_TEMPLATE.md)
- Change history: [CHANGELOG.md](CHANGELOG.md)
- Rollback procedure: [ROLLBACK_RUNBOOK.md](ROLLBACK_RUNBOOK.md)
- French public launch runbook: [docs/MISE_EN_LIGNE_1_0.md](docs/MISE_EN_LIGNE_1_0.md)
- Reviewed bilingual launch-copy draft: [docs/FICHE_ROBLOX_1_0.md](docs/FICHE_ROBLOX_1_0.md)
- Successful Build Validation provides a non-published `.rbxlx` candidate, SHA-256 checksum and exact-commit provenance in the `chaos-survival-place` GitHub Actions artifact. This is a test package, **not** Roblox release certification.
- Manual **Release Candidate Gate** workflow: verifies Build Validation + Open Cloud on the exact SHA and emits a release-evidence artifact without publishing.
- Roblox publication workflow refuses uncertified SHAs and archives publish metadata.

## Product direction

Automated Roblox-engine coverage validates the core gameplay matrix on every push. The project is in release-candidate hardening: the remaining launch gates are an authenticated Studio visual/touch pass, Android + desktop soak/performance validation, persistence/rejoin validation, a small real-player alpha, and final public-page assets.

Monetization infrastructure is now present but remains opt-in and cosmetic-only. Paid offers stay hidden until real Roblox Game Pass IDs are configured as DataModel attributes named `SupporterPassId` and `NeonPackPassId`. The paid service never modifies survival power, movement, health, round rewards or progression rates.

Recommended launch pricing is intentionally low-friction (for example 39–79 Robux per cosmetic/supporter pass), but the live price is always read from Roblox MarketplaceService rather than hard-coded in the client. Final prices should be set in Creator Dashboard only after the authenticated device playtest is clean.

## Architecture

```
src/
├── client/
├── server/
│   ├── Disasters/
│   ├── MapBuilder.lua
│   ├── PlayerData.lua
│   └── init.server.lua
└── shared/
    └── Config.lua
```


## Tests uniquement avant une étape importante / milestone-only validation

**Règle générale du développement : aucun test automatique pendant la phase
d'amélioration.** Cela inclut les PR, les commits sur les branches et les
commits ordinaires sur `main`. Les workflows de vérification lourde sont
**manuels** : ni `push` ni `pull_request` ne lancent des tests.

À un jalon réellement important, notamment juste avant de mettre à jour le
jeu public, déclencher depuis `main`, sur **le même commit exact** :

1. `Build Validation` — audit du code, sécurité, ressources, performances
   Android, Rojo, intégrité et provenance de l'archive ;
2. `Roblox Open Cloud Engine Tests` — les cinq suites réelles complètes ;
3. publier seulement si les deux sont vertes pour ce commit sur `main`,
   avec une validation explicite du propriétaire.

Le workflow de publication publique conserve les protections d'identité
d'univers/place, d'exactitude du commit, de non-régression de branche et
l'avertissement sur les tests Android/PC physiques non certifiés.
Aucun test non exécuté ne doit être présenté comme validé.

## Automated playtesting

The default CI uses Roblox Open Cloud Engine Tests and currently covers all arena/disaster combinations plus every allowed Double Chaos pair in a real Roblox DataModel.

A separate four-client Studio E2E harness is included under `studio/`. It automates UI clicks, voting, movement, staggered joins and client leave behavior using StudioTestService and VirtualInput. Roblox Studio requires a logged-in user session, so the GitHub Studio workflow is manual and targets an authenticated self-hosted Windows runner.

## Integrated visual and locomotion candidate (2026-10-08)

This **unreleased candidate** reconciles PRs #12–#16 with the already merged spectator fix (#11) and Open Cloud retry hardening (#17):

- Chaos Showtime: six R6/R15 emotes, a holographic dance floor, DJ architecture, a neon crown and accessible narrow-screen mobile controls.
- Five distinct arena identities: Classic radar, Towers maintenance elevator, Crossroads transit signage, Orbital gyroscope, and Storm Harbor drydock ship with four original distant port cranes.
- Unique meteor and bomb impact fragments, included in visual performance telemetry.
- Event-driven blast/near-miss/landing reactions on eligible living players and AI bots; spectator/lobby avatars excluded.
- R15 sprint starts, stop skids, sharp pivots, foot planting, takeoff and fall bracing with transient floor cues.

All added content is cosmetic only. No speed, jump, damage, server authority, physics, or monetization changes. Full Studio and real Android performance/gameplay playtests remain required before release.

- Late map-replication resilience: lobby floor and arena base visual builders now watch nested map parts and arena identity attributes instead of relying on container arrival order.

- Cosmetic hazard-impact events also reach spectating clients; visible bursts are filtered by spectator camera range, while movement/body feedback remains disabled for nonparticipants.
