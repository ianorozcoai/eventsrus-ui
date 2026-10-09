import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/state/auth_controller.dart';
import '../../profile/presentation/profile_edit_screen.dart';
import '../../support/presentation/support_tickets_screen.dart';
import '../../vendor/presentation/vendor_onboarding_screen.dart';

class PlannerProfileScreen extends StatelessWidget {
  const PlannerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  (auth.firstName?.isNotEmpty == true ? auth.firstName![0] : auth.email?[0] ?? '?').toUpperCase(),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(height: 16),
              Text(auth.firstName ?? 'Planner', style: Theme.of(context).textTheme.titleLarge),
              Text(auth.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                ),
                child: const Text('Edit Profile'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SupportTicketsScreen()),
                ),
                child: const Text('Support Tickets'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VendorOnboardingScreen()),
                ),
                child: const Text('Become a Vendor'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => auth.logout(), child: const Text('Log out')),
            ],
          ),
        ),
      ),
    );
  }
}
