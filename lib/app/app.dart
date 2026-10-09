import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/navigation/navigator_key.dart';
import '../features/subscription/presentation/billing_history_screen.dart';
import '../features/subscription/presentation/plan_selection_screen.dart';
import '../features/subscription/presentation/subscription_return_screen.dart';
import '../features/vendor/presentation/vendor_onboarding_screen.dart';
import 'auth_gate.dart';
import 'theme.dart';
import 'theme_controller.dart';

class EventsRusApp extends StatelessWidget {
  const EventsRusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().mode;
    return MaterialApp(
      title: 'EventsRUs',
      navigatorKey: rootNavigatorKey,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: themeMode,
      home: const AuthGate(),
      routes: {
        // AuthGate re-resolves to the correct shell (planner vs vendor) based
        // on the current role — used as a "go back to my home" target.
        '/dashboard': (_) => const AuthGate(),
        '/vendor-onboarding': (_) => const VendorOnboardingScreen(),
        '/subscription/plans': (_) => const PlanSelectionScreen(),
        '/subscription/return': (_) => const SubscriptionReturnScreen(),
        '/subscription/history': (_) => const BillingHistoryScreen(),
      },
    );
  }
}
