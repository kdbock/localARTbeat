// weekly_goals_screen.dart (Refactored to Local ARTbeat Design Guide)

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/src/models/weekly_goal_model.dart';
import 'package:artbeat_art_walk/src/services/weekly_goals_service.dart';
import '../widgets/world_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/hud_top_bar.dart';
import '../widgets/gradient_cta_button.dart';

class WeeklyGoalsScreen extends StatefulWidget {
  const WeeklyGoalsScreen({super.key});

  @override
  State<WeeklyGoalsScreen> createState() => _WeeklyGoalsScreenState();
}

class _WeeklyGoalsScreenState extends State<WeeklyGoalsScreen>
    with SingleTickerProviderStateMixin {
  late final WeeklyGoalsService _goalsService;
  List<WeeklyGoalModel> _currentGoals = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _goalsService = context.read<WeeklyGoalsService>();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final goals = await _goalsService.getCurrentWeekGoals();
      final stats = await _goalsService.getWeeklyGoalStats();
      setState(() {
        _currentGoals = goals;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading weekly goals: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: SafeArea(
        child: Column(
          children: [
            HudTopBar(title: 'weekly_goals.title'.tr()),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'weekly_goals.current_tab'.tr()),
                Tab(text: 'weekly_goals.stats_tab'.tr()),
              ],
              labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.tealAccent,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCurrentWeekTab(),
                        _buildStatisticsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeekTab() {
    if (_currentGoals.isEmpty) {
      return Center(
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 64, color: Colors.white30),
              const SizedBox(height: 16),
              Text(
                'weekly_goals.no_goals_title'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'weekly_goals.no_goals_subtitle'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _currentGoals.length,
        itemBuilder: (context, index) {
          final goal = _currentGoals[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    goal.description,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GradientCTAButton(
                    label: 'weekly_goals.progress'.tr(),
                    onPressed: () {},
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'weekly_goals.stats_performance'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_stats['completedGoals'] ?? 0}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_stats['completionRate'] ?? 0}%',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}
