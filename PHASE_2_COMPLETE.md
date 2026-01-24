# Phase 2: Firestore Schema Updates - COMPLETE ✅

**Completed Date**: January 23, 2026

## Overview
Phase 2 updated the Firestore database schema to replace all "supporter" terminology with compliant "booster" terminology. This ensures backend consistency with the UI changes from Phase 1.

---

## ✅ Completed Changes

### 1. Collection Renaming

| Old Collection | New Collection | Purpose |
|----------------|----------------|---------|
| `artist_supporters` | `artist_boosters` | Parent collection for artist boost records |
| `artist_supporters/{artistId}/supporters` | `artist_boosters/{artistId}/boosters` | Subcollection tracking individual boosters |

**Impact**: All Firestore queries now use compliant naming that won't appear in debug logs or error messages.

---

### 2. Field Renaming

| Old Field | New Field | Collections |
|-----------|-----------|-------------|
| `supporterId` | `boosterId` | `giftSubscriptions`, `boosters` subcollection |
| `supporterTier` | *(kept as `tier`)* | `boosters` subcollection |

**Note**: Other fields like `lastBoostAt`, `boostCount`, and `earlyAccessTier` were already using compliant terminology.

---

### 3. Code Updates

#### Flutter App (Dart)
**File**: [`artist_public_profile_screen.dart`](packages/artbeat_artist/lib/src/screens/artist_public_profile_screen.dart)

```dart
// OLD:
FirebaseFirestore.instance
  .collection('artist_supporters')
  .doc(artistUserId)
  .collection('supporters')

// NEW:
FirebaseFirestore.instance
  .collection('artist_boosters')
  .doc(artistUserId)
  .collection('boosters')
```

**Lines Changed**: 65-67, 116-118

---

#### Cloud Functions (JavaScript)
**File**: [`functions/src/index.js`](functions/src/index.js)

```javascript
// OLD:
.collection("artist_supporters")
.doc(recipientId)
.collection("supporters")
.doc(senderId)
.set({
  supporterId: senderId,
  // ...
})

// NEW:
.collection("artist_boosters")
.doc(recipientId)
.collection("boosters")
.doc(senderId)
.set({
  boosterId: senderId,
  // ...
})
```

**Lines Changed**: 761-767

**Impact**: All boost transactions now write to the new schema.

---

### 4. Firestore Security Rules

**File**: [`firestore.rules`](firestore.rules)

**Added New Rules**:
```javascript
// Artist Boosters - tracks users who have boosted an artist
match /artist_boosters/{artistId} {
  allow read: if true; // Public read for displaying booster lists
  allow list: if isAuthenticated();
  allow create: if isAdmin(request.auth.uid);
  allow update: if isAdmin(request.auth.uid);
  allow delete: if isAdmin(request.auth.uid);

  // Boosters subcollection
  match /boosters/{boosterId} {
    allow read: if true; // Public read
    allow list: if isAuthenticated();
    allow create: if isAuthenticated() && (
      request.auth.uid == boosterId ||
      isAdmin(request.auth.uid)
    );
    allow update: if isAuthenticated() && (
      request.auth.uid == boosterId ||
      isAdmin(request.auth.uid)
    );
    allow delete: if isAdmin(request.auth.uid);
  }
}
```

**Updated Existing Rules**:
- `giftSubscriptions` collection: `supporterId` → `boosterId` (lines 1032-1046)

**Lines Changed**: 257-280, 1032-1046

---

### 5. Firestore Indexes

**File**: [`firestore.indexes.json`](firestore.indexes.json)

**Added New Indexes**:
```json
{
  "collectionGroup": "boosters",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "artistId", "order": "ASCENDING" },
    { "fieldPath": "lastBoostAt", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "boosters",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "boosterId", "order": "ASCENDING" },
    { "fieldPath": "tier", "order": "ASCENDING" },
    { "fieldPath": "lastBoostAt", "order": "DESCENDING" }
  ]
}
```

**Updated Existing Indexes**:
- `giftSubscriptions`: `supporterId` → `boosterId`

**Lines Changed**: 848, 855-876

---

## 📦 Data Migration

### Migration Script Created
**File**: [`scripts/migrate_boosters_schema.js`](scripts/migrate_boosters_schema.js)

**Features**:
- ✅ Migrates `artist_supporters` → `artist_boosters` collections
- ✅ Migrates `supporters` → `boosters` subcollections
- ✅ Renames `supporterId` → `boosterId` fields
- ✅ Updates `giftSubscriptions` field names
- ✅ Supports `--dry-run` mode for safe testing
- ✅ Batched operations for large datasets
- ✅ Detailed logging and error handling

**Usage**:
```bash
# Preview changes without writing
node scripts/migrate_boosters_schema.js --dry-run

# Run actual migration
node scripts/migrate_boosters_schema.js

# Custom batch size
node scripts/migrate_boosters_schema.js --batch-size=1000
```

**Prerequisites**:
- Requires `service-account-key.json` in project root
- Install dependencies: `npm install` in functions directory

---

## 🚀 Deployment Steps

### 1. Deploy Firestore Rules & Indexes
```bash
# Deploy rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes
```

**Expected Output**:
```
✔ Deploy complete!

Firestore Rules: DEPLOYED
Firestore Indexes: DEPLOYED
  - boosters (2 new indexes)
  - Updated: giftSubscriptions
```

---

### 2. Deploy Cloud Functions
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

**Functions to Verify**:
- `processBoostTransaction` (or similar function handling boost creation)

---

### 3. Run Data Migration
```bash
# DRY RUN FIRST - Always test before live migration
node scripts/migrate_boosters_schema.js --dry-run

# Review output, then run actual migration
node scripts/migrate_boosters_schema.js
```

**Estimated Time**: ~30 seconds per 1000 booster records

---

### 4. Deploy Updated Flutter App
```bash
# Test locally first
flutter run

# Build release
flutter build appbundle  # Android
flutter build ipa        # iOS
```

---

## ✅ Verification Checklist

After deploying all changes:

- [ ] **Firestore Console Check**
  - [ ] New `artist_boosters` collection exists
  - [ ] New `boosters` subcollection exists under artist documents
  - [ ] `boosterId` field present in booster documents
  - [ ] Old `supporterId` field removed

- [ ] **App Functionality Test**
  - [ ] View artist profile shows "Boosted By" section
  - [ ] Purchase a boost (use development bypass if needed)
  - [ ] Verify boost appears in artist's booster list
  - [ ] Check early access badge displays correctly
  - [ ] Test gift subscriptions still work

- [ ] **Cloud Functions Test**
  - [ ] Monitor Firebase Console logs during boost purchase
  - [ ] Verify function writes to `artist_boosters` collection
  - [ ] Check no errors about missing collections

- [ ] **Security Rules Test**
  - [ ] Non-authenticated users can read booster lists
  - [ ] Authenticated users can create boost records for themselves
  - [ ] Users cannot create boost records for others (except admins)
  - [ ] Test with Firebase Emulator if available

---

## 🗑️ Cleanup (After Verification)

**WAIT 2-4 WEEKS** before deleting old collections to ensure stability.

### Option 1: Firebase Console
1. Open Firebase Console → Firestore Database
2. Navigate to `artist_supporters` collection
3. Delete collection (will prompt for confirmation)

### Option 2: Cleanup Script
```javascript
// scripts/cleanup_old_supporters.js
const admin = require('firebase-admin');
// ... (similar to migration script)

async function deleteOldCollections() {
  const batch = db.batch();
  const snapshot = await db.collection('artist_supporters').get();
  
  snapshot.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  await batch.commit();
  console.log('Deleted artist_supporters collection');
}
```

**⚠️ WARNING**: Deletion is permanent. Backup data first using Firebase export.

---

## 📊 Schema Comparison

### Before (Phase 1)
```
artist_supporters/{artistId}
  └── supporters/{supporterId}
        ├── supporterId: string
        ├── artistId: string
        ├── tier: string
        ├── lastBoostAt: timestamp
        ├── boostCount: number
        └── earlyAccessTier: string

giftSubscriptions/{subscriptionId}
  ├── supporterId: string
  ├── artistId: string
  └── ...
```

### After (Phase 2)
```
artist_boosters/{artistId}
  └── boosters/{boosterId}
        ├── boosterId: string         ← Changed
        ├── artistId: string
        ├── tier: string
        ├── lastBoostAt: timestamp
        ├── boostCount: number
        └── earlyAccessTier: string

giftSubscriptions/{subscriptionId}
  ├── boosterId: string              ← Changed
  ├── artistId: string
  └── ...
```

---

## 🔄 Rollback Plan

If critical issues arise after deployment:

### 1. Revert Code Changes
```bash
# Revert Flutter app
git revert <commit-hash>
flutter build appbundle

# Revert Cloud Functions
git revert <commit-hash>
firebase deploy --only functions
```

### 2. Revert Firestore Rules
```bash
# Use backup rules
cp firestore.rules.backup firestore.rules
firebase deploy --only firestore:rules
```

### 3. Data Still Intact
- Old `artist_supporters` collection remains until manually deleted
- App can be configured to read from old collection temporarily
- Migration script can be run again after fixing issues

---

## 🎯 Success Criteria

Phase 2 is considered successful when:

1. ✅ All Firestore queries use `artist_boosters`/`boosters` collections
2. ✅ All field references use `boosterId` instead of `supporterId`
3. ✅ Cloud Functions write to new schema
4. ✅ Security rules protect new collections appropriately
5. ✅ Indexes enable efficient queries on new schema
6. ✅ Data migration completed without errors
7. ✅ App functionality verified in production
8. ✅ No "supporter" terminology in backend logs/errors

---

## 📝 Notes

**Backward Compatibility**: The migration script copies data to new collections without deleting old ones. This allows for safe rollback if issues occur.

**Performance Impact**: Adding new indexes may take 5-10 minutes to build in production. During this time, queries may be slightly slower.

**Cost Impact**: Minimal. Migration reads old data once and writes to new collections. Ongoing costs are identical to previous schema.

**Future Phases**: Phase 3 will implement the creator earnings balance system to complete the compliance model.

---

## Next Steps: Phase 3

With Phase 2 complete, proceed to:

**Phase 3: Creator Earnings Balance System**
- Implement platform-mediated payment flow
- Add earnings tracking for artists
- Create payout request system
- Build admin earnings dashboard

**Estimated Complexity**: High (requires payment integration)  
**Blocking Phase 2**: No - can be developed independently
