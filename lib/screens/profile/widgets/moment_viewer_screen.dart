import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_colors.dart';
import 'profile_shared_widgets.dart';

class MomentViewerScreen extends StatefulWidget {
  final String momentId;
  final Map<String, dynamic> data;

  const MomentViewerScreen({
    super.key,
    required this.momentId,
    required this.data,
  });

  @override
  State<MomentViewerScreen> createState() => MomentViewerScreenState();
}

class MomentViewerScreenState extends State<MomentViewerScreen> {
  late Map<String, dynamic> data;
  bool coverMode = true;

  @override
  void initState() {
    super.initState();
    data = Map<String, dynamic>.from(widget.data);
  }

  Future<void> toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final likes = List<String>.from(data["likes"] ?? []);
    final liked = likes.contains(uid);

    setState(() {
      liked ? likes.remove(uid) : likes.add(uid);
      data["likes"] = likes;
    });

    await FirebaseFirestore.instance.collection("moments").doc(widget.momentId).set({
      "likes": liked ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid]),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteMoment(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ownerId = (data["userId"] ?? "").toString();

    if (uid != ownerId) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: const Text(
          "Moment löschen?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          "Dieser Moment wird dauerhaft gelöscht.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Löschen",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection("moments").doc(widget.momentId).delete();

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("moments").doc(widget.momentId).snapshots(),
      builder: (context, snap) {
        if (snap.hasData && snap.data!.data() != null) {
          data = snap.data!.data() as Map<String, dynamic>;
        }

        final imageUrl = (data["imageUrl"] ?? "")
            .toString()
            .trim()
            .replaceAll("\n", "")
            .replaceAll("\r", "")
            .replaceAll(" ", "");

        final ownerId = (data["userId"] ?? "").toString();
        final isMine = ownerId == uid;
        final likes = List<String>.from(data["likes"] ?? []);
        final views = List<String>.from(data["views"] ?? []);
        final liked = likes.contains(uid);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: coverMode ? BoxFit.cover : BoxFit.contain,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => const MomentFallback(),
                      )
                    : const MomentFallback(),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.82),
                          Colors.black.withOpacity(0.08),
                          Colors.black.withOpacity(0.90),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: -90,
                left: -80,
                child: _ViewerGlow(color: C.purple),
              ),
              Positioned(
                bottom: -110,
                right: -90,
                child: _ViewerGlow(color: C.pink),
              ),

              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                      child: Row(
                        children: [
                          MomentCircleButton(
                            icon: Icons.close_rounded,
                            color: Colors.white,
                            onTap: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          const MomentTopBadge(text: "OUTLY MOMENT"),
                          const Spacer(),
                          MomentCircleButton(
                            icon: coverMode
                                ? Icons.fit_screen_rounded
                                : Icons.fullscreen_rounded,
                            color: C.cyan,
                            onTap: () => setState(() => coverMode = !coverMode),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 10),
                            MomentCircleButton(
                              icon: Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              onTap: () => deleteMoment(context),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Spacer(),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.42),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.13)),
                          boxShadow: [
                            BoxShadow(
                              color: C.pink.withOpacity(0.18),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _LikePill(
                              liked: liked,
                              likes: likes.length,
                              onTap: toggleLike,
                            ),
                            const SizedBox(width: 10),
                            _InfoPill(
                              icon: Icons.visibility_rounded,
                              text: "${views.length}",
                              color: Colors.white70,
                            ),
                            const Spacer(),
                            _InfoPill(
                              icon: coverMode
                                  ? Icons.fullscreen_rounded
                                  : Icons.fit_screen_rounded,
                              text: coverMode ? "Vollbild" : "Original",
                              color: C.cyan,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LikePill extends StatelessWidget {
  final bool liked;
  final int likes;
  final VoidCallback onTap;

  const _LikePill({
    required this.liked,
    required this.likes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: liked ? C.pink.withOpacity(0.22) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: liked ? C.pink : Colors.white.withOpacity(0.16),
          ),
          boxShadow: liked
              ? [
                  BoxShadow(
                    color: C.pink.withOpacity(0.28),
                    blurRadius: 18,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: liked ? C.pink : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 7),
            Text(
              "$likes",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.13)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class MomentCircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const MomentCircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.46),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.20),
              blurRadius: 18,
            ),
          ],
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

class MomentTopBadge extends StatelessWidget {
  final String text;

  const MomentTopBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.44),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: C.pink.withOpacity(0.32)),
        boxShadow: [
          BoxShadow(
            color: C.pink.withOpacity(0.18),
            blurRadius: 18,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ViewerGlow extends StatelessWidget {
  final Color color;

  const _ViewerGlow({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.22),
            blurRadius: 110,
            spreadRadius: 45,
          ),
        ],
      ),
    );
  }
}