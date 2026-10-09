import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme.dart';
import '../data/models/signup_intent.dart';
import 'login_screen.dart';

/// Shown as the very first screen once session-restore resolves to
/// "not logged in" (see AuthGate) - matches eventsrus-web's landing-page
/// role-picker ("What brings you here today?"), reached here before any
/// login attempt rather than as a modal over a marketing page, since this
/// app has no public marketing landing page of its own.
class RolePickerScreen extends StatelessWidget {
  const RolePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset('assets/images/logo-login.svg', width: 200),
                  const SizedBox(height: 24),
                  Text(
                    'What brings you here today?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Choose how you'd like to use EventsRUs.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  _RoleCard(
                    icon: Icons.celebration_outlined,
                    iconColor: kBrandBlue,
                    title: "I'm Planning an Event",
                    subtitle: 'Find and book trusted suppliers for your celebration',
                    onTap: () => _goToLogin(context, SignupIntent.planner),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    icon: Icons.storefront_outlined,
                    iconColor: kBrandOrange,
                    title: "I'm a Supplier",
                    subtitle: 'Grow your business and get more bookings',
                    onTap: () => _goToLogin(context, SignupIntent.vendor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToLogin(BuildContext context, SignupIntent intent) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginScreen(intent: intent)),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
