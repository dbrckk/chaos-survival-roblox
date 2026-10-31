# Chaos Survival — coordination caméra, impacts, réceptions et retours Android

31 octobre 2026. Travail sur les contrôleurs client, sans audit actuel des cartes, sans exécution Roblox Studio et sans publication publique.

## Constat issu de l’inspection réelle de main

Les contrôleurs `movement-feel.client.lua` et `body-feel.client.lua` ont déjà des animations dédiées : impulsion légère de caméra à l’atterrissage, réactions localisées aux explosions, marqueurs de réception et accentuation corporelle. Le problème se situe dans la synchronisation d’événements et la restitution des **anciens états** :

- `movement-feel` réagissait à un `RoundState` sans vérifier le type, l’ancien numéro de manche ou l’intégrité des `disasterIds`. Un snapshot en retard pouvait réactiver un lancement/overdrive caméra sur un match ultérieur ou provoquer une erreur Lua si le tableau était mal formé.
- Sur une caméra Scriptable, une transition de spectateur, la perte du personnage ou un retour après suspension Android, le contrôleur effaçait seulement une partie de son ressort : `impactKick`, `landingKick`, `presentationKickTarget` et l’historique de vitesse restaient en mémoire. Le joueur pouvait recevoir une secousse devenue obsolète lors du rétablissement de la caméra native.
- Les événements d’impact ne vérifiaient que `typeof(position)=="Vector3"` sans rejeter les coordonnées infinies/NaN ; un rayon non fini pouvait atteindre `math.clamp`. Ce sont des données de présentation **non fiables** et elles ne doivent pas atteindre l’orientation des articulations ou la caméra.
- `body-feel` acceptait tout `RoundFeedback` comme une célébration fraîche, même après le résultat ou à la manche suivante, et répétait la même animation sur les reçus dupliqués.
- Le `VfxQuality.get(nil)` par défaut High pouvait s’appliquer aux poussières et poses décoratives avant la première décision du régulateur de FPS sur Android.

## Correctifs

1. **Propriété de la caméra** : `suspendCameraMotion()` remet à zéro **tous les ressorts et impulsions locaux**, l’historique de saut, le bus FOV cosmétique et l’aperçu d’atterrissage lorsque le joueur ne possède plus la caméra. Il rééchantillonne la vitesse réelle du `HumanoidRootPart` quand elle existe, sans produire de fausse accélération lors du retour. Réutilisé en cas de frame suspendue Android (delta invalide/long).
2. **États de manche** : ignorer les snapshots malformés ou de numéro antérieur ; ne recalculer les impulsions de RoundStart, FinalRush et Overdrive qu’à partir de transitions valides. Une nouvelle manche numérotée en phase `round` reçoit un nouveau kick initial au lieu d’hériter du FinalRush de la manche précédente. Les désastres actifs ne sont lus que si `disasterIds` est une table.
3. **Validation des impacts** : utiliser `CharacterReactionRules.validPosition` pour rejeter les coordonnées invalides, et valider le rayon contre NaN, infinité et valeurs négatives avant les calculs cosmétiques. Ne modifier **aucune** zone serveur, force physique, collision, dégâts, projectile ou animation native.
4. **Réceptions réelles seulement** : les particules sur la racine sont déclenchées durant une manche active pour un participant vivant non éliminé ; les réglages suivent `VfxQuality.deviceTier` sur PC/Android.
5. **Victoire du bon match** : l’animation additive du corps réutilise `ResultPresentation.acceptReceipt`, exige un numéro concordant avec la manche observée, et n’est pas redémarrée pour le même reçu/état. Une mise à niveau du résultat (survivant vers master) reste possible. Les postures de résultat sont supprimées avant READY, l’attente ou le nouveau numéro de manche.
6. **Profil Android** : les offsets du corps, les poussières d'atterrissage et les effets de contact au sol démarrent Medium sur écran tactile, puis respectent Low / Medium / High. Le contrôleur Roblox de caméra, sa cible, le `Humanoid` et toutes les commandes Android restent inchangés.

## Validation nécessaire au prochain jalon majeur

- Build Validation et les **cinq suites Roblox Open Cloud** sur le SHA exact de `main`, et non sur l’ancien SHA déjà validé.
- En partie, tester sur Android et PC : READY -> round -> résultat -> READY, plus deux manches numérotées sans intermission ; aucune secousse ou célébration fantôme du round précédent.
- Faire un saut puis passer en caméra Scriptable et revenir pendant la chute ; tester spectateur puis reprise de son propre `Humanoid` ; aucune accélération ou secousse résiduelle, le retour doit conserver la caméra Roblox native.
- Mettre Android en arrière-plan pendant une explosion et reprendre plus tard ; ne pas rejouer l’ancienne secousse ; une nouvelle explosion valide doit rester perceptible.
- Alterner ReduceMotion, Low/Medium/High, et un démarrage sans `VfxQualityTier` ; vérifier poussières, contact au sol, échelle du body-feel et fluidité.
- Tester des payloads d’impact malformés et des reçus de round anciens en environnement autorisé ; aucun artefact ou erreur client.
- Mesurer les FPS, la mémoire, les poses R6/R15, les transitions d’enquête visuelle **plus tard** ; aucun gain quantifié n’est revendiqué ici.

Aucune session Roblox Studio, audit visuel réel des cartes, mesure FPS ou publication publique n’a eu lieu pendant cette amélioration source.
