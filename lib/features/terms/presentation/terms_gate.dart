import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/app_logger.dart';
import '../../auth/state/auth_controller.dart';
import '../data/terms_api.dart';
import 'terms_acceptance_screen.dart';

/// Wraps the signed-in app: anyone who has not accepted the current Terms sees [TermsAcceptanceScreen] first, once.
/// If the check itself cannot be made (offline, server hiccup) the person is let through rather than locked out;
/// it is asked again the next time the app opens.
class TermsGate extends StatefulWidget {
  final Widget child;

  const TermsGate({super.key, required this.child});

  @override
  State<TermsGate> createState() => _TermsGateState();
}

enum _GateState { checking, needsAcceptance, clear }

class _TermsGateState extends State<TermsGate> {
  _GateState _state = _GateState.checking;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    try {
      final status = await context.read<TermsApi>().getStatus();
      if (!mounted) return;
      setState(() => _state = status.accepted ? _GateState.clear : _GateState.needsAcceptance);
    } catch (e) {
      AppLogger.error('Terms', 'Could not check Terms acceptance; letting the person through', error: e);
      if (!mounted) return;
      setState(() => _state = _GateState.clear);
    }
  }

  Future<void> _agree() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<TermsApi>().accept();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _state = _GateState.clear;
      });
    } catch (e) {
      AppLogger.error('Terms', 'Could not record Terms acceptance', error: e);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'We could not save your answer. Please check your connection and try again.';
      });
    }
  }

  Future<void> _open(String path) =>
      launchUrl(Uri.parse('${AppConfig.webBaseUrl}$path'), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _GateState.checking:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _GateState.needsAcceptance:
        return TermsAcceptanceScreen(
          busy: _busy,
          errorMessage: _error,
          onAgree: _agree,
          onDecline: () => context.read<AuthController>().logout(),
          onReadTerms: () => _open('/terms'),
          onReadPrivacy: () => _open('/privacy'),
        );
      case _GateState.clear:
        return widget.child;
    }
  }
}
