import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../data/models/support_ticket.dart';
import '../data/models/support_ticket_message.dart';
import '../data/support_ticket_api.dart';

class SupportTicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  State<SupportTicketDetailScreen> createState() => _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  SupportTicket? _ticket;
  List<SupportTicketMessage>? _messages;
  bool _loading = true;

  final _reply = TextEditingController();
  PlatformFile? _attachment;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<SupportTicketApi>();
      final ticket = await api.getTicket(widget.ticketId);
      final messages = await api.getMessages(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _messages = messages;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() => _attachment = result.files.first);
  }

  Future<void> _send() async {
    final message = _reply.text.trim();
    if (message.isEmpty) return;

    setState(() => _sending = true);
    try {
      await context.read<SupportTicketApi>().reply(widget.ticketId, message, attachment: _attachment);
      _reply.clear();
      setState(() => _attachment = null);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;

    return Scaffold(
      appBar: AppBar(title: Text(ticket?.subject ?? 'Support Ticket')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ticket == null
              ? const Center(child: Text('Could not load this ticket.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: (_messages ?? []).length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final message = _messages![index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(message.senderName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(message.body),
                                  if (message.attachmentUrl != null) ...[
                                    const SizedBox(height: 8),
                                    Text('📎 Attachment', style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimestamp(message.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            if (_attachment != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Chip(
                                  label: Text(_attachment!.name),
                                  onDeleted: () => setState(() => _attachment = null),
                                ),
                              ),
                            Row(
                              children: [
                                IconButton(onPressed: _pickAttachment, icon: const Icon(Icons.attach_file)),
                                Expanded(
                                  child: TextField(
                                    controller: _reply,
                                    decoration: const InputDecoration(hintText: 'Reply...'),
                                    minLines: 1,
                                    maxLines: 4,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _sending ? null : _send,
                                  icon: _sending
                                      ? const SizedBox(
                                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.send),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.month}/${local.day}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
