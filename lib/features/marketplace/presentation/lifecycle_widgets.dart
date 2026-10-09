import 'package:flutter/material.dart';

import '../data/models/booking.dart';
import '../data/models/booking_status_event.dart';
import '../data/models/quotation.dart';
import '../data/models/quotation_status_event.dart';
import 'attachment_viewer.dart';

/// Shared presentation helpers for the quotation/booking lifecycle screens
/// (vendor quotations/bookings, planner event quotations/bookings) - status
/// color mapping mirrors the badge classes eventsrus-web uses on
/// vendor/quotations.html, vendor/bookings.html and planner/events.html so
/// the mobile app reads the same way.

Color quotationStatusColor(QuotationStatus status, ColorScheme scheme) {
  switch (status) {
    case QuotationStatus.booked:
      return Colors.green;
    case QuotationStatus.cancelled:
      return scheme.error;
    case QuotationStatus.declined:
    case QuotationStatus.paymentRejected:
      return Colors.grey;
    case QuotationStatus.quoteSent:
    case QuotationStatus.revisionSent:
      return Colors.blue;
    case QuotationStatus.pendingDeposit:
    case QuotationStatus.paymentReview:
    case QuotationStatus.quoteAccepted:
      return Colors.indigo;
    case QuotationStatus.requestForQuote:
    case QuotationStatus.revisionRequested:
      return Colors.orange;
  }
}

Color bookingStatusColor(BookingStatus status, ColorScheme scheme) {
  switch (status) {
    case BookingStatus.approved:
    case BookingStatus.booked:
      return Colors.green;
    case BookingStatus.proposed:
    case BookingStatus.paymentSubmitted:
      return Colors.orange;
    case BookingStatus.awaitingPayment:
      return Colors.blue;
    case BookingStatus.declined:
      return Colors.grey;
    case BookingStatus.cancelled:
    case BookingStatus.paymentRejected:
      return scheme.error;
  }
}

class QuotationStatusChip extends StatelessWidget {
  final QuotationStatus status;
  final int? version;

  const QuotationStatusChip({super.key, required this.status, this.version});

  @override
  Widget build(BuildContext context) {
    final color = quotationStatusColor(status, Theme.of(context).colorScheme);
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Chip(
          label: Text(status.label),
          backgroundColor: color.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        ),
        if (version != null)
          Text('v$version', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class BookingStatusChip extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = bookingStatusColor(status, Theme.of(context).colorScheme);
    return Chip(
      label: Text(status.label),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

String formatPeso(double amount) => '₱${amount.toStringAsFixed(2)}';

String formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.month}/${local.day}/${local.year}';
}

String formatDateTime(DateTime date) {
  final local = date.toLocal();
  return '${local.month}/${local.day}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

Future<void> showQuotationHistoryDialog(
  BuildContext context,
  List<QuotationStatusEvent> history,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Quotation History'),
      content: SizedBox(
        width: 420,
        child: history.isEmpty
            ? const Text('No history yet.')
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in history)
                      _QuotationHistoryTile(entry: entry),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _QuotationHistoryTile extends StatelessWidget {
  final QuotationStatusEvent entry;

  const _QuotationHistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isAttachment = entry.entryType == HistoryEntryType.attachment;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!isAttachment && entry.toStatus != null)
                QuotationStatusChip(
                  status: entry.toStatus!,
                  version: entry.version,
                )
              else
                const Chip(
                  label: Text('Attachment'),
                  visualDensity: VisualDensity.compact,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entry.changedByName ?? 'Someone'} · ${formatDateTime(entry.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (entry.reason != null && entry.reason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(entry.reason!),
            ),
          if (entry.quotedAmount != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Quoted: ${formatPeso(entry.quotedAmount!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (entry.targetDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Target date: ${formatDate(entry.targetDate!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (entry.packageNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Packages: ${entry.packageNames.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Wrap(
            spacing: 4,
            children: [
              if (entry.pdfUrl != null)
                DocumentLinkButton(label: 'Quote PDF', url: entry.pdfUrl!),
              if (entry.paymentScreenshotUrl != null)
                DocumentLinkButton(
                  label: 'Payment Screenshot',
                  url: entry.paymentScreenshotUrl!,
                  isImage: true,
                ),
              if (entry.invoiceUrl != null)
                DocumentLinkButton(label: 'Invoice', url: entry.invoiceUrl!),
              if (entry.attachmentUrl != null)
                DocumentLinkButton(
                  label: 'Attachment',
                  url: entry.attachmentUrl!,
                  isImage: entry.attachmentFileType == 'IMAGE',
                ),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

Future<void> showBookingHistoryDialog(
  BuildContext context,
  List<BookingStatusEvent> history,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Booking History'),
      content: SizedBox(
        width: 420,
        child: history.isEmpty
            ? const Text('No history yet.')
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in history)
                      _BookingHistoryTile(entry: entry),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _BookingHistoryTile extends StatelessWidget {
  final BookingStatusEvent entry;

  const _BookingHistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (entry.toStatus != null)
                BookingStatusChip(status: entry.toStatus!),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entry.changedByName ?? 'Someone'} · ${formatDateTime(entry.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (entry.reason != null && entry.reason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(entry.reason!),
            ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}
