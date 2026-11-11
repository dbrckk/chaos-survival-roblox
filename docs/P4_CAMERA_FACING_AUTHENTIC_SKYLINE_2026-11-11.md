# P4 — Priorité face caméra des architectures 3D originales

**11 novembre 2026 — Code source seulement.** Le dépôt ne démontre pas une publication Roblox ou une mesure FPS Android.

## Défaut constaté

Les trois systèmes `ApprovedExteriorTowerMeshKit` (quatre tours),
`ApprovedPrimarySkylineMeshKit` (quatre bâtiments dominants) et
`ApprovedSkylineDepthMeshKit` (huit toitures sculptées) choisissaient
leur nombre très restreint de modèles 3D approuvés par distance pure.
Sur Android Low, **un seul modèle par famille** est autorisé hors
pression ; une sculpture cachée derrière le joueur pouvait donc
consommer ce créneau à la place de la silhouette visible à l'écran.

## Intervention

- Réutiliser le vecteur `cameraLook` déjà calculé dans l'unique
  échantillonneur LOD toutes les 0,65/0,90 secondes.
- Appliquer le même score purement géométrique aux trois familles :
  distance conservée, bonus maximal de 60 studs virtuels en face et
  pénalité maximale de 60 studs en arrière. Silhouette de côté : zéro bonus.
- Conserver strictement l'éligibilité réelle en distance et les
  limites Low/Medium/High et de pression existantes ; pas de nouveau
  MeshPart, AssetService, SurfaceAppearance, rayon de chargement ou lumière.
- Projection horizontale seulement. Si le joueur regarde verticalement,
  si la cible est à 36 studs ou moins, ou si `cameraLook` est invalide,
  l'ancien classement par distance s'applique à l'identique.
- Les primitives natives ne sont masquées qu'après montage/validation
  du modèle propriétaire à sept MeshParts ; toute perte d'asset,
  streaming, pression graphique ou changement de carte garde le repli.
  Aucun collider ni signal de catastrophe n'est touché.

## Vérifications et limites

Vérification statique des trois sites d'appel, de leurs paramètres et de
l'usage commun du helper ; vérification arithmétique des cas face/arrière,
latéral et plongée verticale. Les quotas, les sources propriétaires et
l'unique boucle LOD existants ne sont pas modifiés.

**À faire avant certification de release :** Build Validation sur le
commit exact, essai Roblox Engine et comparaison de captures réelles sur
Android Low/Medium. Une meilleure sélection source n'est ni une preuve
de chargement du modèle, ni une évaluation visuelle ou FPS mesurée.
