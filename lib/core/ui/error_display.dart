import 'package:flutter/material.dart';

/// Shared "smooth, non-frightening" error presentation - a floating snackbar
/// with consistent styling, used instead of each screen hand-rolling its
/// own ScaffoldMessenger call. Callers still pass their own contextual
/// message text; only the display mechanism and styling are centralized.
/// The real exception belongs in AppLogger, not here - this widget shows
/// only calm, generic text to the user.
void showFriendlyError(BuildContext context, {String message = 'Something went wrong. Please try again.'}) {
  // No explicit colors here on purpose - SnackBar's Material 3 default
  // (inverseSurface/onInverseSurface) already has good contrast in both
  // light and dark mode. floating + rounded corners is what makes this
  // read as "smooth" rather than the default edge-to-edge bar.
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
}
