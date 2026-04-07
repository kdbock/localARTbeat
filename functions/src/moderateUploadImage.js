const {onRequest} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");
const vision = require("@google-cloud/vision");
const cors = require("cors")({origin: true});

// Create Vision API client
const visionClient = new vision.ImageAnnotatorClient();

/**
 * Moderate an uploaded image for unsafe content using Google Cloud Vision API.
 *
 * Checks for:
 * - Adult content (SPOOF, ADULT, MEDICAL, VIOLENT)
 * - Explicit or obscene material
 *
 * Request body should contain:
 * {
 *   "imageBase64": "base64-encoded image data",
 *   "source": "capture_upload|artflex_selfie|community_post_upload|art_walk_cover|etc",
 *   "userId": "firebase-user-id",
 *   "filename": "original-filename",
 *   "fileSize": number,
 *   "metadata": {}
 * }
 */
exports.moderateUploadImage = onRequest((request, response) => {
  cors(request, response, async () => {
    // Only allow POST requests
    if (request.method !== "POST") {
      logger.warn("Invalid method for moderateUploadImage:", request.method);
      return response.status(405).json({
        status: "error",
        message: "Method Not Allowed. Use POST.",
      });
    }

    try {
      const {imageBase64, source, userId, filename, fileSize, metadata} =
        request.body;

      // Validate required fields
      if (!imageBase64) {
        logger.warn("moderateUploadImage: Missing imageBase64");
        return response.status(400).json({
          status: "error",
          message: "Missing required field: imageBase64",
        });
      }

      // Decode base64 image
      let imageBuffer;
      try {
        imageBuffer = Buffer.from(imageBase64, "base64");
      } catch (e) {
        logger.warn("moderateUploadImage: Invalid base64 encoding", e.message);
        return response.status(400).json({
          status: "error",
          message: "Invalid base64 image encoding",
        });
      }

      // Check image size (keep under 20MB for Vision API)
      if (imageBuffer.length > 20 * 1024 * 1024) {
        logger.warn(
          "moderateUploadImage: Image too large",
          imageBuffer.length,
        );
        return response.status(400).json({
          status: "error",
          message: "Image is too large (>20MB)",
        });
      }

      // Call Google Cloud Vision API for safe search detection
      logger.info("moderateUploadImage: Performing safe search detection", {
        source,
        userId,
        filename,
        size: imageBuffer.length,
      });

      const safeSearchDetectionRequest = {
        image: {content: imageBuffer},
      };

      const detectionResult = await visionClient.safeSearchDetection(
        safeSearchDetectionRequest,
      );
      const safeSearchAnnotations =
        detectionResult[0].safeSearchAnnotation || {};

      logger.info("moderateUploadImage: Safe search result", {
        adult: safeSearchAnnotations.adult,
        medical: safeSearchAnnotations.medical,
        spoof: safeSearchAnnotations.spoof,
        violence: safeSearchAnnotations.violence,
        racy: safeSearchAnnotations.racy,
      });

      // Map likelihood values to scores
      const likelihoods = {
        UNKNOWN: 0,
        VERY_UNLIKELY: 1,
        UNLIKELY: 2,
        POSSIBLE: 3,
        LIKELY: 4,
        VERY_LIKELY: 5,
      };

      const scores = {
        adult: likelihoods[safeSearchAnnotations.adult] || 0,
        medical: likelihoods[safeSearchAnnotations.medical] || 0,
        spoof: likelihoods[safeSearchAnnotations.spoof] || 0,
        violence: likelihoods[safeSearchAnnotations.violence] || 0,
        racy: likelihoods[safeSearchAnnotations.racy] || 0,
      };

      // Fail if any category is HIGH confidence (LIKELY or VERY_LIKELY = 4 or 5)
      const threshold = 3; // POSSIBLE = 3. Block LIKELY+ (4+)
      const isSafe =
        scores.adult <= threshold &&
        scores.violence <= threshold &&
        scores.racy <= threshold &&
        scores.medical <= threshold &&
        scores.spoof <= threshold;

      // Determine reason if unsafe
      let reason = "";
      if (!isSafe) {
        const unsafe = [];
        if (scores.adult > threshold) unsafe.push("adult content");
        if (scores.violence > threshold) unsafe.push("violent content");
        if (scores.racy > threshold) unsafe.push("inappropriate content");
        if (scores.medical > threshold) unsafe.push("medical content");
        if (scores.spoof > threshold) unsafe.push("potentially fake/spoofed");
        reason = `Image contains: ${unsafe.join(", ")}`;
      }

      // Log the moderation decision
      await logModerationDecision({
        userId,
        source,
        filename,
        fileSize,
        approved: isSafe,
        reason,
        scores,
        safeSearchAnnotations,
        metadata,
      });

      // Return verdict
      return response.status(200).json({
        status: "success",
        approved: isSafe,
        isSafe,
        safe: isSafe,
        reason: isSafe ?
          "Image passed AI safety scan" :
          reason ||
            "Image failed safety check due to potentially unsafe content",
        confidence: Math.max(...Object.values(scores)) / 5, // Normalize to 0-1
        scores,
        source,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error("moderateUploadImage: Error during moderation", error);

      // Log the error for debugging
      await logModerationError({
        error: error.message,
        stack: error.stack,
        body: request.body,
      });

      // Return error response (fail closed)
      return response.status(500).json({
        status: "error",
        message:
          "AI safety scanning is temporarily unavailable. Please try again later.",
        error: error.message,
      });
    }
  });
});

/**
 * Log moderation decision to Firestore for audit trail and monitoring.
 */
async function logModerationDecision(data) {
  try {
    const firestore = admin.firestore();
    await firestore.collection("moderation_logs").add({
      ...data,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      type: "upload_image_scan",
    });

    logger.info("Moderation decision logged", {
      userId: data.userId,
      approved: data.approved,
    });
  } catch (error) {
    logger.error("Failed to log moderation decision", error);
    // Don't throw - logging failure shouldn't block the response
  }
}

/**
 * Log moderation errors to Firestore for debugging.
 */
async function logModerationError(data) {
  try {
    const firestore = admin.firestore();
    await firestore.collection("moderation_errors").add({
      ...data,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    logger.error("Failed to log moderation error", error);
  }
}
