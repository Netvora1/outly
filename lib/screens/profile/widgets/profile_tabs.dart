import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class ProfileTabs extends StatelessWidget {
  final int selectedTab;
  final Function(int) onTabSelected;

  const ProfileTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ProfileTabButton(
              text: "Momente",
              active: selectedTab == 0,
              icon: Icons.auto_awesome_rounded,
              color: C.cyan,
              onTap: () => onTabSelected(0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ProfileTabButton(
              text: "Events",
              active: selectedTab == 1,
              icon: Icons.event_available_rounded,
              color: C.pink,
              onTap: () => onTabSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTabButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const ProfileTabButton({
    required this.text,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [
                    color,
                    color.withOpacity(0.72),
                  ],
                )
              : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.26),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? Colors.black : Colors.white54,
            ),
            const SizedBox(width: 7),
            Text(
              text,
              style: TextStyle(
                color: active ? Colors.black : Colors.white54,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}