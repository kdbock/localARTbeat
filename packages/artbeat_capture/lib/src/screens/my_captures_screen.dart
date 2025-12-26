import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MyCapturesScreen extends StatefulWidget {
  final List<CaptureModel> captures;
  const MyCapturesScreen({super.key, required this.captures});

  @override
  State<MyCapturesScreen> createState() => _MyCapturesScreenState();
}

class _MyCapturesScreenState extends State<MyCapturesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _pendingInitialTab;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      int initialTab = 0;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['tab'] is int) {
        initialTab = args['tab'] as int;
      }
      _tabController = TabController(
        length: 3,
        vsync: this,
        initialIndex: initialTab,
      );
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.captures;
    final pending = all.where((c) => c.status == 'pending').toList();
    final approved = all.where((c) => c.status == 'approved').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF07060F),
                  Color(0xFF0B1222),
                  Color(0xFF0A1B15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                HudTopBar(
                  title: 'my_captures_title'.tr(),
                  subtitle: 'my_captures_subtitle'.tr(),
                  onBack: () => Navigator.pop(context),
                ),
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Approved'),
                  ],
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: const Color(0xFF34D399),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(all),
                      _buildList(pending),
                      _buildList(approved),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<CaptureModel> captures) {
    if (captures.isEmpty) {
      return Center(
        child: Text(
          'my_captures_empty'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withAlpha((0.6 * 255).toInt()),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: captures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final capture = captures[index];
        return QuestCaptureTile(
          capture: capture,
          onTap: () {
            Navigator.pushNamed(context, '/capture/detail', arguments: capture);
          },
          onEdit: () {
            Navigator.pushNamed(context, '/capture/edit', arguments: capture);
          },
        );
      },
    );
  }
}

// Dummy model - replace with your actual capture model
// class CaptureItem {
//   final String title;
//   final String description;
//   final String status;
//   final dynamic imageFile;
//
//   CaptureItem({
//     required this.title,
//     required this.description,
//     required this.status,
//     required this.imageFile,
//   });
// }
