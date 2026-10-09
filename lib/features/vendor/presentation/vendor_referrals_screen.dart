import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models/vendor_referral.dart';
import '../data/models/vendor_referral_overview.dart';
import '../data/vendor_referral_api.dart';

class VendorReferralsScreen extends StatefulWidget {
  const VendorReferralsScreen({super.key});

  @override
  State<VendorReferralsScreen> createState() => _VendorReferralsScreenState();
}

class _VendorReferralsScreenState extends State<VendorReferralsScreen> {
  VendorReferralOverview? _overview;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await context.read<VendorReferralApi>().getOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your referrals';
        _loading = false;
      });
    }
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final overview = _overview!;
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Referrals',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Share this with other suppliers. When someone signs up through it and subscribes to PRO, you earn a fixed commission.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _ReferralLinkCard(
              referralCode: overview.referralCode,
              referralLink: overview.referralLink,
              onCopy: _copy,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatTile(
                  label: 'PENDING PAYOUT',
                  value: '₱${overview.totalPendingCommission.toStringAsFixed(2)}',
                  icon: Icons.hourglass_top_outlined,
                ),
                _StatTile(
                  label: 'ALREADY PAID OUT',
                  value: '₱${overview.totalPaidCommission.toStringAsFixed(2)}',
                  icon: Icons.payments_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "Suppliers You've Referred",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (overview.referrals.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  "No referrals yet — share your link above to start earning.",
                  style: TextStyle(color: colorScheme.outline),
                ),
              )
            else
              Column(
                children: overview.referrals.map((r) => _ReferralTile(referral: r)).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReferralLinkCard extends StatelessWidget {
  final String referralCode;
  final String referralLink;
  final void Function(String label, String value) onCopy;

  const _ReferralLinkCard({
    required this.referralCode,
    required this.referralLink,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Referral Link', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _CopyField(label: 'Referral code', value: referralCode, onCopy: onCopy),
          const SizedBox(height: 12),
          _CopyField(label: 'Referral link', value: referralLink, onCopy: onCopy),
        ],
      ),
    );
  }
}

class _CopyField extends StatelessWidget {
  final String label;
  final String value;
  final void Function(String label, String value) onCopy;

  const _CopyField({required this.label, required this.value, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Copy $label',
              onPressed: () => onCopy(label, value),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
              ),
              Icon(icon, size: 18, color: colorScheme.outline),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ReferralTile extends StatelessWidget {
  final VendorReferral referral;

  const _ReferralTile({required this.referral});

  Color _statusColor(ColorScheme colorScheme) {
    switch (referral.status) {
      case ReferralStatus.pending:
        return colorScheme.surfaceContainerHighest;
      case ReferralStatus.converted:
        return colorScheme.tertiaryContainer;
      case ReferralStatus.commissionPaid:
        return colorScheme.primaryContainer;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final commission = referral.commissionAmount;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  referral.referredBusinessName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(colorScheme),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(referral.status.label, style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            commission != null
                ? 'Commission: ₱${commission.toStringAsFixed(2)}'
                : 'Commission: —',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Referred on ${_formatDate(referral.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
          if (referral.convertedAt != null)
            Text(
              'Converted on ${_formatDate(referral.convertedAt!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          if (referral.paidAt != null)
            Text(
              'Paid on ${_formatDate(referral.paidAt!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          if (referral.paymentRemarks != null) ...[
            const SizedBox(height: 8),
            Text(
              referral.paymentRemarks!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ],
          if (referral.paymentProofUrl != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _openProof(context, referral.paymentProofUrl!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('View payment proof', style: TextStyle(color: colorScheme.primary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openProof(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PaymentProofViewer(imageUrl: url),
        fullscreenDialog: true,
      ),
    );
  }
}

class _PaymentProofViewer extends StatelessWidget {
  final String imageUrl;

  const _PaymentProofViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Payment Proof'),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            errorBuilder: (context, error, stackTrace) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not load the payment proof image.',
                style: TextStyle(color: Colors.white),
              ),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
