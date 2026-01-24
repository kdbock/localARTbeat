#!/usr/bin/env node

/**
 * Firestore Schema Migration Script
 * 
 * Migrates data from old "supporter" terminology to new "booster" terminology
 * 
 * Changes:
 * - Collection: artist_supporters → artist_boosters
 * - Subcollection: supporters → boosters
 * - Field: supporterId → boosterId
 * 
 * Usage:
 *   node scripts/migrate_boosters_schema.js [--dry-run] [--batch-size=500]
 * 
 * Options:
 *   --dry-run: Preview changes without writing to database
 *   --batch-size: Number of documents to process per batch (default: 500)
 */

const admin = require('firebase-admin');
const path = require('path');

// Parse command line arguments
const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const batchSizeArg = args.find(arg => arg.startsWith('--batch-size='));
const batchSize = batchSizeArg ? parseInt(batchSizeArg.split('=')[1]) : 500;
const projectIdArg = args.find(arg => arg.startsWith('--project='));
let projectId = projectIdArg ? projectIdArg.split('=')[1] : null;

// Try to get project ID from .firebaserc if not provided
if (!projectId) {
  const fs = require('fs');
  const firebaseRcPath = path.join(__dirname, '..', '.firebaserc');
  if (fs.existsSync(firebaseRcPath)) {
    try {
      const firebaseRc = JSON.parse(fs.readFileSync(firebaseRcPath, 'utf8'));
      projectId = firebaseRc.projects?.default;
      if (projectId) {
        console.log(`📋 Using project from .firebaserc: ${projectId}`);
      }
    } catch (error) {
      // Ignore errors reading .firebaserc
    }
  }
}

console.log('='.repeat(60));
console.log('Firestore Schema Migration: Supporters → Boosters');
console.log('='.repeat(60));
console.log(`Mode: ${dryRun ? 'DRY RUN (no changes will be made)' : 'LIVE MIGRATION'}`);
console.log(`Batch Size: ${batchSize}`);
if (projectId) {
  console.log(`Project ID: ${projectId}`);
}
console.log('='.repeat(60));
console.log('');

// Initialize Firebase Admin
let initializeSuccess = false;

// Try method 1: Service account key file
const serviceAccountPath = path.join(__dirname, '..', 'service-account-key.json');
const fs = require('fs');

if (fs.existsSync(serviceAccountPath)) {
  try {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: projectId || serviceAccount.project_id
    });
    console.log('✓ Firebase Admin initialized with service account key');
    initializeSuccess = true;
  } catch (error) {
    console.error('✗ Failed to initialize with service account key:', error.message);
  }
}

// Try method 2: Application Default Credentials (if logged in with Firebase CLI)
if (!initializeSuccess) {
  try {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: projectId
    });
    console.log('✓ Firebase Admin initialized with application default credentials');
    initializeSuccess = true;
  } catch (error) {
    console.error('✗ Failed to initialize with application default credentials:', error.message);
  }
}

// Try method 3: Use functions emulator environment (if running in emulator)
if (!initializeSuccess) {
  try {
    admin.initializeApp({
      projectId: projectId
    });
    console.log('✓ Firebase Admin initialized (emulator or default)');
    initializeSuccess = true;
  } catch (error) {
    console.error('✗ Failed to initialize Firebase Admin');
  }
}

if (!initializeSuccess) {
  console.error('\n❌ Could not initialize Firebase Admin. Please choose one option:\n');
  console.error('Option 1: Specify project ID');
  console.error('  node scripts/migrate_boosters_schema.js --dry-run --project=wordnerd-artbeat\n');
  console.error('Option 2: Download service account key');
  console.error('  1. Go to Firebase Console → Project Settings → Service Accounts');
  console.error('  2. Click "Generate New Private Key"');
  console.error('  3. Save as service-account-key.json in project root\n');
  console.error('Option 3: Use Firebase CLI authentication');
  console.error('  1. Run: firebase login');
  console.error('  2. Run: export GOOGLE_APPLICATION_CREDENTIALS="~/.config/firebase/credentials.json"');
  console.error('  3. Try migration script again\n');
  console.error('Option 4: Test with Firebase Emulator');
  console.error('  1. Run: firebase emulators:start');
  console.error('  2. Run migration script with emulator running\n');
  process.exit(1);
}

if (!projectId) {
  console.error('\n⚠️  Warning: No project ID detected. This may cause issues.\n');
  console.error('To specify project ID explicitly:');
  console.error('  node scripts/migrate_boosters_schema.js --dry-run --project=wordnerd-artbeat\n');
}

const db = admin.firestore();

// Migration statistics
const stats = {
  artistsProcessed: 0,
  boostersProcessed: 0,
  fieldsMigrated: 0,
  errors: 0,
  skipped: 0
};

/**
 * Migrate a single artist's supporters to boosters
 */
async function migrateArtistBoosters(artistId) {
  try {
    console.log(`\n📋 Processing artist: ${artistId}`);
    
    // Get all supporters for this artist
    const supportersSnapshot = await db
      .collection('artist_supporters')
      .doc(artistId)
      .collection('supporters')
      .get();
    
    if (supportersSnapshot.empty) {
      console.log('  ⚠️  No supporters found, skipping');
      stats.skipped++;
      return;
    }
    
    console.log(`  Found ${supportersSnapshot.size} supporters to migrate`);
    
    if (!dryRun) {
      const batch = db.batch();
      let batchCount = 0;
      
      for (const doc of supportersSnapshot.docs) {
        const data = doc.data();
        
        // Migrate field name: supporterId → boosterId
        const migratedData = { ...data };
        if (data.supporterId) {
          migratedData.boosterId = data.supporterId;
          delete migratedData.supporterId;
          stats.fieldsMigrated++;
        }
        
        // Write to new collection/subcollection structure
        const newDocRef = db
          .collection('artist_boosters')
          .doc(artistId)
          .collection('boosters')
          .doc(doc.id);
        
        batch.set(newDocRef, migratedData);
        batchCount++;
        stats.boostersProcessed++;
        
        // Commit batch if it reaches the limit
        if (batchCount >= batchSize) {
          await batch.commit();
          console.log(`  ✓ Committed batch of ${batchCount} documents`);
          batchCount = 0;
        }
      }
      
      // Commit remaining documents
      if (batchCount > 0) {
        await batch.commit();
        console.log(`  ✓ Committed final batch of ${batchCount} documents`);
      }
    } else {
      // Dry run: just count and preview
      for (const doc of supportersSnapshot.docs) {
        const data = doc.data();
        stats.boostersProcessed++;
        
        if (data.supporterId) {
          stats.fieldsMigrated++;
          console.log(`  📝 Would migrate: ${doc.id} (supporterId → boosterId)`);
        }
      }
    }
    
    stats.artistsProcessed++;
    console.log(`  ✓ Completed artist ${artistId}`);
    
  } catch (error) {
    console.error(`  ✗ Error migrating artist ${artistId}:`, error.message);
    stats.errors++;
  }
}

/**
 * Migrate giftSubscriptions field: supporterId → boosterId
 */
async function migrateGiftSubscriptions() {
  try {
    console.log('\n📋 Processing giftSubscriptions collection');
    
    const snapshot = await db
      .collection('giftSubscriptions')
      .where('supporterId', '!=', null)
      .get();
    
    if (snapshot.empty) {
      console.log('  ℹ️  No documents with supporterId field found');
      return;
    }
    
    console.log(`  Found ${snapshot.size} documents to update`);
    
    if (!dryRun) {
      const batch = db.batch();
      let count = 0;
      
      for (const doc of snapshot.docs) {
        const data = doc.data();
        
        batch.update(doc.ref, {
          boosterId: data.supporterId,
          supporterId: admin.firestore.FieldValue.delete()
        });
        count++;
        stats.fieldsMigrated++;
      }
      
      await batch.commit();
      console.log(`  ✓ Updated ${count} gift subscription documents`);
    } else {
      stats.fieldsMigrated += snapshot.size;
      console.log(`  📝 Would update ${snapshot.size} documents (supporterId → boosterId)`);
    }
    
  } catch (error) {
    console.error('  ✗ Error migrating giftSubscriptions:', error.message);
    stats.errors++;
  }
}

/**
 * Main migration function
 */
async function runMigration() {
  const startTime = Date.now();
  
  try {
    // Step 1: Get all artists with supporters
    console.log('\n🔍 Finding artists with supporters...');
    const artistSupportersSnapshot = await db
      .collection('artist_supporters')
      .get();
    
    console.log(`Found ${artistSupportersSnapshot.size} artists with supporter records\n`);
    
    if (artistSupportersSnapshot.empty) {
      console.log('⚠️  No artists found to migrate');
      return;
    }
    
    // Step 2: Migrate each artist's supporters to boosters
    for (const doc of artistSupportersSnapshot.docs) {
      await migrateArtistBoosters(doc.id);
    }
    
    // Step 3: Migrate giftSubscriptions field
    await migrateGiftSubscriptions();
    
    // Print summary
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    
    console.log('\n' + '='.repeat(60));
    console.log('Migration Summary');
    console.log('='.repeat(60));
    console.log(`Mode:               ${dryRun ? 'DRY RUN' : 'LIVE MIGRATION'}`);
    console.log(`Duration:           ${duration}s`);
    console.log(`Artists processed:  ${stats.artistsProcessed}`);
    console.log(`Boosters migrated:  ${stats.boostersProcessed}`);
    console.log(`Fields updated:     ${stats.fieldsMigrated}`);
    console.log(`Skipped:            ${stats.skipped}`);
    console.log(`Errors:             ${stats.errors}`);
    console.log('='.repeat(60));
    
    if (dryRun) {
      console.log('\n💡 This was a dry run. No changes were made.');
      console.log('   Run without --dry-run to perform the migration.');
    } else {
      console.log('\n✅ Migration complete!');
      console.log('\n⚠️  IMPORTANT NEXT STEPS:');
      console.log('   1. Verify data in new collections (artist_boosters/boosters)');
      console.log('   2. Test app functionality with new schema');
      console.log('   3. Deploy new Firestore rules and indexes');
      console.log('   4. After verification, delete old collections:');
      console.log('      - artist_supporters');
      console.log('      - Use Firebase Console or create cleanup script');
    }
    
  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    stats.errors++;
  } finally {
    process.exit(stats.errors > 0 ? 1 : 0);
  }
}

// Run migration
runMigration();
