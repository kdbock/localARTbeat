import 'package:artbeat_core/artbeat_core.dart' hide GradientBadge;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/gradient_badge.dart';

class QuietModeScreen extends StatefulWidget {
  const QuietModeScreen({super.key});

  @override
  State<QuietModeScreen> createState() => _QuietModeScreenState();
}

class _QuietModeScreenState extends State<QuietModeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isQuietModeEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;
  late final TextEditingController _messageController;
  String _quietModeMessage = '';

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _loadQuietModeSettings();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuietModeSettings() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.data();
        _isQuietModeEnabled = (data?['quietModeEnabled'] as bool?) ?? false;
        _quietModeMessage = (data?['quietModeMessage'] as String?) ?? '';
        _messageController.text = _quietModeMessage;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(
        'quiet_mode.load_error'.tr(namedArgs: {'error': '$e'}),
      );
    }
  }

  Future<void> _persistQuietModeSettings() async {
    FocusScope.of(context).unfocus();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar('quiet_mode.auth_required'.tr());
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {
          'quietModeEnabled': _isQuietModeEnabled,
          'quietModeMessage': _quietModeMessage,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('quiet_mode.save_success'.tr());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar(
        'quiet_mode.save_error'.tr(namedArgs: {'error': '$e'}),
      );
    }
  }

  void _handleToggle(bool value) {
    setState(() => _isQuietModeEnabled = value);
  }

  void _handleMessageChanged(String value) {
    setState(() => _quietModeMessage = value);
  }

  void _showSnackBar(String message) {
    if (message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: 'screen_title_quiet_mode'.tr(),
          glassBackground: true,
          showBackButton: true, subtitle: '',
        ),
        body: SafeArea(
          child: _isLoading
              ? const _QuietModeLoading()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 16),
                      _buildToggleCard(),
                      const SizedBox(height: 16),
                      _buildMessageCard(),
                      const SizedBox(height: 24),
                      GradientCTAButton(
                        text: 'quiet_mode.cta_save'.tr(),
                        icon: Icons.shield_moon_outlined,
                        isLoading: _isSaving,
                        onPressed:
                            _isSaving ? null : _persistQuietModeSettings,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      accentColor: _QuietModePalette.accentTeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientBadge(
            text: 'quiet_mode.hero_badge'.tr(),
            icon: Icons.self_improvement_outlined,
          ),
          const SizedBox(height: 16),
          Text(
            'quiet_mode.hero_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              color: _QuietModePalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'quiet_mode.hero_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: _QuietModePalette.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildStatusPill(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'quiet_mode.status_description'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    final isActive = _isQuietModeEnabled;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _QuietModePalette.accentTeal,
                  _QuietModePalette.accentPurple,
                ],
              )
            : null,
        color: isActive
            ? null
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.nightlight_round : Icons.brightness_5_outlined,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            isActive
                ? 'quiet_mode.status_active'.tr()
                : 'quiet_mode.status_inactive'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleToggle(!_isQuietModeEnabled),
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'quiet_mode.toggle_title'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (_isQuietModeEnabled
                            ? 'quiet_mode.toggle_subtitle_on'
                            : 'quiet_mode.toggle_subtitle_off')
                        .tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 48,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Switch.adaptive(
                  value: _isQuietModeEnabled,
                  onChanged: _handleToggle,
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) => Colors.white,
                  ),
                  trackColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? _QuietModePalette.accentTeal
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'quiet_mode.message_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          GlassTextField(
            controller: _messageController,
            maxLines: 3,
            hintText: 'quiet_mode.message_hint'.tr(),
            onChanged: _handleMessageChanged,
          ),
          const SizedBox(height: 12),
          Text(
            'quiet_mode.message_helper'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuietModeLoading extends StatelessWidget {
  const _QuietModeLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: SizedBox(
          height: 52,
          width: 52,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              _QuietModePalette.accentTeal,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuietModePalette {
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color textPrimary = Color(0xFFF8FAFF);
  static const Color textSecondary = Color(0xFFBBD1FF);
}
