// Local ARTbeat — EventsDrawer theme refresh (matches the new “glass + neon” design used in EventsDashboardScreen)
//
// Drop-in replace this whole file.
// Notes:
// ✅ Same routes + logic
// ✅ Dark glass header + dark list area (no harsh white block)
// ✅ Gradient icon chips + pill items + badge pill
// ✅ Optional “Upcoming Events” preview section (kept lightweight, easy to remove)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';

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
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!mounted) return;

        if (userDoc.exists) {
          setState(() {
            _currentUser = UserModel.fromFirestore(userDoc);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error loading current user: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserEvents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userEvents = await _eventService.getEventsByArtist(user.uid);
        final upcomingEvents = await _eventService.getUpcomingPublicEvents(limit: 5);

        if (!mounted) return;
        setState(() {
          _userEvents = userEvents;
          _upcomingEvents = upcomingEvents;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading user events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF070A12),
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF05060A),
                Color(0xFF0B1220),
                Color(0xFF05060A),
              ],
            ),
          ),
          child: Column(
            children: [
              // Header (glass)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: _Glass(
                  radius: 22,
                  blur: 18,
                  fillAlpha: 0.08,
                  borderAlpha: 0.14,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF7C4DFF).withValues(alpha: 0.20),
                          const Color(0xFF22D3EE).withValues(alpha: 0.12),
                          const Color(0xFF34D399).withValues(alpha: 0.10),
                        ],
                      ),
                    ),
                    child: _buildUserProfileHeader(),
                  ),
                ),
              ),

              // Nav section (glass list)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: _Glass(
                    radius: 22,
                    blur: 16,
                    fillAlpha: 0.06,
                    borderAlpha: 0.12,
                    shadow: false,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                      children: [
                        _sectionLabel('events_drawer_section_main'.tr(), fallback: 'Main'),
                        _NavItem(
                          icon: Icons.home,
                          title: 'events_drawer_home'.tr(),
                          onTap: () => _navigateToScreen(context, '/dashboard'),
                        ),
                        _NavItem(
                          icon: Icons.search,
                          title: 'events_drawer_search'.tr(),
                          onTap: () => _navigateToScreen(context, '/events/search'),
                        ),
                        _NavItem(
                          icon: Icons.message,
                          title: 'events_drawer_messages'.tr(),
                          onTap: () => _navigateToScreen(context, '/messaging'),
                        ),
                        _NavItem(
                          icon: Icons.person,
                          title: 'events_drawer_profile'.tr(),
                          onTap: () => _navigateToScreen(context, '/profile'),
                        ),

                        const SizedBox(height: 10),
                        _divider(),

                        _sectionLabel('events_drawer_section_events'.tr(), fallback: 'Events'),
                        _NavItem(
                          icon: Icons.event,
                          title: 'events_drawer_events_dashboard'.tr(),
                          onTap: () => _navigateToScreen(context, '/events/dashboard'),
                        ),
                        _NavItem(
                          icon: Icons.add_circle,
                          title: 'events_drawer_create_event'.tr(),
                          onTap: () => _navigateToScreen(context, '/events/create'),
                          gradient: const [Color(0xFFFF3D8D), Color(0xFF7C4DFF)],
                        ),
                        _NavItem(
                          icon: Icons.event_note,
                          title: 'events_drawer_my_events'.tr(),
                          badge: _userEvents.isNotEmpty ? _userEvents.length.toString() : null,
                          onTap: () => _navigateToScreen(context, '/events/my-events'),
                        ),
                        _NavItem(
                          icon: Icons.confirmation_number,
                          title: 'events_drawer_my_tickets'.tr(),
                          onTap: () => _navigateToScreen(context, '/events/my-tickets'),
                        ),
                        _NavItem(
                          icon: Icons.calendar_today,
                          title: 'events_drawer_calendar'.tr(),
                          onTap: () => _navigateToScreen(context, '/events/dashboard'),
                        ),
                        _NavItem(
                          icon: Icons.location_on,
                          title: 'events_drawer_nearby_events'.tr(),
                          onTap: () => _navigateToScreen(context, '/events/discover'),
                          gradient: const [Color(0xFF34D399), Color(0xFF22D3EE)],
                        ),

                        if (_upcomingEvents.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _divider(),
                          _sectionLabel(
                            'events_drawer_section_upcoming'.tr(),
                            fallback: 'Upcoming',
                          ),
                          const SizedBox(height: 6),
                          ..._upcomingEvents.take(3).map((e) => _UpcomingEventMini(
                                title: e.title,
                                dateText: _formatMiniDate(e.dateTime),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                    context,
                                    '/events/detail',
                                    arguments: {'eventId': e.id},
                                  );
                                },
                              )),
                        ],

                        const SizedBox(height: 10),
                        _divider(),

                        _sectionLabel('events_drawer_section_settings'.tr(), fallback: 'Settings'),
                        _NavItem(
                          icon: Icons.notifications,
                          title: 'events_drawer_notifications'.tr(),
                          onTap: () => _navigateToScreen(context, '/notifications'),
                        ),
                        _NavItem(
                          icon: Icons.settings,
                          title: 'events_drawer_settings'.tr(),
                          onTap: () => _navigateToScreen(context, '/settings'),
                        ),
                        _NavItem(
                          icon: Icons.help,
                          title: 'events_drawer_help'.tr(),
                          onTap: () => _navigateToScreen(context, '/support'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(
                  'events_drawer_version'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoading
                          ? 'events_drawer_loading'.tr()
                          : (_currentUser?.fullName ?? 'events_drawer_event_attendee'.tr()),
                      style: const TextStyle(
                        color: Color(0xF2FFFFFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isLoading ? '' : _getUserRoleText(),
                      style: const TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _IconPillButton(
                icon: Icons.close,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats chips
          if (!_isLoading && _currentUser != null)
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    value: '${_userEvents.length}',
                    label: 'events_drawer_my_events_stat'.tr(),
                    gradient: const [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatPill(
                    value: '${_upcomingEvents.length}',
                    label: 'events_drawer_upcoming_stat'.tr(),
                    gradient: const [Color(0xFF34D399), Color(0xFF22D3EE)],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _avatar() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3D8D), Color(0xFF7C4DFF), Color(0xFF22D3EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.black.withValues(alpha: 0.18),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
                      ),
                    ),
                  )
                : (_currentUser?.profileImageUrl != null && _currentUser!.profileImageUrl.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: _currentUser!.profileImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.person, color: Colors.white, size: 26),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.person, color: Colors.white, size: 26),
                      ),
          ),
        ),
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

  Widget _sectionLabel(String text, {required String fallback}) {
    final label = (text.trim().isEmpty) ? fallback : text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: const Color(0xFF34D399).withValues(alpha: 0.9),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withValues(alpha: 0.10),
    );
  }

  void _navigateToScreen(BuildContext context, String routeName) {
    Navigator.pop(context);
    Navigator.pushNamed(context, routeName);
  }

  String _formatMiniDate(DateTime dt) {
    // Simple drawer-friendly date. Keep localized later if you want.
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$m/$d • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== Components ====================

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
    this.gradient,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? badge;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final g = gradient ?? const [Color(0xFF7C4DFF), Color(0xFF22D3EE)];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Row(
              children: [
                _GradientIconChip(icon: icon, gradient: g),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xF2FFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  _CountBadge(text: badge!),
                ],
                Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3D8D), Color(0xFF7C4DFF)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3D8D).withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _UpcomingEventMini extends StatelessWidget {
  const _UpcomingEventMini({
    required this.title,
    required this.dateText,
    required this.onTap,
  });

  final String title;
  final String dateText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              _GradientIconChip(
                icon: Icons.event,
                gradient: const [Color(0xFF34D399), Color(0xFF22D3EE)],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xF2FFFFFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateText,
                      style: const TextStyle(
                        color: Color(0x73FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.value,
    required this.label,
    required this.gradient,
  });

  final String value;
  final String label;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          _GradientDot(gradient: gradient),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xF2FFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0x73FFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientDot extends StatelessWidget {
  const _GradientDot({required this.gradient});
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.padding,
    this.radius = 20,
    this.blur = 16,
    this.fillAlpha = 0.08,
    this.borderAlpha = 0.14,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final double blur;
  final double fillAlpha;
  final double borderAlpha;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: fillAlpha),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: borderAlpha)),
            boxShadow: shadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GradientIconChip extends StatelessWidget {
  const _GradientIconChip({required this.icon, required this.gradient});
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _IconPillButton extends StatelessWidget {
  const _IconPillButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.9)),
        ),
      ),
    );
  }
}
