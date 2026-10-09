import 'package:flutter/material.dart';

/// eventsrus-web's actual brand palette (fragments/common.html,
/// landing.html's role cards, login.html) - blue is the app-wide primary
/// (buttons, focus states, the planner/Google-signin accent everywhere),
/// orange is reserved for vendor-identity accents specifically (the vendor
/// onboarding hero below, matching the web login page's vendor card). These
/// used to be a single generic Material orange seed with no tie to the web
/// app's real colors at all.
const kBrandBlue = Color(0xFF0C83FF);
const kBrandOrange = Color(0xFFF8512D);

const kBrandBlack = Color(0xFF0A0A0C);

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBrandBlue,
      brightness: brightness,
    ),
    useMaterial3: true,
  );
  final colorScheme = base.colorScheme;

  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      foregroundColor: colorScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 1),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        // horizontal was missing entirely here, which EdgeInsets.symmetric
        // silently defaults to 0 rather than Flutter's own built-in button
        // padding - every FilledButton app-wide (Save, Confirm, Add Photo,
        // Add Package, ...) read as visually cramped, text nearly touching
        // the button's edges.
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
