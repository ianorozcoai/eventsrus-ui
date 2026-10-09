import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/notification_item.dart';
import '../data/notification_api.dart';

/// Shared between planner and vendor shells — notifications are role-agnostic.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem>? _notifications;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final notifications = await context.read<NotificationApi>().list();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(NotificationItem notification) async {
    if (notification.read) return;
    try {
      await context.read<NotificationApi>().markRead(notification.id);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final notifications = _notifications ?? [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Notifications', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: notifications.isEmpty
                ? const Center(child: Text('No notifications yet.'))
                : ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Card(
                        color: notification.read ? null : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        child: ListTile(
                          leading: Icon(notification.read ? Icons.notifications_none : Icons.notifications_active),
                          title: Text(notification.title),
                          subtitle: Text(notification.body ?? ''),
                          onTap: () => _markRead(notification),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
