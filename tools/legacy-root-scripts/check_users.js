const admin = require("firebase-admin");
admin.initializeApp({ projectId: "wordnerd-artbeat" });
process.env.FIRESTORE_EMULATOR_HOST = "localhost:8080";
const db = admin.firestore();

async function checkUsers() {
  console.log("Checking users...");
  const snapshot = await db.collection("users").limit(20).get();
  console.log(`Found ${snapshot.docs.length} users`);
  let artistCount = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    console.log(
      `User ${doc.id}: userType=${data.userType}, fullName=${data.fullName}, displayName=${data.displayName}`
    );
    if (data.userType === "artist") artistCount++;
  }
  console.log(`Total artists found: ${artistCount}`);
}

checkUsers().catch(console.error);
