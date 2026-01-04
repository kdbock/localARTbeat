import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:artbeat_core/artbeat_core.dart' hide NumberFormat;

import '../../models/commission_template_model.dart';
import '../../services/commission_template_service.dart';
import '../../widgets/widgets.dart';

class CommissionTemplatesBrowser extends StatefulWidget {
  final String? artistId;
  final void Function(CommissionTemplate)? onTemplateSelected;

  const CommissionTemplatesBrowser({
    super.key,
    this.artistId,
    this.onTemplateSelected,
  });

  @override
  State<CommissionTemplatesBrowser> createState() =>
      _CommissionTemplatesBrowserState();
}

class _CommissionTemplatesBrowserState extends State<CommissionTemplatesBrowser>
    with SingleTickerProviderStateMixin {
  late CommissionTemplateService _templateService;
  late TabController _tabController;
  late Future<List<CommissionTemplate>> _featuredTemplatesFuture;

  List<CommissionTemplate> _templates = [];
  List<CommissionTemplate> _filteredTemplates = [];
  bool _isLoading = true;
  String _selectedCategory = '';
  String _searchQuery = '';

  final List<_TemplateCategory> _categoryOptions = const [
    _TemplateCategory(value: '', labelKey: 'commission_templates_category_all'),
    _TemplateCategory(
      value: 'portrait',
      labelKey: 'commission_templates_category_portrait',
    ),
    _TemplateCategory(
      value: 'landscape',
      labelKey: 'commission_templates_category_landscape',
    ),
    _TemplateCategory(
      value: 'character',
      labelKey: 'commission_templates_category_character',
    ),
    _TemplateCategory(
      value: 'digital',
      labelKey: 'commission_templates_category_digital',
    ),
    _TemplateCategory(
      value: 'commercial',
      labelKey: 'commission_templates_category_commercial',
    ),
    _TemplateCategory(
      value: 'other',
      labelKey: 'commission_templates_category_other',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _templateService = CommissionTemplateService();
    _tabController = TabController(length: 2, vsync: this);
    _featuredTemplatesFuture = _templateService.getFeaturedTemplates();
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = await _templateService.getPublicTemplates();
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _filteredTemplates = templates;
        _isLoading = false;
        _featuredTemplatesFuture = _templateService.getFeaturedTemplates();
      });
    } catch (e) {
      AppLogger.error('Failed to load templates: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('commission_templates_load_error',
              namedArgs: {'error': e.toString()},
            ),
          ),
        ),
      );
    }
  }

  Future<void> _refreshFeatured() {
    final future = _templateService.getFeaturedTemplates();
    setState(() {
      _featuredTemplatesFuture = future;
    });
    return future.then((_) {}).catchError((_) {});
  }

  void _filterTemplates() {
    var filtered = _templates;

    if (_selectedCategory.isNotEmpty) {
      filtered = filtered
          .where((t) => t.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (t) =>
                t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    setState(() => _filteredTemplates = filtered);
  }

  void _onTemplateSelected(CommissionTemplate template) {
    if (widget.onTemplateSelected != null) {
      widget.onTemplateSelected!(template);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: tr('commission_templates_app_bar'),
        glassBackground: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: tr('commission_templates_refresh_tooltip'),
            onPressed: _isLoading ? null : _loadTemplates,
          ),
        ], subtitle: '',
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 16),
            child: Column(
              children: [
                _buildHeroCard(),
                const SizedBox(height: 16),
                Expanded(
                  child: GlassPanel(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('commission_templates_panel_title'),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _TemplatesPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr('commission_templates_panel_subtitle'),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _TemplatesPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTabSelector(),
                        const SizedBox(height: 16),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [_buildBrowseTab(), _buildFeaturedTab()],
                          ),
                        ),
                      ],
                    ),
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
      accentColor: _TemplatesPalette.purpleAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('commission_templates_hero_badge'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _TemplatesPalette.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('commission_templates_hero_title'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _TemplatesPalette.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('commission_templates_hero_subtitle'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _TemplatesPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GradientCTAButton(
                  text: tr('commission_templates_hero_primary_cta'),
                  icon: Icons.auto_awesome,
                  onPressed: () => _tabController.animateTo(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: HudButton.secondary(
                  onPressed: _isLoading ? null : _loadTemplates,
                  text: tr('commission_templates_hero_secondary_cta'),
                  icon: Icons.refresh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        labelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        tabs: [
          Tab(text: tr('commission_templates_tab_browse')),
          Tab(text: tr('commission_templates_tab_featured')),
        ],
      ),
    );
  }

  Widget _buildBrowseTab() {
    final children = <Widget>[_buildFiltersCard(), const SizedBox(height: 16)];

    if (_filteredTemplates.isEmpty) {
      children.add(
        _buildEmptyState(
          icon: Icons.search_off,
          title: tr('commission_templates_empty_title'),
          subtitle: tr('commission_templates_empty_subtitle'),
          actionLabel: tr('commission_templates_empty_cta'),
          onActionTap: () {
            setState(() {
              _selectedCategory = '';
              _searchQuery = '';
              _filteredTemplates = _templates;
            });
          },
        ),
      );
    } else {
      children.addAll(_filteredTemplates.map(_buildTemplateCard));
    }

    return RefreshIndicator(
      color: _TemplatesPalette.purpleAccent,
      onRefresh: _loadTemplates,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: children,
      ),
    );
  }

  Widget _buildFeaturedTab() {
    return FutureBuilder<List<CommissionTemplate>>(
      future: _featuredTemplatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: _TemplatesPalette.purpleAccent,
            ),
          );
        }

        if (snapshot.hasError) {
          return RefreshIndicator(
            color: _TemplatesPalette.purpleAccent,
            onRefresh: _refreshFeatured,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                _buildEmptyState(
                  icon: Icons.error_outline,
                  title: tr('commission_templates_featured_error_title'),
                  subtitle: tr('commission_templates_featured_error_subtitle'),
                  actionLabel: tr('commission_templates_featured_error_cta'),
                  onActionTap: _refreshFeatured,
                ),
              ],
            ),
          );
        }

        final templates = snapshot.data ?? [];

        if (templates.isEmpty) {
          return RefreshIndicator(
            color: _TemplatesPalette.purpleAccent,
            onRefresh: _refreshFeatured,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                _buildEmptyState(
                  icon: Icons.star_outline,
                  title: tr('commission_templates_featured_empty_title'),
                  subtitle: tr('commission_templates_featured_empty_subtitle'),
                  actionLabel: tr('commission_templates_featured_empty_cta'),
                  onActionTap: _refreshFeatured,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: _TemplatesPalette.purpleAccent,
          onRefresh: _refreshFeatured,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: templates.length,
            itemBuilder: (context, index) =>
                _buildTemplateCard(templates[index]),
          ),
        );
      },
    );
  }

  Widget _buildFiltersCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('commission_templates_filters_title'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _TemplatesPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('commission_templates_filters_subtitle'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _TemplatesPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          GlassTextField(
            hintText: tr('commission_templates_search_hint'),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _filterTemplates();
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemBuilder: (context, index) =>
                  _buildCategoryPill(_categoryOptions[index]),
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemCount: _categoryOptions.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(_TemplateCategory category) {
    final isSelected = _selectedCategory == category.value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category.value);
        _filterTemplates();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7C4DFF),
                    Color(0xFF22D3EE),
                    Color(0xFF34D399),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: Colors.white.withValues(alpha: isSelected ? 0.3 : 0.16),
          ),
        ),
        child: Text(
          category.labelKey.tr(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(CommissionTemplate template) {
    final priceLabel = intl.NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    ).format(template.basePrice);
    final deliveryLabel = tr('commission_templates_delivery_days_label',
      namedArgs: {'days': template.estimatedDays.toString()},
    );
    final usageLabel = tr('commission_templates_usage_count',
      namedArgs: {'count': template.useCount.toString()},
    );

    return GestureDetector(
      onTap: () => _onTemplateSelected(template),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreviewImage(template),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              template.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _TemplatesPalette.textPrimary,
                              ),
                            ),
                          ),
                          if (template.avgRating > 0)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFC857),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  template.avgRating.toStringAsFixed(1),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _TemplatesPalette.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        template.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _TemplatesPalette.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            priceLabel,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _TemplatesPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Text(
                              deliveryLabel,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _TemplatesPalette.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (template.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: template.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _TemplatesPalette.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  usageLabel,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _TemplatesPalette.textTertiary,
                  ),
                ),
                const Spacer(),
                GradientCTAButton(
                  text: tr('commission_templates_card_cta'),
                  icon: Icons.check_circle_outline,
                  height: 48,
                  onPressed: () => _onTemplateSelected(template),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewImage(CommissionTemplate template) {
    const double size = 96;
    if (template.imageUrl != null && template.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          template.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackPreview(),
        ),
      );
    }
    return _buildFallbackPreview();
  }

  Widget _buildFallbackPreview() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Icon(Icons.palette, color: Colors.white54, size: 32),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _TemplatesPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _TemplatesPalette.textSecondary,
              height: 1.4,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            HudButton.primary(onPressed: onActionTap, text: actionLabel),
          ],
        ],
      ),
    );
  }
}

class _TemplatesPalette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x73FFFFFF);
  static const Color purpleAccent = Color(0xFF7C4DFF);
}

class _TemplateCategory {
  final String value;
  final String labelKey;

  const _TemplateCategory({required this.value, required this.labelKey});
}
