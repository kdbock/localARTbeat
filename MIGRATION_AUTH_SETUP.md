# Migration Script Authentication Setup

The migration script needs Firebase Admin credentials. You have **3 options**:

---

## ✅ Option 1: Interactive Setup (Easiest)

Run the setup helper script:

```bash
./scripts/setup_migration.sh
```

This will guide you through choosing an authentication method.

---

## Option 2: Download Service Account Key

### Steps:
1. Open your Firebase Console: https://console.firebase.google.com
2. Select your project
3. Go to **Project Settings** → **Service Accounts** tab
4. Click **Generate New Private Key**
5. Save the downloaded JSON file as `service-account-key.json` in your project root:
   ```
   /Volumes/ExternalDrive/DevProjects/artbeat/service-account-key.json
   ```

### Then run:
```bash
node scripts/migrate_boosters_schema.js --dry-run
```

**⚠️ Security Note**: 
- Add `service-account-key.json` to `.gitignore` (already should be there)
- Never commit this file to git
- Delete it after migration if not needed

---

## Option 3: Use Firebase CLI Auth (Quick Test)

If you're already logged in with Firebase CLI:

```bash
# Make sure you're logged in
firebase login

# Set your project
firebase use your-project-id

# Run migration
node scripts/migrate_boosters_schema.js --dry-run
```

The script will try to use your Firebase CLI credentials automatically.

---

## Option 4: Use Firebase Emulator (Safest for Testing)

Test the migration on local emulator data:

```bash
# Terminal 1: Start emulator
firebase emulators:start --only firestore

# Terminal 2: Run migration
FIRESTORE_EMULATOR_HOST="localhost:8080" node scripts/migrate_boosters_schema.js --dry-run
```

---

## Troubleshooting

### "Cannot find module 'firebase-admin'"
```bash
cd functions
npm install
cd ..
```

### "Permission denied" errors
Make sure scripts are executable:
```bash
chmod +x scripts/*.sh
chmod +x scripts/*.js
```

### "Index not found" error
Wait a few minutes after deploying indexes:
```bash
firebase deploy --only firestore:indexes
# Wait 5-10 minutes, then retry
```

---

## What the Script Does

The migration script will:
1. ✅ Read all data from `artist_supporters` collection
2. ✅ Copy to new `artist_boosters` collection  
3. ✅ Rename `supporterId` → `boosterId` fields
4. ✅ Update `giftSubscriptions` collection
5. ✅ Keep old collections intact (safe rollback)
6. ✅ Process in batches to handle large datasets

**Safe to Run**: The script never deletes data, only copies and updates.

---

## Recommended Workflow

1. **Test with Emulator First**
   ```bash
   firebase emulators:start --only firestore
   # In another terminal:
   FIRESTORE_EMULATOR_HOST="localhost:8080" node scripts/migrate_boosters_schema.js --dry-run
   ```

2. **Preview Production Changes**
   ```bash
   node scripts/migrate_boosters_schema.js --dry-run
   ```

3. **Run Actual Migration**
   ```bash
   node scripts/migrate_boosters_schema.js
   ```

4. **Verify in Firebase Console**
   - Check `artist_boosters` collection exists
   - Verify data looks correct
   - Test app functionality

5. **Deploy Updated App**
   ```bash
   flutter build appbundle
   ```
