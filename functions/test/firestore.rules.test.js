const {
  test,
  before,
  after,
} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  setDoc,
  updateDoc,
} = require("firebase/firestore");

const PROJECT_ID = "wordnerd-artbeat-rules-test";
const RULES_PATH = path.resolve(__dirname, "../../firestore.rules");

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(RULES_PATH, "utf8"),
    },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "users", "owner"), {userType: "regular"});
    await setDoc(doc(db, "users", "attacker"), {userType: "regular"});
    await setDoc(doc(db, "users", "admin"), {userType: "admin"});
  });
});

test("deny cross-user update of presence/engagement fields", async () => {
  const attackerDb = testEnv.authenticatedContext("attacker").firestore();
  await assertFails(
    updateDoc(doc(attackerDb, "users", "owner"), {
      isOnline: true,
      lastActive: new Date(),
      engagementStats: {followers: 9999},
    })
  );
});

test("allow owner to update own presence/engagement fields", async () => {
  const ownerDb = testEnv.authenticatedContext("owner").firestore();
  await assertSucceeds(
    updateDoc(doc(ownerDb, "users", "owner"), {
      isOnline: true,
      lastActive: new Date(),
      engagementStats: {followers: 1},
    })
  );
});

test("deny forged sender in user notifications subcollection", async () => {
  const attackerDb = testEnv.authenticatedContext("attacker").firestore();
  await assertFails(
    setDoc(doc(attackerDb, "users", "owner", "notifications", "n1"), {
      fromUserId: "owner",
      toUserId: "owner",
      title: "forged",
      read: false,
    })
  );
});

test("allow sender to create notification for target user", async () => {
  const attackerDb = testEnv.authenticatedContext("attacker").firestore();
  await assertSucceeds(
    setDoc(doc(attackerDb, "users", "owner", "notifications", "n2"), {
      fromUserId: "attacker",
      toUserId: "owner",
      title: "legit sender",
      read: false,
    })
  );
});

test("deny top-level notification create when user is neither sender nor recipient", async () => {
  const attackerDb = testEnv.authenticatedContext("attacker").firestore();
  await assertFails(
    setDoc(doc(attackerDb, "notifications", "n3"), {
      fromUserId: "owner",
      toUserId: "admin",
      title: "spoofed",
      read: false,
    })
  );
});

test("allow top-level notification create when user is sender", async () => {
  const attackerDb = testEnv.authenticatedContext("attacker").firestore();
  await assertSucceeds(
    setDoc(doc(attackerDb, "notifications", "n4"), {
      fromUserId: "attacker",
      toUserId: "owner",
      title: "legit top-level",
      read: false,
    })
  );
});

test("allow admin write access path remains valid", async () => {
  const adminDb = testEnv.authenticatedContext("admin").firestore();
  await assertSucceeds(
    updateDoc(doc(adminDb, "users", "owner"), {
      userType: "regular",
      fullName: "Owner User",
    })
  );
});

after(async () => {
  assert.ok(testEnv);
  await testEnv.cleanup();
});
