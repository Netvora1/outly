import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class ProfileVibes extends StatelessWidget {
  final List<String> vibes;
  final bool isMe;
  final VoidCallback onEdit;

  const ProfileVibes({
    super.key,
    required this.vibes,
    required this.isMe,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            C.cyan.withOpacity(0.12),
            C.purple.withOpacity(0.10),
            C.card,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: C.cyan.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: C.cyan.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.interests_rounded, color: C.cyan),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  "Vibes",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isMe)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: C.cyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: C.cyan.withOpacity(0.28)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.tune_rounded, color: C.cyan, size: 17),
                        SizedBox(width: 6),
                        Text(
                          "Ändern",
                          style: TextStyle(
                            color: C.cyan,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Interessen, Aktivitäten und echte Outly-Energie.",
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (vibes.isEmpty)
            const Text(
              "Noch keine Vibes ausgewählt.",
              style: TextStyle(color: Colors.white54),
            )
          else
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: vibes.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: C.cyan.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: C.cyan.withOpacity(0.30)),
                    boxShadow: [
                      BoxShadow(
                        color: C.cyan.withOpacity(0.08),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Text(
                    "#$item",
                    style: const TextStyle(
                      color: C.cyan,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}