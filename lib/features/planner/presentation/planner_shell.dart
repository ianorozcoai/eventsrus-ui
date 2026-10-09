import 'package:flutter/material.dart';

import '../../marketplace/presentation/brand_header_bar.dart';
import '../../marketplace/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_edit_screen.dart';
import '../../support/presentation/support_tickets_screen.dart';
import 'event_create_screen.dart';
import 'events_list_screen.dart';

class PlannerShell extends StatefulWidget {
  const PlannerShell({super.key});

  @override
  State<PlannerShell> createState() => _PlannerShellState();
}

class _PlannerShellState extends State<PlannerShell> {
  // Only Events (0) and Notifications (1) are real embedded tabs. Profile
  // (2) and Support (3) push straight to their own full screens instead of
  // showing an intermediate hub - see _onDestinationSelected - so _index
  // never takes those values and the nav bar never shows them as
  // "selected", same as tapping a one-off action rather than switching tabs.
  int _index = 0;

  static const _screens = [
    EventsListScreen(),
    NotificationsScreen(),
  ];

  void _onDestinationSelected(int index) {
    switch (index) {
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
        );
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SupportTicketsScreen()),
        );
      default:
        setState(() => _index = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandHeaderBar(),
      body: SafeArea(child: _screens[_index]),
      floatingActionButton: _index == 0
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EventCreateScreen()),
              ),
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFF5B21B6),
          indicatorColor: Colors.white.withValues(alpha: 0.25),
          iconTheme: WidgetStateProperty.resolveWith(
            (_) => const IconThemeData(color: Colors.white),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: Colors.white,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onDestinationSelected,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Events'),
            NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Notifications'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
            NavigationDestination(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
          ],
        ),
      ),
    );
  }
}
