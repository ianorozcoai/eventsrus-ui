import 'dart:ui';

import 'package:flutter/material.dart';

class BlurredModalCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const BlurredModalCard({
    super.key,
    required this.child,
    this.maxWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(color: Colors.black.withValues(alpha: 0.4)),
        ),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
