import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme_controller.dart';

/// "Appearance" picker - reachable from both AppTopBar (planner, and
/// vendor's wide/tablet layout) and BrandHeaderBar (vendor's phone-width
/// layout), so every shell has the same one place to change this.
Future<void> showThemeModePicker(BuildContext context) {
  final controller = context.read<ThemeController>();
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => RadioGroup<ThemeMode>(
              groupValue: controller.mode,
              onChanged: (selected) {
                if (selected != null) controller.setThemeMode(selected);
                Navigator.of(sheetContext).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    secondary: Icon(Icons.brightness_auto_outlined),
                    title: Text('System default'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    secondary: Icon(Icons.light_mode_outlined),
                    title: Text('Light'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    secondary: Icon(Icons.dark_mode_outlined),
                    title: Text('Dark'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
