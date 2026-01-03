import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/widgets.dart';

class GiftRulesScreen extends StatelessWidget {
  const GiftRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: 'gift_rules.title'.tr(),
          glassBackground: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 16),
                ..._GiftRulesData.sections
                    .map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _GiftRulesSectionCard(section: section),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: GradientCTAButton(
                    text: 'gift_rules.cta'.tr(),
                    icon: Icons.card_giftcard,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
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
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      accentColor: _GiftRulesPalette.accentTeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientBadge(
            text: 'gift_rules.hero_badge'.tr(),
            icon: Icons.shield_moon_outlined,
          ),
          const SizedBox(height: 16),
          Text(
            'gift_rules.hero_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: _GiftRulesPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'gift_rules.hero_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: _GiftRulesPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _GiftRulesData.stats
                .map((stat) => _GiftRulesStatChip(stat: stat))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GiftRulesPalette {
  static const Color textPrimary = Color(0xFFF8FAFF);
  static const Color textSecondary = Color(0xFFBBD1FF);
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentPink = Color(0xFFFF3D8D);
  static const Color accentYellow = Color(0xFFFFC857);
}

class _GiftRulesStat {
  const _GiftRulesStat({
    required this.labelKey,
    required this.valueKey,
    required this.icon,
    required this.accent,
  });

  final String labelKey;
  final String valueKey;
  final IconData icon;
  final Color accent;
}

class _GiftRulesSection {
  const _GiftRulesSection({
    required this.titleKey,
    required this.subtitleKey,
    required this.itemKeys,
    required this.icon,
    required this.accent,
  });

  final String titleKey;
  final String subtitleKey;
  final List<String> itemKeys;
  final IconData icon;
  final Color accent;
}

class _GiftRulesData {
  static const stats = [
    _GiftRulesStat(
      labelKey: 'gift_rules.stats.tiers_label',
      valueKey: 'gift_rules.stats.tiers_value',
      icon: Icons.auto_awesome,
      accent: _GiftRulesPalette.accentPurple,
    ),
    _GiftRulesStat(
      labelKey: 'gift_rules.stats.limit_label',
      valueKey: 'gift_rules.stats.limit_value',
      icon: Icons.timelapse,
      accent: _GiftRulesPalette.accentYellow,
    ),
    _GiftRulesStat(
      labelKey: 'gift_rules.stats.security_label',
      valueKey: 'gift_rules.stats.security_value',
      icon: Icons.shield_outlined,
      accent: _GiftRulesPalette.accentTeal,
    ),
  ];

  static const sections = [
    _GiftRulesSection(
      titleKey: 'gift_rules.sections.tiers.title',
      subtitleKey: 'gift_rules.sections.tiers.subtitle',
      itemKeys: [
        'gift_rules.sections.tiers.items.supporter',
        'gift_rules.sections.tiers.items.fan',
        'gift_rules.sections.tiers.items.patron',
        'gift_rules.sections.tiers.items.benefactor',
      ],
      icon: Icons.workspace_premium_outlined,
      accent: _GiftRulesPalette.accentPurple,
    ),
    _GiftRulesSection(
      titleKey: 'gift_rules.sections.rules.title',
      subtitleKey: 'gift_rules.sections.rules.subtitle',
      itemKeys: [
        'gift_rules.sections.rules.items.non_refundable',
        'gift_rules.sections.rules.items.active_artists',
        'gift_rules.sections.rules.items.daily_limit',
        'gift_rules.sections.rules.items.account_age',
        'gift_rules.sections.rules.items.verification',
      ],
      icon: Icons.rule_folder_outlined,
      accent: _GiftRulesPalette.accentPink,
    ),
    _GiftRulesSection(
      titleKey: 'gift_rules.sections.credits.title',
      subtitleKey: 'gift_rules.sections.credits.subtitle',
      itemKeys: [
        'gift_rules.sections.credits.items.in_app',
        'gift_rules.sections.credits.items.subscriptions',
        'gift_rules.sections.credits.items.ads',
        'gift_rules.sections.credits.items.engagement',
        'gift_rules.sections.credits.items.direct_support',
      ],
      icon: Icons.credit_score_outlined,
      accent: _GiftRulesPalette.accentGreen,
    ),
    _GiftRulesSection(
      titleKey: 'gift_rules.sections.guidelines.title',
      subtitleKey: 'gift_rules.sections.guidelines.subtitle',
      itemKeys: [
        'gift_rules.sections.guidelines.items.no_soliciting',
        'gift_rules.sections.guidelines.items.no_off_platform',
        'gift_rules.sections.guidelines.items.respectful_messages',
        'gift_rules.sections.guidelines.items.report',
      ],
      icon: Icons.groups_2_outlined,
      accent: _GiftRulesPalette.accentPink,
    ),
    _GiftRulesSection(
      titleKey: 'gift_rules.sections.security.title',
      subtitleKey: 'gift_rules.sections.security.subtitle',
      itemKeys: [
        'gift_rules.sections.security.items.apple_pay',
        'gift_rules.sections.security.items.history',
        'gift_rules.sections.security.items.monitoring',
        'gift_rules.sections.security.items.policy',
      ],
      icon: Icons.lock_clock_outlined,
      accent: _GiftRulesPalette.accentYellow,
    ),
  ];
}

class _GiftRulesStatChip extends StatelessWidget {
  const _GiftRulesStatChip({required this.stat});

  final _GiftRulesStat stat;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: stat.accent.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(stat.icon, color: stat.accent, size: 20),
            const SizedBox(height: 12),
            Text(
              stat.valueKey.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _GiftRulesPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat.labelKey.tr().toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: _GiftRulesPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftRulesSectionCard extends StatelessWidget {
  const _GiftRulesSectionCard({required this.section});

  final _GiftRulesSection section;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: section.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Icon(section.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.titleKey.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _GiftRulesPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      section.subtitleKey.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: _GiftRulesPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            section.itemKeys.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index == section.itemKeys.length - 1 ? 0 : 12,
              ),
              child: _GiftRulesBullet(
                textKey: section.itemKeys[index],
                accent: section.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftRulesBullet extends StatelessWidget {
  const _GiftRulesBullet({required this.textKey, required this.accent});

  final String textKey;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                accent,
                _GiftRulesPalette.accentTeal,
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            textKey.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: _GiftRulesPalette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
