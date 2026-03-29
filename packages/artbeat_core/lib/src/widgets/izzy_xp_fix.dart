import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:provider/provider.dart';

/// Fix XP points for Izzy Piel specifically
class IzzyXPFix extends StatefulWidget {
  const IzzyXPFix({Key? key}) : super(key: key);

  @override
  State<IzzyXPFix> createState() => _IzzyXPFixState();
}

class _IzzyXPFixState extends State<IzzyXPFix> {
  bool _isFixing = false;
  String _status = '';
  late final UserMaintenanceService _userMaintenanceService;

  @override
  void initState() {
    super.initState();
    _userMaintenanceService = context.read<UserMaintenanceService>();
  }

  Future<void> _fixIzzyXP() async {
    if (_isFixing) return;

    setState(() {
      _isFixing = true;
      _status = 'Starting Izzy XP fix...';
    });

    try {
      const izzyId = 'EdH8MvWk4Ja6eoSZM59QtOaxEK43';
      setState(
        () => _status = 'Repairing Izzy\'s XP from approved captures...',
      );

      final result = await _userMaintenanceService
          .repairUserXpFromApprovedCaptures(izzyId);

      if (result == null) {
        setState(() {
          _status = '❌ Could not find Izzy\'s user document';
          _isFixing = false;
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        _status = result.wasUpdated
            ? '✅ Izzy XP Fix Complete!\n'
                  'Approved captures: ${result.actualApprovedCaptures}\n'
                  'Stored count: ${result.storedCapturesCount}\n'
                  'XP: ${result.previousXp} → ${result.updatedXp}\n'
                  'Level: ${result.previousLevel} → ${result.updatedLevel}\n'
                  'XP gained: ${result.updatedXp - result.previousXp}'
            : '✅ Izzy\'s XP is already correct!\n'
                  'Approved captures: ${result.actualApprovedCaptures}\n'
                  'Stored count: ${result.storedCapturesCount}\n'
                  'Current XP: ${result.previousXp}\n'
                  'Expected XP: ${result.updatedXp}';
        _isFixing = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error fixing Izzy XP: $e';
        _isFixing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "izzy_xp_fix_fab",
      onPressed: _isFixing ? null : _fixIzzyXP,
      backgroundColor: _isFixing ? Colors.grey : Colors.blue,
      foregroundColor: Colors.white,
      label: Text(_isFixing ? 'Fixing Izzy...' : 'Fix Izzy XP'),
      icon: _isFixing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.person_pin),
      tooltip: _status.isEmpty ? 'Fix Izzy Piel\'s XP points' : _status,
    );
  }
}
