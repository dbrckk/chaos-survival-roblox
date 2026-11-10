# P4 — Contrat runtime du pont signature Towers

**10 novembre 2026 — uniquement code source sur main, aucun nouveau jeu public certifié.**

## Origine vérifiée

OBJ original authentiquement triangulé à **3 042 triangles, sept groupes de matériaux**, source de `tools/generate_original_signature_towers_bridge.py` : dimensions **40,64 × 4,87784 × 6,77 studs**. L'action GitHub #42777274284 a validé les géométries/UV/normales/tangentes puis Roblox a réellement créé le Model propriétaire **126298311664881** et renvoyé **Moderation: Approved**.

## Remplacement strict

Le module serveur `PremiumTowersSignatureBridgeAssets` charge tardivement par AssetService et passe obligatoirement par `OriginalMeshScenery.sanitize`. Il rejette une source autre que sept MeshParts ancrables, non collisionnels et aux dimensions strictement admissibles.

Le kit client `ApprovedTowersSignatureBridgeMeshKit` recherche uniquement la vraie carte GeneratedMap/Arena **Towers** et son modèle distant `ArenaSignatureMegastructure`, au bon emplacement au nord du sol réel. Il impose la présence de **OverheadServiceBridge** (Part 41 × 2,4 × 6,5 studs), **LowerTruss** (Part 35 × 0,8 × 1,2 studs), **HangingSignal** (WedgePart), ainsi que des deux ascenseurs massifs. Il contrôle les CFrames relatifs des deux premières natives.

Le modèle 3D est cloné avec une **échelle uniforme** et repositionné dans l'enveloppe réunie de deux natives, au point local `CFrame.new(0,-1.3,-.275)` relatif au centre d'OverheadServiceBridge. Sept véritables MeshParts, aucun Roblox Part ajouté, tous ancrés, Massless, CanCollide/CanTouch/CanQuery false, CastShadow false. **Les deux blocs rectangulaires natifs sont masqués ensemble uniquement après validation et installation complète du clone.** Les autres pièces, y compris le signal lumineux et les colonnes, restent intactes.

## LOD Android, rollback et preuve

Le kit réutilise la seule cadence déjà existante de `scenery-lod.client.lua` et le budget de visibilité/Part existant `VisualBudgetRules.LocalFolders`. Low : 0 sculpture, Medium/High : au plus 1 sculpture de 7 MeshParts (le seul grand pont), pression 1 supprime le Medium, pression 2 supprime tout. Distances nominales 390/575 studs avec rétention de 24 studs.

Le client remet les deux Parts natives d'origine en cas de source manquante, modèle partiellement streamé, variation de position, disparition de la carte, réduction de Base, tier Low ou pression GPU 2. Les compteurs `LocalApprovedTowersForgedBridgeCount` et `LocalTowersSignaturePrimitiveSlabsReplaced` comptent uniquement les montages réels dans le client, jamais un FPS fictif.

**Aucune compilation Roblox Engine, mesure Android, capture réelle ni publication publique n'est déclarée dans ce lot.** Le jalon de publication doit vérifier l'orientation des vrais MeshParts, le rendu visible depuis les routes Towers, l'intégration au streaming et le maintien des collisions/charges Skyrail. Le dernier upload public précédemment attesté demeure P2, workflow #42650986552.
