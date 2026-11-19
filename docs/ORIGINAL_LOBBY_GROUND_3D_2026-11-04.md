# Chaos Survival — véritable sol 3D du lobby (4 novembre 2026)

**Statut : intégration source sur main ; validation en moteur et rendu Android de ce lot encore à effectuer. Non publié.**

## Défaut visuel traité

Le lobby est une plateforme physique de 74 × 74 studs avec un panneau central de 68 × 68 studs. Auparavant, la finition client se limitait principalement à quelques bandes et panneaux primitifs en Part ; elle ne donnait pas de relief industriel crédible à la grande surface du premier écran.

Le nouveau PremiumLobbyGroundMeshKit réemploie le Model original approuvé **72507987666671**, déjà importé et chargé côté serveur par PremiumRouteMeshAssets : véritables triangles, UV et tangentes, jusqu'à sept MeshParts par dalle (source de 2 976 triangles). Aucune nouvelle ressource Marketplace, requête HTTP client, génération de Part simulant un mesh ou nouvel AssetId.

Jusqu'à quatre dalles 3D sont réduites à environ 34 studs et disposées en un carré 2×2, avec des rotations par quarts de tour. Leur surface reste sous les tutoriels VOTE / SURVIVE / REPEAT, les marquages et la plateforme centrale ; le floor collidable demeure autoritaire et inchangé. Les anciennes lignes natives du client sont omises uniquement si les dalles réellement authentifiées sont montées.

## Budget et sécurité

| Qualité | Pression 0 | Pression 1 | Pression 2 |
| --- | ---: | ---: | ---: |
| Low | 0 | 0 | 0 |
| Medium | 2 | 1 | 0 |
| High | 4 | 2 | 0 |

Les quatre dalles du vestibule totalisent 28 MeshParts et environ 11 904 triangles source en High avec la source actuelle à sept pièces. Le dossier LobbySurfaceDetailLocal est déjà recensé par VisualBudgetRules. Aucun nouveau SpotLight, RenderStepped, collider, toucher, raycast ni boucle de chargement. Pas de nouvelle texture raster 2K sur ce lot.

Avant tout montage, le client confirme l'ID exact, le dossier vérifié, les attributs CosmeticOnly / OwnerVerified / PremiumGround3D, le type Model, l'absence de scripts, des MeshParts uniquement et la taille attendue. Les quatre clones sont intégralement préparés avant publication dans le dossier : si un seul échoue, le montage est annulé.

La surveillance événementielle reconstruit le sol après arrivée tardive du modèle, streaming de Lobby.Floor, changement de carte, pression FPS ou changement de qualité. La disparition anormale d'un MeshPart client déclenche la reconstruction. Le serveur conserve sa géométrie native, ses panneaux de guidage et les fonctions de sécurité.

## Estrade centrale

L’estrade reprend le relief biseauté de la même dalle approuvée sur une empreinte de 23,4 × 23,4 studs. Le maillage suit le repère du plateau de collision, dépasse sa surface de 0,024 stud et reste sous ses quatre repères lumineux. Le signal central occupe 7,5 × 7,5 studs afin de laisser les reliefs visibles autour.

À pression 0, la dalle centrale utilise la marge sous les plafonds existants de 24 MeshParts en Medium et 48 en High. Avec le modèle à sept pièces, l’ensemble du lobby passe à trois dalles en Medium (21 MeshParts) et cinq en High (35 MeshParts). La dalle centrale se retire dès la pression 1. Le plateau natif sert de secours lorsque le maillage ou le budget manque. Le client recalcule son montage si l’estrade arrive après le sol.

Deux attributs diagnostiques du joueur sont renseignés depuis le montage réel : LocalOriginalLobbyGroundTileCount et LocalOriginalLobbyGroundMeshPartCount. Ces compteurs ne mesurent pas le rendu ni la VRAM.

## Raccord vers le portail

Le chevron cyan dessiné par deux profils forgés indique la sortie de l’estrade. L’allée et ses deux rails partent au pied du rebord et se terminent cinq studs après le portail, à l’intérieur du vestibule. Les chevrons de départ et les repères d’approche suivent l’empreinte de l’allée. Le signal de lancement se déplace de l’estrade vers le portail.

## Finition de secours du vestibule

Lorsque les dalles 3D se retirent, le client pose les joints et les trappes de maintenance sur la face supérieure du revêtement visible. Les quatre paires de positions possibles contournent les zones d’entraînement, les inscriptions et l’allée du portail. La configuration prévoit quatre joints et quatre trappes en Low, six de chaque en Medium et huit de chaque en High, avec les huit petits inserts lumineux en High. Le streaming du revêtement déclenche le recalcul de ces finitions.

## Acceptation visuelle restante

- Build Rojo et validation moteur des sept suites sur le SHA exact du lot.
- Captures Studio et Android Low / Medium / High : relief réel de premier plan, bonne orientation/continuité des UV, quatre bordures de dalle, lisibilité des panneaux et absence d'interférence avec CenterPlatform.
- Mesures de temps de chargement, FPS et mémoire Android, notamment sous pression 1/2 et en arrivant avant la réplication du Model.
- Vérification des fallbacks lors de la suppression du template et du remplacement complet de la carte.
- Ne pas déclarer ce lot public ou certifié AAA avant ces preuves.
