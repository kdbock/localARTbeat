import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../theme/artbeat_colors.dart';

/// "Are you an artist?" Call-to-Action widget
///
/// This widget appears at the bottom of dashboard screens to encourage
/// non-artist users to explore subscription options and become artists.
/// It's the entry point to the subscription process.
class ArtistCTAWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final bool showDismiss;

  const ArtistCTAWidget({super.key, this.onTap, this.showDismiss = true});

  @override
  State<ArtistCTAWidget> createState() => _ArtistCTAWidgetState();
}

class _ArtistCTAWidgetState extends State<ArtistCTAWidget> {
  static const String _dismissedKey = 'artist_cta_dismissed';
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadDismissedState();
  }

  Future<void> _loadDismissedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _isDismissed = prefs.getBool(_dismissedKey) ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading artist CTA dismissed state: $e');
    }
  }

  Future<void> _dismissCTA() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dismissedKey, true);
      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
      }
    } catch (e) {
      debugPrint('Error dismissing artist CTA: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if dismissed
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<UserModel?>(
      future: UserService().getCurrentUserModel(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final user = snapshot.data!;

        // Don't show if user is already an artist
        if (user.userType == 'artist' || user.userType == 'gallery') {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ArtbeatColors.primary.withValues(alpha: 0.1),
                ArtbeatColors.accentOrange.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ArtbeatColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap ?? () => _navigateToSubscription(context),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with optional dismiss button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ArtbeatColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.palette_outlined,
                            color: ArtbeatColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Are you an artist?',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: ArtbeatColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Turn your passion into profit',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: ArtbeatColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.showDismiss)
                          IconButton(
                            onPressed: _dismissCTA,
                            icon: const Icon(
                              Icons.close,
                              color: ArtbeatColors.textSecondary,
                              size: 20,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Features row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeature(
                          icon: Icons.card_giftcard_outlined,
                          text: 'Receive boosts',
                        ),
                        _buildFeature(
                          icon: Icons.attach_money_outlined,
                          text: 'Get sponsored',
                        ),
                        _buildFeature(
                          icon: Icons.work_outline,
                          text: 'Commissions',
                        ),
                        _buildFeature(
                          icon: Icons.trending_up_outlined,
                          text: 'Earn income',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            widget.onTap ??
                            () => _navigateToSubscription(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtbeatColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Get Started - From \$4.99/month',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: Text(
                        'Join artists earning through boosts, sponsorships & commissions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeature({required IconData icon, required String text}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: ArtbeatColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: ArtbeatColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _navigateToSubscription(BuildContext context) {
    Navigator.of(context).pushNamed('/subscription/plans');
  }
}

/// Compact version of the artist CTA for smaller spaces
class CompactArtistCTAWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const CompactArtistCTAWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: UserService().getCurrentUserModel(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final user = snapshot.data!;

        // Don't show if user is already an artist
        if (user.userType == 'artist' || user.userType == 'gallery') {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ArtbeatColors.primary.withValues(alpha: 0.1),
                ArtbeatColors.accentOrange.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ArtbeatColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () => _navigateToSubscription(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.palette_outlined,
                      color: ArtbeatColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Are you an artist?',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: ArtbeatColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            'Start selling your art today',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: ArtbeatColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ArtbeatColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Start',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToSubscription(BuildContext context) {
    Navigator.of(context).pushNamed('/subscription/plans');
  }
}
