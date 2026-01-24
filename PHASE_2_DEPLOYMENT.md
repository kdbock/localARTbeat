# Phase 2 Deployment Guide

**IMPORTANT**: Follow these steps in order to safely deploy the Firestore schema changes.

---

## Prerequisites

- [ ] Phase 1 deployed and verified
- [ ] Firebase CLI installed (`npm install -g firebase-tools`)
- [ ] Service account key downloaded (`service-account-key.json` in project root)
- [ ] Access to Firebase Console
- [ ] Backup of current Firestore data (optional but recommended)

---

## Step 1: Test Locally (Firebase Emulator)

**Optional but highly recommended for large projects**

```bash
# Start emulators
firebase emulators:start

# In another terminal, test migration
export FIRESTORE_EMULATOR_HOST="localhost:8080"
node scripts/migrate_boosters_schema.js --dry-run
```

---

## Step 2: Deploy Firestore Rules & Indexes

```bash
# Deploy rules (creates security for new collections)
firebase deploy --only firestore:rules

# Deploy indexes (enables efficient queries)
firebase deploy --only firestore:indexes
```

**Expected Output**:
```
✔  firestore: rules and indexes deployed successfully
```

**⏱️ Estimated Time**: 1-2 minutes  
**⚠️ Note**: Index building may take 5-10 minutes for large datasets

---

## Step 3: Deploy Cloud Functions

```bash
# Navigate to functions directory
cd functions

# Install dependencies (if not already done)
npm install

# Return to project root
cd ..

# Deploy functions
firebase deploy --only functions
```

**Expected Output**:
```
✔  functions: deployed successfully
```

**⏱️ Estimated Time**: 2-5 minutes

---

## Step 4: Run Data Migration

### 4a. Dry Run (Preview Only)
```bash
node scripts/migrate_boosters_schema.js --dry-run
```

**Review the output carefully**:
- Number of artists to migrate
- Number of boosters to migrate
- Fields to be updated
- Any errors or warnings

### 4b. Live Migration
```bash
# Only run this after reviewing dry-run output!
node scripts/migrate_boosters_schema.js
```

**⏱️ Estimated Time**: ~30 seconds per 1000 booster records

**Progress Indicators**:
```
📋 Processing artist: abc123
  Found 15 supporters to migrate
  ✓ Committed batch of 15 documents
  ✓ Completed artist abc123
```

**What Happens**:
1. Reads all documents from `artist_supporters` collection
2. For each artist, reads all `supporters` subcollection documents
3. Copies data to new `artist_boosters`/`boosters` structure
4. Renames `supporterId` → `boosterId` field
5. Updates `giftSubscriptions` field names
6. Commits changes in batches

**⚠️ IMPORTANT**: 
- Old collections are NOT deleted (safe rollback)
- Migration can be re-run if interrupted
- Monitor Firebase Console during migration

---

## Step 5: Deploy Flutter App

### 5a. Test Locally First
```bash
flutter clean
flutter pub get
flutter run
```

**Manual Test Cases**:
- [ ] View artist profile → "Boosted By" section loads
- [ ] Purchase boost → appears in booster list
- [ ] Check early access badge displays
- [ ] Verify no errors in console about missing collections

### 5b. Build Release
```bash
# Android
flutter build appbundle --release

# iOS
flutter build ipa --release
```

### 5c. Deploy to Stores
- Upload to Google Play Console (Internal/Beta track first)
- Upload to App Store Connect (TestFlight first)
- Monitor crash reports for 24-48 hours before production release

---

## Step 6: Verification

### 6a. Firestore Console Check
1. Open Firebase Console → Firestore Database
2. Verify new collections exist:
   - `artist_boosters` (parent collection)
   - `boosters` (subcollection under artist documents)
3. Verify field names:
   - `boosterId` (not `supporterId`)
   - `lastBoostAt`, `boostCount`, `earlyAccessTier`

### 6b. Test Boost Purchase
1. Open app (use dev/staging environment)
2. Navigate to artist profile
3. Tap boost button
4. Complete purchase (use test payment if available)
5. Refresh profile → verify booster appears in list
6. Check Firebase Console → verify data in `artist_boosters` collection

### 6c. Monitor Cloud Functions Logs
```bash
firebase functions:log --only processBoostTransaction
```

Look for:
- ✅ Successful writes to `artist_boosters` collection
- ❌ No errors about missing collections
- ❌ No references to old `artist_supporters` collection

---

## Step 7: Monitor Production

**First 24 Hours**:
- Check Firebase Console hourly for errors
- Monitor crash reports in Firebase Crashlytics
- Review user feedback/support tickets
- Watch for spike in error rates

**Key Metrics to Watch**:
- Boost purchase success rate
- Database read/write errors
- App crash rate
- User retention

---

## Rollback Plan

If critical issues occur:

### Immediate Rollback (App Only)
```bash
# Revert to previous app version
flutter build appbundle --release
# Upload previous version to stores
```

### Full Rollback (Backend + App)
```bash
# Revert code changes
git revert <commit-hash>

# Redeploy functions
firebase deploy --only functions

# Redeploy rules (use backup)
cp firestore.rules.backup firestore.rules
firebase deploy --only firestore:rules

# Redeploy app
flutter build appbundle --release
```

**Data Integrity**: Old collections remain intact, so app can read from them during rollback.

---

## Cleanup (After 2-4 Weeks)

Once confident in new schema:

```bash
# Backup old data first!
firebase firestore:export gs://your-bucket/backups/artist_supporters

# Delete old collection (use Firebase Console or script)
# WARNING: This is permanent!
```

---

## Troubleshooting

### Issue: "Index not found" error
**Solution**: Wait 5-10 minutes for indexes to build, then retry

### Issue: Migration script fails with "Permission denied"
**Solution**: Verify service account key has Firestore Admin role

### Issue: App shows empty booster lists
**Solution**: Check Firestore rules allow public read on `artist_boosters` collection

### Issue: Cloud Function writes to old collection
**Solution**: Verify functions deployed correctly with `firebase functions:log`

### Issue: High error rate in production
**Solution**: Revert app to previous version, investigate in staging

---

## Support

If issues persist:
1. Check Firebase Console logs
2. Review [PHASE_2_COMPLETE.md](PHASE_2_COMPLETE.md) for troubleshooting
3. Test in Firebase Emulator for detailed error messages
4. Roll back if user experience is significantly impacted

---

## Success Confirmation

Phase 2 deployment is successful when:
- ✅ All booster data visible in new `artist_boosters` collection
- ✅ App functions normally with no increase in errors
- ✅ Boost purchases write to new schema
- ✅ No "supporter" terminology in logs
- ✅ User experience unchanged from user perspective
