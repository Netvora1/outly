import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class ProfileNeonBackground extends StatelessWidget {
  const ProfileNeonBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF05040B),
                  Color(0xFF15072A),
                  Color(0xFF07080F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),

        Positioned(
          top: -120,
          left: -90,
          child: _GlowOrb(
            size: 310,
            color: C.purple,
            opacity: 0.28,
          ),
        ),

        Positioned(
          top: 180,
          right: -140,
          child: _GlowOrb(
            size: 340,
            color: C.pink,
            opacity: 0.20,
          ),
        ),

        Positioned(
          bottom: -140,
          left: 20,
          child: _GlowOrb(
            size: 300,
            color: C.cyan,
            opacity: 0.12,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity),
            blurRadius: 120,
            spreadRadius: 60,
          ),
        ],
      ),
    );
  }
}