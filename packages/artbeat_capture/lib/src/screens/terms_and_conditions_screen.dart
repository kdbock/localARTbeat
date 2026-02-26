import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_capture/artbeat_capture.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key, this.showAcceptButton = false});

  final bool showAcceptButton;

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _isSaving = false;

  Future<void> _acceptAndContinue() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      await CaptureTermsService.markTermsAccepted();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // Background
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
                  title: 'terms_title'.tr(),
                  subtitle: 'terms_subtitle'.tr(),
                  onBack: () => Navigator.pop(context),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: GlassCard(
                          radius: 26,
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            _termsText,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(
                                (0.9 * 255).toInt(),
                              ),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.showAcceptButton)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: SizedBox(
                      width: double.infinity,
                      child: HudButton(
                        label: _isSaving ? 'Saving...' : 'I Agree - Continue',
                        icon: Icons.check_circle_outline,
                        onTap: _isSaving ? () {} : _acceptAndContinue,
                      ),
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

const String _termsText = '''
Capture & Community Rules

Before submitting a capture, confirm all of the following:

1. Safety First
- Do not enter restricted, dangerous, or private areas.
- Follow local laws and posted signage.

2. Rights & Permissions
- Only upload content you own or have permission to share.
- Respect artist copyrights, trademarks, and property rights.

3. Content Standards
- No harassment, hateful content, threats, or illegal activity.
- No explicit sexual content or exploitative imagery.
- Submissions can be removed for policy violations.

4. Public Visibility
- Approved captures may appear in public feeds and discovery surfaces.

By continuing, you confirm you understand and agree to these rules.
''';
