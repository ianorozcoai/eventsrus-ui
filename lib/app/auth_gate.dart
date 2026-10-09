import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/widgets/splash_screen.dart';
import '../features/auth/data/models/role.dart';
import '../features/auth/data/models/signup_intent.dart';
import '../features/auth/presentation/role_picker_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/planner/presentation/planner_shell.dart';
import '../features/subscription/presentation/plan_selection_screen.dart';
import '../features/vendor/presentation/vendor_onboarding_screen.dart';
import '../features/vendor/presentation/vendor_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Session-restore is just a secure-storage read - near-instant - but the
  // splash's entrance animation deserves to actually be seen rather than
  // flashing past, so it's held on screen for this long no matter how fast
  // restoreSession() resolves. Only ever applies once: status starts at
  // unknown and never reverts to it after (logout goes to unauthenticated).
  static const _minSplashDuration = Duration(seconds: 3);

  bool _minSplashElapsed = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthController>().restoreSession();
    Future.delayed(_minSplashDuration, () {
      if (mounted) setState(() => _minSplashElapsed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final status = auth.status;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: _resolveChild(auth, status),
    );
  }

  Widget _resolveChild(AuthController auth, AuthStatus status) {
    if (status == AuthStatus.unknown || !_minSplashElapsed) {
      return const SplashScreen();
    }

    if (status == AuthStatus.unauthenticated) {
      return const RolePickerScreen();
    }

    if (auth.role == Role.admin) {
      // This app is planner/vendor only - an ADMIN-role account should never
      // reach a dashboard here. In practice this shouldn't happen (admins
      // authenticate through eventsrus-web's separate username/password
      // admin login, not Google Sign-In tied to a User row), but if it ever
      // does, sign them straight back out rather than falling through to
      // PlannerShell below.
      WidgetsBinding.instance.addPostFrameCallback((_) => auth.logout());
      return const SplashScreen();
    }

    if (auth.role == Role.vendor) {
      // A vendor who has never subscribed at all (no row exists on the
      // backend yet - auth.plan is null, set from the same login/session
      // payload as SubscriptionStatusResponse.plan) is routed to a forced
      // plan-selection screen instead of the dashboard - mirrors web's
      // planSelectionModal, which keeps reappearing every login until the
      // vendor pays, adapted to mobile as a forced initial screen rather
      // than a literal modal (see PlanSelectionScreen's doc comment).
      // Returned directly here (not pushed), so there's no back button and
      // nothing to pop past. As soon as auth.plan becomes non-null (PayPal
      // return flow's applyPlanUpdate, or an immediate GCash grant) this
      // widget rebuilds (AuthController is watched above) and swaps
      // straight to VendorShell with no extra navigation needed.
      return auth.plan == null ? const PlanSelectionScreen(forced: true) : const VendorShell();
    }

    if (auth.signupIntent == SignupIntent.vendor) {
      // Declared vendor intent at sign-up (came through the "I'm a
      // Supplier" door) but role is still planner - onboarding was started
      // and never finished. Route straight back into it instead of the
      // planner dashboard, same as eventsrus-web does for this exact state.
      // Returned directly (not pushed) for the same reason as the vendor
      // plan-selection screen above - no back button, nothing to pop past.
      return const VendorOnboardingScreen();
    }

    return const PlannerShell();
  }
}
