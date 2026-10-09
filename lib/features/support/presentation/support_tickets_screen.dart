import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/support_ticket.dart';
import '../data/models/ticket_category.dart';
import '../data/models/ticket_status.dart';
import '../data/support_ticket_api.dart';
import 'create_ticket_screen.dart';
import 'support_ticket_detail_screen.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  List<SupportTicket>? _tickets;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tickets = await context.read<SupportTicketApi>().listForUser();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tickets = _tickets ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Support Tickets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
          );
          if (created == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: tickets.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No support tickets yet.')),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: tickets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return Card(
                          child: ListTile(
                            title: Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              ticket.lastMessagePreview ?? ticket.category.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: _StatusBadge(status: ticket.status),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => SupportTicketDetailScreen(ticketId: ticket.id)),
                              );
                              _load();
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TicketStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      TicketStatus.open => Colors.blue,
      TicketStatus.inProgress => Colors.orange,
      TicketStatus.resolved => Colors.green,
      TicketStatus.closed => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(status.label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
