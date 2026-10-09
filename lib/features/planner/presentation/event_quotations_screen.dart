import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../marketplace/data/booking_amendment_api.dart';
import '../../marketplace/data/booking_api.dart';
import '../../marketplace/data/models/booking.dart';
import '../../marketplace/data/models/booking_amendment.dart';
import '../../marketplace/data/models/quotation.dart';
import '../../marketplace/data/models/quotation_status_event.dart';
import '../../marketplace/data/quotation_api.dart';
import '../../marketplace/presentation/amendment_widgets.dart';
import '../../marketplace/presentation/attachment_viewer.dart';
import '../../marketplace/presentation/lifecycle_widgets.dart';
import '../../reviews/data/review_api.dart';
import '../../reviews/presentation/review_dialog.dart';

/// Planner-side view of everything happening on a single event: every
/// quotation being negotiated with a vendor, and every resulting booking -
/// the mobile equivalent of eventsrus-web's planner/events.html quotations
/// and bookings tables, scoped to one event.
class EventQuotationsScreen extends StatefulWidget {
  final int eventId;
  final String? eventName;

  const EventQuotationsScreen({
    super.key,
    required this.eventId,
    this.eventName,
  });

  @override
  State<EventQuotationsScreen> createState() => _EventQuotationsScreenState();
}

class _EventQuotationsScreenState extends State<EventQuotationsScreen> {
  List<Quotation>? _quotations;
  List<Booking>? _bookings;
  bool _loading = true;
  int? _busyQuotationId;
  int? _busyBookingId;
  int _unseenQuotations = 0;
  int _unseenBookings = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final quotations = await context.read<QuotationApi>().listForEvent(
        widget.eventId,
      );
      final bookings = await context.read<BookingApi>().listForEvent(
        widget.eventId,
      );
      if (!mounted) return;
      setState(() {
        _quotations = quotations;
        _bookings = bookings;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
    // Unseen-tab badges are a secondary, non-blocking concern.
    try {
      final unseenQuotations = await context
          .read<QuotationApi>()
          .unseenCountForEvent(widget.eventId);
      final unseenBookings = await context
          .read<BookingApi>()
          .unseenCountForEvent(widget.eventId);
      if (!mounted) return;
      setState(() {
        _unseenQuotations = unseenQuotations;
        _unseenBookings = unseenBookings;
      });
    } catch (_) {}
  }

  void _onTabTapped(int index) {
    if (index == 0 && _unseenQuotations > 0) {
      context
          .read<QuotationApi>()
          .markSeenForEvent(widget.eventId)
          .catchError((_) {});
      setState(() => _unseenQuotations = 0);
    } else if (index == 1 && _unseenBookings > 0) {
      context
          .read<BookingApi>()
          .markSeenForEvent(widget.eventId)
          .catchError((_) {});
      setState(() => _unseenBookings = 0);
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

  // ----- Quotation actions -----

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

  // ----- Booking actions -----

  Future<void> _respondToProposal(Booking booking, bool approve) async {
    setState(() => _busyBookingId = booking.id);
    try {
      final api = context.read<BookingApi>();
      if (approve) {
        await api.approve(booking.id);
      } else {
        await api.decline(booking.id);
      }
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyBookingId = null);
    }
  }

  Future<void> _uploadBookingScreenshot(Booking booking) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null ||
        result.files.isEmpty ||
        result.files.single.bytes == null)
      return;
    final file = result.files.single;

    setState(() => _busyBookingId = booking.id);
    try {
      await context.read<BookingApi>().submitPaymentScreenshot(
        bookingId: booking.id,
        screenshotBytes: file.bytes!,
        screenshotFilename: file.name,
      );
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyBookingId = null);
    }
  }

  Future<void> _showBookingReason(Booking booking) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payment Rejected'),
        content: Text(booking.paymentRejectionReason ?? 'No reason on file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(Booking booking) async {
    final reasonController = TextEditingController();
    final requiresPolicyAck =
        booking.cancellationPolicyUrl != null || booking.refundTermsUrl != null;
    bool policyAcknowledged = !requiresPolicyAck;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Cancel Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "This marks the booking as CANCELLED and notifies the vendor. This can't be undone.",
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for cancellation',
                ),
                maxLines: 3,
              ),
              if (requiresPolicyAck) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  children: [
                    if (booking.cancellationPolicyUrl != null)
                      TextButton(
                        onPressed: () =>
                            openDocument(booking.cancellationPolicyUrl!),
                        child: const Text('Cancellation Policy'),
                      ),
                    if (booking.refundTermsUrl != null)
                      TextButton(
                        onPressed: () => openDocument(booking.refundTermsUrl!),
                        child: const Text('Refund Terms'),
                      ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: policyAcknowledged,
                  onChanged: (value) =>
                      setDialogState(() => policyAcknowledged = value ?? false),
                  title: const Text(
                    'I have read and agree to the cancellation policy and refund terms.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Never mind'),
            ),
            FilledButton(
              onPressed: policyAcknowledged
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: const Text('Cancel Booking'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    setState(() => _busyBookingId = booking.id);
    try {
      await context.read<BookingApi>().cancel(
        bookingId: booking.id,
        reason: reasonController.text.trim(),
      );
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyBookingId = null);
    }
  }

  Future<void> _showBookingHistory(Booking booking) async {
    try {
      final history = await context.read<BookingApi>().history(booking.id);
      if (!mounted) return;
      await showBookingHistoryDialog(context, history);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _proposeAmendment(Booking booking) async {
    final input = await showProposeAmendmentDialog(context);
    if (input == null) return;

    setState(() => _busyBookingId = booking.id);
    try {
      await context.read<BookingAmendmentApi>().propose(
        bookingId: booking.id,
        note: input.note,
        newPrice: input.newPrice,
        newEventDatetime: input.newEventDatetime,
        newAgreementDetails: input.newAgreementDetails,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Amendment proposed.')));
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyBookingId = null);
    }
  }

  Future<void> _viewAmendments(Booking booking) async {
    final amendmentApi = context.read<BookingAmendmentApi>();
    List<BookingAmendment> amendments;
    try {
      amendments = await amendmentApi.listForBooking(booking.id);
    } catch (e) {
      _showError(e);
      return;
    }
    if (!mounted) return;

    await showAmendmentsDialog(
      context,
      amendments: amendments,
      // The viewer on this screen is always the planner on this booking -
      // compare against booking.plannerUserId (a real id both sides already
      // have) rather than a name-prefix match against proposedByName, which
      // can misfire for two users with similar first names.
      isProposedByMe: (amendment) =>
          amendment.proposedByUserId == booking.plannerUserId,
      onAccept: (amendment) => _respondToAmendment(booking, amendment.id, true),
      onReject: (amendment) =>
          _respondToAmendment(booking, amendment.id, false),
      onWithdraw: (amendment) => _withdrawAmendment(booking, amendment.id),
    );
  }

  Future<void> _respondToAmendment(
    Booking booking,
    int amendmentId,
    bool accept,
  ) async {
    setState(() => _busyBookingId = booking.id);
    try {
      final api = context.read<BookingAmendmentApi>();
      if (accept) {
        await api.accept(amendmentId);
      } else {
        await api.reject(amendmentId);
      }
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyBookingId = null);
    }
  }

  Future<void> _withdrawAmendment(Booking booking, int amendmentId) async {
    setState(() => _busyBookingId = booking.id);
    try {
      await context.read<BookingAmendmentApi>().withdraw(amendmentId);
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyBookingId = null);
    }
  }

  // ----- Review actions -----

  /// Leaves a first review (booking.canReview) or edits the existing one
  /// (booking.reviewId != null) - see Booking's canReview/reviewId/
  /// reviewRating/reviewComment fields, which already mirror
  /// BookingResponse#canReview et al.
  Future<void> _leaveOrEditReview(Booking booking) async {
    final isEdit = booking.reviewId != null;
    final result = await showReviewFormDialog(
      context,
      vendorLabel: booking.vendorBusinessName ?? 'Vendor',
      initialRating: isEdit ? booking.reviewRating : null,
      initialComment: isEdit ? booking.reviewComment : null,
    );
    if (result == null) return;

    setState(() => _busyBookingId = booking.id);
    try {
      final api = context.read<ReviewApi>();
      if (isEdit) {
        await api.update(
          reviewId: booking.reviewId!,
          rating: result.rating,
          comment: result.comment,
        );
      } else {
        await api.submit(
          bookingId: booking.id,
          rating: result.rating,
          comment: result.comment,
        );
      }
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyBookingId = null);
    }
  }

  Widget _tabLabel(String text, int unseenCount) {
    if (unseenCount == 0) return Text(text);
    return Badge(label: Text('$unseenCount'), child: Text(text));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.eventName ?? 'Quotations & Bookings'),
          bottom: TabBar(
            onTap: _onTabTapped,
            tabs: [
              Tab(child: _tabLabel('Quotations', _unseenQuotations)),
              Tab(child: _tabLabel('Bookings', _unseenBookings)),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [_buildQuotationsTab(), _buildBookingsTab()],
              ),
      ),
    );
  }

  Widget _buildQuotationsTab() {
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

  Widget _buildBookingsTab() {
    final bookings = _bookings ?? [];
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings for this event yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final busy = _busyBookingId == booking.id;
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
                        booking.vendorBusinessName ?? 'Vendor',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${booking.price != null ? formatPeso(booking.price!) : 'No price set'}'
                        '${booking.eventDatetime != null ? ' • ${formatDate(booking.eventDatetime!)}' : ''}',
                      ),
                      if (booking.hasPendingAmendment)
                        const Text(
                          'Amendment pending',
                          style: TextStyle(color: Colors.orange),
                        ),
                      const SizedBox(height: 6),
                      BookingStatusChip(status: booking.status),
                      if (booking.reviewRating != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              StarRatingRow(
                                rating: booking.reviewRating!.toDouble(),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Your review',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
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
                            case 'approve':
                              _respondToProposal(booking, true);
                            case 'declineProposal':
                              _respondToProposal(booking, false);
                            case 'screenshot':
                              _uploadBookingScreenshot(booking);
                            case 'reason':
                              _showBookingReason(booking);
                            case 'cancel':
                              _cancelBooking(booking);
                            case 'history':
                              _showBookingHistory(booking);
                            case 'proposeAmendment':
                              _proposeAmendment(booking);
                            case 'viewAmendments':
                              _viewAmendments(booking);
                            case 'review':
                              _leaveOrEditReview(booking);
                            case 'viewScreenshot':
                              showImageViewer(
                                context,
                                booking.paymentScreenshotUrl!,
                              );
                            case 'viewInvoice':
                              openDocument(booking.invoiceUrl!);
                          }
                        },
                        itemBuilder: (context) => [
                          if (booking.status == BookingStatus.proposed) ...[
                            const PopupMenuItem(
                              value: 'approve',
                              child: Text('Approve'),
                            ),
                            const PopupMenuItem(
                              value: 'declineProposal',
                              child: Text('Decline'),
                            ),
                          ],
                          if (booking.status == BookingStatus.awaitingPayment ||
                              booking.status == BookingStatus.paymentRejected)
                            const PopupMenuItem(
                              value: 'screenshot',
                              child: Text('Upload Payment Screenshot'),
                            ),
                          if (booking.status == BookingStatus.paymentRejected)
                            const PopupMenuItem(
                              value: 'reason',
                              child: Text('View Reason'),
                            ),
                          if (booking.paymentScreenshotUrl != null)
                            const PopupMenuItem(
                              value: 'viewScreenshot',
                              child: Text('View Screenshot'),
                            ),
                          if (booking.invoiceUrl != null)
                            const PopupMenuItem(
                              value: 'viewInvoice',
                              child: Text('View Invoice'),
                            ),
                          if (booking.status == BookingStatus.booked &&
                              !booking.hasPendingAmendment)
                            const PopupMenuItem(
                              value: 'proposeAmendment',
                              child: Text('Propose Amendment'),
                            ),
                          if (booking.status == BookingStatus.booked &&
                              booking.hasPendingAmendment)
                            const PopupMenuItem(
                              value: 'viewAmendments',
                              child: Text('View Amendment'),
                            ),
                          if (booking.canReview)
                            const PopupMenuItem(
                              value: 'review',
                              child: Text('Leave a Review'),
                            ),
                          if (booking.reviewId != null)
                            const PopupMenuItem(
                              value: 'review',
                              child: Text('Edit Your Review'),
                            ),
                          if (!booking.isTerminal)
                            const PopupMenuItem(
                              value: 'cancel',
                              child: Text('Cancel'),
                            ),
                          const PopupMenuItem(
                            value: 'history',
                            child: Text('History'),
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
