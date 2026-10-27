import 'package:flutter/material.dart';

/// What the supplier chose on the sign-up welcome.
enum TrialWelcomeChoice { subscribeNow, continueTrial }

/// The one-time message right after a supplier signs up: welcome, how long the free trial is, and a clear choice
/// between subscribing now or carrying on with the trial. Without it a new supplier sees an ordinary dashboard
/// and has no idea the free period will end. The supplier must pick one of the two buttons.
Future<TrialWelcomeChoice> showTrialWelcomeDialog(BuildContext context, {required int? daysLeft}) async {
  final choice = await showDialog<TrialWelcomeChoice>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: _TrialWelcomeDialog(daysLeft: daysLeft),
    ),
  );
  return choice ?? TrialWelcomeChoice.continueTrial;
}

class _TrialWelcomeDialog extends StatelessWidget {
  final int? daysLeft;

  const _TrialWelcomeDialog({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trial = daysLeft == null ? 'a free trial' : 'a $daysLeft-day free trial';

    return AlertDialog(
      key: const Key('trial-welcome-dialog'),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.celebration_outlined, size: 30, color: Color(0xFF7C3AED)),
      ),
      title: const Text('Welcome to EventsRUs!', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your supplier account is ready. You have $trial: every supplier tool is unlocked and no payment is '
            'needed today.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'You can subscribe now, or keep exploring and choose a plan any time before the trial ends.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actions: [
        FilledButton(
          key: const Key('trial-welcome-subscribe'),
          onPressed: () => Navigator.of(context).pop(TrialWelcomeChoice.subscribeNow),
          child: const Text('Subscribe now'),
        ),
        OutlinedButton(
          key: const Key('trial-welcome-continue'),
          onPressed: () => Navigator.of(context).pop(TrialWelcomeChoice.continueTrial),
          child: const Text('Continue with free trial'),
        ),
      ],
    );
  }
}
