import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../coordinator/presentation/event_coordinator_screen.dart';
import '../../marketplace/data/conversation_api.dart';
import '../../marketplace/data/models/conversation_message.dart';
import '../../marketplace/data/models/conversation_summary.dart';
import '../data/event_api.dart';
import '../data/models/planner_event.dart';
import 'event_quotations_screen.dart';
import 'vendor_profile_screen.dart';

class EventChatModeScreen extends StatefulWidget {
  final int eventId;

  const EventChatModeScreen({super.key, required this.eventId});

  @override
  State<EventChatModeScreen> createState() => _EventChatModeScreenState();
}

class _EventChatModeScreenState extends State<EventChatModeScreen> {
  PlannerEvent? _event;
  SuggestedVendor? _selectedVendor;
  List<ConversationSummary> _conversations = [];
  List<ConversationMessage> _messages = [];
  final _messageController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    PlannerEvent? event;
    try {
      event = await context.read<EventApi>().getEvent(widget.eventId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    if (!mounted) return;
    setState(() {
      _event = event;
      _loading = false;
    });

    // Conversations are a secondary concern for this screen — if this call
    // fails, the event itself should still display rather than the whole
    // screen reporting "not found" for an unrelated failure.
    try {
      final conversations = await context.read<ConversationApi>().listConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations.where((c) => c.eventId == widget.eventId).toList();
        final realVendors = event!.suggestions.where((s) => s.isRealVendor).toList();
        if (realVendors.isNotEmpty) _selectVendor(realVendors.first);
      });
    } catch (_) {
      // Non-fatal — chat pane just stays empty until this succeeds.
    }
  }

  void _selectVendor(SuggestedVendor vendor) {
    setState(() => _selectedVendor = vendor);
    final existing = _conversations
        .where((c) => c.otherPartyUserId == vendor.vendorProfileId)
        .toList();
    if (existing.isNotEmpty) {
      _loadMessages(existing.first.id);
    } else {
      setState(() => _messages = []);
    }
  }

  Future<void> _loadMessages(int conversationId) async {
    try {
      final messages = await context.read<ConversationApi>().getMessages(conversationId);
      if (!mounted) return;
      setState(() => _messages = messages);
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final vendor = _selectedVendor;
    if (vendor == null || _messageController.text.trim().isEmpty) return;
    final text = _messageController.text.trim();
    _messageController.clear();

    final existing = _conversations.where((c) => c.otherPartyUserId == vendor.vendorProfileId).toList();
    try {
      if (existing.isEmpty) {
        await context.read<ConversationApi>().sendInquiry(
              eventId: widget.eventId,
              vendorUserId: vendor.vendorProfileId!,
              plannerName: 'Planner',
              message: text,
            );
        final conversations = await context.read<ConversationApi>().listConversations();
        if (!mounted) return;
        setState(() => _conversations = conversations.where((c) => c.eventId == widget.eventId).toList());
        _selectVendor(vendor);
      } else {
        await context.read<ConversationApi>().sendMessage(existing.first.id, text);
        _loadMessages(existing.first.id);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send message')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final event = _event;
    if (event == null) {
      return const Scaffold(body: Center(child: Text('Event not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(event.name ?? 'Event'),
        actions: [
          IconButton(
            tooltip: 'Events Coordinator',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventCoordinatorScreen(eventId: widget.eventId, eventName: event.name),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Quotations & Bookings',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventQuotationsScreen(eventId: widget.eventId, eventName: event.name),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return Row(
              children: [
                SizedBox(width: 280, child: _buildSuggestionsPane(event)),
                const VerticalDivider(width: 1),
                Expanded(child: _buildChatPane()),
                const VerticalDivider(width: 1),
                SizedBox(width: 280, child: _buildVendorPane()),
              ],
            );
          }
          // Phone width: the 3-pane desktop layout above doesn't fit a
          // phone screen (needs 560px+ before the chat pane gets any room
          // at all), so collapse to a horizontal vendor-suggestion strip +
          // a compact selected-vendor header on top of the chat pane.
          return Column(
            children: [
              SizedBox(height: 88, child: _buildSuggestionsStrip(event)),
              const Divider(height: 1),
              if (_selectedVendor != null) _buildVendorStrip(_selectedVendor!),
              Expanded(child: _buildChatPane()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsStrip(PlannerEvent event) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      children: event.suggestions.map((s) {
        final selected = _selectedVendor?.vendorProfileId == s.vendorProfileId &&
            _selectedVendor?.vendorType == s.vendorType;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(s.isRealVendor ? (s.businessName ?? s.vendorType) : s.vendorType),
            selected: selected,
            onSelected: s.isRealVendor ? (_) => _selectVendor(s) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVendorStrip(SuggestedVendor vendor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              vendor.businessName ?? vendor.vendorType,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (vendor.slug != null)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VendorProfileScreen(slug: vendor.slug!, eventId: widget.eventId),
                ),
              ),
              child: const Text('View Profile'),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsPane(PlannerEvent event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Suggestions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        if (event.aiIdeaText != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(event.aiIdeaText!, style: Theme.of(context).textTheme.bodySmall),
          ),
        const Divider(),
        Expanded(
          child: ListView(
            children: event.suggestions.map((s) {
              final selected = _selectedVendor?.vendorProfileId == s.vendorProfileId &&
                  _selectedVendor?.vendorType == s.vendorType;
              return ListTile(
                selected: selected,
                leading: const Icon(Icons.storefront_outlined),
                title: Text(s.isRealVendor ? (s.businessName ?? s.vendorType) : s.vendorType),
                subtitle: Text(s.isRealVendor ? 'View & message' : 'No vendors matched yet'),
                enabled: s.isRealVendor,
                onTap: s.isRealVendor ? () => _selectVendor(s) : null,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChatPane() {
    final vendor = _selectedVendor;
    if (vendor == null) {
      return const Center(child: Text('Select a vendor to start chatting'));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
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
                  controller: _messageController,
                  decoration: const InputDecoration(hintText: 'Type a message...'),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _sendMessage, child: const Text('Send')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVendorPane() {
    final vendor = _selectedVendor;
    if (vendor == null) {
      return const Center(child: Text('No vendor selected'));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vendor.businessName ?? vendor.vendorType, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(vendor.city ?? '', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          if (vendor.slug != null)
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VendorProfileScreen(slug: vendor.slug!, eventId: widget.eventId),
                ),
              ),
              child: const Text('View Full Profile'),
            ),
        ],
      ),
    );
  }
}
