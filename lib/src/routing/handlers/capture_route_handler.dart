import 'package:artbeat_admin/artbeat_admin.dart' as admin;
import 'package:artbeat_capture/artbeat_capture.dart' as capture;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../route_utils.dart';

typedef AdminRouteDelegate = Route<dynamic>? Function(RouteSettings settings);

class CaptureRouteHandler {
  const CaptureRouteHandler();

  Route<dynamic>? handleRoute(
    RouteSettings settings, {
    required AdminRouteDelegate handleAdminRoute,
  }) {
    switch (settings.name) {
      case core.AppRoutes.captures:
      case core.AppRoutes.captureMyCaptures:
      case core.AppRoutes.capturePending:
      case core.AppRoutes.captureMap:
      case core.AppRoutes.captureApproved:
      case core.AppRoutes.capturePublic:
        return _buildUserCapturesRoute(settings.name!);

      case core.AppRoutes.captureBrowse:
        return _buildCaptureListRoute(
          futureBuilder: (context) =>
              context.read<capture.CaptureService>().getAllCapturesFresh(),
          errorText: 'Error loading community captures',
          builder: (captures) => capture.CapturesListScreen(captures: captures),
        );

      case core.AppRoutes.captureDashboard:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.EnhancedCaptureDashboardScreen(),
        );

      case core.AppRoutes.captureCamera:
      case core.AppRoutes.captureCreate:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CaptureScreen(),
        );

      case core.AppRoutes.captureAdminModeration:
        return handleAdminRoute(
          RouteSettings(
            name: admin.AdminRoutes.contentModeration,
            arguments: settings.arguments,
          ),
        );

      case core.AppRoutes.captureTerms:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.TermsAndConditionsScreen(),
        );

      case core.AppRoutes.captureDetail:
        final captureId = RouteUtils.getArgument<String>(settings, 'captureId');
        if (captureId == null || captureId.isEmpty) {
          return RouteUtils.createErrorRoute('Capture ID is required');
        }
        return RouteUtils.createMainLayoutRoute(
          child: Builder(
            builder: (context) => FutureBuilder<core.CaptureModel?>(
              future: context.read<capture.CaptureService>().getCaptureById(
                captureId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Text('Error loading capture'));
                }
                return capture.CaptureDetailViewerScreen(
                  capture: snapshot.data!,
                );
              },
            ),
          ),
        );

      case core.AppRoutes.captureEdit:
        final captureModel = RouteUtils.getArgument<core.CaptureModel>(
          settings,
          'capture',
        );
        if (captureModel == null) {
          return RouteUtils.createErrorRoute('Capture data is required');
        }
        return RouteUtils.createMainLayoutRoute(
          child: capture.CaptureEditScreen(capture: captureModel),
        );

      case core.AppRoutes.captureNearby:
        return _buildCaptureListRoute(
          futureBuilder: (context) =>
              context.read<capture.CaptureService>().getPublicCaptures(),
          useLoadingScreen: true,
          retryRouteName: core.AppRoutes.captureNearby,
          builder: (captures) => capture.CapturesListScreen(captures: captures),
        );

      case core.AppRoutes.capturePopular:
        return _buildCaptureListRoute(
          futureBuilder: (context) =>
              context.read<capture.CaptureService>().getAllCapturesFresh(),
          useLoadingScreen: true,
          retryRouteName: core.AppRoutes.capturePopular,
          builder: (captures) => capture.CapturesListScreen(captures: captures),
        );

      case core.AppRoutes.captureSearch:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SearchResultsPage(),
        );

      case core.AppRoutes.captureSettings:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CaptureSettingsScreen(),
        );

      case core.AppRoutes.captureReview:
        final captureId = RouteUtils.getArgument<String>(settings, 'captureId');
        if (captureId == null || captureId.isEmpty) {
          return RouteUtils.createErrorRoute('Capture ID is required');
        }
        return RouteUtils.createMainLayoutRoute(
          child: capture.CaptureReviewScreen(captureId: captureId),
        );

      default:
        return RouteUtils.createNotFoundRoute('Capture feature');
    }
  }

  Route<dynamic> _buildUserCapturesRoute(
    String routeName,
  ) => RouteUtils.createMainLayoutRoute(
    child: Builder(
      builder: (context) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          return const Center(
            child: Text('Please log in to view your captures'),
          );
        }
        return FutureBuilder<List<capture.CaptureModel>>(
          future: context.read<capture.CaptureService>().getCapturesForUser(
            userId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading captures'));
            }
            final captures = snapshot.data ?? [];
            switch (routeName) {
              case core.AppRoutes.captureMyCaptures:
                return capture.MyCapturesScreen(captures: captures);
              case core.AppRoutes.capturePending:
                final pending = captures
                    .where((captureModel) => captureModel.status == 'pending')
                    .toList();
                return capture.MyCapturesPendingScreen(captures: pending);
              case core.AppRoutes.captureApproved:
                final approved = captures
                    .where((captureModel) => captureModel.status == 'approved')
                    .toList();
                return capture.MyCapturesApprovedScreen(captures: approved);
              case core.AppRoutes.captures:
              case core.AppRoutes.captureMap:
              case core.AppRoutes.capturePublic:
              default:
                return capture.CapturesListScreen(captures: captures);
            }
          },
        );
      },
    ),
  );

  Route<dynamic> _buildCaptureListRoute({
    required Future<List<capture.CaptureModel>> Function(BuildContext context)
    futureBuilder,
    required Widget Function(List<capture.CaptureModel> captures) builder,
    String errorText = 'Error loading captures',
    bool useLoadingScreen = false,
    String? retryRouteName,
  }) => RouteUtils.createMainLayoutRoute(
    child: Builder(
      builder: (context) => FutureBuilder<List<capture.CaptureModel>>(
        future: futureBuilder(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            if (useLoadingScreen) {
              return const core.LoadingScreen();
            }
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (retryRouteName != null) {
              return _buildRetryableErrorState(
                context,
                error: snapshot.error.toString(),
                retryRouteName: retryRouteName,
              );
            }
            return Center(child: Text(errorText));
          }
          return builder(snapshot.data ?? []);
        },
      ),
    ),
  );

  Widget _buildRetryableErrorState(
    BuildContext context, {
    required String error,
    required String retryRouteName,
  }) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        const Text(
          'Error',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(retryRouteName),
          child: Text('common_retry'.tr()),
        ),
      ],
    ),
  );
}
