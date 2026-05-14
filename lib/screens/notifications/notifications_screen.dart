import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_colors.dart';
import '../../widgets/common/info_card.dart';
import '../../widgets/common/outly_avatar.dart';
import '../home/home_screen.dart';
import '../profile/user_profile_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData iconForType(String type) {
    switch (type) {
      case "follow":
        return Icons.person_add_alt_1_rounded;
      case "join":
        return Icons.local_fire_department_rounded;
      case "request":
        return Icons.how_to_reg_rounded;
      case "chat":
        return Icons.chat_bubble_outline_rounded;
      case "admin":
        return Icons.admin_panel_settings_rounded;
      case "outly_news":
      case "broadcast":
        return Icons.campaign_rounded;
      case "support_reply":
        return Icons.support_agent_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color colorForType(String type) {
    switch (type) {
      case "follow":
        return C.cyan;
      case "join":
        return C.orange;
      case "request":
        return C.green;
      case "chat":
        return C.pink;
      case "admin":
        return C.purple2;
      case "outly_news":
      case "broadcast":
        return C.cyan;
      case "support_reply":
        return C.green;
      default:
        return C.cyan;
    }
  }

  bool isSystemNotification(String type, String fromUserId) {
    return fromUserId == "outly" ||
        type == "outly_news" ||
        type == "broadcast" ||
        type == "support_reply" ||
        type == "admin";
  }

  String systemName(String type) {
    if (type == "support_reply") return "Outly Support";
    if (type == "admin") return "Outly Admin";
    return "Outly";
  }

  Future<void> markAsRead(DocumentReference ref) async {
    await ref.set({
      "read": true,
      "readAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllAsRead(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection("notifications")
        .where("toUserId", isEqualTo: uid)
        .where("read", isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snap.docs) {
      batch.set(doc.reference, {
        "read": true,
        "readAt": Timestamp.now(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> openNotification(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> data,
  ) async {
    await markAsRead(ref);

    if (!context.mounted) return;

    final type = (data["type"] ?? "").toString();
    final fromUserId = (data["fromUserId"] ?? "").toString();
    final targetId = (data["targetId"] ?? "").toString();
    final title = (data["title"] ?? systemName(type)).toString();
    final text = (data["text"] ?? "").toString();

    if (type == "follow" && fromUserId.isNotEmpty && fromUserId != "outly") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: fromUserId),
        ),
      );
      return;
    }

    if ((type == "join" || type == "request" || type == "event") &&
        targetId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(activityId: targetId),
        ),
      );
      return;
    }

    final color = colorForType(type);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: color.withOpacity(0.28)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.16),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(iconForType(type), color: color, size: 34),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Schließen"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (uid.isEmpty) {
      return const Scaffold(
        backgroundColor: C.bg,
        body: Center(
          child: Text(
            "Nicht angemeldet.",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        title: const Text(
          "Benachrichtigungen",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: () => markAllAsRead(uid),
            child: const Text(
              "Alle gelesen",
              style: TextStyle(
                color: C.cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("toUserId", isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: C.cyan),
            );
          }

          final docs = snap.data!.docs.toList();

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
            return const Center(
              child: InfoCard(
                title: "Noch nichts da",
                text:
                    "Hier erscheinen neue Follower, Event-Updates, Join-Anfragen und Outly News.",
              ),
            );
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final type = (data["type"] ?? "").toString();
              final title = (data["title"] ?? "").toString();
              final text = (data["text"] ?? "").toString();
              final fromUserId = (data["fromUserId"] ?? "").toString();
              final read = data["read"] == true;
              final color = colorForType(type);
              final isSystem = isSystemNotification(type, fromUserId);

              return FutureBuilder<DocumentSnapshot>(
                future: isSystem || fromUserId.isEmpty
                    ? null
                    : FirebaseFirestore.instance
                        .collection("users")
                        .doc(fromUserId)
                        .get(),
                builder: (context, userSnap) {
                  final userData =
                      userSnap.data?.data() as Map<String, dynamic>? ?? {};

                  final username = isSystem
                      ? systemName(type)
                      : (userData["username"] ?? "User").toString();

                  final photoUrl = isSystem
                      ? ""
                      : (userData["photoUrl"] ?? "").toString();

                  return GestureDetector(
                    onTap: () => openNotification(context, doc.reference, data),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: read ? C.card : color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: read
                              ? Colors.white.withOpacity(0.08)
                              : color.withOpacity(0.45),
                        ),
                        boxShadow: [
                          if (!read)
                            BoxShadow(
                              color: color.withOpacity(0.18),
                              blurRadius: 18,
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              isSystem
                                  ? CircleAvatar(
                                      radius: 25,
                                      backgroundColor: color.withOpacity(0.15),
                                      child: Icon(
                                        type == "support_reply"
                                            ? Icons.support_agent_rounded
                                            : Icons.auto_awesome_rounded,
                                        color: color,
                                      ),
                                    )
                                  : OutlyAvatar(photoUrl: photoUrl, radius: 25),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: color,
                                  child: Icon(
                                    iconForType(type),
                                    size: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSystem ? username : "@$username",
                                  style: TextStyle(
                                    color: read ? Colors.white70 : color,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (title.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!read)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}