# VIS-010 / VIS-027 — routes 3D continues sur les vrais raccords Sky Spine et promenades

**5 novembre 2026 — lot source, aucune publication.** Base auditée `d322dc90f38111e75a9f2a2b06aa2e6151894cec`. La version publique reste `968a49d`.

## Diagnostic

Le sampler `PremiumRouteMeshKit` choisissait les **5** ponts 3D High / **3** Medium uniquement par proximité, en ignorant la connexion des vraies plateformes entre elles. Le résultat pouvait être **modèle premium → boite native → modèle premium** au milieu d'un même chemin, même avec des slots disponibles. L'ancien code vérifiait bien chaque rectangle individuellement, mais ne cherchait aucune continuité de parcours.

## Correction

- Nouvel arbitre de **jonction réelle**, en conservant l'identité de chaque vrai collider `Platforms.PlatformN`, `ChaosPermanentRoute`, ses deux variantes `PromenadeLane + PromenadeStep` (2×8) ou `SkySpineStep` (1×10), et sa phase de collision. Les quatre skybridges à volets Towers restent soumis aux anciennes barrières.
- Dans un même couloir, seules les étapes **consécutives**, de même altitude, alignées et séparées par un vrai saut de **0,35 à 4,5 studs**, constituent une jonction admise. Dans l'interchange en H, seules les étapes Sky Spine **1 / 10** proches des étapes promenade **4 / 5**, effectivement jointives par les empreintes physiques orientées, sont retenues.
- La première enveloppe premium choisie est toujours la plus pertinente selon caméra/LOD. Les copies restantes préfèrent de **38 points** les decks véritablement adjacents aux copies déjà retenues, sans franchir les limites de distance/qualité, sans ajouter de modèles et sans supprimer de plateformes. Cette modification peut réduire l'alternance de modules premium / blocs natifs le long d'un trajet ; elle **ne bouche pas** les vrais interstices de saut.
- Les vrais modèles `PremiumSkybridgeModule` **Approved 94023662427980**, les apparences PBR 2K, les quotas **Low 1 / Medium 3 / High 5**, la validation de couverture des panneaux, le plafonnement des segments **1/3/4**, les quatre sous-châssis High et les budgets mobiles partagés sont inchangés.
- Contrôle défensif contre les faux liens : un décor ou un doublon `Part` sans vraie provenance, un deck au mauvais étage, décollé, hors corridor ou en `CollapsePhase="Warning"` ne peut obtenir le bonus de voisinage. Aucune modification du PathfindingService, de la collision, des bots ou des données de jeu.
- `LocalOriginalConnectedRoute3DPairs` : mesure du nombre de **paires de decks actuellement montées en vrais modèles 3D et physiquement voisines**, distincte du nombre de `MeshParts`. Ce compteur ne prouve pas la continuité d'un maillage UV ni le rendu Android : seules les images réelles peuvent le confirmer.

## Critère de validation moteur et visuelle

Tester dans le vrai moteur Roblox : deux promenades X jointives malgré leur espace de saut de 2,4, leur ordre inverse, une étape non consécutive et éloignée, une jonction Sky Spine Z / promenade X vraiment chevauchante, puis la même déplacée, mise en Warning, déco-collisionnée et falsifiée par une Part sans attribut. Contrôler le build et les sept suites Engine sur le même SHA au jalon important, sans publier. Android : vérifier la texture PBR aux jonctions, les vraies lacunes de saut, et la sélection High/Medium devant caméra mobile. Éviter toute capture/score FPS supposé.
