import 'dart:async';

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

class VendorBookingsScreen extends StatefulWidget {
  const VendorBookingsScreen({super.key});

  @override
  State<VendorBookingsScreen> createState() => _VendorBookingsScreenState();
}

class _VendorBookingsScreenState extends State<VendorBookingsScreen> {
  List<Booking>? _bookings;
  bool _loading = true;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<BookingApi>();
      final bookings = await api.listForVendor();
      unawaited(api.markSeen().catchError((_) {}));
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

  Future<void> _acknowledgePayment(Booking booking) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null ||
        result.files.isEmpty ||
        result.files.single.bytes == null)
      return;
    final invoice = result.files.single;

    setState(() => _busyId = booking.id);
    try {
      await context.read<BookingApi>().acknowledgePayment(
        bookingId: booking.id,
        invoiceBytes: invoice.bytes!,
        invoiceFilename: invoice.name,
      );
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _rejectPayment(Booking booking) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Payment'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reject Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    setState(() => _busyId = booking.id);
    try {
      await context.read<BookingApi>().rejectPayment(
        bookingId: booking.id,
        reason: reasonController.text.trim(),
      );
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "This marks the booking as CANCELLED and notifies the planner. This can't be undone.",
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Never mind'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    setState(() => _busyId = booking.id);
    try {
      await context.read<BookingApi>().cancel(
        bookingId: booking.id,
        reason: reasonController.text.trim(),
      );
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _showReason(Booking booking) async {
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

  Future<void> _showHistory(Booking booking) async {
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

    setState(() => _busyId = booking.id);
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
      if (mounted) setState(() => _busyId = null);
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
      // The viewer on this screen is always the vendor on this booking -
      // compare against booking.vendorUserId (a real id both sides already
      // have) rather than a name-prefix match against proposedByName, which
      // can misfire for two users with similar first names.
      isProposedByMe: (amendment) =>
          amendment.proposedByUserId == booking.vendorUserId,
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
    setState(() => _busyId = booking.id);
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
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _withdrawAmendment(Booking booking, int amendmentId) async {
    setState(() => _busyId = booking.id);
    try {
      await context.read<BookingAmendmentApi>().withdraw(amendmentId);
      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  // Same 3-way split as eventsrus-web's vendor/bookings.html tabs.
  static const _inFluxStatuses = {
    BookingStatus.proposed,
    BookingStatus.approved,
    BookingStatus.awaitingPayment,
    BookingStatus.paymentSubmitted,
    BookingStatus.paymentRejected,
  };
  static const _cancelledStatuses = {
    BookingStatus.cancelled,
    BookingStatus.declined,
  };

  List<Booking> _amended(List<Booking> all) => all
      .where((b) => b.hasPendingAmendment || _inFluxStatuses.contains(b.status))
      .toList();
  List<Booking> _booked(List<Booking> all) => all
      .where((b) => b.status == BookingStatus.booked && !b.hasPendingAmendment)
      .toList();
  List<Booking> _cancelled(List<Booking> all) =>
      all.where((b) => _cancelledStatuses.contains(b.status)).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final bookings = _bookings ?? [];
    final amended = _amended(bookings);
    final booked = _booked(bookings);
    final cancelled = _cancelled(bookings);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bookings & Contracts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                tabs: [
                  Tab(text: 'Amended (${amended.length})'),
                  Tab(text: 'Booked (${booked.length})'),
                  Tab(text: 'Cancelled (${cancelled.length})'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildList(amended, 'Nothing in flux right now.'),
                    _buildList(booked, 'No booked contracts yet.'),
                    _buildList(cancelled, 'No cancelled bookings.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Booking> bookings, String emptyMessage) {
    return bookings.isEmpty
        ? Center(child: Text(emptyMessage))
        : ListView.separated(
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final busy = _busyId == booking.id;
              return Card(
                child: ListTile(
                  title: Text(booking.plannerName ?? 'Planner'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.eventName ?? 'Event #${booking.eventId}'),
                      Text(
                        '${booking.eventDatetime != null ? formatDate(booking.eventDatetime!) : 'No date set'}'
                        ' • ${booking.price != null ? formatPeso(booking.price!) : 'No price set'}',
                      ),
                      if (booking.hasPendingAmendment)
                        const Text(
                          'Amendment pending',
                          style: TextStyle(color: Colors.orange),
                        ),
                    ],
                  ),
                  trailing: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BookingStatusChip(status: booking.status),
                            PopupMenuButton<String>(
                              onSelected: (action) {
                                switch (action) {
                                  case 'acknowledge':
                                    _acknowledgePayment(booking);
                                  case 'rejectPayment':
                                    _rejectPayment(booking);
                                  case 'cancel':
                                    _cancelBooking(booking);
                                  case 'reason':
                                    _showReason(booking);
                                  case 'history':
                                    _showHistory(booking);
                                  case 'proposeAmendment':
                                    _proposeAmendment(booking);
                                  case 'viewAmendments':
                                    _viewAmendments(booking);
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
                                if (booking.status ==
                                    BookingStatus.paymentSubmitted) ...[
                                  const PopupMenuItem(
                                    value: 'acknowledge',
                                    child: Text('Acknowledge Payment'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'rejectPayment',
                                    child: Text('Reject Payment'),
                                  ),
                                ],
                                if (booking.status ==
                                    BookingStatus.paymentRejected)
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
