# P4 — Dalles de sol 3D visibles devant le joueur

**Date :** 11 novembre 2026.
**Baseline GitHub :** `b420b7cb1df2db1c502389e1271bda917f613c45`.
**Nature :** amélioration de la sélection et de la couverture des modèles
3D originaux du sol ; aucune nouvelle Place Roblox publiée par cette PR.

## Problème vérifié dans le code

L'arène a **36 dalles cosmétiques** de 49 × 49 studs. Le modèle Roblox
`72507987666671` est **créateur-approuvé** et possède une vraie
géométrie triangulée, des UV/tangentes et au plus sept MeshParts par dalle
(2 976 triangles par instance). Le kit High autorise déjà 36 dalles,
tandis que Medium en autorisait seulement 12 et Low seulement 2.

Le classement par distance pénalisait fortement les dalles éloignées
*derrière* la caméra, mais ne privilégiait pas les dalles *devant* la
caméra à des distances comparables. Des dalles peu visibles pouvaient
donc consommer le quota au détriment de la portion de terrain
effectivement regardée.

## Livraison

| Profil | Sans pression avant | Sans pression après | Pression 1 après | Pression 2 après |
| --- | ---: | ---: | ---: | ---: |
| Low | 2 | **2** | 2 | 1 |
| Medium | 12 | **16** | **10** | 4 |
| High | 36 | **36** | 24 | 16 |

Medium couvre **4 dalles de plus** soit potentiellement **9 604 studs²**
supplémentaires de sol sculpté proche si les quatre candidates
remplissent toutes les conditions. Le maximum importé Medium
passe de **35 712 à 47 616 triangles** (contre 107 136 High).
La première pression réduit Medium à 10 instances, soit 29 760
triangles ; la seconde à 4, soit 11 904. Low ne reçoit aucune
nouvelle pièce et ne change pas de coût.

- Toujours le **même modèle original approuvé** ; aucun nouvel ID,
  téléchargement, matériau, texture ou cache client.
- Les **16 mêmes textures 2K approuvées** restent soumises aux
  plafonds PBR existants : pas d'augmentation de la bande passante
  ou de la population PBR. Les dalles Medium ajoutées gardent les
  matériaux importés du modèle 3D.
- Le classement existant conserve ses rayons, son bonus de rétention
  et sa pénalité pour les dalles éloignées derrière la caméra.
  Une **petite avance plafonnée à 18 studs de score**, uniquement
  pour les dalles réellement devant le regard et à plus de 24 studs,
  sélectionne mieux la géométrie visible sans nouvel appel raycast.
- Les surfaces natives, l'unique sol physique `Base`,
  les télégraphes des dangers et les contrastes RisingLava restent
  sous leurs propriétaires actuels. Le modèle est supprimé lors de
  Shrinking Arena, du streaming, de l'augmentation de pression ou
  d'une perte du modèle source.

## Vérifications et limites

Le contrôle de régression source **préexistant**
`tools/verify_original_3d_budget_census.py` est étendu : budgets,
priorité caméra, restitution native, provenance et appartenance
au census de Parts locales Android. **Aucun nouveau test unitaire.**
Les source checks GitHub ne constituent pas une mesure FPS Medium
Android, ni une capture 3D réelle. Les 16 dalles ne sont pas garanties
visibles simultanément : la caméra, le streaming et le rayon de
195 studs peuvent réduire le nombre.

Une nouvelle Build Validation et Roblox Open Cloud Engine Tests
sur le SHA exact de `main` devront précéder toute publication
Roblox de ce changement.
