import 'package:flutter/material.dart';

enum ActivityType {
  sale(
    icon: Icons.attach_money,
    color: Colors.green,
  ),
  commission(
    icon: Icons.brush,
    color: Colors.blue,
  ),
  gift(
    icon: Icons.card_giftcard,
    color: Colors.purple,
  ),
  sponsorship(
    icon: Icons.handshake,
    color: Colors.orange,
  );

  const ActivityType({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;
}

class ActivityModel {
  final ActivityType type;
  final String title;
  final String description;
  final String timeAgo;
  final DateTime timestamp;

  const ActivityModel({
    required this.type,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.timestamp,
  });
}
