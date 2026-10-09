import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../marketplace/data/conversation_api.dart';
import '../../marketplace/data/lead_api.dart';
import '../../marketplace/data/models/conversation_summary.dart';
import '../../marketplace/data/models/lead.dart';
import '../../marketplace/presentation/conversation_thread_screen.dart';

class VendorLeadsScreen extends StatefulWidget {
  const VendorLeadsScreen({super.key});

  @override
  State<VendorLeadsScreen> createState() => _VendorLeadsScreenState();
}

class _VendorLeadsScreenState extends State<VendorLeadsScreen> {
  List<Lead>? _leads;
  List<ConversationSummary> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        context.read<LeadApi>().listForVendor(),
        context.read<ConversationApi>().listConversations(),
      ]);
      if (!mounted) return;
      setState(() {
        _leads = results[0] as List<Lead>;
        _conversations = results[1] as List<ConversationSummary>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  ConversationSummary? _conversationForEvent(int eventId) {
    for (final c in _conversations) {
      if (c.eventId == eventId) return c;
    }
    return null;
  }

  void _openOrStartConversation(Lead lead) {
    final existing = _conversationForEvent(lead.eventId);
    if (existing != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationThreadScreen(conversationId: existing.id, summary: existing),
        ),
      );
      return;
    }
    _showComposeDialog(lead);
  }

  Future<void> _showComposeDialog(Lead lead) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Message ${lead.plannerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Introduce yourself and offer your services...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This starts a new conversation with ${lead.plannerName} about ${lead.eventName ?? 'their event'}.',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
    if (message == null || message.isEmpty || !mounted) return;

    try {
      await context.read<ConversationApi>().sendVendorMessage(lead.eventId, message);
      final conversations = await context.read<ConversationApi>().listConversations();
      if (!mounted) return;
      setState(() => _conversations = conversations);
      final created = _conversationForEvent(lead.eventId);
      if (created != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationThreadScreen(conversationId: created.id, summary: created),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final leads = _leads ?? [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Leads', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Planners who viewed your storefront while planning an event.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: leads.isEmpty
                ? const Center(child: Text('No leads yet.'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      itemCount: leads.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final lead = leads[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(child: Icon(Icons.person_outline)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(lead.plannerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(lead.eventName ?? 'Untitled event'),
                                          if (lead.eventDate != null)
                                            Text(
                                              'Event date: ${_formatEventDate(lead.eventDate!)}',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _VisitDateLabel(label: 'First visited', date: lead.firstVisitedAt),
                                    ),
                                    Expanded(
                                      child: _VisitDateLabel(label: 'Last visited', date: lead.lastVisitedAt),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _vendorViolet,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _openOrStartConversation(lead),
                                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                    label: const Text('Send Message'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _VisitDateLabel extends StatelessWidget {
  final String label;
  final DateTime date;

  const _VisitDateLabel({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(_formatDateTime(date), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '${_monthNames[local.month - 1]} ${local.day}, ${local.year}\n$hour:$minute $ampm';
  }
}

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

// Same deep violet as the vendor shell's bottom nav / dashboard stat-card
// icons (see VendorShell's own copy of this color for why this exact shade).
const _vendorViolet = Color(0xFF5B21B6);

String _formatEventDate(DateTime date) => '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
