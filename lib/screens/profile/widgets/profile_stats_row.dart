import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class ProfileStats extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;
  final int eventCount;

  const ProfileStats({
    super.key,
    required this.userId,
    required this.data,
    required this.eventCount,
  });

  @override
  Widget build(BuildContext context) {
    final followers = List.from(data["followers"] ?? []);
    final following = List.from(data["following"] ?? []);

    return Row(
      children: [
        Expanded(
          child: ProfileStatBox(
            value: "$eventCount",
            label: "Events",
            icon: Icons.local_fire_department_rounded,
            color: C.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ProfileStatBox(
            value: "${followers.length}",
            label: "Follower",
            icon: Icons.groups_2_rounded,
            color: C.cyan,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ProfileStatBox(
            value: "${following.length}",
            label: "Folgt",
            icon: Icons.person_add_alt_1_rounded,
            color: C.purple,
          ),
        ),
      ],
    );
  }
}

class ProfileStatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const ProfileStatBox({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
