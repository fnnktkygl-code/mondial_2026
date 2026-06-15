const admin = require('firebase-admin');

// Target Match IDs to remove predictions for
const TARGET_MATCH_IDS = ['g_537351', 'g_537352', 'g_537357', 'g_537358'];

// Check if dry run is requested
const isDryRun = process.argv.includes('--dry-run') || process.env.DRY_RUN === 'true';

async function main() {
  console.log('----------------------------------------------------');
  console.log(`🚀 STARTING PREDICTIONS CLEANUP (${isDryRun ? 'DRY RUN' : 'LIVE RUN'})`);
  console.log(`Target matches: ${TARGET_MATCH_IDS.join(', ')}`);
  console.log('----------------------------------------------------\n');

  // Initialize Firebase Admin
  try {
    try {
      const serviceAccount = require('./serviceAccountKey.json');
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      console.log('✅ Initialized using serviceAccountKey.json');
    } catch (e) {
      admin.initializeApp({
        projectId: 'mondial-2026-challenge-8f'
      });
      console.log('✅ Initialized using default credentials / environmental projectId');
    }
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
    process.exit(1);
  }

  const db = admin.firestore();

  try {
    const usersSnapshot = await db.collection('users').get();
    console.log(`\nFound ${usersSnapshot.size} total users in the database.`);

    let usersProcessed = 0;
    let predictionsRemoved = 0;

    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const username = userData.username || 'Unknown User';
      const predictions = userData.predictions || {};
      
      const matchesToCleanup = [];
      for (const matchId of TARGET_MATCH_IDS) {
        if (predictions[matchId] !== undefined) {
          matchesToCleanup.push(matchId);
        }
      }

      if (matchesToCleanup.length > 0) {
        usersProcessed++;
        predictionsRemoved += matchesToCleanup.length;
        console.log(`👤 User: ${username} (${doc.id})`);
        console.log(`   Found predictions for: ${matchesToCleanup.join(', ')}`);

        if (isDryRun) {
          console.log(`   [DRY RUN] Would delete these predictions from Firestore.`);
        } else {
          // Prepare Firestore update using FieldValue.delete() for nested fields
          const updateData = {};
          for (const matchId of matchesToCleanup) {
            updateData[`predictions.${matchId}`] = admin.firestore.FieldValue.delete();
          }

          console.log(`   [LIVE RUN] Deleting predictions...`);
          await db.collection('users').doc(doc.id).update(updateData);
          console.log(`   [LIVE RUN] Successfully deleted.`);
        }
      }
    }

    console.log('\n----------------------------------------------------');
    console.log(`📊 SUMMARY`);
    console.log(`Processed users with matching predictions: ${usersProcessed}`);
    console.log(`Total prediction entries ${isDryRun ? 'to be removed' : 'removed'}: ${predictionsRemoved}`);
    console.log('----------------------------------------------------');

  } catch (error) {
    console.error('❌ Error during cleanup execution:', error);
  } finally {
    process.exit(0);
  }
}

main();
