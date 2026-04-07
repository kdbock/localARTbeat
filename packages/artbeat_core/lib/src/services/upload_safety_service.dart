import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../utils/env_loader.dart';
import '../utils/logger.dart';

class UploadModerationDecision {
  final bool isAllowed;
  final String reason;
  final double? confidence;
  final Map<String, dynamic> raw;

  const UploadModerationDecision({
    required this.isAllowed,
    required this.reason,
    this.confidence,
    this.raw = const <String, dynamic>{},
  });
}

class UploadSafetyService {
  final EnvLoader _envLoader;
  final http.Client _client;

  UploadSafetyService({EnvLoader? envLoader, http.Client? client})
    : _envLoader = envLoader ?? EnvLoader(),
      _client = client ?? http.Client();

  Future<UploadModerationDecision> scanImageFile({
    required File imageFile,
    required String source,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!await imageFile.exists()) {
        return const UploadModerationDecision(
          isAllowed: false,
          reason: 'Image file is missing.',
        );
      }

      final endpoint = _resolveEndpoint();
      if (endpoint == null) {
        AppLogger.warning(
          'UploadSafetyService: moderation endpoint is not configured',
        );
        return const UploadModerationDecision(
          isAllowed: false,
          reason:
              'AI safety scanning is unavailable right now. Please try again later.',
        );
      }

      final bytes = await imageFile.readAsBytes();
      final payload = <String, dynamic>{
        'imageBase64': base64Encode(bytes),
        'source': source,
        'userId': userId,
        'filename': imageFile.uri.pathSegments.isNotEmpty
            ? imageFile.uri.pathSegments.last
            : null,
        'fileSize': bytes.length,
        'metadata': metadata ?? <String, dynamic>{},
      };

      final response = await _client
          .post(
            endpoint,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        AppLogger.warning(
          'UploadSafetyService: moderation endpoint failed '
          '(${response.statusCode})',
        );
        return const UploadModerationDecision(
          isAllowed: false,
          reason:
              'AI safety scanning is unavailable right now. Please try again later.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const UploadModerationDecision(
          isAllowed: false,
          reason: 'Unexpected moderation response.',
        );
      }

      final allowed = _extractAllowed(decoded);
      final reason = _extractReason(decoded, allowed);
      return UploadModerationDecision(
        isAllowed: allowed,
        reason: reason,
        confidence: _extractConfidence(decoded),
        raw: decoded,
      );
    } on TimeoutException {
      return const UploadModerationDecision(
        isAllowed: false,
        reason:
            'AI safety scanning timed out. Please retry when your connection is stable.',
      );
    } catch (e) {
      AppLogger.error('UploadSafetyService: scan failed: $e');
      return const UploadModerationDecision(
        isAllowed: false,
        reason: 'AI safety scanning failed. Please try again later.',
      );
    }
  }

  Uri? _resolveEndpoint() {
    final explicitEndpoint = _envLoader
        .get('UPLOAD_MODERATION_ENDPOINT')
        .trim();
    if (explicitEndpoint.isNotEmpty) {
      return Uri.tryParse(explicitEndpoint);
    }

    final endpointPath = _envLoader.get(
      'UPLOAD_MODERATION_ENDPOINT_PATH',
      defaultValue: '/moderateUploadImage',
    );

    if (_envLoader.has('FIREBASE_FUNCTIONS_BASE_URL')) {
      final baseUrl = _envLoader.cloudFunctionsBaseUrl;
      return Uri.tryParse('$baseUrl$endpointPath');
    }

    const baseFromDefines = String.fromEnvironment(
      'FIREBASE_FUNCTIONS_BASE_URL',
    );
    if (baseFromDefines.isNotEmpty) {
      final sanitizedBase = baseFromDefines.replaceFirst(RegExp(r'/+$'), '');
      return Uri.tryParse('$sanitizedBase$endpointPath');
    }

    return null;
  }

  bool _extractAllowed(Map<String, dynamic> response) {
    final boolCandidates = [
      response['isSafe'],
      response['safe'],
      response['isAppropriate'],
      response['approved'],
      response['allow'],
      response['allowed'],
    ];

    for (final value in boolCandidates) {
      if (value is bool) {
        return value;
      }
    }

    final status = response['status']?.toString().toLowerCase();
    if (status == 'approved' || status == 'safe' || status == 'pass') {
      return true;
    }
    if (status == 'rejected' || status == 'unsafe' || status == 'blocked') {
      return false;
    }

    final moderationStatus = response['moderationStatus']
        ?.toString()
        .toLowerCase();
    if (moderationStatus == 'approved' || moderationStatus == 'safe') {
      return true;
    }
    if (moderationStatus == 'rejected' ||
        moderationStatus == 'unsafe' ||
        moderationStatus == 'blocked') {
      return false;
    }

    // Fail closed when backend response does not declare a verdict.
    return false;
  }

  String _extractReason(Map<String, dynamic> response, bool allowed) {
    final reason = response['reason']?.toString().trim();
    if (reason != null && reason.isNotEmpty) return reason;

    final message = response['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;

    final classification = response['classification']?.toString().trim();
    if (classification != null && classification.isNotEmpty) {
      return classification;
    }

    return allowed
        ? 'Image passed AI safety scan.'
        : 'Image failed AI safety scan.';
  }

  double? _extractConfidence(Map<String, dynamic> response) {
    final value = response['confidence'] ?? response['score'];
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
