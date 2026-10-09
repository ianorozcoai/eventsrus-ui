import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/data/models/role.dart';
import '../../auth/state/auth_controller.dart';
import '../data/conversation_api.dart';
import '../data/models/conversation_message.dart';
import '../data/models/conversation_summary.dart';
import '../data/models/quotation.dart';
import '../data/quotation_api.dart';

/// A single conversation's message thread, pushed as its own full-screen
/// route (back button + header) from either the conversation list or a
/// tapped push notification - see ConversationsScreen's doc comment for why
/// this isn't a side-by-side pane on phone width.
///
/// [summary] is passed when opened from the list (avoids a refetch); when
/// opened from a notification tap only the id is known, so this screen
/// fetches the list itself and finds the matching entry.
class ConversationThreadScreen extends StatefulWidget {
  final int conversationId;
  final ConversationSummary? summary;

  const ConversationThreadScreen({
    super.key,
    required this.conversationId,
    this.summary,
  });

  @override
  State<ConversationThreadScreen> createState() =>
      _ConversationThreadScreenState();
}

class _ConversationThreadScreenState extends State<ConversationThreadScreen> {
  ConversationSummary? _summary;
  List<ConversationMessage> _messages = [];
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  bool _sending = false;
  PlatformFile? _pendingAttachment;

  @override
  void initState() {
    super.initState();
    _summary = widget.summary;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (_summary == null) {
        final conversations = await context
            .read<ConversationApi>()
            .listConversations();
        for (final c in conversations) {
          if (c.id == widget.conversationId) {
            _summary = c;
            break;
          }
        }
      }
      final messages = await context.read<ConversationApi>().getMessages(
        widget.conversationId,
      );
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;
    setState(() => _pendingAttachment = result.files.single);
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    final attachment = _pendingAttachment;
    if (text.isEmpty || _sending) return;
    _replyController.clear();
    setState(() {
      _sending = true;
      _pendingAttachment = null;
    });
    try {
      await context.read<ConversationApi>().sendMessage(
        widget.conversationId,
        text,
        attachmentBytes: attachment?.bytes,
        attachmentFilename: attachment?.name,
      );
      final messages = await context.read<ConversationApi>().getMessages(
        widget.conversationId,
      );
      if (!mounted) return;
      setState(() => _messages = messages);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Vendor-only entry point for starting a brand-new quote directly from
  /// chat, for when negotiation happened here with no prior storefront
  /// request - mirrors eventsrus-web's "Create a Quote" button
  /// (VendorController#createQuoteFromChat). First checks for any existing
  /// quotation history for this event; if one exists, points the vendor at
  /// the Quotations hub instead of creating a duplicate, same gate web
  /// applies.
  Future<void> _createQuote() async {
    final summary = _summary;
    if (summary == null) return;

    List<Quotation> existing;
    try {
      final allQuotations = await context.read<QuotationApi>().listForVendor();
      existing = allQuotations
          .where((q) => q.eventId == summary.eventId)
          .toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not check for an existing quotation.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A quotation already exists for this event - manage it from the Quotations hub.',
          ),
        ),
      );
      return;
    }

    final pdfResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (pdfResult == null ||
        pdfResult.files.isEmpty ||
        pdfResult.files.single.bytes == null)
      return;
    final pdf = pdfResult.files.single;
    if (!mounted) return;

    final amountController = TextEditingController();
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create a Quote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quote PDF: ${pdf.name}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Quoted Amount (₱)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: double.tryParse(amountController.text.trim()) == null
                ? null
                : () => Navigator.of(dialogContext).pop(true),
            child: const Text('Send Quote'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) return;

    try {
      await context.read<QuotationApi>().createFromChat(
        eventId: summary.eventId,
        pdfBytes: pdf.bytes!,
        pdfFilename: pdf.name,
        quotedAmount: amount,
        message: messageController.text.trim().isEmpty
            ? null
            : messageController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote sent - manage it from the Quotations hub.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.message
          : 'Could not create the quote. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _buildAttachmentPreview(BuildContext context) {
    final attachment = _pendingAttachment!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              attachment.bytes!,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => _pendingAttachment = null),
              icon: Icon(
                Icons.cancel,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final isVendor = context.watch<AuthController>().role == Role.vendor;
    return Scaffold(
      appBar: AppBar(
        title: Text(summary?.otherPartyName ?? 'Conversation'),
        actions: [
          if (isVendor && summary != null)
            IconButton(
              onPressed: _createQuote,
              icon: const Icon(Icons.request_quote_outlined),
              tooltip: 'Create a Quote',
            ),
        ],
        bottom: summary?.eventName == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    summary!.eventName!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? const Center(
                            child: Text('No messages yet - say hello.'),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMe =
                                  summary == null ||
                                  message.senderUserId !=
                                      summary.otherPartyUserId;
                              return _MessageBubble(
                                message: message,
                                isMe: isMe,
                              );
                            },
                          ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_pendingAttachment != null)
                            _buildAttachmentPreview(context),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _sending ? null : _pickAttachment,
                                icon: const Icon(Icons.attach_file),
                                tooltip: 'Attach a photo',
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _replyController,
                                  minLines: 1,
                                  maxLines: 4,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    hintText: 'Message...',
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onSubmitted: (_) => _sendReply(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: _sending ? null : _sendReply,
                                icon: _sending
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
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
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ConversationMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final attachmentUrl = message.attachmentUrl;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.fromLTRB(
          attachmentUrl == null ? 14 : 6,
          attachmentUrl == null ? 10 : 6,
          attachmentUrl == null ? 14 : 6,
          10,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachmentUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => _showImageViewer(context, attachmentUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      attachmentUrl,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : const SizedBox(
                              width: 200,
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            if (message.body.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: attachmentUrl == null ? 0 : 8,
                ),
                child: Text(
                  message.body,
                  style: TextStyle(
                    color: isMe
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen pinch-to-zoom viewer, same pattern used across the rest of
/// the app for a tapped photo (gallery, package photo, QR code, legal
/// document) - images are always shown in-app, never via an external
/// browser (see VendorStorefrontScreen's own copy of this helper).
void _showImageViewer(BuildContext context, String imageUrl) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: InteractiveViewer(child: Image.network(imageUrl)),
    ),
  );
}
