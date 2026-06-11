# Scripts de Maintenance Firebase

Ce dossier contient des scripts pour administrer votre base de données Firebase.

## Nettoyage des données (`cleanup_firebase.js`)

Ce script supprime :
- Tous les documents de la collection `users` (y compris les sous-collections comme `notifications`).
- Tous les documents de la collection `groups`.
- Tous les utilisateurs enregistrés dans Firebase Authentication.

### Utilisation

1. **Installer Node.js** si ce n'est pas déjà fait.
2. Dans ce dossier (`scripts/`), initialisez npm et installez la dépendance :
   ```bash
   npm init -y
   npm install firebase-admin
   ```
3. **Récupérer la clé de service** :
   - Allez dans la [Console Firebase](https://console.firebase.google.com/).
   - Sélectionnez votre projet.
   - Cliquez sur l'icône d'engrenage (Paramètres du projet) > **Comptes de service**.
   - Cliquez sur **Générer une nouvelle clé privée**.
   - Enregistrez le fichier JSON téléchargé dans ce dossier sous le nom `serviceAccountKey.json`.
4. **Lancer le script** :
   ```bash
   node cleanup_firebase.js
   ```

⚠️ **ATTENTION** : Cette opération est irréversible. Assurez-vous d'avoir une sauvegarde si nécessaire.
