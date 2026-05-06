import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/app_colors.dart';

class AuthShell extends StatelessWidget {
  final Widget child;
  final bool showBack;

  const AuthShell({
    super.key,
    required this.child,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: showBack
          ? AppBar(
              backgroundColor: C.bg,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.2,
              colors: [
                C.purple.withOpacity(0.22),
                C.bg,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}