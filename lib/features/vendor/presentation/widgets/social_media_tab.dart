import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/social_media_platform.dart';
import '../../data/models/vendor_social_media_link.dart';
import '../../data/vendor_social_media_api.dart';

/// Settings tab for a vendor's social media links (Facebook/Instagram/X/
/// TikTok/YouTube) - as many as they want, shown on their public
/// storefront. Mirrors eventsrus-web's "Social Media" tab in
/// vendor/settings.html: add/delete happen immediately against the backend
/// (VendorSocialMediaLinkController), independent of the rest of the
/// Account Settings screen's Save/Cancel flow.
class SocialMediaTab extends StatefulWidget {
  const SocialMediaTab({super.key});

  @override
  State<SocialMediaTab> createState() => _SocialMediaTabState();
}

class _SocialMediaTabState extends State<SocialMediaTab> {
  List<VendorSocialMediaLink>? _links;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final links = await context.read<VendorSocialMediaApi>().list();
      if (!mounted) return;
      setState(() {
        _links = links;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addLink() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddSocialMediaLinkDialog(),
    );
    if (added == true) _load();
  }

  Future<void> _delete(VendorSocialMediaLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this link?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await context.read<VendorSocialMediaApi>().deleteLink(link.id);
      if (!mounted) return;
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final links = _links ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Links', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              FilledButton.icon(
                onPressed: _addLink,
                icon: const Icon(Icons.add),
                label: const Text('Add Link'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (links.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No social media links yet. Add one so planners can find you online.')),
            )
          else
            ...links.map((link) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(link.platform.icon),
                    title: Text(link.platform.label),
                    subtitle: Text(link.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove',
                      onPressed: () => _delete(link),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _AddSocialMediaLinkDialog extends StatefulWidget {
  const _AddSocialMediaLinkDialog();

  @override
  State<_AddSocialMediaLinkDialog> createState() => _AddSocialMediaLinkDialogState();
}

class _AddSocialMediaLinkDialogState extends State<_AddSocialMediaLinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  SocialMediaPlatform _platform = SocialMediaPlatform.facebook;
  bool _submitting = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await context.read<VendorSocialMediaApi>().addLink(_platform, _url.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Social Media Link'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<SocialMediaPlatform>(
              initialValue: _platform,
              decoration: const InputDecoration(labelText: 'Platform'),
              items: SocialMediaPlatform.values
                  .map((platform) => DropdownMenuItem(value: platform, child: Text(platform.label)))
                  .toList(),
              onChanged: (value) => setState(() => _platform = value ?? SocialMediaPlatform.facebook),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _url,
              decoration: const InputDecoration(labelText: 'Link', hintText: 'https://...'),
              keyboardType: TextInputType.url,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add Link'),
        ),
      ],
    );
  }
}
