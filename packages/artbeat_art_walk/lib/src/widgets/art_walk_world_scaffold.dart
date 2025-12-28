import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/art_walk_design_system.dart';
import 'world_background.dart';

class ArtWalkWorldScaffold extends StatelessWidget {
  final String title;
  final bool translateTitle;
  final Widget body;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  const ArtWalkWorldScaffold({
    required this.title,
    required this.body,
    this.translateTitle = true,
    this.actions,
    this.showBackButton = true,
    this.floatingActionButton,
    this.drawer,
    this.scaffoldKey,
    this.appBar,
    this.bottomNavigationBar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = translateTitle ? title.tr() : title;

    return WorldBackground(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: drawer,
        appBar: appBar ??
            ArtWalkDesignSystem.buildAppBar(
              title: resolvedTitle,
              showBackButton: showBackButton,
              actions: actions,
              scaffoldKey: scaffoldKey,
            ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
