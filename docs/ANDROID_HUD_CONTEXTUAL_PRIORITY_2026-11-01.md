# Android HUD — suppression des superpositions redondantes (2026-11-01)

## Contexte et constat des six captures réelles

La session Android fournie montre plusieurs éléments superposés pendant une catastrophe : la grande bannière autoritaire `TopHUD`, le compteur `4/4 EN VIE`, un encart central `FLUX • TRAVERSE UNE ARCHE`, la progression inférieure `ÉCLATS / PASSERELLE / PLUIE DE MÉTÉORES` et, dans la colonne de gauche, `TRANSPORT RAPIDE D2`. Le bouton DASH et le saut Android se trouvent à droite. Il est impératif de préserver l'identité du danger, ses consignes, son minuteur, le nombre de survivants, les touches de mobilité et les avertissements de terrain.

Le panneau noir vertical recouvrant le coin supérieur droit des captures est une **fenêtre flottante externe du téléphone**, pas un écran du projet Roblox.

## Modifications implémentées — uniquement sur mobile

- **Bannière critique raccourcie mais conservée** : pour un paysage Android large, `UIResponsive.mobileProfile` réduit `topWidthScale` de 0,60 à **0,56**, `topHeight` de 54 à **50 px**, sans modifier la place de sécurité de gauche pour le menu Roblox ni cacher le titre, la consigne ou le minuteur.
- **Barre de survie moins encombrante** : en paysage large, largeur de 0,48 à **0,44** de la fenêtre, hauteur 46 à **42 px**, maintien de l'écart en bas pour le saut Android. Quand la pastille de droite répète **exactement** le même nom de catastrophe que le grand titre, on la masque et on agrandit la **pastille de l'objectif réellement actionnable**. Les consignes distinctes `SURVEILLE LES DEUX FLANCS`, `OVERDRIVE`, `FINAL RUSH`, une fusion, une consigne d'arène et les accélérations restent visibles et prioritaires.
- **GRID et FLUX contextuels** : sur Android uniquement, si le joueur n'a encore commencé **aucune progression**, l'encart central apparaît uniquement quand il est à moins de **42 studs d'une véritable arche/borne physique** ; après 1/3 ou 1/4, il reste affiché pour rendre lisible l'enchaînement. Desktop inchangé. Les vraies bornes et leurs triggers restent toujours présents et interactifs.
- **Correction de mise à jour** : le tracker GRID peut redevenir visible quand un joueur se rapproche d'une borne **sans événement de progression**. La visibilité est recalculée avant l'optimisation `lastStyleKey`.
- **Détours secondaires** : la carte `TRANSPORT RAPIDE / CACHE` est masquée sur Android quand un `DoubleChaos`, `FinalRush`, un front `ImpactWaveMode=Flanks/Sweep` ou **12 secondes ou moins** à la manche exige de voir davantage de terrain. Tous les prompts d'action et objets physiques restent actifs, et la carte réapparaît quand ces conditions sont terminées.
- Les contrôles d'affichage réutilisent les **cadences déjà existantes** : 0,20 s FLUX, GRID update existant et 0,25 s navigateur. Aucun nouveau `ScreenGui`, `RenderStepped`, `RemoteEvent`, asset 3D ou shader. Desktop, serveur, scores, catastrophes, IA, économie et physique inchangés.

## Contrats et acceptation

Les fonctions pures `UIResponsive.showMobileMechanicProgress` et `UIResponsive.showMobileOptionalExpedition` sont couvertes par une **extension de la suite existante** `tests/engine/ui-responsive.spec.luau` : guidage GRID/FLUX visible à proximité et après démarrage, priorités de fin de manche et doubles catastrophes, dimensions wide paysage. Pas de nouveau framework ni tests unitaires durant l'amélioration courante.

**À vérifier avant publication publique** :
1. Même SHA : Build Validation et cinq suites moteur Open Cloud.
2. Captures Roblox Studio + Android **paysage 1536×688, 960×440, 640×360** et portrait 400×720 : la bannière/timer/4 sur 8 en vie gardent leur lisibilité, les messages FR/EN tiennent dans la largeur, DASH/touche de saut restent atteignables.
3. Entrer en Crossroads loin d'une arche : pas de grand encart central permanent. Approcher à moins de 42 studs sans commencer : affichage du guidage. Traverser une arche : **1/3** visible pendant l'enchaînement. Même protocole pour les quatre stations Classic.
4. Lors d'un impact `Flanks`, un DoubleChaos et un FinalRush, le guide de transport facultatif cède la place à la scène tout en conservant les vraies interactions du décor.
5. Tester les transitions d'un état stable (statut inférieur identique au titre) à `Flanks`, `Overdrive`, `FinalRush` et à un changement de carte; toutes les pastilles d'information utiles doivent réapparaître. Activer `ReduceMotion` et changer de taille de fenêtre.
6. Comparer le nombre de pixels obstrués avant/après avec capture authentique, plutôt que modifier la note AAA en fonction de l'inspection du code.

**État** : changements source GitHub uniquement. Les tests moteur et le rendu Android ne sont pas encore exécutés ; la dernière expérience Roblox publique vérifiée reste publiée depuis `e8767c98c475a3efb39ed53ed7bbe16efa1865d2`.


## Complément — positionnement de l'introduction de manche (PR suivante)

- `UIResponsive.mobileRoundBanner(viewport, topInset)` ne fixe plus la bannière à 39 % de l'écran, là où elle masquait les concurrents et une partie des trajectoires Android. Sa hauteur est limitée à **48 / 52 / 58 px** selon la hauteur disponible, sa largeur à **48–84 %** selon le format.
- Le bandeau d'introduction utilise **la véritable marge supérieure native de Roblox** obtenue par `GuiService:GetGuiInset()`. Son premier pixel se place sous le bandeau critique `ChaosHUD` **et** sa pastille de survivants ; son bord inférieur reste au-dessus de la jauge inférieure. La hauteur du `TopHUD` n'est pas réduite davantage et les événements dangereux ne sont pas supprimés.
- Sur une fenêtre Android exceptionnellement étroite en hauteur (par exemple **400×230** ou **540×320 avec 70 px de marge native**), si aucune bande sûre ne peut contenir le message, seule **l'introduction secondaire** est omise. Les informations primaires de survie continuent de s'afficher. La fenêtre invisible ne peut pas réserver le canal d'alerte `MobileHudNotices`.
- Lors d'un pivot, d'un fractionnement de l'écran ou d'un changement de caméra, le placement est recalculé avec la même connexion `ViewportSize` existante : si le bandeau devient impossible à afficher, il se ferme immédiatement, libère la priorité « intro » et invalide les callbacks de masquage retardés. Aucun `RenderStepped`, aucun nouveau `ScreenGui` ou serveur.
- La suite existante `ui-responsive.spec.luau` est étendue aux tailles **540×320, 640×360, 960×440, 1536×688 et 400×720** avec une marge native de 48 px, puis aux deux cas non conformes. Les calculs de rectangles et l'ordre des priorités sont contrôlés côté source ; **aucun test moteur Roblox ni capture Android réelle n'est revendiqué ici**.

**Critère de réception supplémentaire** : vérifier une rotation **paysage → écran fractionné → paysage** pendant une introduction READY puis pendant une célébration ; l'alerte de catastrophe, le compteur de survivants et la jauge du bas restent lisibles, et un nouveau message événementiel n'est pas bloqué par une ancienne « intro » cachée.
