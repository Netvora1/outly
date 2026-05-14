import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../widgets/common/outly_avatar.dart';
import 'outly_level_badge.dart';

class ProfileHero extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final bool uploadingImage;
  final VoidCallback onImageTap;
  final String level;
  final Color levelColor;
  final IconData levelIcon;

  const ProfileHero({
    super.key,
    required this.data,
    required this.isMe,
    required this.uploadingImage,
    required this.onImageTap,
    required this.level,
    required this.levelColor,
    required this.levelIcon,
  });

  @override
  Widget build(BuildContext context) {
    final username = (data["username"] ?? "user").toString();
    final bio = (data["bio"] ?? "Neu bei Outly 🔥").toString();
    final city = (data["city"] ?? "Keine Stadt").toString();
    final photoUrl = (data["photoUrl"] ?? "").toString().trim();

    final followers = List.from(data["followers"] ?? []).length;
    final following = List.from(data["following"] ?? []).length;
    final events = data["eventsCount"] ?? 0;

    final verified = data["verified"] == true;
    final creator = data["creator"] == true;
    final trusted = data["trusted"] == true;
    final legend = data["legend"] == true;
    final vip = data["vip"] == true;
    final team = data["team"] == true;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                C.purple.withOpacity(0.95),
                C.pink.withOpacity(0.38),
                C.cyan.withOpacity(0.18),
                C.bg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        Positioned(
          right: -55,
          top: 65,
          child: Icon(
            levelIcon,
            size: 215,
            color: Colors.white.withOpacity(0.07),
          ),
        ),

        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.06),
                  C.bg.withOpacity(0.20),
                  C.bg,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        Positioned(
          left: 20,
          right: 20,
          bottom: 22,
          child: Column(
            children: [
              GestureDetector(
                onTap: isMe ? onImageTap : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 126,
                      height: 126,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [levelColor, C.pink, C.purple],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: levelColor.withOpacity(0.38),
                            blurRadius: 34,
                          ),
                        ],
                      ),
                      child: OutlyAvatar(
                        photoUrl: photoUrl,
                        radius: 59,
                      ),
                    ),
                    if (uploadingImage)
                      Container(
                        width: 126,
                        height: 126,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.50),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: C.pink),
                        ),
                      ),
                    if (isMe)
                      Positioned(
                        right: 0,
                        bottom: 7,
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: C.pink,
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 7,
                runSpacing: 6,
                children: [
                  Text(
                    "@$username",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                  if (verified)
                    const Icon(Icons.verified_rounded,
                        color: Colors.blueAccent, size: 23),
                  if (creator)
                    const Icon(Icons.workspace_premium_rounded,
                        color: C.orange, size: 22),
                  if (trusted)
                    const Icon(Icons.shield_rounded, color: C.cyan, size: 21),
                  if (legend)
                    const Icon(Icons.whatshot_rounded, color: C.pink, size: 21),
                  if (vip)
                    const Icon(Icons.diamond_rounded,
                        color: Colors.purpleAccent, size: 21),
                  if (team)
                    const Icon(Icons.bolt_rounded,
                        color: Colors.greenAccent, size: 21),
                ],
              ),

              const SizedBox(height: 8),

              OutlyLevelBadge(
                level: level,
                color: levelColor,
                icon: levelIcon,
              ),

              const SizedBox(height: 9),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_rounded, color: C.pink, size: 17),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  _HeroStat(value: "$events", label: "Events"),
                  _HeroDivider(),
                  _HeroStat(value: "$followers", label: "Follower"),
                  _HeroDivider(),
                  _HeroStat(value: "$following", label: "Folgt"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withOpacity(0.12),
    );
  }
}