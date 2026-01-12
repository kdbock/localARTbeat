import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/device_utils.dart';

/// A wrapper around BackdropFilter that safely handles simulator rendering issues
/// by disabling the blur on simulators if Impeller is causing crashes.
class SafeBackdropFilter extends StatelessWidget {
  final ImageFilter filter;
  final Widget child;
  final BlendMode blendMode;

  const SafeBackdropFilter({
    super.key,
    required this.filter,
    required this.child,
    this.blendMode = BlendMode.srcOver,
  });

  @override
  Widget build(BuildContext context) {
    if (DeviceUtils.isSimulator) {
      return child;
    }
    return BackdropFilter(
      filter: filter,
      blendMode: blendMode,
      child: child,
    );
  }
}
