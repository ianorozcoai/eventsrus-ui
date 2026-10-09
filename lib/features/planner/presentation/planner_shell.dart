import 'package:flutter/material.dart';

import '../../marketplace/presentation/app_top_bar.dart';
import '../../marketplace/presentation/conversations_screen.dart';
import '../../marketplace/presentation/notifications_screen.dart';
import 'event_create_screen.dart';
import 'events_list_screen.dart';
import 'planner_calendar_screen.dart';
import 'planner_profile_screen.dart';

class PlannerShell extends StatefulWidget {
  const PlannerShell({super.key});

  @override
  State<PlannerShell> createState() => _PlannerShellState();
}

class _PlannerShellState extends State<PlannerShell> {
  int _index = 0;

  static const _titles = ['Events', 'Messages', 'Notifications', 'Calendar', 'Profile'];

  static const _screens = [
    EventsListScreen(),
    ConversationsScreen(),
    NotificationsScreen(),
    PlannerCalendarScreen(),
    PlannerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: _titles[_index]),
      body: SafeArea(child: _screens[_index]),
      floatingActionButton: _index == 0
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EventCreateScreen()),
              ),
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Notifications'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
