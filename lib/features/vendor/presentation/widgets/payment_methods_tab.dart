import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/payment_method_status.dart';
import '../../data/models/vendor_payment_method.dart';
import '../../data/models/vendor_settings.dart';
import '../../data/vendor_payment_method_api.dart';
import '../../data/vendor_settings_api.dart';
import 'image_upload_tile.dart';

/// Settings tab for a vendor's payment methods (a QR code image + a short
/// label, e.g. "GCash", "BDO - Savings Account") - shown on their public
/// storefront once approved. Mirrors eventsrus-web's "Payment Methods" tab
/// in vendor/settings.html: add/delete happen immediately against the
/// backend (VendorPaymentMethodController), independent of the rest of the
/// Account Settings screen's Save/Cancel flow. Admin approval review
/// doesn't have a screen yet (see VendorPaymentMethod's doc comment on the
/// backend) so every upload comes back APPROVED today, but the status
/// badge is still shown since PENDING/REJECTED are real possible values.
///
/// The free-text "Payment instructions" shown above the QR codes (web's same
/// tab) is NOT part of VendorPaymentMethodController - it's a field on the
/// main vendor settings resource (VendorSettingsRequest/Response), saved via
/// VendorSettingsApi. That endpoint is a full unconditional overwrite
/// (UserService#updateSettings has no null-check for most fields), so saving
/// just this one field here still means fetch-current-settings, change only
/// paymentInstructions, then PUT the whole object back - never construct a
/// bare VendorSettings() with only this field set.
class PaymentMethodsTab extends StatefulWidget {
  const PaymentMethodsTab({super.key});

  @override
  State<PaymentMethodsTab> createState() => _PaymentMethodsTabState();
}

class _PaymentMethodsTabState extends State<PaymentMethodsTab> {
  List<VendorPaymentMethod>? _methods;
  VendorSettings? _settings;
  final _instructions = TextEditingController();
  bool _loading = true;
  bool _savingInstructions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        context.read<VendorPaymentMethodApi>().list(),
        context.read<VendorSettingsApi>().getSettings(),
      ]);
      if (!mounted) return;
      setState(() {
        _methods = results[0] as List<VendorPaymentMethod>;
        _settings = results[1] as VendorSettings;
        _instructions.text = _settings?.paymentInstructions ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveInstructions() async {
    final settings = _settings;
    if (settings == null) return;

    setState(() => _savingInstructions = true);
    try {
      final updated = await context.read<VendorSettingsApi>().updateSettings(
            settings.copyWith(paymentInstructions: _instructions.text.trim()),
          );
      if (!mounted) return;
      setState(() => _settings = updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment instructions saved')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _savingInstructions = false);
    }
  }

  Future<void> _addMethod() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddPaymentMethodDialog(),
    );
    if (added == true) _load();
  }

  Future<void> _delete(VendorPaymentMethod method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this payment method?'),
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
      await context.read<VendorPaymentMethodApi>().delete(method.id);
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

    final methods = _methods ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All payment methods are subject to verification before they go live on your storefront. '
                    'Newly added QR codes stay hidden from planners until our team approves them.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Payment instructions', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _instructions,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g., GCash and Maya are preferred for the down payment. Bank transfer is available for larger balances.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          Text('Shown to planners alongside your QR codes on your storefront.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _savingInstructions ? null : _saveInstructions,
              child: _savingInstructions
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Instructions'),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('QR Codes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              FilledButton.icon(
                onPressed: _addMethod,
                icon: const Icon(Icons.add),
                label: const Text('Add Payment Method'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (methods.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No payment methods yet. Add a QR code so planners can pay you directly.')),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: methods.length,
              itemBuilder: (context, index) => _PaymentMethodCard(
                method: methods[index],
                onDelete: () => _delete(methods[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final VendorPaymentMethod method;
  final VoidCallback onDelete;

  const _PaymentMethodCard({required this.method, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: method.qrImageUrl != null
                      ? Image.network(
                          method.qrImageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 100,
                            height: 100,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.qr_code_2, size: 40),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.qr_code_2, size: 40),
                        ),
                ),
                const SizedBox(height: 8),
                Text(method.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                _StatusBadge(status: method.status),
              ],
            ),
            Positioned(
              top: -4,
              right: -4,
              child: IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Remove',
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                  minimumSize: const Size(28, 28),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PaymentMethodStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: status.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(status.label, style: TextStyle(color: status.color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _AddPaymentMethodDialog extends StatefulWidget {
  const _AddPaymentMethodDialog();

  @override
  State<_AddPaymentMethodDialog> createState() => _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<_AddPaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  PlatformFile? _qrImage;
  bool _submitting = false;
  String? _fileError;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_qrImage == null) {
      setState(() => _fileError = 'Please choose a QR code image.');
      return;
    }

    setState(() {
      _submitting = true;
      _fileError = null;
    });
    try {
      await context.read<VendorPaymentMethodApi>().create(_label.text.trim(), _qrImage!);
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
      title: const Text('Add Payment Method'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'Label', hintText: 'e.g., GCash, Maya, BDO - Savings Account'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ImageUploadTile(
              label: 'QR code image',
              file: _qrImage,
              onChanged: (file) => setState(() {
                _qrImage = file;
                _fileError = null;
              }),
            ),
            if (_fileError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_fileError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'PNG or JPEG only. Held for review before it appears on your storefront.',
                style: TextStyle(fontSize: 12),
              ),
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
              : const Text('Add Payment Method'),
        ),
      ],
    );
  }
}
