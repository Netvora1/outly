import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class EventFallback extends StatelessWidget {
  final Color color;

  const EventFallback({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.85),
            C.card,
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_fire_department_rounded,
          color: Colors.white54,
          size: 54,
        ),
      ),
    );
  }
}

class MomentFallback extends StatelessWidget {
  const MomentFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.card2,
      child: const Center(
        child: Icon(
          Icons.photo_rounded,
          color: Colors.white38,
          size: 34,
        ),
      ),
    );
  }
}

class EmptyProfileBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const EmptyProfileBox({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: C.cyan.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          Icon(icon, color: C.cyan, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, height: 1.35),
          ),
        ],
      ),
    );
  }
}