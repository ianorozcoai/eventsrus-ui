import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/billing_cycle.dart';
import '../../data/models/billing_source.dart';
import '../../data/models/subscription_status_response.dart';
import '../../data/play_billing_gateway.dart';
import '../../data/subscription_api.dart';

/// Google Play's own page for managing (and cancelling) this app's subscription.
Uri playManageSubscriptionUri() => Uri.https('play.google.com', '/store/account/subscriptions', {
      'sku': AppConfig.playSubscriptionId,
      'package': AppConfig.androidPackageName,
    });

enum _Phase { loading, loadError, alreadySubscribed, notAvailable, ready, activating }

/// The Android purchase flow (Google Play Billing through RevenueCat). Shows
/// only store prices, never PayPal/GCash or any pointer to paying elsewhere
/// (Google Play Payments policy).
///
/// Order of events: ask the backend (GET /subscription/status) whether the
/// supplier already has a plan; only if not, ask the store for the three
/// packages; after a purchase, wait for RevenueCat's webhook to reach the
/// backend (the backend is the source of truth for access) by re-reading the
/// status for a few seconds.
class PlayBillingPlanPicker extends StatefulWidget {
  final void Function(SubscriptionStatusResponse) onStatusChanged;

  /// How long to wait between status checks after a purchase; tests shorten it.
  final Duration activationPollInterval;
  final int activationPollAttempts;

  const PlayBillingPlanPicker({
    super.key,
    required this.onStatusChanged,
    this.activationPollInterval = const Duration(seconds: 2),
    this.activationPollAttempts = 8,
  });

  @override
  State<PlayBillingPlanPicker> createState() => _PlayBillingPlanPickerState();
}

class _PlayBillingPlanPickerState extends State<PlayBillingPlanPicker> {
  _Phase _phase = _Phase.loading;
  SubscriptionStatusResponse? _status;
  List<PlayOffer> _offers = const [];
  BillingCycle? _selected;
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _message = null;
    });
    try {
      final status = await context.read<SubscriptionApi>().getStatus();
      if (!mounted) return;
      _status = status;
      if (status.plan != null) {
        setState(() => _phase = _Phase.alreadySubscribed);
        return;
      }
      final userId = status.userId;
      if (userId == null) {
        setState(() => _phase = _Phase.notAvailable);
        return;
      }
      final offers = await context.read<PlayBillingGateway>().loadOffers(userId.toString());
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _selected = offers.isEmpty
            ? null
            : offers.firstWhere((o) => o.cycle == BillingCycle.quarterly, orElse: () => offers.first).cycle;
        _phase = offers.isEmpty ? _Phase.notAvailable : _Phase.ready;
      });
    } on PlayBillingUnavailable catch (e) {
      AppLogger.error('PlayBilling', 'Not available: ${e.reason}');
      if (!mounted) return;
      setState(() => _phase = _Phase.notAvailable);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e.message;
        _phase = _Phase.loadError;
      });
    } catch (e, st) {
      AppLogger.error('PlayBilling', 'Unexpected error while loading', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _phase = _Phase.notAvailable);
    }
  }

  Future<void> _buy() async {
    final offer = _offers.firstWhere((o) => o.cycle == _selected);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final outcome = await context.read<PlayBillingGateway>().purchase(offer);
      if (!mounted) return;
      if (outcome == PlayPurchaseOutcome.cancelled) {
        setState(() => _busy = false);
        return;
      }
      await _waitForActivation();
    } catch (e, st) {
      AppLogger.error('PlayBilling', 'Purchase failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'The purchase could not be completed. You have not been charged. Please try again.';
      });
    }
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await context.read<PlayBillingGateway>().restore();
      if (!mounted) return;
      await _waitForActivation();
    } catch (e, st) {
      AppLogger.error('PlayBilling', 'Restore failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Could not restore purchases right now. Please try again.';
      });
    }
  }

  /// The purchase is final once Google confirms it, but access is granted by
  /// the backend when RevenueCat's webhook arrives, usually within seconds.
  Future<void> _waitForActivation() async {
    setState(() => _phase = _Phase.activating);
    final api = context.read<SubscriptionApi>();
    for (var i = 0; i < widget.activationPollAttempts; i++) {
      try {
        final status = await api.getStatus();
        if (!mounted) return;
        if (status.plan != null) {
          _status = status;
          widget.onStatusChanged(status);
          setState(() {
            _busy = false;
            _phase = _Phase.alreadySubscribed;
          });
          return;
        }
      } on ApiException {
        // Keep trying; a blip here must not hide a purchase that went through.
      }
      await Future<void>.delayed(widget.activationPollInterval);
      if (!mounted) return;
    }
    setState(() {
      _busy = false;
      _phase = _Phase.notAvailable;
      _message = 'Your purchase went through and is being activated. This can take a few minutes. '
          'Use the refresh button above to check again.';
    });
  }

  Future<void> _manage() async {
    await launchUrl(playManageSubscriptionUri(), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.loading:
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(key: Key('play-loading'))),
        );
      case _Phase.activating:
        return const _InfoCard(
          key: Key('play-activating'),
          title: 'Activating your plan',
          body: 'Thank you! We are confirming your purchase with Google Play. This usually takes a few seconds.',
          showProgress: true,
        );
      case _Phase.loadError:
        return _InfoCard(
          key: const Key('play-load-error'),
          title: 'Could not load your plan',
          body: _message ?? 'Please check your connection and try again.',
          actions: [FilledButton(onPressed: _load, child: const Text('Retry'))],
        );
      case _Phase.alreadySubscribed:
        return _InfoCard(
          key: const Key('play-already-subscribed'),
          title: 'You already have an active plan',
          body: _status?.billingSource == BillingSource.googlePlay
              ? 'Your PRO plan is billed through Google Play. Subscriptions bought in Google Play are '
                  'managed and cancelled in Google Play.'
              : 'Your PRO plan is active, so there is nothing to buy here.',
          actions: [
            if (_status?.billingSource == BillingSource.googlePlay)
              OutlinedButton(
                key: const Key('play-manage-subscription'),
                onPressed: _manage,
                child: const Text('Manage subscription'),
              ),
          ],
        );
      case _Phase.notAvailable:
        return _InfoCard(
          key: const Key('play-not-available'),
          title: 'Subscriptions in the app',
          body: _message ?? 'Buying a subscription in the app is not available yet. Please check back soon.',
          actions: [
            OutlinedButton(
              key: const Key('play-manage-subscription'),
              onPressed: _manage,
              child: const Text('Manage subscription'),
            ),
          ],
        );
      case _Phase.ready:
        return _buildReady(context);
    }
  }

  Widget _buildReady(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      key: const Key('play-offers'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final offer in _offers)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              key: Key('play-offer-${offer.cycle.toApi()}'),
              onTap: _busy ? null : () => setState(() => _selected = offer.cycle),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selected == offer.cycle ? colorScheme.primary : colorScheme.outlineVariant,
                    width: _selected == offer.cycle ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selected == offer.cycle ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: _selected == offer.cycle ? colorScheme.primary : colorScheme.outlineVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${offer.cycle.label} (${offer.cycle.durationLabel})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(offer.priceString, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        if (_message != null) ...[
          Text(_message!, style: TextStyle(color: colorScheme.error)),
          const SizedBox(height: 12),
        ],
        FilledButton(
          key: const Key('play-subscribe'),
          onPressed: _busy ? null : _buy,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Subscribe with Google Play'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('play-restore'),
          onPressed: _busy ? null : _restore,
          child: const Text('Restore purchases'),
        ),
        OutlinedButton(
          key: const Key('play-manage-subscription'),
          onPressed: _manage,
          child: const Text('Manage subscription'),
        ),
        const SizedBox(height: 8),
        Text(
          'Renews automatically until cancelled. Subscriptions bought in Google Play are cancelled in '
          'Google Play (Manage subscription).',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  final List<Widget> actions;
  final bool showProgress;

  const _InfoCard({super.key, required this.title, required this.body, this.actions = const [], this.showProgress = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body),
            if (showProgress) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
