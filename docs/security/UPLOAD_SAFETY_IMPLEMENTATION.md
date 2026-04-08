# Upload Safety & AI Image Moderation — Implementation Guide

**Status:** ✅ Ready for deployment (March 29, 2026)

## Overview

This document describes the complete end-to-end implementation of AI-powered image moderation for all user uploads in ARTbeat. The system uses Google Cloud Vision API to detect unsafe content (adult, violent, medical, spoofed images) and blocks uploads that fail safety checks.

## Architecture

```
User Uploads Image
       ↓
[App Side] UploadSafetyService.scanImageFile()
       ↓
Base64 encode image → HTTP POST to moderateUploadImage endpoint
       ↓
[Cloud Functions] moderateUploadImage handler
       ↓
Call Google Cloud Vision API safeSearchDetection
       ↓
Evaluate scores against safety threshold
       ↓
Return verdict (approved/rejected with reason)
       ↓
[App Side] Check result → Allow upload OR show error
       ↓
Log decision to Firestore moderation_logs collection
```

## Components Implemented

### 1. App-Side Safety Gate (Dart/Flutter)

**File:** `packages/artbeat_core/lib/src/services/upload_safety_service.dart`

**Class:** `UploadSafetyService`

**Public API:**

```dart
Future<UploadModerationDecision> scanImageFile({
  required File imageFile,
  required String source,
  String? userId,
  Map<String, dynamic>? metadata,
})
```

**Decision Class:** `UploadModerationDecision`
- `isAllowed`: bool (true = safe to upload)
- `reason`: String (explanation if blocked)
- `confidence`: double? (0-1 confidence score)
- `raw`: Map (raw API response for debugging)

**Integration Points:**

All image uploads now call the safety service before publishing:

1. **Capture uploads** (`packages/artbeat_capture/lib/src/services/storage_service.dart`)
   - `uploadCaptureImage()` → calls `_enforceUploadSafety()`

2. **Community image uploads** (`packages/artbeat_community/lib/services/firebase_storage_service.dart`)
   - `uploadImage()` → calls `_enforceSafeImageUpload()`
   - `uploadImages()` → calls `_enforceSafeImageUpload()` per image
   - `uploadImageWithProgress()` → calls `_enforceSafeImageUpload()`

3. **ARTflex selfies** (`packages/artbeat_capture/lib/src/screens/capture_view_screen.dart`)
   - `_captureAndPostArtFlex()` → calls `_uploadSafetyService.scanImageFile()`

4. **Art Walk covers** (`packages/artbeat_art_walk/lib/src/services/art_walk_service.dart`)
   - `_uploadCoverImage()` → calls `_uploadSafetyService.scanImageFile()`
   - `uploadPublicArtImage()` → calls `_uploadSafetyService.scanImageFile()`

**Behavior:**

- If endpoint is not configured: **Fail closed** (block upload)
- If endpoint is unavailable: **Fail closed** (block upload)
- If image fails safety check: **Block upload** with user-friendly error
- If image passes: **Allow upload to proceed**

### 2. Cloud Function — Image Moderation Endpoint

**File:** `functions/src/moderateUploadImage.js`

**Export:** `exports.moderateUploadImage`

**Framework:** Firebase Cloud Functions v2 (Node.js)

**Vision API:** Google Cloud Vision `safeSearchDetection`

**Request Format:**

```json
{
  "imageBase64": "base64-encoded-image",
  "source": "capture_upload|artflex_selfie|community_post_upload|art_walk_cover|public_art_upload",
  "userId": "firebase-user-id",
  "filename": "original-filename.jpg",
  "fileSize": 1024000,
  "metadata": {}
}
```

**Response Format:**

```json
{
  "status": "success|error",
  "approved": true/false,
  "isSafe": true/false,
  "safe": true/false,
  "reason": "Explanation if blocked",
  "confidence": 0.85,
  "scores": {
    "adult": 0,
    "violence": 1,
    "medical": 0,
    "racy": 2,
    "spoof": 0
  },
  "source": "capture_upload",
  "timestamp": "2026-03-29T18:00:00.000Z"
}
```

**Safety Thresholds:**

Vision API returns likelihood values:
- UNKNOWN (0)
- VERY_UNLIKELY (1)
- UNLIKELY (2)
- POSSIBLE (3) ← Current threshold
- LIKELY (4) ← Block
- VERY_LIKELY (5) ← Block

**Categories Checked:**

1. **Adult:** Sexually explicit content (scores 0-5)
2. **Violence:** Graphic violence or injury (scores 0-5)
3. **Medical:** Graphic medical procedures (scores 0-5)
4. **Racy:** Sexually suggestive content (scores 0-5)
5. **Spoof:** Doctored/fake images (scores 0-5)

**Logging:**

Every decision is logged to Firestore for audit trail and monitoring:

- **Success:** `moderation_logs` collection
  - Fields: userId, source, filename, fileSize, approved, reason, scores, timestamp
- **Error:** `moderation_errors` collection
  - Fields: error message, stack trace, request body, timestamp

### 3. Artist-Only Direct Posting Enforcement

Direct posting to the community feed is now restricted to artist accounts only:

**Files Updated:**

- `packages/artbeat_community/lib/screens/create_art_post_screen.dart`
- `packages/artbeat_community/lib/screens/feed/create_post_screen.dart`
- `packages/artbeat_community/lib/screens/create_art_post_screen.dart`

**Behavior:**

If a non-artist user attempts to create a direct post, they receive:

> "Direct posting is available for artist accounts. Use Art Walk and ARTflex moments to auto-share your activity."

Non-artists can still share to the feed through:
- Auto-generated activity posts (walk completion, capture discovery)
- Auto-share on Art Walk creation
- ARTflex selfie moments (with moderation scan)

### 4. Branding Consistency — ARTflex Capitalization

All user-facing copy updated to capitalize "ART" in branded terms:

**Changes:**

- "ArtFlex Shot" → **"ARTflex Shot"**
- "ArtFlex moments" → **"ARTflex moments"**
- "ArtFlex posted to community feed" → **"ARTflex posted to community feed"**

**Files Updated:**

- `packages/artbeat_capture/lib/src/screens/capture_view_screen.dart`
- `packages/artbeat_community/lib/screens/unified_community_hub.dart`
- `packages/artbeat_community/lib/screens/art_community_hub.dart`
- `packages/artbeat_community/lib/screens/create_art_post_screen.dart`

## Deployment Steps

### Step 1: Install Cloud Function Dependencies

```bash
cd functions
npm install
```

This installs the new `@google-cloud/vision` dependency added to `package.json`.

### Step 2: Deploy the Cloud Function

```bash
firebase deploy --only functions:moderateUploadImage
```

**Expected output:**
```
✔  functions[us-central1-moderateUploadImage]: Successful create/update operations (1)
```

### Step 3: Verify Deployment

```bash
firebase functions:list | grep moderateUploadImage
```

Or test directly:

```bash
curl -X POST \
  https://us-central1-wordnerd-artbeat.cloudfunctions.net/moderateUploadImage \
  -H "Content-Type: application/json" \
  -d '{
    "imageBase64": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
    "source": "test",
    "userId": "test-user"
  }'
```

Should return:

```json
{
  "status": "success",
  "approved": true,
  "isSafe": true,
  "safe": true,
  "reason": "Image passed AI safety scan",
  "confidence": 0,
  "scores": {
    "adult": 0,
    "medical": 0,
    "spoof": 0,
    "violence": 0,
    "racy": 0
  },
  "source": "test",
  "timestamp": "2026-03-29T18:00:00.000Z"
}
```

### Step 4: Environment Configuration

**Option A: Auto-resolve (Recommended)**

The app will automatically resolve to:
```
{FIREBASE_FUNCTIONS_BASE_URL}/moderateUploadImage
```

No explicit configuration needed. Just ensure `FIREBASE_FUNCTIONS_BASE_URL` is set in your `.env` (usually already configured).

**Option B: Explicit Configuration**

If you need to override the endpoint, set in `.env`:

```bash
UPLOAD_MODERATION_ENDPOINT=https://us-central1-wordnerd-artbeat.cloudfunctions.net/moderateUploadImage
```

### Step 5: Test in App

1. Rebuild Flutter app:
   ```bash
   flutter clean && flutter pub get
   flutter run
   ```

2. Test capture upload:
   - Open camera
   - Take a photo
   - Submit → Should scan image before publishing
   
3. Test community post:
   - If artist: Try posting with image → Should scan
   - If non-artist: Try direct post → Should show "artist accounts only" message

4. Check Firestore:
   - Collections → `moderation_logs` → Should see audit trail

## Failure Scenarios & Recovery

### Scenario 1: Endpoint Unavailable

**What happens:**
- App shows: "AI safety scanning is unavailable. Please try again later."
- Upload is blocked

**Recovery:**
1. Deploy the function (see Step 2 above)
2. User can retry the upload

### Scenario 2: Image Too Large

**What happens:**
- App shows: "Image is too large. Please provide an image under 20MB."
- Request rejected

**Recovery:**
- User compresses the image and retries

### Scenario 3: Vision API Rate Limit

**What happens:**
- Function returns HTTP 500 with appropriate error message
- App shows: "AI safety scanning failed. Please try again later."

**Recovery:**
- Implemented in Firebase quotas/billing
- Auto-scales with demand
- Can increase quota in Google Cloud Console if needed

### Scenario 4: Firestore Logging Fails

**What happens:**
- Moderation decision is still returned to app
- Logging failure is logged to Firebase Functions logs (non-blocking)
- Upload proceeds normally

**Recovery:**
- Logging is non-blocking; does not prevent uploads
- Retry logs are handled by Firestore backoff logic

## Monitoring & Analytics

### View Moderation Logs

In Firebase Console:

1. Go to Firestore Database
2. Collection → `moderation_logs`
3. Filter by fields:
   - `approved`: true/false
   - `source`: capture_upload, artflex_selfie, etc.
   - `timestamp`: date range

**Example Query (Firestore SDK):**

```dart
final db = FirebaseFirestore.instance;
final logs = await db
    .collection('moderation_logs')
    .where('approved', isEqualTo: false)
    .orderBy('timestamp', descending: true)
    .limit(10)
    .get();
```

### View Function Logs

```bash
firebase functions:log --region us-central1 | grep moderateUploadImage
```

### Metrics to Monitor

1. **Upload Success Rate:** % of uploads that pass safety scan
2. **False Positive Rate:** Safe images incorrectly blocked (unlikely with Vision API)
3. **Content Type Distribution:** What categories are blocked most often
4. **Geographic Patterns:** Are certain regions seeing more blocks
5. **Cost:** Vision API charges per detection call

## Cost Analysis

**Google Cloud Vision API:**
- Safe Search Detection: ~$2.00 per 1,000 API calls
- Estimate at 10,000 uploads/month: ~$20/month
- Firebase Cloud Functions: included with Firebase Spark plan

**Total Estimated Cost:** $20-50/month depending on upload volume

## Next Steps (Optional)

### 1. Enhanced Moderation (Future)

Current implementation uses Vision API for generic safety. Future enhancements:

- Custom ML model trained on ARTbeat content norms
- Real-time false positive feedback loop
- Artist community moderation for edge cases
- Severity scoring (must-block vs. flag-for-review)

### 2. User Appeal Flow

When content is blocked, allow users to:
- Request manual review by support
- Provide context/justification
- Submit appeal with explanation

### 3. Moderation Dashboard

Admin panel to:
- View blocked uploads
- Manually approve or confirm blocks
- Adjust safety thresholds per category
- Review appeal requests
- Export moderation reports

### 4. Regional Sensitivity

Some content norms vary by region; future could support:
- Region-specific safety thresholds
- Language/cultural context awareness
- Localized messaging for users

## Troubleshooting

### "Moderation endpoint is not configured"

**Cause:** `FIREBASE_FUNCTIONS_BASE_URL` is missing or invalid

**Fix:**
```bash
# In .env file:
FIREBASE_FUNCTIONS_BASE_URL=https://us-central1-wordnerd-artbeat.cloudfunctions.net
```

Then rebuild app.

### "Image is too large (>20MB)"

**Cause:** User selected image larger than Vision API limit

**Fix:**
- Recommend image compression in app docs
- Consider pre-compression in upload handler

### "AI safety scanning failed" (persistent)

**Cause:** Cloud Function is failing or not deployed

**Fix:**
```bash
# Check deployment
firebase deploy --only functions:moderateUploadImage

# Check logs
firebase functions:log | grep moderateUploadImage

# Check Vision API is enabled
gcloud services enable vision.googleapis.com --project=wordnerd-artbeat
```

### Firestore moderation_logs Collection Not Created

**Cause:** Normal — Firestore creates collections on first write

**Fix:**
- Just upload an image; first write will create collection
- Or manually create in Firebase Console

### High False Positive Rate

**Example:** Safe art photos being blocked

**Fix:**
1. Review the scores in `moderation_logs` for blocked images
2. Analyze if Vision API is over-detecting for your use case
3. Adjust threshold in `moderateUploadImage.js`:
   ```javascript
   const threshold = 3; // Change to 4 if too conservative
   ```
4. Redeploy function

## References

- **Vision API Docs:** https://cloud.google.com/vision/docs/detecting-safe-search
- **Likelihood Value Reference:** https://cloud.google.com/vision/docs/reference/rest/v1/safe-search
- **App Implementation:** `packages/artbeat_core/lib/src/services/upload_safety_service.dart`
- **Cloud Function:** `functions/src/moderateUploadImage.js`
- **API Documentation:** `functions/MODERATION_API.md`
- **UX Recommendations:** `docs/UX_RECOMMENDATIONS_2026-03-29.md`

---

**Status:** ✅ Implementation complete and ready for production deployment

**Last Updated:** March 29, 2026

**Implemented by:** AI Code Assistant (Claude Haiku 4.5)
