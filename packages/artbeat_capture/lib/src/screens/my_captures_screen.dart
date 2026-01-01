import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppRoutes;

class MyCapturesScreen extends StatelessWidget {
  final List<CaptureModel> captures;
  const MyCapturesScreen({super.key, required this.captures});

  @override
  Widget build(BuildContext context) {
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
                Expanded(child: _buildList(captures)),
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
            Navigator.pushNamed(
              context,
              AppRoutes.captureDetail,
              arguments: {'captureId': capture.id},
            );
          },
          onEdit: () {
            Navigator.pushNamed(
              context,
              AppRoutes.captureEdit,
              arguments: capture,
            );
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
