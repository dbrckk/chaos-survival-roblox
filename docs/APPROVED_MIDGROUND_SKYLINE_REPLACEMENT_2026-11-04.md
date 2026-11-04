# Classic Grid & Crossroads — substitution des masses de skyline par quatre vraies familles 3D

**4 novembre 2026 — code source uniquement, pas de publication du jeu.**

## Problème corrigé

Les quatre masses de diffusion Classic (\`ClassicBroadcastMass1..4\`) et les quatre blocs de transit Crossroads (\`CrossroadsTransitMass1..4\`) étaient des \`Part\` rectangulaires non physiques. Les détails \`ArenaDetailKit\` ajoutaient des ornements, mais pas de vraie silhouette architecturale. Ces huit emplacements se trouvent **en dehors** de l'arène jouable.

Le nouveau \`ApprovedMidgroundSkylineMeshKit.lua\` réutilise les quatre **vrais Roblox Models déjà Approved** du propriétaire, sans nouveau téléchargement ni identifiant inventé :

| Source réelle | Roblox Model ID | Emplacements |
|---|---|---|
| Observatory | \`132020956214241\` | Classic 1, Crossroads 3 |
| Aerial | \`135791763112202\` | Classic 2, Crossroads 2 |
| Turbine | \`84217436280282\` | Classic 3, Crossroads 4 |
| Freight | \`88725004643299\` | Classic 4, Crossroads 1 |

Ce sont **quatre modèles réutilisés**, pas huit nouvelles créations ni une augmentation du registre de 62 assets. La provenance provient du chargement serveur existant \`PremiumDistrictFacadeAssets\` et des modèles \`ApprovedDistrictFacadeTemplates\`. Les mêmes sources continuent à servir leurs usages historiques dans les districts.

## Substitution réelle et contraintes

- Chaque groupe natif est indexé par \`OriginalMidgroundSkylineIndex\` et \`OriginalMidgroundSkylineVariant\` dans le constructeur \`arena-midground-mass.client.lua\`. Le groupe inclut la masse et ses ornements ; aucune géométrie de jeu, avertissement ou collider n'est indexé.
- La source exige \`OwnerVerified\`, \`DistrictFacade3D\`, \`CosmeticOnly\`, son **ID exact**, 1 à 24 \`MeshPart\` non collisionnants, sans scripts, et la même plage de dimensions validée côté serveur. Un asset absent ou rejeté laisse le natif visible.
- Chaque vrai clone est mis à l'échelle dans des bornes explicites, orienté selon l'axe long du bloc d'origine, puis aligné par sa **base**, sans \`Part\` supplémentaire et sans déplacement du gameplay.
- Seuls les groupes situés **au moins 18 studs au-delà** du vrai bord physique de l'arène sont éligibles. Le kit vérifie aussi la taille, l'ancrage, le nom, les index et l'orientation du support.
- Le bloc original et ses motifs ne deviennent invisibles **qu'après montage intégral** du clone authentifié. La transparence des anciens éléments est restaurée à une baisse de qualité, perte source, streaming, déplacement du support ou nouvelle carte.
- Les MeshParts sont ancrés, sans collision, touche, requête physique ni ombre, sans nouveau \`RunService\`, \`RemoteEvent\`, \`PointLight\` ou AssetService client.
- Toutes les clones sont comptés dans \`VisualBudgetRules.LocalFolders\` et le budget actuel de **440 / 680 / 900 Parts**.

## Budget adaptatif

| Tier | Pression 0 | Pression 1 | Pression 2 | Distance maximale + rétention |
|---|---:|---:|---:|---|
| Android Low | **1** modèle | 0 | 0 | 230 + 24 studs |
| Medium | **2** modèles | 1 | 0 | 300 + 32 studs |
| High | **4** modèles | 2 | 0 | 405 + 44 studs |

Les diagnostics \`LocalOriginalMidgroundSkylineCount\` et \`LocalOriginalMidgroundNativeReplaced\` mesurent respectivement les modèles authentiques montés et les primitives natives effectivement masquées ; **ils ne prouvent ni FPS, ni rendu, ni déploiement**.

## Hors périmètre volontaire

Les six sphères \`OrbitalStationMass\` restent actuellement des primitives Roblox. Elles se trouvent à l'intérieur ou près des parcours de la carte Orbital. Un remplacement architectural volumineux de bâtiment masquerait la navigation ; leur substitution nécessite des assets originaux adaptés à cette petite échelle et une validation de lisibilité sur Android. Les remplacer maintenant avec une façade serait une régression.

## Validation de jalon avant publication

1. Rojo Build Validation et suites moteur Roblox Cloud sur le **même SHA** de release, y compris validation source/provenance, scripts, budgets et non-collision.
2. Vérification visuelle réelle sur Classic et Crossroads sous Android Low/Medium/High : pas de face mal orientée, de bloc qui traverse le mesh, ni de trou en streaming.
3. Scènes avec \`OptionalVfxPressure=1/2\`, changement d'arène et de qualité, destruction du modèle/source au chargement, et rétrécissement réel de l'arène.
4. Comparer la fréquence d'images et la mémoire sur trente minutes ; aucun lancement public sans avoir réellement obtenu les preuves requises.
