import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/ui/error_display.dart';
import '../../auth/data/models/business_type.dart';
import '../../marketplace/data/conversation_api.dart';
import '../../marketplace/data/models/vendor_package.dart';
import '../../marketplace/data/models/vendor_public_profile.dart';
import '../../marketplace/data/quotation_api.dart';
import '../../marketplace/data/vendor_directory_api.dart';
import '../../marketplace/presentation/storefront_sections.dart';
import '../../moderation/data/moderation_models.dart';
import '../../moderation/presentation/moderation_actions.dart';
import '../../reviews/presentation/review_dialog.dart';
import '../data/event_api.dart';

class VendorProfileScreen extends StatefulWidget {
  final String slug;
  final int eventId;
  // The category the planner was browsing when they got here (from Search
  // Result's Browse pop-up) - threaded through to the bookmark toggle so
  // the resulting checklist item groups under the right category heading.
  // Null when reached some other way (name search) - the backend then
  // falls back to the vendor's own first business type.
  final String? categoryContext;

  const VendorProfileScreen({
    super.key,
    required this.slug,
    required this.eventId,
    this.categoryContext,
  });

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  VendorPublicProfile? _profile;
  bool _loading = true;
  bool _bookmarked = false;
  bool _bookmarkBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await context.read<VendorDirectoryApi>().getProfile(
        widget.slug,
        eventId: widget.eventId,
      );
      bool bookmarked = false;
      try {
        final event = await context.read<EventApi>().getEvent(widget.eventId);
        bookmarked = profile.vendorProfileId != null &&
            event.bookmarkedVendorProfileIds.contains(profile.vendorProfileId);
      } catch (e, st) {
        // Non-fatal - the bookmark button just starts unbookmarked.
        AppLogger.warn('VendorProfileScreen', 'Could not determine bookmark status: $e\n$st');
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _bookmarked = bookmarked;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.error('VendorProfileScreen', 'Failed to load vendor profile', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    final profile = _profile;
    if (profile == null) return;
    final next = !_bookmarked;
    setState(() => _bookmarkBusy = true);
    try {
      await context.read<EventApi>().setVendorBookmark(
            widget.eventId,
            profile.vendorUserId,
            bookmarked: next,
            category: widget.categoryContext,
          );
      if (!mounted) return;
      setState(() => _bookmarked = next);
    } catch (e, st) {
      AppLogger.error('VendorProfileScreen', 'Failed to update bookmark', error: e, stackTrace: st);
      if (!mounted) return;
      showFriendlyError(context, message: 'Could not update bookmark');
    } finally {
      if (mounted) setState(() => _bookmarkBusy = false);
    }
  }

  Future<void> _openSendInquiry() async {
    final profile = _profile;
    if (profile == null) return;
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _SendInquiryScreen(eventId: widget.eventId, vendorUserId: profile.vendorUserId),
      ),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inquiry sent')));
    }
  }

  Future<void> _openRequestQuotation() async {
    final profile = _profile;
    if (profile == null) return;
    final requested = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _RequestQuotationScreen(
          eventId: widget.eventId,
          vendorUserId: profile.vendorUserId,
          packages: profile.packages,
        ),
      ),
    );
    if (requested == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quotation requested')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final profile = _profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Supplier not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.businessName ?? 'Supplier'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) async {
              final name = profile.businessName ?? 'this supplier';
              if (value == 'report') {
                await reportWithDialog(
                  context,
                  contentType: ReportContentType.storefront,
                  contentId: profile.vendorUserId,
                  subject: name,
                );
              } else if (value == 'block') {
                final blocked = await confirmAndBlock(context, userId: profile.vendorUserId, name: name);
                if (blocked && context.mounted) Navigator.of(context).maybePop();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Report this supplier')),
              PopupMenuItem(value: 'block', child: Text('Block this supplier')),
            ],
          ),
        ],
      ),
      // top: false - the AppBar already clears the top inset; this is only
      // for the bottom, which nothing else here accounts for (no
      // bottomNavigationBar on this pushed screen) and which otherwise lets
      // the last section run under Android's edge-to-edge gesture/nav bar.
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  if (profile.logoImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        profile.logoImageUrl!,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.businessName ?? '',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (profile.identityVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Colors.green, size: 20),
                      ],
                    ],
                  ),
                  if (profile.businessTypes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        profile.businessTypes.map(BusinessTypeApi.labelOrRaw).join(' • '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (profile.averageRating != null)
                    Row(
                      children: [
                        StarRatingRow(rating: profile.averageRating!, size: 16),
                        const SizedBox(width: 6),
                        Text('${profile.averageRating!.toStringAsFixed(1)} (${profile.reviewCount})',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    )
                  else
                    Text('No reviews yet', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Text(profile.description ?? ''),
                  const SizedBox(height: 20),
                  // Orange fill for "Bookmarked" - same family as
                  // eventsrus-web's storefront (.btn-warning). This is a
                  // deliberate status color (same meaning as "verified"
                  // green elsewhere), not a theme accent, so it's one fixed
                  // shade on purpose rather than derived from the theme -
                  // it needs to read the same way regardless of light/dark
                  // mode, same as the green verified badge above.
                  _bookmarked
                      ? FilledButton.icon(
                          onPressed: _bookmarkBusy ? null : _toggleBookmark,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                          ),
                          icon: _bookmarkBusy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.bookmark),
                          label: const Text('Bookmarked'),
                        )
                      : OutlinedButton.icon(
                          onPressed: _bookmarkBusy ? null : _toggleBookmark,
                          icon: _bookmarkBusy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.bookmark_border),
                          label: const Text('Bookmark this supplier'),
                        ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _openSendInquiry,
                    child: const Text('Send Inquiry'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _openRequestQuotation,
                    child: const Text('Request Quotation'),
                  ),
                  const SizedBox(height: 24),
                  StorefrontSections(profile: profile),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Full screen (not a dialog) so it reads consistently with the rest of the
/// app's forms, which all got moved off popups to their own screens with a
/// back arrow.
class _SendInquiryScreen extends StatefulWidget {
  final int eventId;
  final int vendorUserId;

  const _SendInquiryScreen({required this.eventId, required this.vendorUserId});

  @override
  State<_SendInquiryScreen> createState() => _SendInquiryScreenState();
}

class _SendInquiryScreenState extends State<_SendInquiryScreen> {
  final _messageController = TextEditingController();
  DateTime? _targetDate;
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (date != null) setState(() => _targetDate = date);
  }

  Future<void> _send() async {
    if (_messageController.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await context.read<ConversationApi>().sendInquiry(
        eventId: widget.eventId,
        vendorUserId: widget.vendorUserId,
        plannerName: 'Planner',
        targetDate: _targetDate,
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      AppLogger.error('SendInquiryScreen', 'Failed to send inquiry', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _sending = false);
      showFriendlyError(context, message: 'Could not send inquiry');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Inquiry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                title: Text(_targetDate == null ? 'Target date (optional)' : _targetDate.toString()),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
              maxLines: 6,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same reasoning as [_SendInquiryScreen] - a full screen instead of a
/// dialog, now with the optional package picker.
class _RequestQuotationScreen extends StatefulWidget {
  final int eventId;
  final int vendorUserId;
  final List<VendorPackage> packages;

  const _RequestQuotationScreen({
    required this.eventId,
    required this.vendorUserId,
    required this.packages,
  });

  @override
  State<_RequestQuotationScreen> createState() => _RequestQuotationScreenState();
}

class _RequestQuotationScreenState extends State<_RequestQuotationScreen> {
  final _messageController = TextEditingController();
  DateTime? _targetDate;
  final _selectedPackageIds = <int>{};
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (date != null) setState(() => _targetDate = date);
  }

  Future<void> _send() async {
    if (_messageController.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await context.read<QuotationApi>().requestQuotation(
        eventId: widget.eventId,
        vendorUserId: widget.vendorUserId,
        plannerName: 'Planner',
        targetDate: _targetDate,
        message: _messageController.text.trim(),
        packageIds: _selectedPackageIds.isEmpty ? null : _selectedPackageIds.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      AppLogger.error('RequestQuotationScreen', 'Failed to request quotation', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _sending = false);
      showFriendlyError(context, message: 'Could not request quotation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Quotation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                title: Text(_targetDate == null ? 'Target date (optional)' : _targetDate.toString()),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'What do you need a quote for?',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
            ),
            if (widget.packages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Packages you\'re interested in (optional)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final package in widget.packages)
                    FilterChip(
                      label: Text(package.name),
                      selected: _selectedPackageIds.contains(package.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedPackageIds.add(package.id);
                        } else {
                          _selectedPackageIds.remove(package.id);
                        }
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Request'),
            ),
          ],
        ),
      ),
    );
  }
}
