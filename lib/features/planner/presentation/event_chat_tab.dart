import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../marketplace/data/conversation_api.dart';
import '../../marketplace/data/models/conversation_summary.dart';
import '../../marketplace/presentation/conversation_thread_screen.dart';

/// The "Chat" tab inside [PlannerEventShell] - a flat list of conversations
/// actually in progress for this event, same Messenger-style row pattern
/// and same shared ConversationThreadScreen as the vendor's own chat list.
///
/// Deliberately shows ONLY real conversations, not the event's full roster
/// of AI-suggested vendor categories (most of which were never contacted) -
/// that used to clutter this tab with rows that weren't real chats.
/// Starting a brand-new conversation with a suggested-but-uncontacted
/// vendor now happens from the Overview tab instead, which already lists
/// suggestions; this tab reloads (see [reload]) once that happens so the
/// new conversation shows up here immediately.
class EventChatTab extends StatefulWidget {
  final int eventId;

  const EventChatTab({super.key, required this.eventId});

  @override
  State<EventChatTab> createState() => EventChatTabState();
}

class EventChatTabState extends State<EventChatTab> {
  List<ConversationSummary> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    try {
      final conversations = await context.read<ConversationApi>().listConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations.where((c) => c.eventId == widget.eventId).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openThread(ConversationSummary conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationThreadScreen(
          conversationId: conversation.id,
          summary: conversation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_conversations.isEmpty) {
      return const Center(child: Text('No conversations for this event yet.'));
    }

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final unread = conversation.unreadCount > 0;
          return ListTile(
            leading: CircleAvatar(
              child: Text(
                conversation.otherPartyName.isNotEmpty
                    ? conversation.otherPartyName[0].toUpperCase()
                    : '?',
              ),
            ),
            title: Text(
              conversation.otherPartyName,
              style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal),
            ),
            trailing: unread
                ? CircleAvatar(
                    radius: 10,
                    child: Text('${conversation.unreadCount}', style: const TextStyle(fontSize: 10)),
                  )
                : const Icon(Icons.chevron_right),
            onTap: () => _openThread(conversation),
          );
        },
      ),
    );
  }
}
