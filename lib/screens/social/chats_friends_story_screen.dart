import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/event_utils.dart';
import '../../services/storage_service.dart';

import '../../widgets/common/info_card.dart';
import '../../widgets/common/outly_avatar.dart';
import '../../widgets/common/verified_name.dart';
import '../../widgets/auth/gradient_button.dart';
import '../../core/safety_utils.dart';
import '../../widgets/common/mini_badge.dart';
import '../../widgets/common/segment_button.dart';
import '../home/home_screen.dart';

import '../profile/user_profile_screen.dart';
import '../../widgets/common/mini_badge.dart';
import '../../widgets/auth/outly_logo.dart';
import '../profile/user_profile_screen.dart';

class ChatTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 16,
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.18),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}

class _FollowingList extends StatelessWidget {
  final String uid;
  final List<String> following;
  final List<String> followers;

  const _FollowingList({
    required this.uid,
    required this.following,
    required this.followers,
  });

  @override
  Widget build(BuildContext context) {
    if (following.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: const [
          InfoCard(
            title: "Noch keine Freunde",
            text: "Folge Leuten, dann erscheinen sie hier direkt. Du musst sie nicht jedes Mal neu suchen.",
          ),
        ],
      );
    }

    final visibleIds = following.take(10).toList();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .where(FieldPath.documentId, whereIn: visibleIds)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: C.cyan),
          );
        }

        final users = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data["isBanned"] != true;
        }).toList();

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                "Deine Freunde",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ...users.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final followsBack = followers.contains(doc.id);

              return FriendUserCard(
                userId: doc.id,
                data: data,
                followsBack: followsBack,
              );
            }),

            if (following.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: InfoCard(
                  title: "Mehr Freunde vorhanden",
                  text:
                      "Aktuell werden die ersten 10 angezeigt. Später machen wir Pagination, damit alle sauber geladen werden.",
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UserSearchResults extends StatelessWidget {
  final String uid;
  final String search;

  const _UserSearchResults({
    required this.uid,
    required this.search,
  });

  bool matchesSearch(Map<String, dynamic> data, String search) {
    final q = search.trim().toLowerCase();

    final username = (data["username"] ?? "").toString().toLowerCase();
    final city = (data["city"] ?? "").toString().toLowerCase();
    final bio = (data["bio"] ?? "").toString().toLowerCase();

    return username.contains(q) || city.contains(q) || bio.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: C.cyan),
          );
        }

        final users = snap.data!.docs.where((doc) {
          if (doc.id == uid) return false;

          final data = doc.data() as Map<String, dynamic>;

          if (data["isBanned"] == true) return false;

          final blockedBy = List<String>.from(data["blockedBy"] ?? []);
          if (blockedBy.contains(uid)) return false;

          return matchesSearch(data, search);
        }).toList();

        if (users.isEmpty) {
          return const Center(
            child: InfoCard(
              title: "Nichts gefunden",
              text: "Kein User passt zu deiner Suche.",
            ),
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                "Suchergebnisse",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...users.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return FriendUserCard(
                userId: doc.id,
                data: data,
                followsBack: false,
              );
            }),
          ],
        );
      },
    );
  }
}

class FriendUserCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;
  final bool followsBack;

  const FriendUserCard({
    super.key,
    required this.userId,
    required this.data,
    required this.followsBack,
  });

  String chatId(String a, String b) {
    final ids = [a, b]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  @override
  Widget build(BuildContext context) {
    final username = (data["username"] ?? "user").toString();
    final city = (data["city"] ?? "Keine Stadt").toString();
    final bio = (data["bio"] ?? "").toString();
    final photoUrl = (data["photoUrl"] ?? "").toString();
    final verified = data["verified"] == true;
    final trustScore = data["trustScore"] ?? 100;
    final color = safetyColor(trustScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: userId)
                ),
              );
            },
            child: OutlyAvatar(
              photoUrl: photoUrl,
              radius: 29,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: userId)
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  verifiedName(username, verified, size: 17),
                  const SizedBox(height: 4),
                  Text(
                    city,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      MiniBadge(
                        text: safetyLabel(trustScore),
                        icon: Icons.shield_outlined,
                        color: color,
                      ),
                      if (followsBack)
                        MiniBadge(
                          text: "folgt dir",
                          icon: Icons.favorite,
                          color: C.pink,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          Column(
            children: [
              CircleAvatar(
                backgroundColor: C.cyan,
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivateChatScreen(
                          otherUserId: userId,
                          otherUsername: username,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.08),
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white70),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: userId)
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _FriendStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FriendsSearch extends StatelessWidget {
  final String uid;
  final String search;
  final ValueChanged<String> onSearch;

  const FriendsSearch({
    super.key,
    required this.uid,
    required this.search,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    Widget userTile(QueryDocumentSnapshot doc) {
      final data = doc.data() as Map<String, dynamic>;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: C.cyan.withOpacity(0.22)),
        ),
        child: ListTile(
          leading: OutlyAvatar(
            photoUrl: (data["photoUrl"] ?? "").toString(),
            radius: 25,
          ),
          title: verifiedName(
            data["username"] ?? "user",
            data["verified"] == true,
          ),
          subtitle: Text(
            data["city"] ?? "Keine Stadt",
            style: const TextStyle(color: Colors.white54),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: doc.id),
              ),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: TextField(
            onChanged: (v) => onSearch(v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: "Username suchen...",
              prefixIcon: Icon(Icons.search, color: C.cyan),
            ),
          ),
        ),

        const SizedBox(height: 14),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("users").snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: C.cyan),
                ),
              );
            }

            final allUsers = snap.data!.docs.where((doc) {
              if (doc.id == uid) return false;

              final data = doc.data() as Map<String, dynamic>;
              if (data["isBanned"] == true) return false;

              return true;
            }).toList();

            final searchResults = allUsers.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data["username"] ?? "").toString().toLowerCase();

              if (search.isEmpty) {
                final followers = List<String>.from(data["followers"] ?? []);
                return followers.contains(uid);
              }

              return name.contains(search);
            }).toList();

            final suggestions = allUsers.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final followers = List<String>.from(data["followers"] ?? []);

              return !followers.contains(uid);
            }).take(5).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (search.isEmpty && suggestions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      "✨ Vorschläge für dich",
                      style: TextStyle(
                        color: C.cyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: suggestions.map(userTile).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    search.isEmpty ? "Deine Freunde" : "Suchergebnisse",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                if (searchResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                    child: InfoCard(
                      title: "Keine Freunde gefunden",
                      text: "Suche nach Usern oder folge Leuten.",
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: searchResults.map(userTile).toList(),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class ChatsFriendsStoryScreen extends StatefulWidget {
  const ChatsFriendsStoryScreen({super.key});

  @override
  State<ChatsFriendsStoryScreen> createState() => _ChatsFriendsStoryScreenState();
}

class _ChatsFriendsStoryScreenState extends State<ChatsFriendsStoryScreen> {
  int tab = 0;
  String search = "";

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: LinearGradient(
                  colors: [
                    C.purple.withOpacity(0.62),
                    C.card,
                    C.cyan.withOpacity(0.16),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: C.cyan.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                     OutlyLogo(),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Deine Leute 💬",
                              style: TextStyle(
                                fontSize: 29,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Chats, Freunde und echte Connections.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SegmentButton(
                            text: "Chats",
                            active: tab == 0,
                            onTap: () => setState(() => tab = 0),
                          ),
                        ),
                        Expanded(
                          child: SegmentButton(
                            text: "Freunde",
                            active: tab == 1,
                            onTap: () => setState(() => tab = 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
           
            const SizedBox(height: 14),

            if (tab == 0)
              ChatsList(uid: uid)
            else
              FriendsSearch(
                uid: uid,
                search: search,
                onSearch: (v) => setState(() => search = v),
              ),
          ],
        ),
      ),
    );
  }
}

class _SocialTabButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _SocialTabButton({
    required this.text,
    required this.icon,
    required this.active,
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
          color: active ? C.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: C.cyan.withOpacity(0.30),
                    blurRadius: 18,
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatsList extends StatelessWidget {
  final String uid;

  const ChatsList({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("privateChats")
          .where("participants", arrayContains: uid)
          .snapshots(),
      builder: (context, privateSnap) {
        if (!privateSnap.hasData) {
          return const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator(color: C.cyan)),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("activities")
              .where("participants", arrayContains: uid)
              .snapshots(),
          builder: (context, activitySnap) {
            if (!activitySnap.hasData) {
              return const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator(color: C.cyan)),
              );
            }

            final privateChats = privateSnap.data!.docs.toList();
            final activityChats = activitySnap.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data["hasChat"] == true && isEventActive(data);
            }).toList();

            if (privateChats.isEmpty && activityChats.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 50),
                child: InfoCard(
                  title: "Noch keine Chats",
                  text: "Private Chats und Event-Chats erscheinen hier.",
                ),
              );
            }

            return Column(
              children: [
                ...privateChats.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final participants = List<String>.from(data["participants"] ?? []);

                  final otherUserId = participants.firstWhere(
                    (id) => id != uid,
                    orElse: () => "",
                  );

                  if (otherUserId.isEmpty) return const SizedBox.shrink();

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("users")
                        .doc(otherUserId)
                        .get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox.shrink();

                      final userData =
                          userSnap.data!.data() as Map<String, dynamic>? ?? {};

                      if (userData["isBanned"] == true) {
                        return const SizedBox.shrink();
                      }

                      final username = userData["username"] ?? "user";

                      return ChatTile(
                        color: C.cyan,
                        icon: Icons.person,
                        title: "@$username",
                        subtitle: data["lastMessage"] ?? "Privater Chat",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrivateChatScreen(
                                otherUserId: otherUserId,
                                otherUsername: username,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }),

                ...activityChats.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final category = data["category"] ?? "Chill";

                  return ChatTile(
                    color: catColor(category),
                    icon: catIcon(category),
                    title: data["title"] ?? "Event",
                    subtitle: data["place"] ?? "Event-Chat öffnen",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivityDetailScreen(activityId: doc.id),
                        ),
                      );
                    },
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}