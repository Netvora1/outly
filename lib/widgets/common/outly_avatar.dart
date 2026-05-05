import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/app_colors.dart';

class OutlyAvatar extends StatelessWidget {
  final String photoUrl;
  final String fallbackIcon;
  final double radius;

  const OutlyAvatar({
    super.key,
    required this.photoUrl,
    this.fallbackIcon = "",
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = photoUrl.trim();
    final hasImage = cleanUrl.isNotEmpty && cleanUrl.startsWith("http");

    return CircleAvatar(
      radius: radius,
      backgroundColor: C.card2,
      child: ClipOval(
        child: hasImage
            ? Image.network(
                cleanUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Icon(Icons.person, color: C.cyan, size: radius);
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    width: radius * 2,
                    height: radius * 2,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: C.cyan,
                      ),
                    ),
                  );
                },
              )
            : Icon(Icons.person, color: C.cyan, size: radius),
      ),
    );
  }
}
