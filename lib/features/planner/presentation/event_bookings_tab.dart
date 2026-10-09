import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../marketplace/data/booking_amendment_api.dart';
import '../../marketplace/data/booking_api.dart';
import '../../marketplace/data/models/booking.dart';
import '../../marketplace/data/models/booking_amendment.dart';
import '../../marketplace/presentation/amendment_widgets.dart';
import '../../marketplace/presentation/attachment_viewer.dart';
import '../../marketplace/presentation/lifecycle_widgets.dart';
import '../../reviews/data/review_api.dart';
import '../../reviews/presentation/review_dialog.dart';

/// The "Booking" tab inside [PlannerEventShell] - every booking resulting
/// from an accepted quotation for this one event. Split out of the old
/// EventQuotationsScreen now that each is its own bottom-nav destination.
class EventBookingsTab extends StatefulWidget {
  final int eventId;

  const EventBookingsTab({super.key, required this.eventId});

  @override
  State<EventBookingsTab> createState() => EventBookingsTabState();
}

class EventBookingsTabState extends State<EventBookingsTab> {
  List<Booking>? _bookings;
  bool _loading = true;
  int? _busyBookingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final bookings = await context.read<BookingApi>().listForEvent(widget.eventId);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
