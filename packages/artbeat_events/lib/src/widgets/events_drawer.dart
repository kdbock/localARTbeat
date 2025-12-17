import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';

/// Events navigation drawer with user profile and event-specific navigation options
class EventsDrawer extends StatefulWidget {
  const EventsDrawer({super.key});

  @override
  State<EventsDrawer> createState() => _EventsDrawerState();
}

class _EventsDrawerState extends State<EventsDrawer> {
  UserModel? _currentUser;
  bool _isLoading = true;
  List<ArtbeatEvent> _userEvents = [];
  List<ArtbeatEvent> _upcomingEvents = [];

  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUserEvents();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _currentUser = UserModel.fromFirestore(userDoc);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } on Exception catch (e) {
      AppLogger.error('Error loading current user: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserEvents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userEvents = await _eventService.getEventsByArtist(user.uid);
        final upcomingEvents = await _eventService.getUpcomingPublicEvents(
          limit: 5,
        );

        if (mounted) {
          setState(() {
            _userEvents = userEvents;
            _upcomingEvents = upcomingEvents;
          });
        }
      }
    } on Exception catch (e) {
      AppLogger.error('Error loading user events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ArtbeatColors.primaryPurple,
                ArtbeatColors.primaryGreen,
                Colors.white,
              ],
              stops: [0.0, 0.3, 0.3],
            ),
          ),
          child: Column(
            children: [
              // User profile header
              _buildUserProfileHeader(),

              // Navigation items
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerItem(
                        icon: Icons.home,
                        title: 'events_drawer_home'.tr(),
                        onTap: () => _navigateToScreen(context, '/dashboard'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.search,
                        title: 'events_drawer_search'.tr(),
                        onTap: () =>
                            _navigateToScreen(context, '/events/search'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.message,
                        title: 'events_drawer_messages'.tr(),
                        onTap: () => _navigateToScreen(context, '/messaging'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.person,
                        title: 'events_drawer_profile'.tr(),
                        onTap: () => _navigateToScreen(context, '/profile'),
                      ),
                      const Divider(),
                      _buildDrawerItem(
                        icon: Icons.event,
                        title: 'events_drawer_events_dashboard'.tr(),
                        onTap: () =>
                            _navigateToScreen(context, '/events/dashboard'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.add_circle,
                        title: 'events_drawer_create_event'.tr(),
                        onTap: () =>
                            _navigateToScreen(context, '/events/create'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.event_note,
                        title: 'events_drawer_my_events'.tr(),
                        onTap: () =>
                            _navigateToScreen(context, '/events/my-events'),
                        badge: _userEvents.isNotEmpty
                            ? _userEvents.length.toString()
                            : null,
                      ),
                      _buildDrawerItem(
                        icon: Icons.confirmation_number,
                        title: 'events_drawer_my_tickets'.tr(),
                        onTap: () =>
                            _navigateToScreen(context, '/events/my-tickets'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.calendar_today,
                        title: 'events_drawer_calendar'.tr(),
                        onTap: () => _navigateToScreen(
                          context,
                          '/events/dashboard',
                        ), // Redirect to dashboard for now
                      ),
                      _buildDrawerItem(
                        icon: Icons.location_on,
                        title: 'events_drawer_nearby_events'.tr(),
                        onTap: () => _navigateToScreen(
                          context,
                          '/events/discover',
                        ), // Use discover route
                      ),
                      const Divider(),
                      _buildDrawerItem(
                        icon: Icons.notifications,
                        title: 'events_drawer_notifications'.tr(),
                        onTap: () =>
                            _navigateToScreen(context, '/notifications'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.settings,
                        title: 'events_drawer_settings'.tr(),
                        onTap: () => _navigateToScreen(context, '/settings'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.help,
                        title: 'events_drawer_help'.tr(),
                        onTap: () => _navigateToScreen(context, '/support'),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer with version info
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Text(
                  'events_drawer_version'.tr(),
                  style: const TextStyle(
                    color: ArtbeatColors.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      child: Column(
        children: [
          // User avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ArtbeatColors.primaryPurple,
                    ),
                  )
                : _currentUser?.profileImageUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _currentUser!.profileImageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        size: 40,
                        color: ArtbeatColors.primaryPurple,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 40,
                    color: ArtbeatColors.primaryPurple,
                  ),
          ),

          const SizedBox(height: 12),

          // User name
          Text(
            _isLoading
                ? 'events_drawer_loading'.tr()
                : _currentUser?.fullName ?? 'events_drawer_event_attendee'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // User role/status
          Text(
            _isLoading ? '' : _getUserRoleText(),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Quick stats
          if (!_isLoading && _currentUser != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip(
                  '${_userEvents.length}',
                  'events_drawer_my_events_stat'.tr(),
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  '${_upcomingEvents.length}',
                  'events_drawer_upcoming_stat'.tr(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _getUserRoleText() {
    if (_currentUser == null) return 'events_drawer_attendee'.tr();

    final userType = _currentUser!.userType;
    if (userType == null) return 'events_drawer_event_attendee'.tr();

    switch (userType) {
      case 'artist':
        return 'events_drawer_event_artist'.tr();
      case 'business':
        return 'events_drawer_event_organizer'.tr();
      case 'moderator':
        return 'events_drawer_event_moderator'.tr();
      case 'admin':
        return 'events_drawer_event_admin'.tr();
      default:
        return 'events_drawer_event_attendee'.tr();
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
  }) {
    return ListTile(
      leading: Icon(icon, color: ArtbeatColors.primaryPurple),
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ArtbeatColors.textPrimary,
              fontSize: 16,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _navigateToScreen(BuildContext context, String routeName) {
    Navigator.pop(context); // Close drawer
    Navigator.pushNamed(context, routeName);
  }
}
