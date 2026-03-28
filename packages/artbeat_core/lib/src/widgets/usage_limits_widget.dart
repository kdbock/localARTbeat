import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/usage_tracking_service.dart';

/// Widget to display usage statistics and limits following 2025 industry standards
/// Shows progress bars, warnings, and upgrade prompts for better UX
class UsageLimitsWidget extends StatefulWidget {
  final String userId;
  final bool showUpgradePrompt;
  final VoidCallback? onUpgradePressed;

  const UsageLimitsWidget({
    super.key,
    required this.userId,
    this.showUpgradePrompt = true,
    this.onUpgradePressed,
  });

  @override
  State<UsageLimitsWidget> createState() => _UsageLimitsWidgetState();
}

class _UsageLimitsWidgetState extends State<UsageLimitsWidget> {
  late UsageTrackingService _usageService;
  Map<String, dynamic>? _usageStats;
  bool _isLoading = true;
  double _overageCost = 0.0;

  @override
  void initState() {
    super.initState();
    _usageService = context.read<UsageTrackingService>();
    _loadUsageStats();
  }

  Future<void> _loadUsageStats() async {
    setState(() => _isLoading = true);

    try {
      final stats = await _usageService.getUsageStats(widget.userId);
      final overage = await _usageService.calculateOverageCosts(widget.userId);

      if (mounted) {
        setState(() {
          _usageStats = stats;
          _overageCost = overage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_usageStats == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildUsageItem('artworks', 'Artworks', Icons.palette),
            const SizedBox(height: 12),
            _buildUsageItem('aiCredits', 'AI Credits', Icons.auto_awesome),
            const SizedBox(height: 12),
            _buildUsageItem('teamMembers', 'Team Members', Icons.group),
            const SizedBox(height: 12),
            _buildStorageUsage(),
            if (_overageCost > 0) ...[
              const SizedBox(height: 16),
              _buildOverageWarning(),
            ],
            if (widget.showUpgradePrompt && _shouldShowUpgradePrompt()) ...[
              const SizedBox(height: 16),
              _buildUpgradePrompt(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final subscription = _usageStats!['subscription'] as String;

    return Row(
      children: [
        Icon(Icons.analytics_outlined, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          'Usage Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            subscription,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageItem(String key, String label, IconData icon) {
    final item = _usageStats![key] as Map<String, dynamic>;
    final used = item['used'] as int;
    final limit = item['limit'] as int;
    final percentage = item['percentage'] as double;
    final approachingLimit = item['approaching_limit'] as bool;
    final unlimited = item['unlimited'] as bool;

    Color progressColor = Colors.green;
    if (approachingLimit) {
      progressColor = Colors.orange;
    }
    if (percentage >= 1.0) {
      progressColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              unlimited ? '$used (Unlimited)' : '$used / $limit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: approachingLimit ? Colors.orange : null,
                fontWeight: approachingLimit ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!unlimited) ...[
          LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          if (approachingLimit) ...[
            const SizedBox(height: 4),
            const Text(
              'Approaching limit',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (percentage > 1.0) ...[
            const SizedBox(height: 4),
            const Text(
              'Over limit - overage charges apply',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ] else ...[
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Unlimited',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStorageUsage() {
    final storage = _usageStats!['storage'] as Map<String, dynamic>;
    final usedGB = double.parse(storage['used_gb'] as String);
    final limitGB = storage['limit_gb'] as dynamic;
    final unlimited = storage['unlimited'] as bool;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.storage, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Storage',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              unlimited
                  ? '${usedGB}GB (Unlimited)'
                  : '${usedGB}GB / ${limitGB}GB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!unlimited) ...[
          LinearProgressIndicator(
            value: (limitGB is num && limitGB > 0)
                ? (usedGB / limitGB).clamp(0.0, 1.0)
                : 0.0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              (limitGB is num && usedGB / limitGB > 0.8)
                  ? Colors.orange
                  : Colors.green,
            ),
          ),
        ] else ...[
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Unlimited',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOverageWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overage Charges',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Additional charges this month: \$${_overageCost.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Need More?',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Upgrade your plan for higher limits and unlimited features',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onUpgradePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Upgrade Plan'),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowUpgradePrompt() {
    if (_usageStats == null) return false;

    // Show upgrade prompt if any feature is approaching limit or over limit
    for (final key in ['artworks', 'aiCredits', 'teamMembers']) {
      final item = _usageStats![key] as Map<String, dynamic>;
      final approachingLimit = item['approaching_limit'] as bool;
      final percentage = item['percentage'] as double;

      if (approachingLimit || percentage >= 1.0) {
        return true;
      }
    }

    return false;
  }
}
