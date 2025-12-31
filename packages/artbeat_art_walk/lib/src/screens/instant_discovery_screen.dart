import 'package:flutter/material.dart';

class InstantDiscoveryScreen extends StatelessWidget {
  final dynamic userPosition;
  final dynamic initialNearbyArt;

  const InstantDiscoveryScreen({
    Key? key,
    this.userPosition,
    this.initialNearbyArt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instant Discovery Radar')),
      body: const Center(child: Text('Radar screen goes here')),
    );
  }
}
