# Chaos Survival — audit screenshots Android du 5 novembre 2026

État initial vérifié sur la branche publique `main`
`27d5a8a59b312343cc3012ec4cd0e69c1286ed16`.

## Constat sur trois captures réelles

1. **P0 / fausse mission de dernier instant :** « ACTIVE LE SIGNAL
   2s • 123st ». Le client priorisait automatiquement toute station
   active, même quand sa fenêtre de neuf secondes était presque finie
   et que la cible réelle était trop éloignée. Elle écrasait aussi
   l'indication d'une éventuelle caisse permanente proche.
2. **P1 / horloge ambiguë :** « TRANSPORT RAPIDE D4 6s • 121st »
   ne distingue pas « ouvre dans » de « expire dans ». La distance
   indiquée est celle du prochain waypoint, pas nécessairement celle
   du signal final.
3. **P1 / consigne tronquée :** « BOUGE AVANT QUE LES PLATEFORMES
   CLIGNOTANTES... » dans le HUD supérieur. Le texte long de
   localisation française dépassait l'emplacement disponible.
4. **P2 / direction visuelle :** beaucoup de surfaces orangées
   de décor et de lave dans la même scène ; une capture statique
   ne permet pas de déduire que les collisions et les dangers sont
   incorrects. Nécessite audit visuel séparé avec vrai mouvement.
5. Le panneau de téléphone flottant à droite semble être une
   surimpression Android extérieure au jeu. Ne pas le retirer
   en modifiant les contrôles Roblox.

## Correctifs sans modifier le serveur des récompenses

- Ajout de `DistrictSignalNavigationRules`, logique déterministe
  avec vitesse **optimiste** de 28 studs/s (intègre les aides au
  déplacement), durée de prompt du signal et durée de maintien du
  vrai transport, lorsque le client observe un hub utilisable.
- Lorsqu'une station est **déjà active**, sa consigne facultative
  n'est conservée que s'il subsiste assez de temps selon cette
  borne optimiste. Sinon le navigateur reprend une caisse réelle
  éligible à proximité ou se masque. Aucun gain de récompense,
  temps de manche, position, collision ou remote n'est modifié.
- Les stations **annoncées avant ouverture** ne sont pas masquées :
  leur vraie fenêtre future permet toujours de se préparer.
- Le HUD compact Android affiche maintenant une phase
  explicite (`OUVRE 6s` / `FIN 6s`, `OPENS` / `ENDS`).
- Consigne française courte : « QUITTE LES PLATEFORMES QUI
  CLIGNOTENT ». Version anglaise raccourcie également.

## Gate avant nouvelle publication

La suite Roblox Engine
`tests/engine/district-signal-navigation.spec.luau`
contrôle 2s/123stud, un signal accessible, la présence/l'absence
de transport valide, les entrées non numériques, les libellés FR/EN
et la lisibilité de l'indication de danger.

**Statut : les tests sont ajoutés ; aucun test moteur ni capture
Android post-correction n'est ici prétendu exécuté.**
Une nouvelle publication doit correspondre au SHA exact validé.

## Travaux ultérieurs séparés

Contraste réel « lave / structure sûre », lecture des contours et
qualité des matériaux PBR sur plusieurs conditions d'éclairage ;
réduire le poids des overlays uniquement après vérification de leurs
zones tactiles Android et des informations critiques affichées.
