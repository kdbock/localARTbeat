import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';

class DashboardEventsSection extends StatelessWidget {
  final DashboardViewModel viewModel;

  const DashboardEventsSection({Key? key, required this.viewModel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context),
            const SizedBox(height: 16),
            _buildEventsContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: ArtbeatColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.event, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'dashboard_events_title',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              Text(
                'dashboard_events_subtitle',
                style: TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/events'),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsContent(BuildContext context) {
    if (viewModel.isLoadingEvents) {
      return _buildLoadingState();
    }

    if (viewModel.eventsError != null) {
      return _buildErrorState();
    }

    final events = viewModel.events;

    if (events.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 12,
              right: index == events.length - 1 ? 0 : 0,
            ),
            child: _buildEventCard(context, event),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 12),
            child: _buildSkeletonCard(),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: ArtbeatColors.textSecondary,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Unable to load events',
              style: TextStyle(color: ArtbeatColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_outlined,
              color: ArtbeatColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'No upcoming events',
              style: TextStyle(
                color: ArtbeatColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back soon for art events!',
              style: TextStyle(color: ArtbeatColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/events/create'),
              icon: const Icon(Icons.add, size: 16),
              label: Text('dashboard_create_event'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/events/detail',
            arguments: {'eventId': event.id},
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Event image (if available and valid)
                if (_isValidImageUrl(event.imageUrl))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FadeInImage(
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: const AssetImage(
                        'assets/default_profile.png',
                      ),
                      image:
                          ImageUrlValidator.safeNetworkImage(event.imageUrl) ??
                          const AssetImage('assets/default_profile.png')
                              as ImageProvider,
                      imageErrorBuilder: (context, error, stackTrace) {
                        AppLogger.error('Error loading event image: $error');
                        return Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: ArtbeatColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.event,
                            color: ArtbeatColors.textSecondary,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ArtbeatColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: ArtbeatColors.textSecondary,
                      size: 32,
                    ),
                  ),

                const SizedBox(height: 6),

                // Date badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatEventDate(event.startDate),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ArtbeatColors.error,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Event title
                Text(
                  event.title.isNotEmpty ? event.title : 'Untitled Event',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ArtbeatColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                // Location
                if (event.location.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: ArtbeatColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ArtbeatColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],

                // Description
                if (event.description.isNotEmpty) ...[
                  Flexible(
                    child: Text(
                      event.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: ArtbeatColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Attendees count and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 12,
                          color: ArtbeatColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.attendeeIds.length} attending',
                          style: const TextStyle(
                            fontSize: 11,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (event.price != null && (event.price ?? 0) > 0)
                      Text(
                        '\$${(event.price ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.primaryGreen,
                        ),
                      )
                    else
                      const Text(
                        'Free',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.primaryGreen,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(ArtbeatColors.error),
        ),
      ),
    );
  }

  String _formatEventDate(DateTime? date) {
    if (date == null) return 'TBD';

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return '${difference}d away';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    // Check if it's a valid HTTP/HTTPS URL
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Must have http or https scheme
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }

    // Must have a host
    if (!uri.hasAuthority || uri.host.isEmpty) {
      return false;
    }

    // Avoid localhost and placeholder URLs
    if (uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host.contains('placeholder') ||
        url.contains('placeholder_url_')) {
      return false;
    }

    return true;
  }
}
