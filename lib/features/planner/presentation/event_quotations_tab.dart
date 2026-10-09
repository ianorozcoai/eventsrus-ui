import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../marketplace/data/models/quotation.dart';
import '../../marketplace/data/models/quotation_status_event.dart';
import '../../marketplace/data/quotation_api.dart';
import '../../marketplace/presentation/attachment_viewer.dart';
import '../../marketplace/presentation/lifecycle_widgets.dart';

/// The "Quotations" tab inside [PlannerEventShell] - every quotation being
/// negotiated with a vendor for this one event. Split out of the old
/// EventQuotationsScreen (which used to tab Quotations/Bookings together)
/// now that each is its own bottom-nav destination.
class EventQuotationsTab extends StatefulWidget {
  final int eventId;

  const EventQuotationsTab({super.key, required this.eventId});

  @override
  State<EventQuotationsTab> createState() => EventQuotationsTabState();
}

class EventQuotationsTabState extends State<EventQuotationsTab> {
  List<Quotation>? _quotations;
  bool _loading = true;
  int? _busyQuotationId;

  static const _canAcceptOrRevise = {
    QuotationStatus.quoteSent,
    QuotationStatus.revisionSent,
  };
  static const _canDecline = {
    QuotationStatus.requestForQuote,
    QuotationStatus.quoteSent,
    QuotationStatus.revisionRequested,
    QuotationStatus.revisionSent,
  };
  static const _canUploadScreenshot = {
    QuotationStatus.pendingDeposit,
    QuotationStatus.paymentRejected,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  /// Exposed so [PlannerEventShell] can refresh this tab after an action
  /// taken elsewhere (e.g. switching into this tab clears its unseen badge
  /// but doesn't need a reload; this is for anything that does).
  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final quotations = await context.read<QuotationApi>().listForEvent(widget.eventId);
      if (!mounted) return;
      setState(() {
        _quotations = quotations;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is ApiException
        ? error.message
        : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _acceptQuote(Quotation quotation) async {
    List<QuotationStatusEvent> history = [];
    try {
      history = await context.read<QuotationApi>().history(quotation.id);
    } catch (_) {
      // Fall back to just the current version below.
    }
    final versions = history
        .where(
          (e) =>
              e.toStatus == QuotationStatus.quoteSent ||
              e.toStatus == QuotationStatus.revisionSent,
        )
        .toList();

    int? selectedVersion = quotation.version;
    final messageController = TextEditingController();
    PlatformFile? screenshot;
    final requiresPolicyAck =
        quotation.cancellationPolicyUrl != null ||
        quotation.refundTermsUrl != null;
    bool policyAcknowledged = !requiresPolicyAck;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            "Accept ${quotation.vendorBusinessName ?? 'Vendor'}'s Quotation",
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (versions.isNotEmpty) ...[
                  const Text(
                    'Which version would you like to accept?',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  RadioGroup<int>(
                    groupValue: selectedVersion,
                    onChanged: (value) =>
                        setDialogState(() => selectedVersion = value),
                    child: Column(
                      children: [
                        for (final entry in versions)
                          RadioListTile<int>(
                            value: entry.version ?? quotation.version,
                            title: Text(
                              'Version ${entry.version} • ${entry.quotedAmount != null ? formatPeso(entry.quotedAmount!) : '-'}',
                            ),
                            subtitle: entry.targetDate != null
                                ? Text(
                                    'Target date: ${formatDate(entry.targetDate!)}',
                                  )
                                : null,
                          ),
                      ],
                    ),
                  ),
                ] else
                  Text(
                    'Version ${quotation.version} • ${quotation.quotedAmount != null ? formatPeso(quotation.quotedAmount!) : '-'}',
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Accepting locks in the version you choose. You can pay the deposit now or come back later.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message to the vendor (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    screenshot == null
                        ? 'Attach payment screenshot (optional)'
                        : screenshot!.name,
                  ),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      setDialogState(() => screenshot = result.files.single);
                    }
                  },
                ),
                if (requiresPolicyAck) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (quotation.cancellationPolicyUrl != null)
                        TextButton(
                          onPressed: () =>
                              openDocument(quotation.cancellationPolicyUrl!),
                          child: const Text('Cancellation Policy'),
                        ),
                      if (quotation.refundTermsUrl != null)
                        TextButton(
                          onPressed: () =>
                              openDocument(quotation.refundTermsUrl!),
                          child: const Text('Refund Terms'),
                        ),
                    ],
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: policyAcknowledged,
                    onChanged: (value) => setDialogState(
                      () => policyAcknowledged = value ?? false,
                    ),
                    title: const Text(
                      'I have read and agree to the cancellation policy and refund terms.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: policyAcknowledged
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: const Text('Accept Quote'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _busyQuotationId = quotation.id);
    try {
      await context.read<QuotationApi>().acceptQuote(
        quotationId: quotation.id,
        acceptedVersion: selectedVersion,
        message: messageController.text.trim().isEmpty
            ? null
            : messageController.text.trim(),
        screenshotBytes: screenshot?.bytes,
        screenshotFilename: screenshot?.name,
      );
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyQuotationId = null);
    }
  }

  Future<void> _requestRevision(Quotation quotation) async {
    final messageController = TextEditingController();
    DateTime? targetDate = quotation.targetDate;
    List<PlatformFile> images = [];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            'Request Revision - ${quotation.vendorBusinessName ?? 'Vendor'}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    targetDate == null
                        ? 'Target date (optional)'
                        : formatDate(targetDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: targetDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 1095)),
                    );
                    if (date != null) setDialogState(() => targetDate = date);
                  },
                ),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'What would you like changed?',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    images.isEmpty
                        ? 'Add reference images (optional)'
                        : '${images.length} image(s) selected',
                  ),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: true,
                      withData: true,
                    );
                    if (result != null)
                      setDialogState(() => images = result.files);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: messageController.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(true),
              child: const Text('Send Revision Request'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || messageController.text.trim().isEmpty) return;

    setState(() => _busyQuotationId = quotation.id);
    try {
      await context.read<QuotationApi>().requestRevision(
        quotationId: quotation.id,
        message: messageController.text.trim(),
        targetDate: targetDate,
        images: [
          for (final image in images)
            (bytes: image.bytes!, filename: image.name),
        ],
      );
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyQuotationId = null);
    }
  }

  Future<void> _declineQuotation(Quotation quotation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Decline Quotation - ${quotation.vendorBusinessName ?? 'Vendor'}',
        ),
        content: const Text(
          "Not going with this vendor for this quote? This closes it out - it won't affect any other quotations for this event.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Never mind'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Decline Quotation'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busyQuotationId = quotation.id);
    try {
      await context.read<QuotationApi>().decline(quotation.id);
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyQuotationId = null);
    }
  }

  Future<void> _uploadQuotationScreenshot(Quotation quotation) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null ||
        result.files.isEmpty ||
        result.files.single.bytes == null)
      return;
    final file = result.files.single;

    setState(() => _busyQuotationId = quotation.id);
    try {
      await context.read<QuotationApi>().submitPaymentScreenshot(
        quotationId: quotation.id,
        screenshotBytes: file.bytes!,
        screenshotFilename: file.name,
      );
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyQuotationId = null);
    }
  }

  Future<void> _sendQuotationAttachment(Quotation quotation) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null ||
        result.files.isEmpty ||
        result.files.single.bytes == null)
      return;
    final file = result.files.single;
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Attachment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${file.name}'),
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
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyQuotationId = quotation.id);
    try {
      await context.read<QuotationApi>().addAttachment(
        quotationId: quotation.id,
        fileBytes: file.bytes!,
        filename: file.name,
        message: messageController.text.trim().isEmpty
            ? null
            : messageController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attachment sent.')));
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyQuotationId = null);
    }
  }

  Future<void> _showQuotationHistory(Quotation quotation) async {
    try {
      final history = await context.read<QuotationApi>().history(quotation.id);
      if (!mounted) return;
      await showQuotationHistoryDialog(context, history);
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final quotations = _quotations ?? [];
    if (quotations.isEmpty) {
      return const Center(
        child: Text('No quotations requested for this event yet.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: quotations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final quotation = quotations[index];
        final busy = _busyQuotationId == quotation.id;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quotation.vendorBusinessName ?? 'Vendor',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (quotation.quotedAmount != null)
                        Text(
                          formatPeso(quotation.quotedAmount!),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      Text(
                        quotation.requestMessage ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      QuotationStatusChip(
                        status: quotation.status,
                        version: quotation.version,
                      ),
                    ],
                  ),
                ),
                busy
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : PopupMenuButton<String>(
                        onSelected: (action) {
                          switch (action) {
                            case 'accept':
                              _acceptQuote(quotation);
                            case 'revise':
                              _requestRevision(quotation);
                            case 'decline':
                              _declineQuotation(quotation);
                            case 'screenshot':
                              _uploadQuotationScreenshot(quotation);
                            case 'history':
                              _showQuotationHistory(quotation);
                            case 'attachment':
                              _sendQuotationAttachment(quotation);
                            case 'viewPdf':
                              openDocument(quotation.pdfUrl!);
                            case 'viewReferenceImages':
                              showImageGalleryDialog(
                                context,
                                'Reference Images',
                                quotation.referenceImageUrls,
                              );
                            case 'viewResponseImages':
                              showImageGalleryDialog(
                                context,
                                'Quote Images',
                                quotation.responseImageUrls,
                              );
                            case 'viewPaymentScreenshot':
                              showImageViewer(
                                context,
                                quotation.paymentScreenshotUrl!,
                              );
                          }
                        },
                        itemBuilder: (context) => [
                          if (_canAcceptOrRevise.contains(
                            quotation.status,
                          )) ...[
                            const PopupMenuItem(
                              value: 'accept',
                              child: Text('Accept Quote'),
                            ),
                            const PopupMenuItem(
                              value: 'revise',
                              child: Text('Request Revision'),
                            ),
                          ],
                          if (_canUploadScreenshot.contains(quotation.status))
                            const PopupMenuItem(
                              value: 'screenshot',
                              child: Text('Upload Payment Screenshot'),
                            ),
                          if (quotation.pdfUrl != null)
                            const PopupMenuItem(
                              value: 'viewPdf',
                              child: Text('View Quote PDF'),
                            ),
                          if (quotation.referenceImageUrls.isNotEmpty)
                            const PopupMenuItem(
                              value: 'viewReferenceImages',
                              child: Text('View Reference Images'),
                            ),
                          if (quotation.responseImageUrls.isNotEmpty)
                            const PopupMenuItem(
                              value: 'viewResponseImages',
                              child: Text('View Quote Images'),
                            ),
                          if (quotation.paymentScreenshotUrl != null)
                            const PopupMenuItem(
                              value: 'viewPaymentScreenshot',
                              child: Text('View Payment Screenshot'),
                            ),
                          if (_canDecline.contains(quotation.status))
                            const PopupMenuItem(
                              value: 'decline',
                              child: Text('Decline'),
                            ),
                          const PopupMenuItem(
                            value: 'history',
                            child: Text('History'),
                          ),
                          const PopupMenuItem(
                            value: 'attachment',
                            child: Text('Send Attachment'),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
