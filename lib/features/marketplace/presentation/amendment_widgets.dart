import 'package:flutter/material.dart';

import '../data/models/booking_amendment.dart';
import 'lifecycle_widgets.dart';

/// Shared dialogs for the post-booking amendment ("change order") flow -
/// used by both the vendor's and the planner's booking screens, since
/// either side can propose/accept/reject/withdraw (see
/// BookingAmendmentApi/BookingAmendmentService on the backend - there's no
/// vendor-only or planner-only restriction on who may propose).

/// Prompts for a new price/date/details plus a required note explaining the
/// change. Returns null if the user cancelled.
Future<
    ({
      double? newPrice,
      DateTime? newEventDatetime,
      String? newAgreementDetails,
      String note,
    })?> showProposeAmendmentDialog(BuildContext context) {
  final priceController = TextEditingController();
  final detailsController = TextEditingController();
  final noteController = TextEditingController();
  DateTime? newEventDatetime;

  return showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Propose a Change'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Leave any field blank to keep it unchanged.', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'New price (optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(newEventDatetime == null ? 'New date & time (optional)' : newEventDatetime.toString()),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final date = await showDatePicker(
                    context: dialogContext,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 1095)),
                  );
                  if (date != null) setDialogState(() => newEventDatetime = date);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'New agreement details (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note explaining the change'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (noteController.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop((
                newPrice: double.tryParse(priceController.text.trim()),
                newEventDatetime: newEventDatetime,
                newAgreementDetails: detailsController.text.trim().isEmpty ? null : detailsController.text.trim(),
                note: noteController.text.trim(),
              ));
            },
            child: const Text('Send Proposal'),
          ),
        ],
      ),
    ),
  );
}

/// Shows this booking's amendment history with Accept/Reject (for a pending
/// amendment proposed by the other side) or Withdraw (for one proposed by
/// the current user) actions. [isProposedByMe] lets the caller apply
/// whatever "is this my own proposal" check it can - the backend is the
/// final source of truth either way and will reject the wrong action with a
/// clear message.
Future<void> showAmendmentsDialog(
  BuildContext context, {
  required List<BookingAmendment> amendments,
  required bool Function(BookingAmendment amendment) isProposedByMe,
  required Future<void> Function(BookingAmendment amendment) onAccept,
  required Future<void> Function(BookingAmendment amendment) onReject,
  required Future<void> Function(BookingAmendment amendment) onWithdraw,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Amendments'),
      content: SizedBox(
        width: 420,
        child: amendments.isEmpty
            ? const Text('No amendments proposed yet.')
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final amendment in amendments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Chip(
                                  label: Text(amendment.status.label),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${amendment.proposedByName ?? 'Someone'} · ${formatDateTime(amendment.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(amendment.note),
                            if (amendment.newPrice != null)
                              Text('New price: ${formatPeso(amendment.newPrice!)}',
                                  style: Theme.of(context).textTheme.bodySmall),
                            if (amendment.newEventDatetime != null)
                              Text('New date: ${formatDateTime(amendment.newEventDatetime!)}',
                                  style: Theme.of(context).textTheme.bodySmall),
                            if (amendment.newAgreementDetails != null)
                              Text('New details: ${amendment.newAgreementDetails}',
                                  style: Theme.of(context).textTheme.bodySmall),
                            if (amendment.status.name == 'pending') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (!isProposedByMe(amendment)) ...[
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(dialogContext).pop();
                                        await onReject(amendment);
                                      },
                                      child: const Text('Reject'),
                                    ),
                                    FilledButton(
                                      onPressed: () async {
                                        Navigator.of(dialogContext).pop();
                                        await onAccept(amendment);
                                      },
                                      child: const Text('Accept'),
                                    ),
                                  ] else
                                    OutlinedButton(
                                      onPressed: () async {
                                        Navigator.of(dialogContext).pop();
                                        await onWithdraw(amendment);
                                      },
                                      child: const Text('Withdraw'),
                                    ),
                                ],
                              ),
                            ],
                            const Divider(height: 16),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
      ],
    ),
  );
}
