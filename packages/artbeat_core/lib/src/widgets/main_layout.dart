import 'package:flutter/material.dart';
import 'enhanced_bottom_nav.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final void Function(int)? onNavigationChanged;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    this.onNavigationChanged,
    this.appBar,
    this.drawer,
    this.endDrawer,
    this.scaffoldKey,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  void _handleNavigation(int index) {
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
            ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
            break;
          case 1:
            // Art Walk tab - navigate to art walk map/dashboard
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/art-walk/map', (route) => false);
            break;
          case 2:
            // Capture tab - launch capture sequence
            Navigator.of(context).pushNamed('/capture/camera');
            break;
          case 3:
            // Community tab - navigate to community hub
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/community/hub', (route) => false);
            break;
          case 4:
            // Events tab - navigate to events discover
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/events/discover', (route) => false);
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
      body: widget.child,
      bottomNavigationBar: widget.currentIndex == -1
          ? null
          : EnhancedBottomNav(
              currentIndex: widget.currentIndex,
              onTap: _handleNavigation,
            ),
    );
  }
}
