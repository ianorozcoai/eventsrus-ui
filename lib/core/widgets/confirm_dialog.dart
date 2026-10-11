import 'package:flutter/material.dart';

/// Shared "are you sure?" confirmation - call from a plain button handler
/// instead of acting immediately. Returns true only if the planner tapped
/// the confirm button; false or null (dismissed) both mean "don't proceed".
Future<bool?> showConfirmDialog(
  BuildContext context, {
  String? title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: title != null ? Text(title) : null,
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(cancelLabel)),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(confirmLabel)),
      ],
    ),
  );
}
