import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class ProfileLevelCard extends StatelessWidget {
  final String level;
  final Color color;
  final IconData icon;

  const ProfileLevelCard({
    super.key,
    required this.level,
    required this.color,
    required this.icon,
  });

  String description() {
    switch (level) {
      case "Legend":
        return "Sehr aktiv in der Outly Community.";
      case "Explorer":
        return "Erstellt Events und entdeckt neue Leute.";
      case "Social":
        return "Aktiv, sozial und oft dabei.";
      case "Active":
        return "Hat schon starke Vibes auf Outly.";
      default:
        return "Neu dabei. Noch am Entdecken.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.14),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Outly $level",
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description(),
                  style: const TextStyle(
                    color: Colors.white60,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}