import 'package:flutter/material.dart';
import 'dart:async';

class NavigationOverlay extends StatefulWidget {
  final Widget child;

  const NavigationOverlay({super.key, required this.child});

  static _NavigationOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<_NavigationOverlayState>();
  }

  static NavigatorObserver createObserver(BuildContext context) {
    return _NavigationOverlayObserver(of(context));
  }

  @override
  State<NavigationOverlay> createState() => _NavigationOverlayState();
}

class _NavigationOverlayObserver extends NavigatorObserver {
  final _NavigationOverlayState? _state;

  _NavigationOverlayObserver(this._state);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _state?.stopNavigation();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _state?.stopNavigation();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _state?.stopNavigation();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _state?.stopNavigation();
  }
}

class _NavigationOverlayState extends State<NavigationOverlay> {
  bool _isNavigating = false;
  Timer? _timeoutTimer;

  void startNavigation() {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });

    // Safety timeout to prevent permanent blocking
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isNavigating) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  void stopNavigation() {
    _timeoutTimer?.cancel();
    if (mounted && _isNavigating) {
      setState(() {
        _isNavigating = false;
      });
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_isNavigating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
