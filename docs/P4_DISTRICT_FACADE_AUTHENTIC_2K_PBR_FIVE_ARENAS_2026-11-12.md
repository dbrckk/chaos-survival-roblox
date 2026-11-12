# P4 — Véritables finitions PBR 2K sur les façades 3D des quartiers (5 arènes)

**12 novembre 2026.** Lot de finition des volumes architecturaux visibles de près, sans inventer de MeshIds ni de nouveaux modèles.

## Constat vérifié

Les **16 bâtiments de quartier** de chaque arène utilisent quatre profils réels de bardage/toiture 3D approuvés et modulaires, synchronisés par `PremiumDistrictFacadeMeshKit`. Chaque profil possède ses propres triangles, UV et tangentes. Avant ce lot, les matériaux issus du glTF avaient surtout des facteurs fixes de couleur, rugosité et métal ; ils n'étaient **pas éligibles** au moteur commun de textures 2K, ce qui donnait des surfaces plus plates en gros plan.

| Profil original | Asset Roblox créateur, Approved | Type de construction |
|---|---|---|
| Observatory | `132020956214241` | Lames, pods et antennes d'observation |
| Freight | `88725004643299` | Portiques, engrenages, câbles et transport |
| Turbine | `84217436280282` | Turbines, gaines et ventilation industrielles |
| Aerial | `135791763112202` | Mât, anneaux et relais de communication |

Les quatre IDs proviennent du registre de modèles approuvés et du pipeline Roblox existant ; aucune source tierce n'est introduite.

## Changement livré dans le client

1. `PremiumDistrictFacadeMeshKit` marque explicitement son dossier local original `ApprovedDistrictFacadesLocal` comme `CosmeticOnly`, et préserve sur chaque clone vérifié `OwnerVerified`, `DistrictFacade3D`, l'ID Roblox de son profil et `DistrictIndex`.
2. `PremiumNearfieldPbrKit` rend les quatre sources éligibles **dans chacune des cinq variantes** Classic, Towers, Crossroads, Orbital et Harbor.
3. La vérification PBR exige les **6 ou 7 MeshParts d'origine** de chaque modèle de district, le dossier propriétaire exact, l'ID signé, les attributs d'origine, l'indice authentique du bâtiment et la géométrie entièrement non-collisionnelle. Les autres sculptures conservent leur vérification historique à sept MeshParts exactement.
4. **Seules les surfaces visibles** et reconnaissables par leur rôle `ARMOR`, `BRUSHED`, `ALLOY` ou `CERAMIC` peuvent recevoir temporairement les vraies images 2K `SurfaceAppearance`. Les signaux `SIGNAL`, le carbone `CARBON`, les grips `GRIP` et les vitrages `GLASS` restent inchangés.
5. Le choix utilise la **même sélection camera/LOD** déjà exécutée **après** `PremiumDistrictFacadeMeshKit.sync` dans le passage `scenery-lod.client.lua`. Aucun script ou timer graphique ajouté.

## Limites et protection Android

- Les **16 images Roblox 2K** approuvées sont réutilisées à l'identique : normales, rugosité, metalness et couleur pour quatre familles de matériaux.
- **Low** : aucune nouvelle couche PBR 2K ; la silhouette 3D d'origine reste régie par les seuils existants.
- **Medium** : jusqu'à deux modèles candidats sur Android sans pression GPU ; **High** : quatre sur Android, six PC ; quota partagé avec toutes les autres sculptures éligibles, **pas** un quota séparé pour ces façades.
- Les 12 modèles 3D maximum permis en High par le kit de façade ne signifient pas 12 modèles avec PBR ; le quota global garde la priorité.
- Les textures reviennent à leur apparence glTF d'origine en cas de LOD caché, de streaming, d'opt-out `PbrMaterialsDisabled`, de changement d'arène ou de pression graphique.
- Aucun nouveau collisionneur, physique, part serveur, générateur de triangles, lumière, API d'import ni texture réseau.

## Validation technique

Le vérificateur source existant `tools/verify_premium_nearfield_pbr.py` contrôle maintenant les quatre vrais IDs dans chacune des cinq arènes, la provenance du propriétaire, le nombre exact de groupes permis, les surfaces exclues et l'ordre de synchronisation source → PBR. Le workflow existant `original-nearfield-pbr-source.yml` vérifie cette intégration sur PR et fusion.

**Limite de preuve :** la CI source ne certifie ni visibilité effective des images Roblox sur Android, ni qualité AAA, ni FPS ou publication publique. Pour qualifier le rendu : capturer chaque variante en Medium/High, zoomer sur les quatre profils à moins de 150 studs, noter `LocalOriginalDistrictFacadeMeshCount` / `LocalPremiumNearfieldPbrSurfaceCount`, tester la disparition d'une façade, le rollback, l'opt-out et les perf p95.

**Chantier suivant :** les corps de bâtiment natifs encore visibles sous les facades 3D (murs, fenêtres, murs latéraux) doivent être traités comme une famille distincte, sans jamais masquer une porte ou un obstacle essentiel au parcours.
