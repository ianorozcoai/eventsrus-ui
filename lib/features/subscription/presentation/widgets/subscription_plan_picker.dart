import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/data/models/plan_tier.dart';
import '../../../vendor/presentation/widgets/image_upload_tile.dart';
import '../../data/models/billing_cycle.dart';
import '../../data/models/create_subscription_request.dart';
import '../../data/models/subscription_status_response.dart';
import '../../data/subscription_api.dart';

/// The billing-cycle picker + PayPal/GCash payment buttons - shared between
/// PlanSelectionScreen (a brand-new vendor's forced first choice, or a
/// dedicated "Upgrade" push) and BillingHistoryScreen (inlined directly
/// under the Current Plan card, matching eventsrus-web's single-page
/// vendor/subscription.html layout instead of requiring a separate screen
/// to renew).
class SubscriptionPlanPicker extends StatefulWidget {
  final SubscriptionStatusResponse status;
  final void Function(SubscriptionStatusResponse) onStatusChanged;

  const SubscriptionPlanPicker({super.key, required this.status, required this.onStatusChanged});

  @override
  State<SubscriptionPlanPicker> createState() => _SubscriptionPlanPickerState();
}

class _SubscriptionPlanPickerState extends State<SubscriptionPlanPicker> {
  // Matches the web picker's default-checked cycle.
  BillingCycle _selectedCycle = BillingCycle.quarterly;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _continueToPayPal() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final subscriptionApi = context.read<SubscriptionApi>();
      final response = await subscriptionApi.createSubscription(
        CreateSubscriptionRequest(plan: PlanTier.pro, billingCycle: _selectedCycle),
      );
      final approveUri = Uri.parse(response.approvalUrl);
      final launched = await launchUrl(approveUri, webOnlyWindowName: '_self');
      if (!launched && mounted) {
        setState(() => _errorMessage = 'Could not open PayPal. Please try again.');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _payWithGcash() async {
    final result = await showDialog<SubscriptionStatusResponse>(
      context: context,
      builder: (_) => _GcashPaymentDialog(billingCycle: _selectedCycle),
    );
    if (result == null || !mounted) return;
    widget.onStatusChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status.gcashAwaitingVerification) _GcashStatusBanner.awaiting(),
        if (status.gcashRejected) _GcashStatusBanner.rejected(status.gcashRejectionReason),
        // Monthly is hidden on web's picker too (still fully functional,
        // see BillingCycle's own doc comment) - match that here.
        for (final cycle in BillingCycle.values.where((c) => c != BillingCycle.monthly))
          _BillingCycleCard(
            cycle: cycle,
            status: status,
            selected: _selectedCycle == cycle,
            onSelected: () => setState(() => _selectedCycle = cycle),
          ),
        const SizedBox(height: 8),
        if (_errorMessage != null) ...[
          Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
        ],
        Text('Payment Method', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _continueToPayPal,
          icon: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.account_balance_wallet_outlined),
          label: const Text('Continue with PayPal'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isSubmitting ? null : _payWithGcash,
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Pay with GCash'),
        ),
      ],
    );
  }
}

class _BillingCycleCard extends StatelessWidget {
  final BillingCycle cycle;
  final SubscriptionStatusResponse status;
  final bool selected;
  final VoidCallback onSelected;

  const _BillingCycleCard({
    required this.cycle,
    required this.status,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badge = cycle.savingsBadge;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? colorScheme.primary : colorScheme.outlineVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      cycle.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '(${cycle.durationLabel})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₱${status.monthlyPrice} / month', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '₱${status.priceFor(cycle)} total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline notice for the GCash manual-review states - mirrors web's
/// separate gcashAwaitingVerificationModal / gcashRejectedModal dismissible
/// popups, adapted into an inline card rather than another modal on mobile.
class _GcashStatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _GcashStatusBanner({required this.icon, required this.color, required this.title, required this.message});

  factory _GcashStatusBanner.awaiting() => const _GcashStatusBanner(
        icon: Icons.hourglass_top,
        color: Colors.orange,
        title: 'Your GCash payment is being reviewed',
        message: 'We received your payment screenshot. An admin will confirm it shortly and '
            'activate your PRO plan - no further action needed from you.',
      );

  factory _GcashStatusBanner.rejected(String? reason) => _GcashStatusBanner(
        icon: Icons.error_outline,
        color: Colors.red,
        title: 'Your GCash payment verification failed',
        message: reason ?? 'Please re-upload your payment screenshot below.',
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// GCash manual-payment popup - mirrors eventsrus-web's gcashPaymentModal
/// fragment (QR code + screenshot upload + optional remarks).
class _GcashPaymentDialog extends StatefulWidget {
  final BillingCycle billingCycle;

  const _GcashPaymentDialog({required this.billingCycle});

  @override
  State<_GcashPaymentDialog> createState() => _GcashPaymentDialogState();
}

class _GcashPaymentDialogState extends State<_GcashPaymentDialog> {
  final _remarks = TextEditingController();
  PlatformFile? _screenshot;
  bool _submitting = false;
  String? _fileError;
  String? _errorMessage;

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_screenshot == null) {
      setState(() => _fileError = 'Please upload a screenshot of your payment.');
      return;
    }

    setState(() {
      _submitting = true;
      _fileError = null;
      _errorMessage = null;
    });

    try {
      final status = await context.read<SubscriptionApi>().submitGcashPayment(
            billingCycle: widget.billingCycle,
            screenshot: _screenshot!,
            vendorRemarks: _remarks.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(status);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pay via GCash'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/gcash.jpg', fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            const Text(
              'Scan the QR code or send payment to the GCash account above, then upload a '
              'screenshot of your payment confirmation. An admin reviews it and activates your '
              'subscription once confirmed.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ImageUploadTile(
              label: 'Payment screenshot',
              file: _screenshot,
              onChanged: (file) => setState(() {
                _screenshot = file;
                _fileError = null;
              }),
            ),
            if (_fileError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_fileError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarks,
              decoration: const InputDecoration(
                labelText: 'Remarks (optional)',
                hintText: 'e.g. Sent via GCash app, ref #12345',
              ),
              maxLines: 2,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Upload Payment Screenshot'),
        ),
      ],
    );
  }
}
