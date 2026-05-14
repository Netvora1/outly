import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_colors.dart';
import 'moment_viewer_screen.dart';
import 'profile_shared_widgets.dart';

class ProfileMomentsGrid extends StatelessWidget {
  final String userId;

  const ProfileMomentsGrid({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("moments")
          .where("userId", isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const EmptyProfileBox(
            icon: Icons.photo_library_rounded,
            title: "Momente Fehler",
            text: "Momente konnten gerade nicht geladen werden.",
          );
        }

        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: C.cyan)),
          );
        }

        final docs = snap.data!.docs.toList();

        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final db = b.data() as Map<String, dynamic>;
          final ta = da["createdAt"];
          final tb = db["createdAt"];

          if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
          return 0;
        });

        if (docs.isEmpty) {
          return const EmptyProfileBox(
            icon: Icons.photo_library_rounded,
            title: "Noch keine Momente",
            text: "Hier erscheinen echte Highlights aus dem Leben.",
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;

            return _MomentTile(
              momentId: docs[i].id,
              data: data,
            );
          },
        );
      },
    );
  }
}

class _MomentTile extends StatelessWidget {
  final String momentId;
  final Map<String, dynamic> data;

  const _MomentTile({
    required this.momentId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (data["imageUrl"] ?? "")
        .toString()
        .trim()
        .replaceAll("\n", "")
        .replaceAll("\r", "")
        .replaceAll(" ", "");

    final type = (data["type"] ?? "photo").toString();
    final likes = List<String>.from(data["likes"] ?? []);
    final views = List<String>.from(data["views"] ?? []);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MomentViewerScreen(
              momentId: momentId,
              data: data,
            ),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: C.cyan.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: C.cyan.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const MomentFallback(),
              )
            else
              const MomentFallback(),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.02),
                    Colors.black.withOpacity(0.18),
                    Colors.black.withOpacity(0.78),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            Positioned(
              top: 7,
              left: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.42),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: C.cyan,
                  size: 14,
                ),
              ),
            ),

            if (type == "video")
              const Positioned(
                right: 7,
                top: 7,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),

            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: C.pink,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${likes.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.visibility_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${views.length}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}