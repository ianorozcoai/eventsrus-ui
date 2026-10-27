import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// What the supplier chose on the sign-up welcome.
enum TrialWelcomeChoice { subscribeNow, continueTrial }

/// The one-time full-page welcome right after a supplier signs up: the logo, a warm welcome, how long the free
/// trial is and why, and a clear choice between subscribing now or carrying on with the trial. Without it a new
/// supplier lands on an ordinary dashboard and has no idea the free period will end. There is no back button:
/// the supplier answers with one of the two buttons.
Future<TrialWelcomeChoice> showTrialWelcomeScreen(BuildContext context, {required int? daysLeft}) async {
  final choice = await Navigator.of(context).push<TrialWelcomeChoice>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => TrialWelcomeScreen(daysLeft: daysLeft),
    ),
  );
  return choice ?? TrialWelcomeChoice.continueTrial;
}

class TrialWelcomeScreen extends StatelessWidget {
  static const _accent = Color(0xFF7C3AED);

  final int? daysLeft;

  const TrialWelcomeScreen({super.key, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final trialLabel = daysLeft == null ? 'Free trial' : '$daysLeft-day free trial';

    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('trial-welcome-screen'),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The dark-background logo on dark themes, the dark-text logo on light ones.
                          SvgPicture.asset(
                            dark ? 'assets/images/logo-navbar.svg' : 'assets/images/logo-login.svg',
                            key: const Key('trial-welcome-logo'),
                            height: 44,
                            alignment: Alignment.centerLeft,
                          ),
                          const SizedBox(height: 48),
                          Text(
                            'Welcome to EventsRUs!',
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your supplier account is ready.',
                            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            key: const Key('trial-welcome-label'),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              trialLabel,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: dark ? const Color(0xFFC4B5FD) : const Color(0xFF5B21B6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _Point('Every supplier tool is unlocked'),
                          const _Point('No payment is needed today'),
                          const _Point('Subscribe any time before the trial ends'),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          key: const Key('trial-welcome-subscribe'),
                          onPressed: () => Navigator.of(context).pop(TrialWelcomeChoice.subscribeNow),
                          child: const Text('Subscribe now'),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          key: const Key('trial-welcome-continue'),
                          onPressed: () => Navigator.of(context).pop(TrialWelcomeChoice.continueTrial),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Continue with free trial'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final String text;

  const _Point(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 22, color: TrialWelcomeScreen._accent),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
