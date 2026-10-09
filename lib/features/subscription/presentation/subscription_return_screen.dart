import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/data/models/plan_tier.dart';
import '../../auth/state/auth_controller.dart';
import '../data/models/subscription_status_response.dart';
import '../data/subscription_api.dart';

class SubscriptionReturnScreen extends StatefulWidget {
  const SubscriptionReturnScreen({super.key});

  @override
  State<SubscriptionReturnScreen> createState() => _SubscriptionReturnScreenState();
}

class _SubscriptionReturnScreenState extends State<SubscriptionReturnScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  SubscriptionStatusResponse? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confirm());
  }

  Future<void> _confirm() async {
    final vendorSubscriptionId = int.tryParse(
      Uri.base.queryParameters['vendorSubscriptionId'] ?? '',
    );

    if (vendorSubscriptionId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Missing subscription reference. Please try upgrading again.';
      });
      return;
    }

    try {
      // A PayPal redirect is a fresh page load, so AuthGate's restoreSession()
      // never ran — do it here or role/firstName/etc. would stay null.
      await context.read<AuthController>().restoreSession();
      if (!mounted) return;

      final subscriptionApi = context.read<SubscriptionApi>();
      final status = await subscriptionApi.confirmSubscription(vendorSubscriptionId);
      if (!mounted) return;
      await context.read<AuthController>().applyPlanUpdate(
            plan: status.plan,
            planExpiresAt: status.expiresAt,
          );
      if (!mounted) return;
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _errorMessage == null ? Icons.check_circle : Icons.error,
                        color: _errorMessage == null
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ??
                            (_status?.plan != null
                                ? 'Your ${_status!.plan!.toApi()} plan is now active.'
                                : "We're finalizing your subscription with PayPal. "
                                    'It should activate shortly.'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false),
                        child: const Text('Back to Dashboard'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
