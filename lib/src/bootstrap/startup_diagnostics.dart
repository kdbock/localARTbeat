import 'dart:async';
import 'dart:developer' as developer;

import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

const bool enableVerboseRebuildLogging =
    // ignore: do_not_use_environment
    bool.fromEnvironment('VERBOSE_REBUILDS');
const bool forceMinimalRenderApp =
    // ignore: do_not_use_environment
    bool.fromEnvironment('FORCE_MINIMAL_APP');
const Duration _slowFrameThreshold = Duration(milliseconds: 32);
const Duration _slowTapThreshold = Duration(milliseconds: 120);

bool _performanceDiagnosticsInstalled = false;
bool _tapFrameCallbackScheduled = false;
final List<_PendingTapTrace> _pendingTapTraces = [];
Timer? _imageCacheStatsTimer;

void installStartupDiagnostics() {
  _installPerformanceDiagnostics();
  _enableDebugBuildFlags(enableVerboseRebuildLogging);
}

void _installPerformanceDiagnostics() {
  if (_performanceDiagnosticsInstalled || kReleaseMode) return;
  _performanceDiagnosticsInstalled = true;

  WidgetsBinding.instance.addTimingsCallback(_handleFrameTimings);
  GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  _imageCacheStatsTimer?.cancel();
  _imageCacheStatsTimer = Timer.periodic(
    const Duration(seconds: 30),
    (_) => ImageManagementService().logCacheStats(label: 'periodic'),
  );
  Timer(
    const Duration(seconds: 6),
    () => ImageManagementService().logCacheStats(label: 'startup'),
  );
}

void _enableDebugBuildFlags(bool enableVerboseRebuilds) {
  if (!kDebugMode) return;
  debugProfileBuildsEnabled = true;
  debugProfilePaintsEnabled = true;
  debugPrintRebuildDirtyWidgets = enableVerboseRebuilds;
  developer.Timeline.instantSync(
    'DebugFlags.Enabled',
    arguments: {
      'profileBuilds': debugProfileBuildsEnabled,
      'profilePaints': debugProfilePaintsEnabled,
      'printRebuilds': debugPrintRebuildDirtyWidgets,
    },
  );
  AppLogger.info(
    '⚙️ Debug build profiling enabled: '
    'builds=$debugProfileBuildsEnabled paints=$debugProfilePaintsEnabled '
    'rebuilds=$debugPrintRebuildDirtyWidgets (verbose=$enableVerboseRebuilds)',
  );
}

void _handleFrameTimings(List<FrameTiming> timings) {
  for (final timing in timings) {
    final total = timing.totalSpan;
    if (total <= _slowFrameThreshold) {
      continue;
    }
    developer.Timeline.instantSync(
      'UI.SlowFrame',
      arguments: {
        'totalMs': total.inMilliseconds,
        'buildMs': timing.buildDuration.inMilliseconds,
        'rasterMs': timing.rasterDuration.inMilliseconds,
      },
    );
    AppLogger.warning(
      '⚠️ Slow frame: total=${total.inMilliseconds}ms '
      'build=${timing.buildDuration.inMilliseconds}ms '
      'raster=${timing.rasterDuration.inMilliseconds}ms',
    );
  }
}

void _handlePointerEvent(PointerEvent event) {
  if (event is! PointerDownEvent) return;
  final task = developer.TimelineTask()
    ..start(
      'UI.TapToFrame',
      arguments: {
        'kind': event.kind.toString(),
        'x': event.position.dx.round(),
        'y': event.position.dy.round(),
      },
    );
  final trace = _PendingTapTrace(task);
  _pendingTapTraces.add(trace);

  if (_tapFrameCallbackScheduled) {
    return;
  }
  _tapFrameCallbackScheduled = true;
  SchedulerBinding.instance.addPostFrameCallback((_) {
    _tapFrameCallbackScheduled = false;
    for (final pending in _pendingTapTraces) {
      pending.finish();
    }
    _pendingTapTraces.clear();
  });
}

class _PendingTapTrace {
  _PendingTapTrace(this.task) : stopwatch = Stopwatch()..start();

  final developer.TimelineTask task;
  final Stopwatch stopwatch;

  void finish() {
    stopwatch.stop();
    task.finish();
    if (stopwatch.elapsed >= _slowTapThreshold) {
      developer.Timeline.instantSync(
        'UI.SlowTap',
        arguments: {'tapToFrameMs': stopwatch.elapsedMilliseconds},
      );
      AppLogger.warning(
        '⚠️ Slow tap-to-frame: ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }
}
