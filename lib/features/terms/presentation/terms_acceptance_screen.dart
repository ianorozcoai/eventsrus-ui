import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The one-time full-page "please accept our Terms" screen: the logo, the rules in three plain lines, links to the
/// full Terms and Privacy Policy on the website, and a clear choice. There is no back button: the person agrees
/// or declines (which signs them out).
class TermsAcceptanceScreen extends StatelessWidget {
  final VoidCallback onAgree;
  final VoidCallback onDecline;
  final VoidCallback onReadTerms;
  final VoidCallback onReadPrivacy;
  final bool busy;
  final String? errorMessage;

  const TermsAcceptanceScreen({
    super.key,
    required this.onAgree,
    required this.onDecline,
    required this.onReadTerms,
    required this.onReadPrivacy,
    this.busy = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('terms-acceptance-screen'),
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
                          SvgPicture.asset(
                            dark ? 'assets/images/logo-navbar.svg' : 'assets/images/logo-login.svg',
                            height: 44,
                            alignment: Alignment.centerLeft,
                          ),
                          const SizedBox(height: 40),
                          Text(
                            'Please review our Terms',
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'To keep EventsRUs safe for planners and suppliers, please agree to our Terms & Agreement before you continue.',
                            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 24),
                          const _Rule('Be respectful: no harassment, hate, scams, spam or unlawful content.'),
                          const _Rule('You can report anything and block anyone from inside the app.'),
                          const _Rule('We may remove content or suspend accounts that break the rules.'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                key: const Key('terms-read-terms'),
                                onPressed: onReadTerms,
                                child: const Text('Read the full Terms'),
                              ),
                              TextButton(
                                key: const Key('terms-read-privacy'),
                                onPressed: onReadPrivacy,
                                child: const Text('Privacy Policy'),
                              ),
                            ],
                          ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
                          ],
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
                          key: const Key('terms-agree'),
                          onPressed: busy ? null : onAgree,
                          child: busy
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('I agree and continue'),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          key: const Key('terms-decline'),
                          onPressed: busy ? null : onDecline,
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Decline and log out'),
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

class _Rule extends StatelessWidget {
  final String text;

  const _Rule(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 22, color: Color(0xFF7C3AED)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
