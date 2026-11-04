# Orbital Ring — six vraies stations 3D compactes

**4 novembre 2026 — code source, sans publication publique.**

Les six sphères OrbitalStationMass et leurs ornements natifs disposent maintenant de deux substitutions 3D originales, réelles et déjà approuvées par Roblox. Les index 1, 3, 5 utilisent le **satellite à panneaux solaires** (Roblox Model 127850230318627, import Approved #41733818047), les index 2, 4, 6 le **module de confinement énergétique** (Roblox Model 127295681925871, import Approved #41729439190).

Ce sont deux sources distinctes du registre existant des 62 modèles : 7 MeshParts sculptés chacun, matériaux UV/tangentes, structures mécaniques, aucun ID inventé. Le serveur les charge déjà comme templates vérifiés via PremiumAmbientMotionAssets et PremiumServiceEquipmentAssets. Le client ne fait aucun nouvel import.

## Implantation sûre

Le constructeur ArenaMidgroundMass indexe les éléments natifs par station, y compris leurs ailes et bras. La substitution ne peut commencer que si les 7 MeshParts vérifiés sont présents, avec la provenance Roblox exacte et la géométrie d'origine dans ses limites. Les sculptures sont ancrées, non collisionnantes, sans CanTouch/CanQuery, et sans lumière supplémentaire. Le modèle reste dans une enveloppe de taille plafonnée et entièrement au-delà du vrai carré de l'arène avec une marge d'au moins trois studs. Aucune route, collision, catastrophe ou bot n'est modifié.

Les objets natifs sont masqués localement uniquement après montage complet, et restaurés si le modèle ou son template disparaît, en cas de shrink, changement de carte ou diminution de qualité. Les nouvelles sculptures sont inscrites dans VisualBudgetRules.LocalFolders et utilisent le sampler scenery-lod existant, sans nouvelle boucle de rendu.

## Budget Android par pression FPS

| Qualité | Normale | Pression 1 | Pression 2 | Distance de sélection |
|---|---:|---:|---:|---:|
| Low | 1 modèle / 7 MeshParts | 0 | 0 | 290 studs |
| Medium | 3 modèles / 21 MeshParts | 1 | 0 | 345 studs |
| High | 6 modèles / 42 MeshParts | 3 | 0 | 430 studs |

Les compteurs LocalOriginalOrbitalStationCount et LocalOriginalOrbitalNativeReplaced donnent les montages 3D et le nombre de primitives masquées. Cela ne valide ni les FPS ni la présentation visuelle Android.

## Contrôles requis avant publication

Build Rojo et sept suites moteur Roblox Cloud sur le SHA final ; vérification des six silhouettes et axes 3D sur Android en Low, Medium, High ; stabilité après changement de carte/streaming, pression 1/2, shrink et reconnexion ; contrôle visuel des plateformes, HUD et distances ; 30 minutes de mesure mémoire/FPS. **Aucune publication effectuée par ce lot.**
