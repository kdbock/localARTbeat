import 'package:artbeat_core/artbeat_core.dart';

enum GoNowStatus { idle, enRoute, arrived, captured, skipped }

class GoNowSession {
  final String pieceId;
  final GoNowStatus status;
  final DateTime updatedAt;

  const GoNowSession({
    required this.pieceId,
    required this.status,
    required this.updatedAt,
  });
}

/// Keeps lightweight in-memory state for "Go Now" continuity and funnel logs.
class GoNowFlowService {
  static final GoNowFlowService _instance = GoNowFlowService._internal();
  factory GoNowFlowService() => _instance;
  GoNowFlowService._internal();

  final Map<String, GoNowSession> _sessions = <String, GoNowSession>{};

  GoNowStatus statusFor(String pieceId) {
    final session = _sessions[pieceId];
    return session?.status ?? GoNowStatus.idle;
  }

  void setStatus(String pieceId, GoNowStatus status) {
    _sessions[pieceId] = GoNowSession(
      pieceId: pieceId,
      status: status,
      updatedAt: DateTime.now(),
    );
  }

  void trackFunnelEvent(String eventName, Map<String, Object?> metadata) {
    AppLogger.info('GoNowFunnel::$eventName::$metadata');
  }
}
