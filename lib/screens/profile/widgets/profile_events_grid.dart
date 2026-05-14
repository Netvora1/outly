import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_colors.dart';
import '../../../core/event_utils.dart';
import 'profile_shared_widgets.dart';

class ProfileEventGrid extends StatelessWidget {
  final String userId;

  const ProfileEventGrid({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("activities")
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: C.pink),
            ),
          );
        }

        final docs = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          return data["creatorId"] == userId ||
              data["userId"] == userId;
        }).toList();

        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final db = b.data() as Map<String, dynamic>;

          final ta = da["createdAt"];
          final tb = db["createdAt"];

          if (ta is Timestamp && tb is Timestamp) {
            return tb.compareTo(ta);
          }

          return 0;
        });

        if (docs.isEmpty) {
          return const EmptyProfileBox(
            icon: Icons.event_available_rounded,
            title: "Noch keine Aktivitäten",
            text:
                "Sobald hier echte Aktivitäten erstellt werden, erscheinen sie im Profil.",
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.74,
          ),
          itemBuilder: (context, index) {
            final data =
                docs[index].data() as Map<String, dynamic>;

            return _ProfileEventCard(data: data);
          },
        );
      },
    );
  }
}

class _ProfileEventCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ProfileEventCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        (data["title"] ?? "Aktivität").toString();

    final category =
        (data["category"] ?? "Chill").toString();

    final city =
        (data["city"] ?? data["location"] ?? "")
            .toString();

    final imageUrl =
        (data["imageUrl"] ?? "").toString().trim();

    final participants =
        List.from(data["participants"] ?? []);

    final maxPeople =
        data["maxPeople"] ?? data["maxParticipants"] ?? 0;

    final color = catColor(category);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
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
              errorBuilder: (_, __, ___) =>
                  EventFallback(color: color),
            )
          else
            EventFallback(color: color),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.04),
                  Colors.black.withOpacity(0.25),
                  Colors.black.withOpacity(0.96),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: color.withOpacity(0.44),
                ),
              ),
              child: Text(
                category.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),

          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.48),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.group_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    maxPeople is int && maxPeople > 0
                        ? "${participants.length}/$maxPeople"
                        : "${participants.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (city.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: color,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          city,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}