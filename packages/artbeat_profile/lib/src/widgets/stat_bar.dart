import 'package:flutter/material.dart';

/// A widget to display user stats like followers, following, favorites, xp
class StatBar extends StatelessWidget {
  final dynamic followers;
  final dynamic following;
  final dynamic favorites;
  final dynamic xp;

  const StatBar({
    super.key,
    required this.followers,
    required this.following,
    required this.favorites,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStat('Followers', followers.toString()),
        _buildStat('Following', following.toString()),
        _buildStat('Favorites', favorites.toString()),
        _buildStat('XP', xp.toString()),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}
