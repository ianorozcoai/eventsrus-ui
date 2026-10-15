import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/data/models/role.dart';
import '../../auth/state/auth_controller.dart';
import '../data/user_api.dart';

/// True only when the user has ticked "I understand and accept" AND typed
/// the word DELETE (any case, surrounding spaces ignored) - mirrors the
/// backend's own check (AccountDeletionRequest), which rejects anything else.
bool isDeletionConfirmed({required String typedText, required bool accepted}) =>
    accepted && typedText.trim().toUpperCase() == 'DELETE';

/// "16 Nov 2026" - no intl dependency for one date.
String formatDeletionDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Profile -> Delete account. Google Play requires an in-app way to delete
/// an account and its data. Deleting starts a 30-day grace period (signing
/// in again within it cancels the deletion), then personal data is removed
/// permanently. See docs/account-deletion-design.md.
class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    return DeleteAccountView(
      isVendor: auth.role == Role.vendor,
      requestDeletion: () => context.read<UserApi>().requestAccountDeletion(),
      onFinished: () async {
        // The backend has already ended every session; this clears the
        // app's own cached session and returns to the login screen.
        await auth.logout();
        if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}

/// The screen's UI and behaviour, with the network call and the "all done"
/// step injected so it can be tested without a backend.
class DeleteAccountView extends StatefulWidget {
  final bool isVendor;
  final Future<DateTime> Function() requestDeletion;
  final Future<void> Function() onFinished;

  const DeleteAccountView({
    super.key,
    required this.isVendor,
    required this.requestDeletion,
    required this.onFinished,
  });

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  final _confirmController = TextEditingController();
  bool _accepted = false;
  bool _submitting = false;
  String? _blockedReason;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting && isDeletionConfirmed(typedText: _confirmController.text, accepted: _accepted);

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _blockedReason = null;
    });
    try {
      final scheduledFor = await widget.requestDeletion();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Deletion scheduled'),
          content: Text(
            'Your account will be permanently deleted on ${formatDeletionDate(scheduledFor)}. '
            'Changed your mind? Sign in again before then and nothing is deleted.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      await widget.onFinished();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _blockedReason = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Delete your account?', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text(
                'Your records will be permanently deleted 30 days after you confirm. '
                'If you sign in again within those 30 days, the deletion is cancelled and nothing is lost.',
              ),
              const SizedBox(height: 16),
              Text('What gets deleted', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              const Text(
                '• Your name, email, phone number and address\n'
                '• Your messages and notifications\n'
                '• Your events\' notes and details\n'
                '• Your sign-in and push notification connections',
              ),
              if (widget.isVendor) ...[
                const SizedBox(height: 6),
                const Text(
                  '• Your supplier storefront, photos, packages, ID and business documents',
                ),
              ],
              const SizedBox(height: 16),
              Text('What we keep', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              const Text(
                'Bookings, quotations and payment records are kept without your name, '
                'as required for the other person\'s records and for legal and fraud-prevention reasons.',
              ),
              if (widget.isVendor) ...[
                const SizedBox(height: 16),
                Card(
                  color: theme.colorScheme.secondaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Planning to come back? Cancel your subscription instead of deleting your account. '
                      'Your storefront and data stay safe, and everything is back when you re-subscribe. '
                      'If you have an active subscription, you must cancel it before you can delete.',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _accepted,
                onChanged: _submitting ? null : (value) => setState(() => _accepted = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('I understand and accept that my records will be permanently deleted after 30 days.'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Type DELETE to confirm',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
              ),
              if (_blockedReason != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_blockedReason!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                onPressed: _canSubmit ? _submit : null,
                child: _submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Delete my account'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
                child: const Text('Keep my account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
