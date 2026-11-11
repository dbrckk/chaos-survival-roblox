> Mise à jour du 11 novembre 2026 : la version Low décrite ci-dessous
> a été améliorée par le [lot d'un sommet 3D proche](P4_ANDROID_LOW_AUTHENTIC_VARIANT_APEX_2026-11-11.md).
> Le tableau historique ci-dessous (Low = 0) reflète uniquement le
> comportement antérieur à ce correctif et ne représente plus le code
> actuel.

# P4 — Intégration des sommets 3D propres aux variantes

**9 novembre 2026 — code source uniquement, pas de nouvelle publication Roblox Place.**

## Assets authentiques

Quatre Models originaux de 7 véritables MeshParts PBR chacun, tous modérés Approved dans le workflow #42699542702 : Towers 131413152501235, Orbital 131188899020391, Crossroads 134533469777794, Relay 110237986522853. Aucune URL ni MeshId n'est inventé ; les vrais IDs figurent dans assets/source/roblox-asset-registry.json.

## Comportement

src/server/PremiumPerimeterVariantApexAssets.lua charge tardivement, assainit puis vérifie la provenance, la forme, le nombre de MeshParts et les limites dimensionnelles des quatre sources. src/client/ApprovedPerimeterVariantApexMeshKit.lua valide exactement le couple de primitives de sommet propre à la variante dans les quatre véritables modèles PerimeterStation... de la carte active, y compris leur relation de placement relatif.

Un seul Model original réunit **deux formes natives** : les deux natives ne sont masquées localement qu'après clonage et vérification des 7 MeshParts complets. Toutes les pièces importées restent Anchored, Massless, CanCollide=false, CanTouch=false, CanQuery=false, CastShadow=false. Le kit ne modifie ni collision autoritaire, ni logique de dégâts, ni bots. Si le Model source est incomplet, la station streamée partiellement, une pièce est retirée, le socle rétrécit, la carte est remplacée, le profil passe en Low ou la pression VFX devient trop forte, les natives sont restaurées.

Le nouvel ensemble ApprovedPerimeterVariantApexLocal est compté dans le budget visuel 440/680/900 Part existant et le sampler déjà en service dans scenery-lod.client.lua. Aucune nouvelle boucle de rendu ni aucun RemoteEvent n'a été ajouté.

| Profil | Stations max avec sommet 3D | Pièces natives masquées max | MeshParts supplémentaires max |
| --- | ---: | ---: | ---: |
| Low | 0 | 0 | 0 |
| Medium | 1 | 2 | 7 |
| High Android | 2 | 4 | 14 |
| High PC | 3 | 6 | 21 |

Pression VFX 1 réduit la limite de stations de moitié, arrondie à l'inférieur ; pression 2 restaure toutes les primitives. Portée 170 studs en Medium, 245 High, hystérésis 16. Les compteurs clients LocalApprovedPerimeterVariantApexCount et LocalPerimeterVariantNativePiecesReplaced indiquent les remplacements réellement installés, pas une mesure FPS.

## Réception avant une publication

Au prochain jalon exact-SHA de publication, vérifier visuellement l'alignement des deux primitives remplaçables sur toutes les cartes, la normale des quatre imports glTF, le streaming tardif, les réductions de taille de carte et les transitions Android Low/Medium/High. Une couverture source de 16/23 ne représente pas un taux de qualité 3D du jeu entier et aucune mesure Engine/Android n'est revendiquée.
