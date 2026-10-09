import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../coordinator/presentation/event_coordinator_screen.dart';
import '../../marketplace/data/conversation_api.dart';
import '../../marketplace/data/models/conversation_summary.dart';
import '../data/event_api.dart';
import '../data/models/planner_event.dart';
import '../data/models/planner_event_type.dart';

/// The "Overview" tab inside [PlannerEventShell] - the event's own details
/// (type, date, location, description, AI idea), its planning checklist,
/// and the event's suggested vendors. Starting a brand-new conversation
/// with a suggested-but-uncontacted vendor lives here (not the Chat tab,
/// which only ever shows conversations already in progress) - tapping a
/// vendor that's already been messaged just switches to Chat instead.
class EventOverviewTab extends StatefulWidget {
  final PlannerEvent event;
  final VoidCallback onGoToChat;
  final Future<void> Function() onConversationStarted;

  const EventOverviewTab({
    super.key,
    required this.event,
    required this.onGoToChat,
    required this.onConversationStarted,
  });

  @override
  State<EventOverviewTab> createState() => _EventOverviewTabState();
}

class _EventOverviewTabState extends State<EventOverviewTab> {
  late List<EventChecklistItem> _checklist;
  int? _busyChecklistItemId;
  bool _addingItem = false;
  List<ConversationSummary> _conversations = [];
  int? _startingVendorProfileId;

  @override
  void initState() {
    super.initState();
    _checklist = List.of(widget.event.checklist);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await context.read<ConversationApi>().listConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations.where((c) => c.eventId == widget.event.id).toList();
      });
    } catch (_) {
      // Non-fatal - suggestions just show as "not yet contacted" until this
      // succeeds.
    }
  }

  ConversationSummary? _conversationFor(SuggestedVendor vendor) {
    for (final c in _conversations) {
      if (c.otherPartyUserId == vendor.vendorProfileId) return c;
    }
    return null;
  }

  Future<void> _startConversation(SuggestedVendor vendor) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Message ${vendor.businessName ?? vendor.vendorType}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Say hello...'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (message == null || message.isEmpty || vendor.vendorProfileId == null) return;

    setState(() => _startingVendorProfileId = vendor.vendorProfileId);
    try {
      await context.read<ConversationApi>().sendInquiry(
            eventId: widget.event.id,
            vendorUserId: vendor.vendorProfileId!,
            plannerName: 'Planner',
            message: message,
          );
      await widget.onConversationStarted();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send message')),
      );
    } finally {
      if (mounted) setState(() => _startingVendorProfileId = null);
    }
  }

  Future<void> _toggleChecklistItem(EventChecklistItem item) async {
    final newStatus = item.status == ChecklistItemStatus.done
        ? ChecklistItemStatus.todo
        : ChecklistItemStatus.done;
    setState(() => _busyChecklistItemId = item.id);
    try {
      final updated = await context
          .read<EventApi>()
          .updateChecklistStatus(widget.event.id, item.id, newStatus);
      if (!mounted) return;
      setState(() {
        final index = _checklist.indexWhere((e) => e.id == item.id);
        if (index != -1) _checklist[index] = updated;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update checklist item')),
      );
    } finally {
      if (mounted) setState(() => _busyChecklistItemId = null);
    }
  }

  Future<void> _addChecklistItem() async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add checklist item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. "Book the venue"'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (label == null || label.isEmpty) return;

    setState(() => _addingItem = true);
    try {
      final item = await context.read<EventApi>().addChecklistItem(widget.event.id, label);
      if (!mounted) return;
      setState(() => _checklist = [..._checklist, item]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add checklist item')),
      );
    } finally {
      if (mounted) setState(() => _addingItem = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final textTheme = Theme.of(context).textTheme;
    final realVendorSuggestions =
        event.suggestions.where((s) => s.isRealVendor).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name ?? 'Untitled event',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _detailRow(Icons.category_outlined, event.eventType.label),
                if (event.eventDate != null)
                  _detailRow(
                    Icons.calendar_today_outlined,
                    '${event.eventDate!.month}/${event.eventDate!.day}/${event.eventDate!.year}',
                  ),
                if (event.location != null && event.location!.isNotEmpty)
                  _detailRow(Icons.location_on_outlined, event.location!),
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(event.description!, style: textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
        if (event.aiIdeaText != null && event.aiIdeaText!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('AI Idea', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(event.aiIdeaText!, style: textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: const Text('Ask the AI Coordinator'),
            subtitle: const Text('Get planning help for this event'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventCoordinatorScreen(eventId: event.id, eventName: event.name),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Checklist', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    _addingItem
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            tooltip: 'Add checklist item',
                            onPressed: _addChecklistItem,
                          ),
                  ],
                ),
                if (_checklist.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nothing on the checklist yet.'),
                  )
                else
                  for (final item in _checklist)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: item.status == ChecklistItemStatus.done,
                      onChanged: _busyChecklistItemId == item.id
                          ? null
                          : (_) => _toggleChecklistItem(item),
                      title: Text(
                        item.label,
                        style: item.status == ChecklistItemStatus.done
                            ? const TextStyle(decoration: TextDecoration.lineThrough)
                            : null,
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Suggested Vendors', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onGoToChat,
                      child: const Text('Open Chat'),
                    ),
                  ],
                ),
                if (realVendorSuggestions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No vendors matched yet.'),
                  )
                else
                  for (final vendor in realVendorSuggestions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(vendor.businessName ?? vendor.vendorType),
                      subtitle: Text(
                        _conversationFor(vendor) != null
                            ? 'Continue in Chat'
                            : 'Tap to start messaging',
                      ),
                      trailing: _startingVendorProfileId == vendor.vendorProfileId
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _startingVendorProfileId == vendor.vendorProfileId
                          ? null
                          : () {
                              final conversation = _conversationFor(vendor);
                              if (conversation != null) {
                                widget.onGoToChat();
                              } else {
                                _startConversation(vendor);
                              }
                            },
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
