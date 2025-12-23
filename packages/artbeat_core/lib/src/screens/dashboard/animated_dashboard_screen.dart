import 'package:flutter/material.dart';

class AnimatedDashboardScreen extends StatelessWidget {
  const AnimatedDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6E6FA), // Pale purple
              Color(0xFFB2F7CC), // Pale green
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Hero
              const _AppHero(),
              const SizedBox(height: 32),
              // Animated Buttons
              const _AnimatedDashboardButtons(),
              const SizedBox(height: 32),
              // CTA Widgets
              const _ArtistCTA(),
              const SizedBox(height: 16),
              const _BusinessCTA(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppHero extends StatelessWidget {
  const _AppHero();
  @override
  Widget build(BuildContext context) {
    return Text(
      'ARTbeat',
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
    );
  }
}

class _AnimatedDashboardButtons extends StatelessWidget {
  const _AnimatedDashboardButtons();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _AnimatedDashboardButton(
          label: 'Capture',
          gradient: LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFFFFA17F)],
          ),
          icon: Icons.camera_alt,
          route: '/enhanced-capture',
        ),
        _AnimatedDashboardButton(
          label: 'Explore',
          gradient: LinearGradient(
            colors: [Color(0xFFFFA17F), Color(0xFF2193B0)],
          ),
          icon: Icons.explore,
          route: '/artbeat',
        ),
        _AnimatedDashboardButton(
          label: 'Discover',
          gradient: LinearGradient(
            colors: [Color(0xFF2193B0), Color(0xFFFF61A6)],
          ),
          icon: Icons.search,
          route: '/artwalk',
        ),
        _AnimatedDashboardButton(
          label: 'Connect',
          gradient: LinearGradient(
            colors: [Color(0xFFFF61A6), Color(0xFF43E97B)],
          ),
          icon: Icons.people,
          route: '/community',
        ),
      ],
    );
  }
}

class _AnimatedDashboardButton extends StatefulWidget {
  final String label;
  final LinearGradient gradient;
  final IconData icon;
  final String route;
  const _AnimatedDashboardButton({
    required this.label,
    required this.gradient,
    required this.icon,
    required this.route,
    Key? key,
  }) : super(key: key);
  @override
  State<_AnimatedDashboardButton> createState() =>
      _AnimatedDashboardButtonState();
}

class _AnimatedDashboardButtonState extends State<_AnimatedDashboardButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, widget.route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.last.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistCTA extends StatelessWidget {
  const _ArtistCTA();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/onboarding-artist'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.palette, color: Colors.deepPurple),
            SizedBox(width: 10),
            Text(
              'Are you an Artist? Get started',
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.deepPurple),
          ],
        ),
      ),
    );
  }
}

class _BusinessCTA extends StatelessWidget {
  const _BusinessCTA();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/onboarding-business'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.store, color: Colors.green),
            SizedBox(width: 10),
            Text(
              'Are you a local business? Promote here',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
