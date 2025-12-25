import 'package:flutter/material.dart';

class ProfileBadgeGrid extends StatelessWidget {
  final List<Widget> badges;
  final int maxVisible;
  final void Function()? onTapMore;

  const ProfileBadgeGrid({
    Key? key,
    required this.badges,
    this.maxVisible = 4,
    this.onTapMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visibleBadges = badges.take(maxVisible).toList();
    final hasMore = badges.length > maxVisible;

    return Row(
      children: [
        ...visibleBadges,
        if (hasMore)
          GestureDetector(
            onTap: onTapMore,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
              ),
              child: const Icon(Icons.more_horiz, size: 20),
            ),
          ),
      ],
    );
  }
}
