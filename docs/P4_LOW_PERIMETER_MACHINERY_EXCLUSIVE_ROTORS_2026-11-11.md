# P4 — Logements mécaniques 3D sur Android Low sans doubler les turbines

**11 novembre 2026** — évolution depuis le commit GitHub
`2bba337f02130f709d6d5eb33d14c56b45b92706`. La dernière Place publique confirmée à ce stade est
`f929326`; cette modification source n'est pas une publication Roblox.

## Audit du défaut

Les quatre stations périmétriques des cinq arènes contiennent chacune trois
gros volumes cosmétiques natifs : `CoreHousing`,
`CompressorPodL` et `CompressorPodR`. Le kit existant remplace
déjà les trois sur Medium/High à partir des modèles originaux Roblox
**Approved** `127295681925871` (Orbital/core) et
`106083832432833` (Towers/pods), mais **Low=0** conservait
les trois cubes Roblox.

Le précédent lot P4 a autorisé trois vrais rotors sur Low à moins de
130 studs (trois fois sept MeshParts), ainsi qu'une paire de contreforts
détaillés à proximité. Autoriser simplement un autre ensemble complet
aurait potentiellement doublé le coût de la mécanique visible.

## Implémentation

- Un seul ensemble authentique de trois sculptures de logement
  peut remplacer les trois `Part` primitives à **125 studs**
  maximum de la caméra sur Android Low, avec rétention 16 studs.
- Sur Low uniquement, les **deux sources importées doivent contenir
  exactement sept MeshParts**. Trois clones au plus par station,
  soit **21 MeshParts maximum**. Sur Medium/High, les anciens modèles
  à 1–12 MeshParts restent acceptés : aucune régression de qualité.
- Les trois modèles sont clonés, placés et vérifiés avant qu'une
  seule primitive ne soit masquée ; si un seul modèle manque ou est
  non conforme, les trois natives restent présentes.
- **Quota partagé Low entre logements et turbines** : sur la
  passe caméra déjà existante, les logements sont synchronisés d'abord.
  Si leur modèle complet est monté sur Low, le kit des turbines reçoit
  `suppressLow=true` et retire ses 21 MeshParts, restaurant
  les trois cylindres. Sans logement valide, les turbines peuvent
  continuer à monter normalement. Un seul ensemble mécanique
  à 21 MeshParts peut donc être présent sur Low par ces deux kits.
- La même télémétrie de pression s'applique : `stress=1` réduit
  chacun des caps Low de 1 à 0 ; les natives reviennent, et au
  stress niveau 2 elles demeurent visibles. Aucun état persistant,
  timer, nouvelle boucle, `RemoteEvent` ou import supplémentaire.
- Sur Medium/High, les deux familles demeurent indépendantes,
  avec leurs anciens caps, rayons et limites tactiles.
- Les modèles restent non physiques, sans nouvelle ombre, dans
  les dossiers déjà recensés par `VisualBudgetRules.LocalFolders`
  sous le quota Android **440 Parts Low**.

## Limites vérifiables

Le kit `PremiumServiceEquipmentAssets` charge les cinq modèles
approuvés du catalogue de façon séquentielle et optionnelle.
L'arrivée effective des deux sources dépend donc du réseau.
L'éligibilité Low **ne garantit pas** leur affichage ; les
cylindres continuent à recevoir leur remplacement existant tant
qu'aucun logement complet ne peut être monté.

Le script de régression **existant**
`tools/verify_original_3d_budget_census.py` vérifie
le montage atomique, la provenance, l'exclusivité de la passe
Low, le repli sous pression et l'intégration au budget.
Aucun nouveau test unitaire. Une validation Build et Roblox
Engine sur le SHA exact et un audit visuel/FPS Android restent
nécessaires avant toute nouvelle publication.
