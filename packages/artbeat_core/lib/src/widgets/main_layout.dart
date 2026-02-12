import 'package:flutter/material.dart';
import '../services/crash_prevention_service.dart';
import 'navigation_overlay.dart';
import 'enhanced_bottom_nav.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final void Function(int)? onNavigationChanged;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? floatingActionButton;
  final GlobalKey? bottomNavKey;
  final List<GlobalKey>? bottomNavItemKeys;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    this.onNavigationChanged,
    this.appBar,
    this.drawer,
    this.endDrawer,
    this.scaffoldKey,
    this.floatingActionButton,
    this.bottomNavKey,
    this.bottomNavItemKeys,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  void _handleNavigation(int index) {
    // Prevent redundant navigation if we're already on that tab
    if (index == widget.currentIndex) return;

    // Throttle navigation to prevent rapid multiple taps
    if (!CrashPreventionService.shouldAllowNavigation()) return;

    // Show navigation overlay
    final navOverlay = NavigationOverlay.of(context);
    navOverlay?.startNavigation();

    if (widget.onNavigationChanged != null) {
      widget.onNavigationChanged!(index);
    } else {
      // Default navigation logic - use pushNamedAndRemoveUntil to prevent app reloads
      // and ensure proper navigation stack management
      try {
        switch (index) {
          case 0:
            // Home tab - navigate to dashboard
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
            break;
          case 1:
            // Art Walk tab - navigate to art walk map/dashboard
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamedAndRemoveUntil('/art-walk/map', (route) => false);
            break;
          case 2:
            // Capture tab - launch capture sequence
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamed('/capture/camera');
            break;
          case 3:
            // Community tab - navigate to community hub
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamedAndRemoveUntil('/community/hub', (route) => false);
            break;
          case 4:
            // Events tab - navigate to events dashboard
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamedAndRemoveUntil('/events', (route) => false);
            break;
          default:
            // Handle any other indices gracefully - stay on current page
            break;
        }
      } catch (e) {
        // If navigation fails, show feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget.scaffoldKey,
      appBar: widget.appBar,
      drawer: widget.drawer,
      endDrawer: widget.endDrawer,
      backgroundColor: const Color(0xFF07060F),
      floatingActionButton: widget.floatingActionButton,
      body: widget.child,
      bottomNavigationBar: widget.currentIndex == -1
          ? null
          : EnhancedBottomNav(
              key: widget.bottomNavKey,
              itemKeys: widget.bottomNavItemKeys,
              currentIndex: widget.currentIndex,
              onTap: _handleNavigation,
            ),
    );
  }
}
