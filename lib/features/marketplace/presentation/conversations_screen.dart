import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/conversation_api.dart';
import '../data/models/conversation_message.dart';
import '../data/models/conversation_summary.dart';
import 'conversation_thread_screen.dart';

/// Conversation list, shared between the planner and vendor shells — the
/// messaging UI is entirely role-agnostic (the backend already scopes
/// results to whichever role is authenticated).
///
/// On phone width this is a flat Messenger-style list; tapping a row pushes
/// [ConversationThreadScreen] as its own screen. On desktop width (>=900,
/// the vendor shell's wide layout) there's room for a side-by-side list +
/// thread pane instead, so it keeps that master-detail layout - a phone-
/// width Row squeezing a whole chat thread into a sliver of leftover width
/// is what caused every message to render as a single character per line.
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<ConversationSummary>? _conversations;
  ConversationSummary? _selectedForWide;
  List<ConversationMessage> _wideMessages = [];
  final _wideReplyController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _wideReplyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final conversations = await context.read<ConversationApi>().listConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
      if (conversations.isNotEmpty && MediaQuery.of(context).size.width >= 900) {
        _selectForWide(conversations.first);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _selectForWide(ConversationSummary conversation) async {
    setState(() => _selectedForWide = conversation);
    try {
      final messages = await context.read<ConversationApi>().getMessages(conversation.id);
      if (!mounted) return;
      setState(() => _wideMessages = messages);
    } catch (_) {}
  }

  Future<void> _sendWideReply() async {
    final selected = _selectedForWide;
    final text = _wideReplyController.text.trim();
    if (selected == null || text.isEmpty) return;
    _wideReplyController.clear();
    try {
      await context.read<ConversationApi>().sendMessage(selected.id, text);
      await _selectForWide(selected);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final conversations = _conversations ?? [];
    final isWide = MediaQuery.of(context).size.width >= 900;

    if (isWide) return _buildWideLayout(context, conversations);

    if (conversations.isEmpty) {
      return const Center(child: Text('No conversations yet.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: conversations.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) => _ConversationRow(
          conversation: conversations[index],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConversationThreadScreen(
                conversationId: conversations[index].id,
                summary: conversations[index],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, List<ConversationSummary> conversations) {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: conversations.isEmpty
              ? const Center(child: Text('No conversations yet.'))
              : ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final c = conversations[index];
                    return _ConversationRow(
                      conversation: c,
                      selected: _selectedForWide?.id == c.id,
                      onTap: () => _selectForWide(c),
                    );
                  },
                ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedForWide == null
              ? const Center(child: Text('Select a conversation'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${_selectedForWide!.otherPartyName} — ${_selectedForWide!.eventName ?? ''}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _wideMessages.length,
                        itemBuilder: (context, index) {
                          final message = _wideMessages[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(message.senderName, style: Theme.of(context).textTheme.labelSmall),
                                Text(message.body),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _wideReplyController,
                              decoration: const InputDecoration(hintText: 'Type a reply...'),
                              onSubmitted: (_) => _sendWideReply(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(onPressed: _sendWideReply, child: const Text('Send')),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ConversationRow extends StatelessWidget {
  final ConversationSummary conversation;
  final bool selected;
  final VoidCallback onTap;

  const _ConversationRow({required this.conversation, this.selected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;
    final eventDate = conversation.eventDate;
    return ListTile(
      selected: selected,
      onTap: onTap,
      leading: CircleAvatar(
        child: Text(conversation.otherPartyName.isNotEmpty ? conversation.otherPartyName[0].toUpperCase() : '?'),
      ),
      title: Text(
        conversation.otherPartyName,
        style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conversation.eventName ?? 'General inquiry',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: unread ? FontWeight.w600 : FontWeight.normal),
          ),
          if (eventDate != null)
            Text(
              '${_monthNames[eventDate.month - 1]} ${eventDate.day}, ${eventDate.year}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_formatTimestamp(conversation.lastMessageAt), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          if (unread)
            CircleAvatar(
              radius: 10,
              child: Text('${conversation.unreadCount}', style: const TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
    if (isToday) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
    }
    return '${local.month}/${local.day}';
  }
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
