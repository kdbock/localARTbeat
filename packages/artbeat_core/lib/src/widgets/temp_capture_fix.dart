import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:provider/provider.dart';

/// Temporary widget to fix Izzy Piel's capture count issue
class TempCaptureCountFix extends StatefulWidget {
  const TempCaptureCountFix({super.key});

  @override
  State<TempCaptureCountFix> createState() => _TempCaptureCountFixState();
}

class _TempCaptureCountFixState extends State<TempCaptureCountFix> {
  late final UserMaintenanceService _userMaintenanceService;
  bool _isFixing = false;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _userMaintenanceService = context.read<UserMaintenanceService>();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "capture_fix_fab",
      onPressed: _isFixing ? null : _fixCaptureCount,
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      label: _isFixing ? const Text('Fixing...') : const Text('Fix Izzy Count'),
      icon: _isFixing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.build),
    );
  }

  Future<void> _fixCaptureCount() async {
    setState(() {
      _isFixing = true;
      _result = '';
    });

    try {
      const userId = 'EdH8MvWk4Ja6eoSZM59QtOaxEK43';
      AppLogger.info('🔧 Fixing capture count for Izzy Piel: $userId');

      final success = await _userMaintenanceService.recalculateUserCaptureCount(
        userId,
      );

      setState(() {
        _result = success
            ? 'SUCCESS: Fixed Izzy\'s capture count!'
            : 'FAILED: Could not fix capture count';
      });

      AppLogger.info(_result);

      // Show result in snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_result),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      final errorMsg = 'ERROR: $e';
      setState(() {
        _result = errorMsg;
      });
      AppLogger.error('❌ Error fixing capture count: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isFixing = false;
      });
    }
  }
}
