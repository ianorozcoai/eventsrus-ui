import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../app/theme_mode_picker.dart';
import '../../auth/state/auth_controller.dart';
import '../../moderation/presentation/blocked_users_screen.dart';
import '../../profile/presentation/delete_account_screen.dart';

/// Persistent header shared by the vendor and planner shells - always the
/// brand logo, never a per-tab or per-screen title, so it reads the same
/// regardless of which bottom-nav destination is active or which event is
/// open. Dark background to match logo-navbar.svg, which is colored for
/// exactly that (see eventsrus-web's navbar-dark fragment, the same asset's
/// other usage).
class BrandHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandHeaderBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return AppBar(
      backgroundColor: const Color(0xFF252B36),
      foregroundColor: Colors.white,
      centerTitle: true,
      title: SvgPicture.asset('assets/images/logo-navbar.svg', height: 26),
      actions: [
        IconButton(
          onPressed: () => _confirmLogout(context, auth),
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
        ),
        // The three-dot menu holds the occasional things (Appearance, Blocked users, Delete account) so the
        // bar itself stays clean. Google Play requires an in-app way to delete an account; this header is
        // shared by the planner and vendor shells, so one entry here covers both roles.
        PopupMenuButton<String>(
          tooltip: 'More',
          onSelected: (value) {
            if (value == 'appearance') {
              showThemeModePicker(context);
            } else if (value == 'blocked-users') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
              );
            } else if (value == 'delete-account') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
              );
            }
          },
          itemBuilder: (menuContext) => [
            const PopupMenuItem(
              value: 'appearance',
              child: _MenuRow(icon: Icons.brightness_6_outlined, label: 'Appearance'),
            ),
            const PopupMenuItem(
              value: 'blocked-users',
              child: _MenuRow(icon: Icons.block, label: 'Blocked users'),
            ),
            // Destructive, so it is tinted like an error and stays last.
            PopupMenuItem(
              value: 'delete-account',
              child: _MenuRow(
                icon: Icons.delete_outline,
                label: 'Delete account',
                color: Theme.of(menuContext).colorScheme.error,
              ),
            ),
          ],
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

/// One row of the three-dot menu: an icon, then the label.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 14),
        Text(label, style: color == null ? null : TextStyle(color: color)),
      ],
    );
  }
}
