import 'package:flutter/material.dart';

class EventsComingSoonScreen extends StatelessWidget {
  const EventsComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Events Coming Soon',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
