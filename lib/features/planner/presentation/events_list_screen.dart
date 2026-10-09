import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/event_api.dart';
import '../data/models/planner_event.dart';
import '../data/models/planner_event_type.dart';
import 'event_create_screen.dart';
import 'planner_event_shell.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  List<PlannerEventSummary>? _events;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final events = await context.read<EventApi>().listEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _createNew() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventCreateScreen()));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final events = (_events ?? []).where((e) => e.saved).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNew,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('My Events', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No saved events yet.'),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _createNew, child: const Text('Plan Your First Event')),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.event_outlined),
                            title: Text(event.name ?? 'Untitled event'),
                            subtitle: Text(
                              event.eventType.label,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: event.eventDate != null
                                ? Text('${event.eventDate!.month}/${event.eventDate!.day}/${event.eventDate!.year}')
                                : null,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PlannerEventShell(eventId: event.id)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
