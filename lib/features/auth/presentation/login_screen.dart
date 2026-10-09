import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../data/google_auth_gateway.dart';
import '../data/models/signup_intent.dart';
import '../state/auth_controller.dart';

/// Reached after RolePickerScreen - shown full-screen by Navigator.push
/// (not as a dialog/modal over the splash background) so it reads as a real
/// landing moment, matching eventsrus-web's own full-page login screens
/// rather than a small floating card. [intent] carries which door the
/// role-picker chose through to the backend (see GoogleAuthRequest).
class LoginScreen extends StatefulWidget {
  final SignupIntent intent;

  const LoginScreen({super.key, required this.intent});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _errorMessage;
  bool _signingIn = false;

  Future<void> _handleSignIn() async {
    setState(() {
      _errorMessage = null;
      _signingIn = true;
    });
    try {
      final idToken = await GoogleAuthGateway.instance.signIn();
      if (idToken == null) return; // user dismissed the account picker
      if (!mounted) return;

      final authController = context.read<AuthController>();
      try {
        await authController.completeLogin(idToken, intent: widget.intent);
        if (!mounted) return;
        // AuthGate (below this route) has already swapped to the signed-in
        // shell by now - pop back to it so that becomes visible.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final busy = authController.isLoading || _signingIn;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset('assets/images/logo-login.svg', width: 240),
                  const SizedBox(height: 32),
                  Text(
                    widget.intent == SignupIntent.vendor ? 'Supplier Login' : 'Planner Login',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.intent == SignupIntent.vendor
                        ? 'Sign in to manage your storefront, bookings, and subscription.'
                        : 'Sign in to start planning your event.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  if (busy)
                    const CircularProgressIndicator()
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _handleSignIn,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF3C4043),
                          side: const BorderSide(color: Color(0xFFDADCE0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        icon: SvgPicture.asset('assets/images/google_logo.svg', width: 20, height: 20),
                        label: const Text('Sign in with Google'),
                      ),
                    ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
