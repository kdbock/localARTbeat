// Batch updates for remaining Art Walk screens
// This file contains the standardized updates to apply to all remaining screens

import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/src/theme/art_walk_design_system.dart';
import 'package:artbeat_art_walk/src/widgets/art_walk_drawer.dart';

/// Updates to apply to each screen:
///
/// 1. Add import: import 'package:artbeat_art_walk/src/theme/art_walk_design_system.dart';
///
/// 2. Replace AppBar with: ArtWalkDesignSystem.buildAppBar()
///
/// 3. Replace body with: ArtWalkDesignSystem.buildScreenContainer()
///
/// 4. Replace loading states with: ArtWalkScreenTemplate.buildLoadingState()
///
/// 5. Replace empty states with: ArtWalkScreenTemplate.buildEmptyState()
///
/// 6. Replace FloatingActionButton with: ArtWalkDesignSystem.buildFloatingActionButton()
///
/// 7. Replace form fields with: ArtWalkScreenTemplate.buildFormField()
///
/// 8. Replace list items with: ArtWalkScreenTemplate.buildListItem()

/// Standard screen wrapper
class StandardScreenWrapper {
  static Widget wrapScreen({
    required String title,
    required Widget child,
    bool showBackButton = true,
    List<Widget>? actions,
    GlobalKey<ScaffoldState>? scaffoldKey,
    Widget? floatingActionButton,
  }) {
    return Scaffold(
      key: scaffoldKey,
      appBar: ArtWalkDesignSystem.buildAppBar(
        title: title,
        showBackButton: showBackButton,
        actions: actions,
        scaffoldKey: scaffoldKey,
      ),
      drawer: const ArtWalkDrawer(),
      body: ArtWalkDesignSystem.buildScreenContainer(child: child),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Screen-specific configurations
class ScreenConfigs {
  static const Map<String, Map<String, dynamic>> configs = {
    'CreateArtWalkScreen': {
      'title': 'Create Art Walk',
      'hasFloatingActionButton': true,
      'fabIcon': Icons.save,
      'fabTooltip': 'Save Art Walk',
      'showBackButton': true,
    },
    'ArtWalkEditScreen': {
      'title': 'Edit Art Walk',
      'hasFloatingActionButton': true,
      'fabIcon': Icons.save,
      'fabTooltip': 'Save Changes',
      'showBackButton': true,
    },
    'EnhancedArtWalkCreateScreen': {
      'title': 'Create Art Walk',
      'hasFloatingActionButton': true,
      'fabIcon': Icons.save,
      'fabTooltip': 'Save Art Walk',
      'showBackButton': true,
    },
    'EnhancedArtWalkExperienceScreen': {
      'title': 'Art Walk Experience',
      'hasFloatingActionButton': false,
      'showBackButton': true,
    },
    'ArtWalkCelebrationScreen': {
      'title': 'Congratulations!',
      'hasFloatingActionButton': false,
      'showBackButton': false,
    },
    'EnhancedMyArtWalksScreen': {
      'title': 'My Art Walks',
      'hasFloatingActionButton': true,
      'fabIcon': Icons.add_location,
      'fabTooltip': 'Create Art Walk',
      'showBackButton': true,
    },
    'SearchResultsScreen': {
      'title': 'Search Results',
      'hasFloatingActionButton': false,
      'showBackButton': true,
    },
  };
}

/// Common patterns for different screen types
class ScreenPatterns {
  /// Form screen pattern
  static Widget buildFormScreen({
    required String title,
    required List<Widget> formFields,
    required VoidCallback onSave,
    VoidCallback? onCancel,
  }) {
    return Column(
      children: [
        ArtWalkDesignSystem.buildSectionHeader(title: title, icon: Icons.edit),
        const SizedBox(height: ArtWalkDesignSystem.paddingL),
        ...formFields.map(
          (field) => Padding(
            padding: const EdgeInsets.only(
              bottom: ArtWalkDesignSystem.paddingM,
            ),
            child: field,
          ),
        ),
        const SizedBox(height: ArtWalkDesignSystem.paddingL),
        Row(
          children: [
            if (onCancel != null) ...[
              Expanded(
                child: ArtWalkDesignSystem.buildActionButton(
                  text: 'Cancel',
                  onPressed: onCancel,
                  isAccent: false,
                ),
              ),
              const SizedBox(width: ArtWalkDesignSystem.paddingM),
            ],
            Expanded(
              child: ArtWalkDesignSystem.buildActionButton(
                text: 'Save',
                onPressed: onSave,
                icon: Icons.save,
                isAccent: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// List screen pattern
  static Widget buildListScreen({
    required String title,
    required List<Widget> items,
    Widget? searchBar,
    Widget? filterBar,
  }) {
    return Column(
      children: [
        if (searchBar != null) ...[
          searchBar,
          const SizedBox(height: ArtWalkDesignSystem.paddingM),
        ],
        if (filterBar != null) ...[
          filterBar,
          const SizedBox(height: ArtWalkDesignSystem.paddingM),
        ],
        ArtWalkDesignSystem.buildSectionHeader(title: title, icon: Icons.list),
        const SizedBox(height: ArtWalkDesignSystem.paddingM),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: ArtWalkDesignSystem.paddingS),
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }

  /// Detail screen pattern
  static Widget buildDetailScreen({
    required String title,
    required List<Widget> sections,
    List<Widget>? actions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArtWalkDesignSystem.buildSectionHeader(
          title: title,
          icon: Icons.info,
          action: actions != null ? Row(children: actions) : null,
        ),
        const SizedBox(height: ArtWalkDesignSystem.paddingL),
        ...sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(
              bottom: ArtWalkDesignSystem.paddingL,
            ),
            child: section,
          ),
        ),
      ],
    );
  }
}
