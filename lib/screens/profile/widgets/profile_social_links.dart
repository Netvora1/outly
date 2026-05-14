import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class ProfileSocialLinksCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<void> Function(String url) onOpen;

  const ProfileSocialLinksCard({
    super.key,
    required this.data,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final instagram = (data["instagram"] ?? "").toString().trim();
    final tiktok = (data["tiktok"] ?? "").toString().trim();
    final website = (data["website"] ?? "").toString().trim();

    final hasLinks =
        instagram.isNotEmpty || tiktok.isNotEmpty || website.isNotEmpty;

    if (!hasLinks) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.36),
            C.card.withOpacity(0.82),
            C.purple.withOpacity(0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: C.pink.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: C.pink.withOpacity(0.12),
            blurRadius: 28,
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (instagram.isNotEmpty)
            _LinkChip(
              icon: Icons.camera_alt_rounded,
              text: "Instagram",
              color: C.pink,
              onTap: () => onOpen(
                instagram.startsWith("@")
                    ? "instagram.com/${instagram.substring(1)}"
                    : instagram,
              ),
            ),
          if (tiktok.isNotEmpty)
            _LinkChip(
              icon: Icons.music_note_rounded,
              text: "TikTok",
              color: C.cyan,
              onTap: () => onOpen(
                tiktok.startsWith("@")
                    ? "tiktok.com/@${tiktok.substring(1)}"
                    : tiktok,
              ),
            ),
          if (website.isNotEmpty)
            _LinkChip(
              icon: Icons.link_rounded,
              text: "Website",
              color: C.purple2,
              onTap: () => onOpen(website),
            ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _LinkChip({
    required this.icon,
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.38)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}