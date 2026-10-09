import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../marketplace/data/conversation_api.dart';
import '../../marketplace/data/models/vendor_public_profile.dart';
import '../../marketplace/data/quotation_api.dart';
import '../../marketplace/data/vendor_directory_api.dart';

class VendorProfileScreen extends StatefulWidget {
  final String slug;
  final int eventId;

  const VendorProfileScreen({
    super.key,
    required this.slug,
    required this.eventId,
  });

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  VendorPublicProfile? _profile;
  bool _loading = true;

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
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _sendInquiry() async {
    final profile = _profile;
    if (profile == null) return;
    final messageController = TextEditingController();
    DateTime? targetDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Send Inquiry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  targetDate == null
                      ? 'Target date (optional)'
                      : targetDate.toString(),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final date = await showDatePicker(
                    context: dialogContext,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 1095)),
                  );
                  if (date != null) setDialogState(() => targetDate = date);
                },
              ),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 3,
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
      ),
    );

    if (confirmed != true || messageController.text.trim().isEmpty) return;

    try {
      await context.read<ConversationApi>().sendInquiry(
        eventId: widget.eventId,
        vendorUserId: profile.vendorUserId,
        plannerName: 'Planner',
        targetDate: targetDate,
        message: messageController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inquiry sent')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not send inquiry')));
    }
  }

  Future<void> _requestQuotation() async {
    final profile = _profile;
    if (profile == null) return;
    final messageController = TextEditingController();
    DateTime? targetDate;
    final selectedPackageIds = <int>{};

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Request Quotation'),
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
                        : targetDate.toString(),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 1095)),
                    );
                    if (date != null) setDialogState(() => targetDate = date);
                  },
                ),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'What do you need a quote for?',
                  ),
                  maxLines: 3,
                ),
                if (profile.packages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Packages you\'re interested in (optional)',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final package in profile.packages)
                        FilterChip(
                          label: Text(package.name),
                          selected: selectedPackageIds.contains(package.id),
                          onSelected: (selected) => setDialogState(() {
                            if (selected) {
                              selectedPackageIds.add(package.id);
                            } else {
                              selectedPackageIds.remove(package.id);
                            }
                          }),
                        ),
                    ],
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
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Request'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || messageController.text.trim().isEmpty) return;

    try {
      await context.read<QuotationApi>().requestQuotation(
        eventId: widget.eventId,
        vendorUserId: profile.vendorUserId,
        plannerName: 'Planner',
        targetDate: targetDate,
        message: messageController.text.trim(),
        packageIds: selectedPackageIds.isEmpty
            ? null
            : selectedPackageIds.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quotation requested')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not request quotation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final profile = _profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Vendor not found')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(profile.businessName ?? 'Vendor')),
      body: Center(
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
                Text(
                  profile.businessName ?? '',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${profile.city ?? ''}, ${profile.country ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(profile.description ?? ''),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _sendInquiry,
                        child: const Text('Send Inquiry'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _requestQuotation,
                        child: const Text('Request Quotation'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Packages',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...profile.packages.map(
                  (p) => Card(
                    child: ListTile(
                      title: Text(p.name),
                      subtitle: Text(p.description ?? ''),
                      trailing: p.price != null
                          ? Text('₱${p.price!.toStringAsFixed(0)}')
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
