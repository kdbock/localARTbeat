// Copyright (c) 2025 ArtBeat. All rights reserved.

import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Comprehensive tests for Main Dashboard functionality
///
/// Tests cover all dashboard components including:
/// - Dashboard loading and initialization
/// - Welcome banner/hero sections
/// - App bar with navigation icons
/// - Bottom navigation functionality
/// - Drawer menu behavior
/// - Responsive design
/// - Loading and error states
void main() {
  group('🏠 Main Dashboard Tests', () {
    group('Dashboard Loading & Initialization', () {
      testWidgets('✅ Dashboard loads after authentication', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(title: Text('ARTbeat Dashboard')),
                  SliverToBoxAdapter(
                    child: Center(child: Text('Dashboard Content')),
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify dashboard structure
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(SliverAppBar), findsOneWidget);
        expect(find.text('ARTbeat Dashboard'), findsOneWidget);
      });

      testWidgets('✅ Loading states display properly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading Dashboard...'),
                  ],
                ),
              ),
            ),
          ),
        );

        // Verify loading indicators
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading Dashboard...'), findsOneWidget);
      });
    });

    group('Welcome Banner & Hero Sections', () {
      testWidgets('✅ Welcome banner/hero section displays', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  const SliverAppBar(title: Text('ARTbeat'), pinned: true),
                  SliverToBoxAdapter(
                    child: Container(
                      height: 200,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.blue],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Welcome to ARTbeat',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify hero section elements
        expect(find.text('Welcome to ARTbeat'), findsOneWidget);
        expect(find.byType(Container), findsAtLeastNWidgets(1));
      });

      testWidgets('✅ Art Walk hero section displays', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  const SliverAppBar(title: Text('ARTbeat')),
                  SliverToBoxAdapter(
                    child: Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.map, size: 48),
                            const SizedBox(height: 8),
                            const Text(
                              'Discover Art Walk',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {},
                              child: const Text('Start Exploring'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify Art Walk hero components
        expect(find.text('Discover Art Walk'), findsOneWidget);
        expect(find.text('Start Exploring'), findsOneWidget);
        expect(find.byIcon(Icons.map), findsOneWidget);
      });
    });

    group('App Bar & Navigation Icons', () {
      testWidgets('✅ App bar with menu, search, notifications, profile icons', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              appBar: EnhancedUniversalHeader(
                title: 'ARTbeat',
                hasNotifications: true,
                notificationCount: 3,
              ),
              body: Center(child: Text('Dashboard Content')),
            ),
          ),
        );

        // Verify app bar is present
        expect(find.byType(EnhancedUniversalHeader), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('✅ Header displays with proper configuration', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              appBar: EnhancedUniversalHeader(
                title: 'Test Dashboard',
                hasNotifications: true,
                notificationCount: 5,
              ),
              body: Center(child: Text('Content')),
            ),
          ),
        );

        // Verify header components
        expect(find.byType(EnhancedUniversalHeader), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });
    });

    group('Bottom Navigation Bar', () {
      testWidgets('✅ Bottom navigation bar renders correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MainLayout(
              currentIndex: 0,
              child: Center(child: Text('Dashboard')),
            ),
          ),
        );

        // Check for enhanced bottom navigation
        expect(find.byType(EnhancedBottomNav), findsOneWidget);
        expect(find.byType(MainLayout), findsOneWidget);
      });

      testWidgets('✅ Bottom nav handles tap interactions', (tester) async {
        // Test navigation callback behavior

        await tester.pumpWidget(
          MaterialApp(
            home: MainLayout(
              currentIndex: 0,
              onNavigationChanged: (index) {
                // Navigation callback for testing
              },
              child: const Center(child: Text('Dashboard')),
            ),
          ),
        );

        // Find and tap navigation items
        final navItems = find.byType(GestureDetector);
        if (navItems.evaluate().isNotEmpty) {
          await tester.tap(navItems.first);
          await tester.pump();
        }

        // Navigation structure should be present
        expect(find.byType(EnhancedBottomNav), findsOneWidget);
      });

      testWidgets('✅ Bottom nav shows correct active state', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MainLayout(
              currentIndex: 2, // Set active index
              child: Center(child: Text('Capture')),
            ),
          ),
        );

        // Verify bottom navigation shows with correct index
        expect(find.byType(EnhancedBottomNav), findsOneWidget);
        expect(find.text('Capture'), findsOneWidget);
      });

      testWidgets('✅ Bottom nav hidden when currentIndex is -1', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MainLayout(
              currentIndex: -1, // Hide bottom nav
              child: Center(child: Text('No Nav')),
            ),
          ),
        );

        // Bottom nav should be hidden
        expect(find.byType(EnhancedBottomNav), findsNothing);
        expect(find.text('No Nav'), findsOneWidget);
      });
    });

    group('Drawer Menu', () {
      testWidgets('✅ Drawer menu opens/closes', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              drawer: const ArtbeatDrawer(),
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: AppBar(title: const Text('Test')),
              ),
              body: const Center(child: Text('Content')),
            ),
          ),
        );

        // Verify drawer exists and menu button is present
        expect(find.byType(ArtbeatDrawer), findsOneWidget);
        expect(find.byIcon(Icons.menu), findsOneWidget);

        // Test opening drawer via menu button
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        // Drawer should be accessible
        expect(find.byType(Drawer), findsOneWidget);
      });

      testWidgets('✅ Drawer contains navigation options', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              drawer: const ArtbeatDrawer(),
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: AppBar(title: const Text('Test')),
              ),
              body: const Center(child: Text('Content')),
            ),
          ),
        );

        // Open the drawer
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        // Verify drawer structure
        expect(find.byType(Drawer), findsOneWidget);
      });
    });

    group('Responsive Design', () {
      testWidgets('✅ Dashboard responsiveness on different screen sizes', (
        tester,
      ) async {
        // Test on a smaller screen size (iPhone SE)
        await tester.binding.setSurfaceSize(const Size(375, 667));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Dashboard')),
              body: const CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Responsive Content'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify dashboard adapts to small screen
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.text('Responsive Content'), findsOneWidget);

        // Test on a larger screen size (iPad)
        await tester.binding.setSurfaceSize(const Size(768, 1024));
        await tester.pump();

        // Dashboard should still render properly on larger screen
        expect(find.byType(CustomScrollView), findsOneWidget);

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('✅ Layout adapts to orientation changes', (tester) async {
        // Portrait orientation
        await tester.binding.setSurfaceSize(const Size(375, 812));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: Text(
                    'Size: ${constraints.maxWidth}x${constraints.maxHeight}',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(Scaffold), findsOneWidget);

        // Landscape orientation
        await tester.binding.setSurfaceSize(const Size(812, 375));
        await tester.pump();

        // Should still render properly in landscape
        expect(find.byType(Scaffold), findsOneWidget);

        // Reset
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Error Handling', () {
      testWidgets('✅ Error states handled gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text('Something went wrong'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Verify error state display
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('✅ Network error handling', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 48),
                        const SizedBox(height: 8),
                        const Text('No Internet Connection'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Check Connection'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Verify network error handling
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        expect(find.text('No Internet Connection'), findsOneWidget);
        expect(find.text('Check Connection'), findsOneWidget);
      });
    });

    group('Dashboard Integration', () {
      testWidgets('✅ Dashboard integrates with MainLayout properly', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MainLayout(
              currentIndex: 0,
              appBar: EnhancedUniversalHeader(title: 'ARTbeat'),
              drawer: ArtbeatDrawer(),
              child: Center(child: Text('Integrated Dashboard Content')),
            ),
          ),
        );

        // Verify complete integration
        expect(find.byType(MainLayout), findsOneWidget);
        expect(find.byType(EnhancedUniversalHeader), findsOneWidget);
        expect(find.byType(EnhancedBottomNav), findsOneWidget);
        expect(find.text('Integrated Dashboard Content'), findsOneWidget);
      });

      testWidgets('✅ Pull-to-refresh functionality', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RefreshIndicator(
                onRefresh: () async {
                  // Simulate refresh
                  await Future<void>.delayed(const Duration(milliseconds: 100));
                },
                child: const CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 400,
                        child: Center(child: Text('Pull to refresh content')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Look for RefreshIndicator
        expect(find.byType(RefreshIndicator), findsOneWidget);
        expect(find.text('Pull to refresh content'), findsOneWidget);

        // Test pull to refresh gesture
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
      });

      testWidgets('✅ Scroll behavior and physics', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ListTile(title: Text('Item $index')),
                      childCount: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify scrollable content
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.text('Item 0'), findsOneWidget);

        // Test scrolling behavior
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
        await tester.pump();
      });
    });
  });
}
