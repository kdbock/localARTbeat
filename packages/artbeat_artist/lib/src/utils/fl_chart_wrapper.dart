// filepath: /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/utils/fl_chart_wrapper.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SafeLineChart extends StatelessWidget {
  final LineChartData data;

  const SafeLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // This wrapper handles potential issues with MediaQuery.boldTextOverride
    return LineChart(data);
  }
}

class SafeBarChart extends StatelessWidget {
  final BarChartData data;

  const SafeBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // This wrapper handles potential issues with MediaQuery.boldTextOverride
    return BarChart(data);
  }
}

class SafePieChart extends StatelessWidget {
  final PieChartData data;

  const SafePieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // This wrapper handles potential issues with MediaQuery.boldTextOverride
    return PieChart(data);
  }
}
