import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../data/moderation_api.dart';
import '../data/moderation_models.dart';

/// What the person chose in the report dialog.
class ReportDraft {
  final ReportReason reason;
  final String? details;

  const ReportDraft(this.reason, this.details);
}

/// Asks for a reason (and an optional note). Returns null if cancelled.
Future<ReportDraft?> showReportDialog(BuildContext context, {required String subject}) {
  return showDialog<ReportDraft>(
    context: context,
    builder: (_) => _ReportDialog(subject: subject),
  );
}

class _ReportDialog extends StatefulWidget {
  final String subject;

  const _ReportDialog({required this.subject});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  ReportReason? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.subject}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us what is wrong. Our team will look at it. The person is not told who reported them.',
            ),
            const SizedBox(height: 8),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: [
                  for (final reason in ReportReason.values)
                    RadioListTile<ReportReason>(
                      value: reason,
                      contentPadding: EdgeInsets.zero,
                      title: Text(reason.label),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _details,
              maxLength: 1000,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'More details (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _reason == null
              ? null
              : () => Navigator.of(context).pop(ReportDraft(_reason!, _details.text)),
          child: const Text('Send report'),
        ),
      ],
    );
  }
}

/// Dialog, then send, then a plain-language confirmation or the reason it failed.
Future<void> reportWithDialog(
  BuildContext context, {
  required ReportContentType contentType,
  required int contentId,
  required String subject,
}) async {
  final api = context.read<ModerationApi>();
  final messenger = ScaffoldMessenger.of(context);
  final draft = await showReportDialog(context, subject: subject);
  if (draft == null) return;
  try {
    await api.report(
      contentType: contentType,
      contentId: contentId,
      reason: draft.reason,
      details: draft.details,
    );
    messenger.showSnackBar(const SnackBar(content: Text('Thanks. We received your report and will look into it.')));
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// Confirm, then block. Returns true if the person is now blocked.
Future<bool> confirmAndBlock(BuildContext context, {required int userId, required String name}) async {
  final api = context.read<ModerationApi>();
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Block $name?'),
      content: const Text(
        'You and this person will no longer be able to message each other. '
        'Your earlier messages stay as they are, and they are not told you blocked them. '
        'You can unblock them later: tap the three dots at the top, then Blocked users.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Block')),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    await api.blockUser(userId);
    messenger.showSnackBar(SnackBar(content: Text('$name is blocked.')));
    return true;
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
}
