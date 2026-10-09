import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../marketplace/data/models/quotation.dart';
import '../../marketplace/data/quotation_api.dart';
import '../../marketplace/presentation/attachment_viewer.dart';
import '../../marketplace/presentation/lifecycle_widgets.dart';
import '../../planner/data/models/planner_event_type.dart';

class VendorQuotationsScreen extends StatefulWidget {
  const VendorQuotationsScreen({super.key});

  @override
  State<VendorQuotationsScreen> createState() => _VendorQuotationsScreenState();
}

class _VendorQuotationsScreenState extends State<VendorQuotationsScreen> {
  List<Quotation>? _quotations;
  bool _loading = true;
  int? _busyId;

  static const _awaitingVendor = {
    QuotationStatus.requestForQuote,
    QuotationStatus.revisionRequested,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<QuotationApi>();
      final quotations = await api.listForVendor();
      unawaited(api.markSeen().catchError((_) {}));
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

  Future<void> _respond(Quotation quotation) async {
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

    final amountController = TextEditingController();
    final messageController = TextEditingController();
    List<PlatformFile> images = [];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            'Respond to ${quotation.eventName ?? 'Event #${quotation.eventId}'}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (quotation.eventType != null ||
                    quotation.packageNames.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (quotation.eventType != null)
                        Chip(
                          label: Text(quotation.eventType!.label),
                          visualDensity: VisualDensity.compact,
                        ),
                      for (final name in quotation.packageNames)
                        Chip(
                          label: Text(name),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (quotation.targetDate != null) ...[
                  Text(
                    'Target date: ${formatDate(quotation.targetDate!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                ],
                if (quotation.requestMessage != null &&
                    quotation.requestMessage!.isNotEmpty) ...[
                  Text(quotation.requestMessage!),
                  const SizedBox(height: 8),
                ],
                if (quotation.referenceImageUrls.isNotEmpty) ...[
                  Text(
                    'Reference images',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  ImageThumbnailRow(imageUrls: quotation.referenceImageUrls),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Quote PDF: ${pdf.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Quoted Amount (₱)',
                  ),
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    images.isEmpty
                        ? 'Add images (optional)'
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
              onPressed: double.tryParse(amountController.text.trim()) == null
                  ? null
                  : () => Navigator.of(dialogContext).pop(true),
              child: const Text('Send Quote'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) return;

    setState(() => _busyId = quotation.id);
    try {
      await context.read<QuotationApi>().respondWithPdf(
        quotationId: quotation.id,
        pdfBytes: pdf.bytes!,
        pdfFilename: pdf.name,
        quotedAmount: amount,
        message: messageController.text.trim().isEmpty
            ? null
            : messageController.text.trim(),
        images: [
          for (final image in images)
            (bytes: image.bytes!, filename: image.name),
        ],
      );
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _acceptBooking(Quotation quotation) async {
    final messageController = TextEditingController();
    String? paymentType;
    PlatformFile? invoice;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Accept Booking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirming this creates the booking and locks the quote.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmation message (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: paymentType,
                  onChanged: (value) =>
                      setDialogState(() => paymentType = value),
                  child: Column(
                    children: const [
                      RadioListTile<String>(
                        value: 'PARTIAL',
                        title: Text('Partial (deposit)'),
                      ),
                      RadioListTile<String>(
                        value: 'FULL',
                        title: Text('Full payment'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    invoice == null
                        ? 'Attach invoice / receipt'
                        : invoice!.name,
                  ),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      setDialogState(() => invoice = result.files.single);
                    }
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
              onPressed: paymentType == null || invoice == null
                  ? null
                  : () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true ||
        paymentType == null ||
        invoice == null ||
        invoice!.bytes == null)
      return;

    setState(() => _busyId = quotation.id);
    try {
      await context.read<QuotationApi>().acceptBooking(
        quotationId: quotation.id,
        confirmationMessage: messageController.text.trim().isEmpty
            ? null
            : messageController.text.trim(),
        paymentType: paymentType!,
        invoiceBytes: invoice!.bytes!,
        invoiceFilename: invoice!.name,
      );
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _rejectPayment(Quotation quotation) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Payment'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: "e.g. Amount doesn't match",
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Never mind'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reject Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    setState(() => _busyId = quotation.id);
    try {
      await context.read<QuotationApi>().rejectPayment(
        quotationId: quotation.id,
        reason: reasonController.text.trim(),
      );
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _sendAttachment(Quotation quotation) async {
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

    setState(() => _busyId = quotation.id);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment sent to the planner.')),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _showHistory(Quotation quotation) async {
    try {
      final history = await context.read<QuotationApi>().history(quotation.id);
      if (!mounted) return;
      await showQuotationHistoryDialog(context, history);
    } catch (e) {
      _showError(e);
    }
  }

  // Same 3-way split as eventsrus-web's vendor/quotations.html tabs.
  static const _declinedStatuses = {
    QuotationStatus.declined,
    QuotationStatus.cancelled,
  };

  List<Quotation> _inProgress(List<Quotation> all) => all
      .where(
        (q) =>
            q.status != QuotationStatus.booked &&
            !_declinedStatuses.contains(q.status),
      )
      .toList();
  List<Quotation> _booked(List<Quotation> all) =>
      all.where((q) => q.status == QuotationStatus.booked).toList();
  List<Quotation> _declined(List<Quotation> all) =>
      all.where((q) => _declinedStatuses.contains(q.status)).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final quotations = _quotations ?? [];
    final inProgress = _inProgress(quotations);
    final booked = _booked(quotations);
    final declined = _declined(quotations);

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quotations Hub',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              tabs: [
                Tab(text: 'In-Progress (${inProgress.length})'),
                Tab(text: 'Booked (${booked.length})'),
                Tab(text: 'Declined (${declined.length})'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(inProgress, 'No quotation requests yet.'),
                  _buildList(booked, 'No booked quotations yet.'),
                  _buildList(declined, 'No declined quotations yet.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Quotation> quotations, String emptyMessage) {
    return quotations.isEmpty
        ? Center(child: Text(emptyMessage))
        : ListView.separated(
            itemCount: quotations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final quotation = quotations[index];
              final busy = _busyId == quotation.id;
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
                              quotation.eventName ??
                                  'Event #${quotation.eventId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              quotation.plannerName ?? 'Planner',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : PopupMenuButton<String>(
                              onSelected: (action) {
                                switch (action) {
                                  case 'respond':
                                    _respond(quotation);
                                  case 'acceptBooking':
                                    _acceptBooking(quotation);
                                  case 'rejectPayment':
                                    _rejectPayment(quotation);
                                  case 'history':
                                    _showHistory(quotation);
                                  case 'attachment':
                                    _sendAttachment(quotation);
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
                                      'My Attached Images',
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
                                if (_awaitingVendor.contains(quotation.status))
                                  const PopupMenuItem(
                                    value: 'respond',
                                    child: Text('Respond'),
                                  ),
                                if (quotation.status ==
                                    QuotationStatus.paymentReview) ...[
                                  const PopupMenuItem(
                                    value: 'acceptBooking',
                                    child: Text('Accept Booking'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'rejectPayment',
                                    child: Text('Reject Payment'),
                                  ),
                                ],
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
                                    child: Text('View My Attached Images'),
                                  ),
                                if (quotation.paymentScreenshotUrl != null)
                                  const PopupMenuItem(
                                    value: 'viewPaymentScreenshot',
                                    child: Text('View Payment Screenshot'),
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

void unawaited(Future<void> future) {}
