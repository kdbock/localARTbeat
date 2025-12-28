import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MyCapturesApprovedScreen extends StatelessWidget {
  final List<CaptureModel> captures;
  const MyCapturesApprovedScreen({super.key, required this.captures});

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
                  title: 'approved_captures_title'.tr(),
                  subtitle: 'approved_captures_subtitle'.tr(),
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
          'no_approved_captures'.tr(),
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
