import 'package:flutter/material.dart';

import '../../main.dart';

class AuthCheckTile extends StatelessWidget {
  final bool value;
  final Color color;
  final IconData icon;
  final String title;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTapText;

  const AuthCheckTile({
    super.key,
    required this.value,
    required this.color,
    required this.icon,
    required this.title,
    required this.onChanged,
    this.onTapText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.13) : C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? color.withOpacity(0.65) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onTapText,
                child: Text(
                  title,
                  style: TextStyle(
                    color: onTapText == null ? Colors.white70 : C.cyan,
                    fontWeight: onTapText == null ? FontWeight.w500 : FontWeight.bold,
                  ),
                ),
              ),
            ),
            Checkbox(
              value: value,
              activeColor: color,
              onChanged: (v) => onChanged(v ?? false),
            ),
          ],
        ),
      ),
    );
  }
}
