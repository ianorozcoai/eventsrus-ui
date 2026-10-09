import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shown while [AuthController.restoreSession] resolves (see AuthGate's
/// AuthStatus.unknown branch). AuthGate itself holds this on screen for a
/// minimum duration regardless of how fast session-restore actually
/// resolves, so the entrance animation always gets to play out as a real
/// branded moment rather than flashing past. The Flutter-level counterpart
/// to the native launch_background.xml splash the OS shows before the
/// Flutter engine itself has even started - both white now (logo-login.svg
/// has dark "Events" text and a colored icon, so it needs a light
/// background, same as every other place it's used on web).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    // Fade finishes well before the scale settles, so the logo is fully
    // opaque for the tail end of the little "pop" the easeOutBack overshoot
    // gives it - reads as a deliberate entrance, not just a fade.
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: SvgPicture.asset('assets/images/logo-login.svg', width: 240),
          ),
        ),
      ),
    );
  }
}
