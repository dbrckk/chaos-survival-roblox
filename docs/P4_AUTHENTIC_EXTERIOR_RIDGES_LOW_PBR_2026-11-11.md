# P4 — Quatre véritables crêtes extérieures 3D : Low et finitions PBR

**Date :** 11 novembre 2026. **Variantes :** Classic, Towers,
Crossroads, Orbital, Harbor. **Statut :** source, sans publication Place.

## Inventaire : douze grosses formes primitives par carte

Le générateur `src/server/MapBuilder.lua` produit quatre modèles
`ExteriorRidgeNW/NE/SW/SE`, chacun composé de **trois
WedgeParts** sculptés très sommairement, derrière la zone jouable.
Ce sont des éléments non-collisionnels purement décoratifs.

Les modèles 3D originaux, déjà approuvés par Roblox
(`Moderation: Approved`), existent dans
`ApprovedExteriorRidgeTemplates` :

| Coin | Model ID approuvé |
| --- | --- |
| NW | `123836720232695` |
| NE | `83853948389204` |
| SW | `108491064314671` |
| SE | `83023096720529` |

Leurs sept sous-meshes d'origine représentent les crêtes de roche
irrégulières et les plaques métalliques forgées, avec relief,
matériaux et voyants. Aucun ID n'est créé ou deviné dans ce lot.

## Modifications effectives

1. **Low** : le kit `ApprovedExteriorRidgeMeshKit` peut
   afficher **un** modèle original de sept MeshParts à 290 studs
   de la caméra, contre zéro. Cela peut remplacer exactement
   trois formes `WedgePart` natives, si le Model est chargé,
   la vraie topologie correspond et que la pression graphique
   n'est pas élevée.
2. **Medium/High** : les limites existantes de deux/quatre
   crêtes sont conservées (High Android : trois).
3. **Pression 1 sur Low** : `floor(1/2)=0` :
   les trois WedgeParts natives sont immédiatement restaurées.
   Pression 2 : zéro sur tous les tiers. Aucun collider,
   route, dangers, remote, worker ou autre sampler n'est ajouté.
4. **Finition premium** : les quatre Model IDs de crêtes,
   pour chacune des cinq variantes, deviennent éligibles dans
   `PremiumNearfieldPbrKit`. Seuls les groupes ARMOR, BRUSHED,
   ALLOY et CERAMIC reçoivent les `SurfaceAppearance`
   **2K existants** ; SIGNAL, CARBON, GRIP et GLASS restent
   inchangés. Le budget global de modèles PBR reste
   **Medium Android 2 / High Android 4**, sous réserve
   de pression, et le profil Low n'instancie aucun overlay.
5. Les dossiers locaux `ApprovedExteriorRidgesLocal`
   sont déjà comptés dans le recensement adaptatif partagé
   `VisualBudgetRules.LocalFolders`. Aucun double budget ni
   second passage `Workspace:GetDescendants()`.

## Limites

Ce sont **12 primitives éligibles par arène source**, pas un nombre
garanti de remplacements visibles. Une seule arène est active.
Les sources sont importées par le worker serveur optionnel
`PremiumExteriorRidgeAssets` après son délai actuel :
la disponibilité pendant la première manche n'est pas garantie.

Le rendu et les FPS Android réels, la présence du bon
`SurfaceAppearance` après l'import glTF et le seuil de
qualité du modèle seront à vérifier dans Roblox Engine avant
publication de la Place. Les tests source GitHub ne sont pas
des tests sur un appareil Android.
