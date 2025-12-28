import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TurnByTurnNavigationWidget extends StatefulWidget {
  final ArtWalkNavigationService navigationService;
  final VoidCallback? onNextStep;
  final VoidCallback? onPreviousStep;
  final VoidCallback? onStopNavigation;
  final VoidCallback? onCompleteWalk;
  final bool isCompact;

  const TurnByTurnNavigationWidget({
    super.key,
    required this.navigationService,
    this.onNextStep,
    this.onPreviousStep,
    this.onStopNavigation,
    this.onCompleteWalk,
    this.isCompact = false,
  });

  @override
  State<TurnByTurnNavigationWidget> createState() =>
      _TurnByTurnNavigationWidgetState();
}

class _TurnByTurnNavigationWidgetState extends State<TurnByTurnNavigationWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  NavigationUpdate? _lastUpdate;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<NavigationUpdate>(
      stream: widget.navigationService.navigationUpdates,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildShell(
            _StatusMessage(
              icon: Icons.error_outline,
              title:
                  'art_walk_turn_by_turn_navigation_widget_error_navigation_error'
                      .tr()
                      .replaceAll('{error}', snapshot.error.toString()),
            ),
          );
        }

        if (!snapshot.hasData) {
          return _buildShell(
            _StatusMessage(
              icon: Icons.my_location,
              title:
                  'art_walk_turn_by_turn_navigation_widget_text_loading_navigation'
                      .tr(),
              isLoading: true,
            ),
          );
        }

        _lastUpdate = snapshot.data!;
        final update = _lastUpdate!;
        return widget.isCompact
            ? _buildCompactView(update)
            : _buildFullView(update);
      },
    );
  }

  Widget _buildShell(Widget child, {EdgeInsets? padding, double radius = 32}) {
    return WorldBackground(
      withBlobs: false,
      child: GlassCard(
        borderRadius: radius,
        padding: padding ?? const EdgeInsets.all(24),
        child: child,
      ),
    );
  }

  Widget _buildCompactView(NavigationUpdate update) {
    return _buildShell(
      Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      update.currentStep?.maneuverIcon ?? '⬆️',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.currentStep?.cleanInstruction ??
                      'art_walk_turn_by_turn_navigation_widget_text_loading_navigation'
                          .tr(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(),
                ),
                const SizedBox(height: 8),
                if (update.distanceToNextWaypoint != null)
                  Text(
                    'art_walk_turn_by_turn_navigation_widget_label_distance'.tr(
                      namedArgs: {
                        'meters': update.distanceToNextWaypoint!
                            .round()
                            .toString(),
                      },
                    ),
                    style: AppTypography.helper(),
                  ),
              ],
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      radius: 28,
    );
  }

  Widget _buildFullView(NavigationUpdate update) {
    final routeCompleted = _isRouteCompleted(update);
    final progressPercent = (update.routeProgress * 100).clamp(0, 100).toInt();

    return _buildShell(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'art_walk_turn_by_turn_navigation_widget_title'.tr(),
                style: AppTypography.screenTitle(),
              ),
              const Spacer(),
              if (widget.onStopNavigation != null)
                _SmallGlassButton(
                  icon: routeCompleted ? Icons.flag : Icons.close,
                  onTap: widget.onStopNavigation!,
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: update.routeProgress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF22D3EE)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'art_walk_turn_by_turn_navigation_widget_label_progress'.tr(
              namedArgs: {'percent': progressPercent.toString()},
            ),
            style: AppTypography.helper(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          update.currentStep?.maneuverIcon ?? '⬆️',
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.currentStep?.cleanInstruction ??
                          'art_walk_turn_by_turn_navigation_widget_text_loading_navigation'
                              .tr(),
                      style: AppTypography.body(),
                    ),
                    const SizedBox(height: 12),
                    if (update.distanceToNextWaypoint != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.straighten,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'art_walk_turn_by_turn_navigation_widget_label_distance'
                                .tr(
                                  namedArgs: {
                                    'meters': update.distanceToNextWaypoint!
                                        .round()
                                        .toString(),
                                  },
                                ),
                            style: AppTypography.helper(),
                          ),
                        ],
                      ),
                    if (update.currentStep != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            update.currentStep!.formattedDuration,
                            style: AppTypography.helper(),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (update.isOffRoute) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.orange.withValues(alpha: 0.15),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'art_walk_turn_by_turn_navigation_widget_text_off_route'
                          .tr(),
                      style: AppTypography.body(Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_hasNextStep(update)) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Text(
                    _getNextStep(update)?.maneuverIcon ?? '⬆️',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'art_walk_turn_by_turn_navigation_widget_text_next_step'
                              .tr(),
                          style: AppTypography.helper(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getNextStep(update)?.cleanInstruction ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.onPreviousStep != null && !routeCompleted)
                Expanded(
                  child: _DisabledAwareButton(
                    enabled: widget.onPreviousStep != null,
                    child: GlassSecondaryButton(
                      label:
                          'art_walk_turn_by_turn_navigation_widget_button_previous'
                              .tr(),
                      icon: Icons.skip_previous,
                      onTap: widget.onPreviousStep!,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (widget.onPreviousStep != null && !routeCompleted)
                const SizedBox(width: 12),
              if (widget.onStopNavigation != null && !routeCompleted)
                Expanded(
                  child: GlassSecondaryButton(
                    label: 'art_walk_turn_by_turn_navigation_widget_button_stop'
                        .tr(),
                    icon: Icons.stop_circle,
                    onTap: widget.onStopNavigation!,
                  ),
                ),
            ],
          ),
          if ((widget.onPreviousStep != null && !routeCompleted) ||
              (widget.onStopNavigation != null && !routeCompleted))
            const SizedBox(height: 16),
          GradientCTAButton(
            label: routeCompleted
                ? 'art_walk_turn_by_turn_navigation_widget_button_complete'.tr()
                : 'art_walk_turn_by_turn_navigation_widget_button_next'.tr(),
            icon: routeCompleted ? Icons.flag : Icons.skip_next,
            onPressed: routeCompleted
                ? widget.onCompleteWalk
                : widget.onNextStep,
          ),
        ],
      ),
    );
  }

  bool _hasNextStep(NavigationUpdate update) {
    if (update.currentSegment == null || update.currentStep == null) {
      return false;
    }
    final segment = update.currentSegment!;
    final index = segment.steps.indexOf(update.currentStep!);
    return index >= 0 && index < segment.steps.length - 1;
  }

  NavigationStepModel? _getNextStep(NavigationUpdate update) {
    if (!_hasNextStep(update)) return null;
    final segment = update.currentSegment!;
    final index = segment.steps.indexOf(update.currentStep!);
    return segment.steps[index + 1];
  }

  bool _isRouteCompleted(NavigationUpdate update) {
    return update.type == NavigationUpdateType.routeCompleted;
  }
}

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isLoading;

  const _StatusMessage({
    required this.icon,
    required this.title,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: isLoading
              ? const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF22D3EE)),
                )
              : Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 24,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: AppTypography.body())),
      ],
    );
  }
}

class _SmallGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallGlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _DisabledAwareButton extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const _DisabledAwareButton({required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) {
    if (enabled) return child;
    return Opacity(opacity: 0.35, child: IgnorePointer(child: child));
  }
}
