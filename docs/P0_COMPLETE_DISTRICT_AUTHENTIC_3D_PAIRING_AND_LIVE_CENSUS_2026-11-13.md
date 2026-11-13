# P0 — Couverture visuelle complète des districts : façades et coques 3D appariées

**Projet :** Chaos Survival (`dbrckk/chaos-survival-roblox`) · **Date :** 13 novembre 2026.

## Problème observé

Les **16 bâtiments** de chacun des cinq plans sont initialement produits avec une façade, une toiture et des volumes latéraux en primitives Roblox. Deux familles de modèles de créateur modérés `Approved` existent : quatre façades/rooflines originales gérées par `PremiumDistrictFacadeMeshKit` et une coque arrière/latérale originale à **six MeshParts et 1 764 triangles** (asset `77387019170428`) qui remplace exactement **cinq** volumes natifs `ServiceCore`, `ArmoredSupportL/R`, `SideCassette-1/1`.

Sur Android Low, le kit imposait déjà que la façade authentique soit en place avant de monter la coque. En **Medium/High**, la réservation des coques était classée surtout par distance. Si une façade modérée était absente, indisponible ou momentanément évincée, une coque pouvait dépenser un précieux emplacement GPU sur un bâtiment dont la face avant restait une forme primitive, alors qu'un bâtiment voisin avec façade approuvée avait besoin de sa coque pour devenir intégralement 3D.

## Livraison

1. `ApprovedDistrictSidewallMeshKit.pairedPriority` donne une préférence modérée équivalente à **16 studs** aux bâtiments possédant **effectivement** le marqueur client de résidence `LocalApprovedDistrictFacadeMounted=true`. Le tri ne force pas un objet hors caméra (pénalité arrière existante **80**) et n'empêche pas un bâtiment nettement plus proche de recevoir sa coque. La qualité Low garde sa règle **stricte** de façade déjà montée.
2. Les contraintes de distance, de source approuvée, de collision, de porte visible, d'ancrage, de dimensions originales et de repli lors du rétrécissement des arènes sont conservées. Aucun nouveau modèle n'est importé, aucun nouvel appel réseau ou `RenderStepped` n'a été ajouté.
3. **Comptage runtime transparent :** `LocalCompleteDistrict3DCount` = nombre de bâtiments qui ont *simultanément* leur façade approuvée et une coque 3D effectivement montée sur le même propriétaire. `LocalUnpairedDistrictSidewall3DCount` = coques montées sans façade authentique. Les compteurs sont rééchantillonnés dans la **boucle LOD existante**, sans parcourir à nouveau le Workspace.
4. Plafonds inchangés : **Low 1**, **Medium 4** (tactile **3**), **High 10** (tactile **8**) pour les coques latérales. À pression GPU 1, moitié de ces modèles au maximum ; pression 2, **zéro**. Les natives restent en place tant que leur véritable géométrie MeshPart ne peut pas être montée.

## Validation

- `tools/verify_original_3d_budget_census.py` vérifie le modèle réellement approuvé, la priorité appariée, l'ordre de montage (façade avant coque), le comptage client et les plafonds inchangés.
- `tests/engine/visual-budget-rules.spec.luau` utilise le vrai générateur serveur à **16 bâtiments** : monte façade+coque sur un même bâtiment en Low, vérifie les cinq primitives masquées, le retour natif sous pression ou perte de façade, et le comptage exact ; teste également la résidence et la disparition de la paire en Medium. Les règles de classement Medium/High sont testées face à une différence de distance et à la pénalité hors caméra.
- Ces résultats garantissent la sécurité des sélections, **pas** une valeur FPS Android ni un pourcentage de structures « définitivement remplacées ». Le nombre d'édifices complets est désormais consultable en runtime au lieu d'être deviné.

## Résultats finaux vérifiés

- [Contrôle source des budgets et des assets approuvés : réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43420796671).
- [Build Validation : réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43421331456), commit testé `0851ede54574cded0cf224c97043496a734632e0`.
- [Prépublication (déclenchement des tests, pas du jeu) : réussie](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43422081928).
- [**Sept suites Roblox Open Cloud Engine : réussies**](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43422096406), le **même** commit `0851ede54574cded0cf224c97043496a734632e0`. L'intégration Medium et la priorité 3D sont exercées en moteur, avec des fixtures MeshParts de test, non des captures Android.
- Le workflow de prépublication a été restauré à son contenu précédent après une tentative de modification du contrôle de déclenchement. [La comparaison source](https://github.com/dbrckk/chaos-survival-roblox/compare/0851ede54574cded0cf224c97043496a734632e0...6fed4008af36bb3a6f3b9bef0ee32655b0d28e8e) ne montre **aucun fichier modifié** entre le commit moteur validé et ce dernier commit de restauration.

**Publication :** aucune republication publique Roblox n'a eu lieu pendant ce chantier. Une suite Engine verte ne mesure pas des FPS Android réels ni ne remplace la certification visuelle du jeu déployé.
