const admin = require('firebase-admin');

// Initialize Firebase Admin (assumes running in Firebase environment)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function debugUsers() {
  console.log('🔍 Debugging user data...');

  try {
    // Get all users with XP > 0
    const usersSnapshot = await db.collection('users')
      .where('experiencePoints', '>', 0)
      .orderBy('experiencePoints', 'desc')
      .get();

    console.log(`👥 Found ${usersSnapshot.docs.length} users with XP`);

    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const stats = userData.stats || {};
      
      console.log(`\n👤 ${userData.fullName || userData.username || 'Unknown'} (${doc.id})`);
      console.log(`   ⚡ XP: ${userData.experiencePoints || 0}`);
      console.log(`   👑 Level: ${userData.level || 1}`);
      console.log(`   📊 Stats:`, {
        capturesCreated: stats.capturesCreated || 0,
        capturesApproved: stats.capturesApproved || 0,
        walksCreated: stats.walksCreated || 0,
        walksCompleted: stats.walksCompleted || 0,
        highestRatedCapture: stats.highestRatedCapture || 0,
        highestRatedArtWalk: stats.highestRatedArtWalk || 0
      });
    }

    // Check art walks collection
    console.log('\n🚶 Checking art walks...');
    const artWalksSnapshot = await db.collection('artWalks').get();
    console.log(`   Found ${artWalksSnapshot.docs.length} art walks total`);
    
    const creatorCounts = {};
    for (const doc of artWalksSnapshot.docs) {
      const walkData = doc.data();
      const creatorId = walkData.createdBy || walkData.userId;
      if (creatorId) {
        creatorCounts[creatorId] = (creatorCounts[creatorId] || 0) + 1;
      }
    }
    
    console.log('   Art walk creators:', creatorCounts);

  } catch (error) {
    console.error('❌ Error debugging users:', error);
  }
}

// Run the debug
debugUsers();