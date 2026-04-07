# Upload Image Moderation Endpoint

## Overview

The `moderateUploadImage` Cloud Function provides AI-powered content moderation for user-uploaded images. It uses Google Cloud Vision API's Safe Search Detection to identify and block potentially unsafe content including adult, violent, medical, or spoofed images.

## Endpoint

```
POST /moderateUploadImage
```

**Base URL:** (Auto-deployed to Firebase Cloud Functions)
```
https://{REGION}-{PROJECT_ID}.cloudfunctions.net/moderateUploadImage
```

**Region:** us-central1 (or configured region in `functions/` setup)

**Project ID:** wordnerd-artbeat

## Request

### Headers
```
Content-Type: application/json
```

### Body

```json
{
  "imageBase64": "base64-encoded-image-data",
  "source": "capture_upload|artflex_selfie|community_post_upload|art_walk_cover|public_art_upload",
  "userId": "firebase-user-id",
  "filename": "optional-filename.jpg",
  "fileSize": 1024000,
  "metadata": {
    "optional": "metadata fields"
  }
}
```

**Required Fields:**
- `imageBase64`: Base64-encoded image data (raw binary, not data URI)

**Optional Fields:**
- `source`: Source identifier for logging/tracking (helps categorize moderation decisions)
- `userId`: Firebase user ID (for audit logging)
- `filename`: Original filename for logging
- `fileSize`: File size in bytes for logging
- `metadata`: Additional context (e.g., `{captureId, walkId, postId}`)

### Constraints

- **Max image size:** 20 MB (Vision API limit)
- **Supported formats:** JPEG, PNG, GIF, BMP, WebP
- **Base64 encoding:** Standard base64, not data URI format

## Response

### Success Response (HTTP 200)

```json
{
  "status": "success",
  "approved": true,
  "isSafe": true,
  "safe": true,
  "reason": "Image passed AI safety scan",
  "confidence": 0.85,
  "scores": {
    "adult": 0,
    "medical": 0,
    "spoof": 0,
    "violence": 0,
    "racy": 1
  },
  "source": "capture_upload",
  "timestamp": "2026-03-29T18:30:00.000Z"
}
```

**Response Fields:**

- `status`: Always "success" or "error"
- `approved` / `isSafe` / `safe`: Boolean verdict (all three for compatibility)
  - `true` = Image is safe to publish
  - `false` = Image contains unsafe content and should be blocked
- `reason`: Human-readable explanation if blocked
- `confidence`: Confidence score (0-1) based on highest unsafe category score
- `scores`: Individual scores for each content category (0-5 scale)
  - 0-2 = Safe (UNKNOWN, VERY_UNLIKELY, UNLIKELY)
  - 3 = Questionable (POSSIBLE) — currently allowed
  - 4-5 = Unsafe (LIKELY, VERY_LIKELY) — blocked
- `source`: Echo of request source for logging
- `timestamp`: ISO 8601 timestamp of check

### Error Response (HTTP 4xx or 5xx)

```json
{
  "status": "error",
  "message": "User-friendly error message",
  "error": "Technical error details"
}
```

**Common HTTP Status Codes:**

- `400 Bad Request`: Missing imageBase64, invalid base64 encoding, or image too large
- `405 Method Not Allowed`: Request method is not POST
- `500 Internal Server Error`: Vision API call failed or internal error

## Safety Behavior

### Fail-Closed Policy

If the moderation endpoint is unavailable or returns an error, the app will **block the upload** and show the user:

> "AI safety scanning is temporarily unavailable. Please try again later."

This is intentional to prevent unsafe content from being published when the safety gate cannot be verified.

### Categories Checked

The function evaluates five content safety categories using Vision API's `safeSearchDetection`:

1. **Adult** — Sexually explicit or adult-only content
2. **Violence** — Content depicting violence or injury
3. **Medical** — Graphic medical procedures or injuries
4. **Racy** — Sexually suggestive but not explicit content
5. **Spoof** — Fake, spoofed, or doctored images

### Threshold

- **Threshold:** POSSIBLE (score 3)
- **Block if:** Any category is LIKELY or VERY_LIKELY (score 4-5)
- **Allow if:** All categories are UNLIKELY or below (score 0-3)

## Integration Points

The app calls this endpoint from `UploadSafetyService` before:

1. **Capture uploads** — art photos captured from discovery/art walk
2. **ARTFlex selfies** — selfies with artwork
3. **Community post images** — images posted directly to feed
4. **Art Walk cover images** — walk creation/edit cover photos
5. **Public art images** — manually curated art submissions

## Logging

All moderation decisions are logged to Firestore:

- **Collection:** `moderation_logs`
- **Fields:** userId, source, filename, fileSize, approved, reason, scores, timestamp

Errors are logged to:

- **Collection:** `moderation_errors`
- **Fields:** error message, stack trace, body, timestamp

## Deployment

1. **Install dependencies:**
   ```bash
   cd functions
   npm install
   ```

2. **Deploy function:**
   ```bash
   firebase deploy --only functions:moderateUploadImage
   ```

3. **Verify deployment:**
   ```bash
   firebase functions:list | grep moderateUploadImage
   ```

4. **View logs:**
   ```bash
   firebase functions:log --region us-central1
   ```

## Environment Setup

The function uses Google Cloud Vision API, which is automatically enabled for Firebase projects. No additional setup is required beyond standard Firebase deployment permissions.

**Required IAM roles:**
- `roles/cloudfunctions.developer` (for deployment)
- `roles/vision.admin` (auto-granted by Firebase)

## Testing

### Example Request

```bash
curl -X POST \
  https://us-central1-wordnerd-artbeat.cloudfunctions.net/moderateUploadImage \
  -H "Content-Type: application/json" \
  -d '{
    "imageBase64": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
    "source": "test_upload",
    "userId": "test-user-123"
  }'
```

### Example Response

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
  "source": "test_upload",
  "timestamp": "2026-03-29T18:35:22.345Z"
}
```

## Costs

Google Cloud Vision API pricing:
- **Safe Search Detection:** ~$2.00 per 1,000 requests
- **Estimate:** At 10k uploads/month = ~$20/month

## References

- [Google Cloud Vision Safe Search Detection](https://cloud.google.com/vision/docs/detecting-safe-search)
- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [App Implementation: UploadSafetyService](../../packages/artbeat_core/lib/src/services/upload_safety_service.dart)
