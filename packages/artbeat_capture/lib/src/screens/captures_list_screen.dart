import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../widgets/hud_top_bar.dart';
import '../widgets/quest_capture_tile.dart';
import 'package:artbeat_core/artbeat_core.dart';

class CapturesListScreen extends StatelessWidget {
  final List<CaptureModel> captures;

  const CapturesListScreen({super.key, required this.captures});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // Background gradient
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

          // Content
          SafeArea(
            child: Column(
              children: [
                HudTopBar(
                  title: 'captures_list_title'.tr(),
                  subtitle: 'captures_list_subtitle'.tr(),
                  onBack: () => Navigator.pop(context),
                ),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(18),
                    itemCount: captures.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final capture = captures[index];

                      return QuestCaptureTile(
                        capture: capture,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/capture/detail',
                            arguments: {'captureId': capture.id},
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
