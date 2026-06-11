const admin = require('firebase-admin');

/**
 * Script pour supprimer tous les groupes, tous les utilisateurs de Firestore
 * ainsi que tous les comptes de Firebase Authentication.
 * 
 * PRÉREQUIS :
 * 1. Avoir Node.js installé.
 * 2. Télécharger votre clé de service (JSON) depuis la console Firebase :
 *    Paramètres du projet > Comptes de service > Générer une nouvelle clé privée.
 * 3. Enregistrer ce fichier sous le nom 'serviceAccountKey.json' dans le même dossier que ce script.
 * 4. Exécuter : npm install firebase-admin
 */

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function deleteAllUsersFromAuth() {
  console.log('Récupération des utilisateurs de Firebase Auth...');
  let nextPageToken;
  let count = 0;
  
  do {
    const listUsersResult = await auth.listUsers(1000, nextPageToken);
    const uids = listUsersResult.users.map((user) => user.uid);
    if (uids.length > 0) {
      await auth.deleteUsers(uids);
      count += uids.length;
      console.log(`Supprimé ${uids.length} utilisateurs de Auth (Total: ${count}).`);
    }
    nextPageToken = listUsersResult.pageToken;
  } while (nextPageToken);
  
  if (count === 0) console.log('Aucun utilisateur à supprimer dans Auth.');
}

async function main() {
  console.log('--- DÉBUT DU NETTOYAGE FIREBASE ---');

  try {
    // 1. Supprimer la collection 'users' (incluant les sous-collections comme 'notifications')
    console.log('Suppression récursive de la collection "users"...');
    await db.recursiveDelete(db.collection('users'));
    console.log('Collection "users" supprimée.');

    // 2. Supprimer la collection 'groups'
    console.log('Suppression récursive de la collection "groups"...');
    await db.recursiveDelete(db.collection('groups'));
    console.log('Collection "groups" supprimée.');

    // 3. Supprimer tous les utilisateurs de Firebase Auth
    await deleteAllUsersFromAuth();

    console.log('\n--- NETTOYAGE TERMINÉ AVEC SUCCÈS ---');
  } catch (error) {
    console.error('\n❌ ERREUR LORS DU NETTOYAGE :', error);
  } finally {
    process.exit();
  }
}

main();
