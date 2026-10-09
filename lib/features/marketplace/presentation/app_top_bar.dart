import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme_mode_picker.dart';
import '../../auth/state/auth_controller.dart';

/// Persistent top bar shared by the planner and vendor shells — always
/// visible regardless of which tab is selected, so "log out" never has to
/// be hunted for inside a nav item.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AppTopBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          onPressed: () => showThemeModePicker(context),
          icon: const Icon(Icons.brightness_6_outlined),
          tooltip: 'Appearance',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextButton.icon(
            onPressed: () => _confirmLogout(context, auth),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthController auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text("You'll need to sign in again to continue."),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.logout();
    }
  }
}
