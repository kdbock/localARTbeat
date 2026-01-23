import 'package:flutter/material.dart';

enum ActivityType {
  sale(icon: Icons.attach_money, color: Colors.green),
  commission(icon: Icons.brush, color: Colors.blue),
  gift(icon: Icons.bolt, color: Color(0xFF00F5FF)),
  sponsorship(icon: Icons.handshake, color: Colors.orange),
  auction(icon: Icons.gavel, color: Colors.purple);

  const ActivityType({required this.icon, required this.color});

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
