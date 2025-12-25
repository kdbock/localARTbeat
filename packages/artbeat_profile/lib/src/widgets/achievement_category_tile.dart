import 'package:flutter/material.dart';

/// Dummy widget for AchievementCategoryTile
class AchievementCategoryTile extends StatelessWidget {
  final dynamic category;

  const AchievementCategoryTile({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Text('Category $category');
  }
}
