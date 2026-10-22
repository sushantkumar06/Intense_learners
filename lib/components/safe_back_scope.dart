import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A wrapper widget that ensures back navigation gestures and buttons
/// cleanly pop to the previous screen, or navigate to [fallbackLocation]
/// (defaults to '/student/dashboard') if there is no previous route on the stack,
/// preventing the user from ever being kicked directly out of the app.
class SafeBackScope extends StatelessWidget {
  final Widget child;
  final String fallbackLocation;

  const SafeBackScope({
    super.key,
    required this.child,
    this.fallbackLocation = '/student/dashboard',
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackLocation);
        }
      },
      child: child,
    );
  }
}
