import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/legal_texts.dart';

import '../../services/storage_service.dart';

import '../../widgets/auth/gradient_button.dart';
import '../../widgets/common/info_card.dart';
import '../../widgets/common/outly_avatar.dart';
import '../../widgets/common/verified_name.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(backgroundColor: C.bg, title: const Text("Profil")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(userId).get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final followers = List.from(data["followers"] ?? []);
          final following = List.from(data["following"] ?? []);
          final interests = List<String>.from(data["interests"] ?? ["Sport", "Chill", "Gaming"]);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                ProfileBox(
                  data: data,
                  followers: followers.length,
                  following: following.length,
                  userId: userId,
                  showActions: myUid != userId,
                ),
                if (myUid != userId) ...[
                  const SizedBox(height: 14),
                  FollowButton(targetUserId: userId),
                  const SizedBox(height: 12),
                  ReportUserButton(targetUserId: userId),
                  const SizedBox(height: 12),
                  BlockUserButton(targetUserId: userId),
                  const SizedBox(height: 12),
                  GradientButton(
                    text: "Nachricht",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrivateChatScreen(
                            otherUserId: userId,
                            otherUsername: data["username"] ?? "user",
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 22),
                InterestsWrap(interests: interests),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProfileBox extends StatelessWidget {
  final Map<String, dynamic> data;
  final int followers;
  final int following;
  final String userId;
  final bool showActions;

  const ProfileBox({
    super.key,
    required this.data,
    required this.followers,
    required this.following,
    required this.userId,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    final username = (data["username"] ?? "user").toString();
    final city = (data["city"] ?? "Keine Stadt").toString();
    final bio = (data["bio"] ?? "Neu bei Outly 🔥").toString();
    final photoUrl = (data["photoUrl"] ?? "").toString();
    final coverUrl = (data["coverUrl"] ?? "").toString();

    final trustScore = data["trustScore"] ?? 100;
    final creator = data["creator"] == true;
    final verified = data["verified"] == true;
    final identityVerified = data["identityVerified"] == true;
    final ageVerified = data["ageVerified"] == true;

    final color = safetyColor(trustScore);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: color.withOpacity(0.34)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.20),
            blurRadius: 34,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 155,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.75),
                      C.purple.withOpacity(0.55),
                      Colors.black,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: coverUrl.trim().isNotEmpty && coverUrl.startsWith("http")
                      ? DecorationImage(
                          image: NetworkImage(coverUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.35),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -35,
                      top: -30,
                      child: Icon(
                        Icons.explore,
                        size: 150,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_outlined, color: color, size: 17),
                            const SizedBox(width: 6),
                            Text(
                              city,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: -54,
                child: Center(
                  child: Container(
                    width: 116,
                    height: 116,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [color, C.cyan, C.purple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.45),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: OutlyAvatar(
                      photoUrl: photoUrl,
                      radius: 54,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 66),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                verifiedName(username, verified, size: 27),

                const SizedBox(height: 8),

                Text(
                  bio,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SafetyBadge(score: trustScore),
                    if (verified)
                      const MiniBadge(
                        text: "Verifiziert",
                        icon: Icons.verified,
                        color: Colors.blue,
                      ),
                    if (identityVerified)
                      const MiniBadge(
                        text: "Identität geprüft",
                        icon: Icons.verified_user,
                        color: C.green,
                      ),
                    if (ageVerified)
                      const MiniBadge(
                        text: "Alter geprüft",
                        icon: Icons.cake_outlined,
                        color: C.orange,
                      ),
                    if (creator)
                      const MiniBadge(
                        text: "Creator",
                        icon: Icons.workspace_premium,
                        color: C.orange,
                      ),
                  ],
                ),

                const SizedBox(height: 22),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("activities")
                              .where("creatorId", isEqualTo: userId)
                              .snapshots(),
                          builder: (context, aSnap) {
                            final count = aSnap.data?.docs.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return isEventActive(data);
                                }).length ??
                                0;

                            return _ProfileBigStat(
                              value: "$count",
                              label: "Events",
                              icon: Icons.local_fire_department,
                              color: C.orange,
                            );
                          },
                        ),
                      ),
                      _ProfileStatDivider(),
                      Expanded(
                        child: _ProfileBigStat(
                          value: "$followers",
                          label: "Follower",
                          icon: Icons.groups_2_outlined,
                          color: C.cyan,
                        ),
                      ),
                      _ProfileStatDivider(),
                      Expanded(
                        child: _ProfileBigStat(
                          value: "$following",
                          label: "Following",
                          icon: Icons.person_add_alt_1,
                          color: C.purple2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color.withOpacity(0.30)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Safety Status: ${safetyLabel(trustScore)}",
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "$trustScore/100",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBigStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _ProfileBigStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ProfileStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withOpacity(0.10),
    );
  }
}
class FollowButton extends StatefulWidget {
  final String targetUserId;

  const FollowButton({super.key, required this.targetUserId});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool loading = true;
  bool following = false;

  @override
  void initState() {
    super.initState();
    check();
  }

  Future<void> check() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final list = List<String>.from(doc.data()?["following"] ?? []);

    if (!mounted) return;

    setState(() {
      following = list.contains(widget.targetUserId);
      loading = false;
    });
  }

  Future<void> toggle() async {
    if (loading) return;

    setState(() => loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final myRef = FirebaseFirestore.instance.collection("users").doc(uid);
    final targetRef =
        FirebaseFirestore.instance.collection("users").doc(widget.targetUserId);

    try {
      if (following) {
        await myRef.set({
          "following": FieldValue.arrayRemove([widget.targetUserId]),
          "updatedAt": Timestamp.now(),
        }, SetOptions(merge: true));

        await targetRef.set({
          "followers": FieldValue.arrayRemove([uid]),
          "updatedAt": Timestamp.now(),
        }, SetOptions(merge: true));

        if (!mounted) return;

        setState(() {
          following = false;
          loading = false;
        });
      } else {
        await myRef.set({
          "following": FieldValue.arrayUnion([widget.targetUserId]),
          "updatedAt": Timestamp.now(),
        }, SetOptions(merge: true));

        await targetRef.set({
          "followers": FieldValue.arrayUnion([uid]),
          "updatedAt": Timestamp.now(),
        }, SetOptions(merge: true));

        await sendNotification(
          toUserId: widget.targetUserId,
          fromUserId: uid,
          type: "follow",
          text: "folgt dir jetzt.",
        );

        if (!mounted) return;

        setState(() {
          following = true;
          loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aktion fehlgeschlagen")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: loading ? null : toggle,
      icon: loading
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: C.cyan,
              ),
            )
          : Icon(
              following ? Icons.check_circle : Icons.person_add_alt_1,
            ),
      label: Text(
        loading
            ? "Lädt..."
            : following
                ? "Following"
                : "Follow",
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: following ? Colors.white12 : C.cyan,
        foregroundColor: following ? Colors.white : Colors.black,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class BlockUserButton extends StatefulWidget {
  final String targetUserId;

  const BlockUserButton({super.key, required this.targetUserId});

  @override
  State<BlockUserButton> createState() => _BlockUserButtonState();
}

class _BlockUserButtonState extends State<BlockUserButton> {
  bool loading = true;
  bool blocked = false;

  @override
  void initState() {
    super.initState();
    check();
  }

  Future<void> check() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final blockedUsers = List<String>.from(doc.data()?["blockedUsers"] ?? []);

    if (!mounted) return;

    setState(() {
      blocked = blockedUsers.contains(widget.targetUserId);
      loading = false;
    });
  }

  Future<void> toggleBlock() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final myRef = FirebaseFirestore.instance.collection("users").doc(uid);
    final targetRef = FirebaseFirestore.instance.collection("users").doc(widget.targetUserId);

    if (blocked) {
      await myRef.set({
        "blockedUsers": FieldValue.arrayRemove([widget.targetUserId]),
      }, SetOptions(merge: true));

      await targetRef.set({
        "blockedBy": FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));
    } else {
      await myRef.set({
        "blockedUsers": FieldValue.arrayUnion([widget.targetUserId]),
        "following": FieldValue.arrayRemove([widget.targetUserId]),
      }, SetOptions(merge: true));

      await targetRef.set({
        "blockedBy": FieldValue.arrayUnion([uid]),
        "followers": FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));
    }

    if (!mounted) return;

    setState(() => blocked = !blocked);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(blocked ? "User blockiert" : "Blockierung aufgehoben")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: toggleBlock,
      icon: Icon(blocked ? Icons.lock_open : Icons.block),
      label: Text(blocked ? "Blockierung aufheben" : "User blockieren"),
      style: ElevatedButton.styleFrom(
        backgroundColor: blocked ? Colors.white12 : Colors.red.withOpacity(0.14),
        foregroundColor: blocked ? Colors.white : Colors.redAccent,
        minimumSize: const Size(double.infinity, 46),
      ),
    );
  }
}

class ReportUserButton extends StatefulWidget {
  final String targetUserId;

  const ReportUserButton({
    super.key,
    required this.targetUserId,
  });

  @override
  State<ReportUserButton> createState() => _ReportUserButtonState();
}

class _ReportUserButtonState extends State<ReportUserButton> {
  bool loading = false;

  Future<void> reportUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        title: const Text("User melden"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            reportReasonButton(context, "Belästigung"),
            reportReasonButton(context, "Fake Profil"),
            reportReasonButton(context, "Verdächtiges Verhalten"),
            reportReasonButton(context, "Gefährlicher Inhalt"),
          ],
        ),
      ),
    );

    if (reason == null) return;

    setState(() => loading = true);

    await FirebaseFirestore.instance.collection("reports").add({
      "type": "user",
      "targetUserId": widget.targetUserId,
      "reportedBy": currentUser.uid,
      "reason": reason,
      "status": "open",
      "createdAt": Timestamp.now(),
    });

    await FirebaseFirestore.instance.collection("users").doc(widget.targetUserId).set({
      "reportedCount": FieldValue.increment(1),
      "riskFlags": FieldValue.arrayUnion(["reported"]),
      "trustScore": FieldValue.increment(-10),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User wurde gemeldet ✅")),
    );
  }

  Widget reportReasonButton(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, text),
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: loading ? null : reportUser,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.flag_outlined),
      label: const Text("User melden"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.withOpacity(0.14),
        foregroundColor: Colors.redAccent,
        minimumSize: const Size(double.infinity, 46),
        padding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.35)),
        ),
      ),
    );
  }
}

class InterestsWrap extends StatelessWidget {
  final List<String> interests;

  const InterestsWrap({super.key, required this.interests});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Interessen",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: interests.map((i) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: C.cyan.withOpacity(0.35)),
              ),
              child: Text(i, style: TextStyle(color: C.cyan)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class PrivateChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUsername;

  const PrivateChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final msg = TextEditingController();

  @override
  void dispose() {
    msg.dispose();
    super.dispose();
  }

  String getChatId(String a, String b) {
    final ids = [a, b];
    ids.sort();
    return "${ids[0]}_${ids[1]}";
  }

  Future<bool> isBlocked() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final myDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final otherDoc = await FirebaseFirestore.instance.collection("users").doc(widget.otherUserId).get();

    final myData = myDoc.data() ?? {};
    final otherData = otherDoc.data() ?? {};

    final myBlocked = List<String>.from(myData["blockedUsers"] ?? []);
    final otherBlocked = List<String>.from(otherData["blockedUsers"] ?? []);

    return myBlocked.contains(widget.otherUserId) || otherBlocked.contains(uid);
  }

  Future<void> sendMessage() async {
    if (msg.text.trim().isEmpty) return;

    final blocked = await isBlocked();

    if (blocked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chat ist blockiert")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final chatId = getChatId(user.uid, widget.otherUserId);
    final text = msg.text.trim();
    final chatRef = FirebaseFirestore.instance.collection("privateChats").doc(chatId);

    await chatRef.set({
      "participants": [user.uid, widget.otherUserId],
      "lastMessage": text,
      "lastMessageAt": Timestamp.now(),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    await chatRef.collection("messages").add({
      "text": text,
      "senderId": user.uid,
      "receiverId": widget.otherUserId,
      "createdAt": Timestamp.now(),
    });

    msg.clear();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final chatId = getChatId(uid, widget.otherUserId);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: Text("@${widget.otherUsername}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserProfileScreen(userId: widget.otherUserId)),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: isBlocked(),
        builder: (context, blockSnap) {
          final blocked = blockSnap.data == true;

          return Column(
            children: [
              if (blocked)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: InfoCard(
                    title: "Chat blockiert",
                    text: "Ihr könnt euch aktuell keine Nachrichten senden.",
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SafetyBanner(),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("privateChats")
                      .doc(chatId)
                      .collection("messages")
                      .orderBy("createdAt")
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator(color: C.cyan));
                    }

                    final messages = snap.data!.docs;

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text("Noch keine Nachrichten", style: TextStyle(color: Colors.white54)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final m = messages[i].data() as Map<String, dynamic>;
                        final isMe = m["senderId"] == uid;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                            decoration: BoxDecoration(
                              color: isMe ? C.cyan : C.card2,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              m["text"] ?? "",
                              style: TextStyle(
                                color: isMe ? Colors.black : Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (!blocked) MessageInput(controller: msg, onSend: sendMessage),
            ],
          );
        },
      ),
    );
  }
}

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Nachricht schreiben...",
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: C.cyan),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

Future<void> sendNotification({
  required String toUserId,
  required String fromUserId,
  required String type,
  required String text,
  String targetId = "",
}) async {
  if (toUserId == fromUserId) return;

  await FirebaseFirestore.instance.collection("notifications").add({
    "toUserId": toUserId,
    "fromUserId": fromUserId,
    "type": type,
    "text": text,
    "targetId": targetId,
    "read": false,
    "createdAt": Timestamp.now(),
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final username = TextEditingController();
  final city = TextEditingController();
  final bio = TextEditingController();

  bool uploadingImage = false;

  @override
  void dispose() {
    username.dispose();
    city.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> uploadProfileImage() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked == null) return;

    setState(() => uploadingImage = true);

    final bytes = await picked.readAsBytes();

    final url = await uploadImageBytes(
      bytes: bytes,
      path: "profile_images/$uid/profile.jpg",
    );

    if (url != null) {
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "photoUrl": url,
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));
    }

    if (!mounted) return;

    setState(() => uploadingImage = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profilbild aktualisiert ✅")),
    );
  }

  void openEdit(Map<String, dynamic> data) {
    username.text = data["username"] ?? "";
    city.text = data["city"] ?? "";
    bio.text = data["bio"] ?? "";

    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(context).viewInsets.bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Profil bearbeiten",
                style: TextStyle(
                  color: C.cyan,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: username,
                decoration: const InputDecoration(hintText: "Benutzername"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: city,
                decoration: const InputDecoration(hintText: "Stadt"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bio,
                maxLines: 3,
                decoration: const InputDecoration(hintText: "Über mich"),
              ),
              const SizedBox(height: 18),
              GradientButton(
                text: "Speichern",
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser!.uid;

                  await FirebaseFirestore.instance.collection("users").doc(uid).set({
                    "username": username.text.trim(),
                    "city": city.text.trim(),
                    "bio": bio.text.trim(),
                    "updatedAt": Timestamp.now(),
                  }, SetOptions(merge: true));

                  if (!mounted) return;

                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> applyVerification() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "verificationPending": true,
      "verificationAppliedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Verifizierung beantragt ✅")),
    );

    setState(() {});
  }

  Future<void> applyCreator() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "creatorPending": true,
      "creatorAppliedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Creator Bewerbung gesendet 🚀")),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: const Text("Profil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final followers = List.from(data["followers"] ?? []);
          final following = List.from(data["following"] ?? []);
          final interests = List<String>.from(
            data["interests"] ?? ["Sport", "Chill", "Gaming"],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                ProfileBox(
                  data: data,
                  followers: followers.length,
                  following: following.length,
                  userId: uid,
                  showActions: false,
                ),
                const SizedBox(height: 14),
                GradientButton(
                  text: uploadingImage ? "Bild wird hochgeladen..." : "Profilbild ändern",
                  onPressed: uploadingImage ? () {} : uploadProfileImage,
                ),
                const SizedBox(height: 14),
                GradientButton(
                  text: "Profil bearbeiten",
                  onPressed: () => openEdit(data),
                ),
                const SizedBox(height: 22),
                InterestsWrap(interests: interests),
                const SizedBox(height: 22),
                SettingsCard(
                  icon: Icons.verified,
                  title: data["verified"] == true
                      ? "Verifiziert"
                      : data["verificationPending"] == true
                          ? "Verifizierung läuft"
                          : "Verifizierung beantragen",
                  onTap: data["verificationPending"] == true ? () {} : applyVerification,
                ),
                SettingsCard(
                  icon: Icons.workspace_premium,
                  title: data["creator"] == true
                      ? "Creator aktiv"
                      : data["creatorPending"] == true
                          ? "Creator Bewerbung läuft"
                          : "Creator Programm beantragen",
                  onTap: data["creatorPending"] == true ? () {} : applyCreator,
                ),
                if (data["creator"] == true)
                  SettingsCard(
                    icon: Icons.paid,
                    title: "Creator Dashboard",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreatorDashboardScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CreatorDashboardScreen extends StatelessWidget {
  const CreatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: const Text("Creator Dashboard"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: C.cyan),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              InfoCard( // ❗ const entfernt
                title: "Creator Programm",
                text: "Hier siehst du später Einnahmen, Klicks und Einladungen.",
              ),
              const SizedBox(height: 18),

              CreatorStatCard(
                title: "Level",
                value: (data["creatorLevel"] ?? "none").toString(),
              ),
              CreatorStatCard(
                title: "Geschätzte Einnahmen",
                value: "${data["creatorEarnings"] ?? 0} €",
              ),
              CreatorStatCard(
                title: "Views",
                value: "${data["creatorViews"] ?? 0}",
              ),
              CreatorStatCard(
                title: "Klicks",
                value: "${data["creatorClicks"] ?? 0}",
              ),
              CreatorStatCard(
                title: "Referral Code",
                value: (data["creatorReferralCode"] ?? "Noch keiner").toString(),
              ),
            ],
          );
        },
      ),
    );
  }
}
class CreatorStatCard extends StatelessWidget {
  final String title;
  final String value;

  const CreatorStatCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.cyan.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(value, style: const TextStyle(color: C.cyan, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

Future<Position?> getUserPosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  return Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

double distanceInKm(LatLng a, LatLng b) {
  final distance = const Distance();
  return distance.as(LengthUnit.Kilometer, a, b);
}
/* SETTINGS + HELPERS */

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> resetPassword(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passwort-Link wurde gesendet")),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  Future<void> deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (user == null || uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        title: const Text("Account löschen"),
        content: const Text(
          "Dein Account wird dauerhaft gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Löschen", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "isDeleted": true,
        "email": "",
        "username": "deleted_user",
        "photoUrl": "",
        "bio": "",
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));

      await user.delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account gelöscht")),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bitte neu einloggen und Account löschen nochmal versuchen."),
        ),
      );
    }
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: C.cyan,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget dangerButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.14),
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.redAccent.withOpacity(0.35)),
          ),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? "Nicht verfügbar";

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        title: const Text("Einstellungen"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  C.purple.withOpacity(0.55),
                  C.card,
                  C.cyan.withOpacity(0.20),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: C.cyan.withOpacity(0.30)),
              boxShadow: [
                BoxShadow(color: C.purple.withOpacity(0.25), blurRadius: 28),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [C.purple, C.cyan]),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Outly Sicherheit",
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isAdminUser()) ...[
            sectionTitle("Admin"),
            SettingsCard(
              icon: Icons.admin_panel_settings,
              title: "Admin Panel",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                );
              },
            ),
          ],

          sectionTitle("Rechtliches"),
          SettingsCard(
            icon: Icons.lock_outline,
            title: "Datenschutzerklärung",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalTextPage(
                    title: "Datenschutzerklärung",
                    text: privacyText,
                  ),
                ),
              );
            },
          ),
          SettingsCard(
            icon: Icons.description_outlined,
            title: "Nutzungsbedingungen",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalTextPage(
                    title: "Nutzungsbedingungen",
                    text: termsText,
                  ),
                ),
              );
            },
          ),
          SettingsCard(
            icon: Icons.badge_outlined,
            title: "Impressum",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalTextPage(
                    title: "Impressum",
                    text: imprintText,
                  ),
                ),
              );
            },
          ),

          sectionTitle("Schutz & Hilfe"),
          SettingsCard(
            icon: Icons.security,
            title: "Sicherheit",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalTextPage(
                    title: "Sicherheit",
                    text: securityText,
                  ),
                ),
              );
            },
          ),
          SettingsCard(
            icon: Icons.help_outline,
            title: "Hilfe & Support",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              );
            },
          ),
          SettingsCard(
            icon: Icons.notifications_none,
            title: "Benachrichtigungen",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  NotificationsScreen()),
              );
            },
          ),

          sectionTitle("Account"),
          SettingsCard(
            icon: Icons.info_outline,
            title: "Über Outly",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalTextPage(
                    title: "Über Outly",
                    text: aboutText,
                  ),
                ),
              );
            },
          ),
          SettingsCard(
            icon: Icons.key,
            title: "Passwort zurücksetzen",
            onTap: () => resetPassword(context),
          ),

          const SizedBox(height: 12),
          dangerButton(text: "Account löschen", onTap: () => deleteAccount(context)),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: () => logout(context),
            child: const Text("Abmelden", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> updateUser(
    String userId,
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    if (!isAdminUser()) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .set(data, SetOptions(merge: true));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User aktualisiert ✅")),
    );
  }

  Future<void> deleteExpiredEvents(BuildContext context) async {
    if (!isAdminUser()) return;

    final snap = await FirebaseFirestore.instance.collection("activities").get();
    int count = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final deleteAt = data["deleteAt"];

      if (deleteAt is Timestamp && deleteAt.toDate().isBefore(DateTime.now())) {
        await doc.reference.delete();
        count++;
      }
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$count alte Events gelöscht ✅")),
    );
  }

  Future<int> countCollection(String name) async {
    final snap = await FirebaseFirestore.instance.collection(name).get();
    return snap.docs.length;
  }

  Future<int> countOpen(String name) async {
    final snap = await FirebaseFirestore.instance
        .collection(name)
        .where("status", isEqualTo: "open")
        .get();

    return snap.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdminUser()) {
      return const SimplePage(
        title: "Kein Zugriff",
        text: "Du hast keinen Zugriff auf diesen Bereich.",
      );
    }

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        title: const Text(
          "Admin Center",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  C.purple.withOpacity(0.55),
                  C.card,
                  C.cyan.withOpacity(0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: C.cyan.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: C.purple.withOpacity(0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: C.cyan, size: 46),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Outly Kontrolle",
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "User, Safety, Reports, Support und Creator verwalten.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          FutureBuilder<List<int>>(
            future: Future.wait([
              countCollection("users"),
              countCollection("activities"),
              countOpen("reports"),
              countOpen("support"),
            ]),
            builder: (context, snap) {
              final data = snap.data ?? [0, 0, 0, 0];

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.65,
                children: [
                  AdminStatCard(
                    title: "User",
                    value: "${data[0]}",
                    icon: Icons.groups_2_outlined,
                    color: C.cyan,
                  ),
                  AdminStatCard(
                    title: "Events",
                    value: "${data[1]}",
                    icon: Icons.local_fire_department,
                    color: C.orange,
                  ),
                  AdminStatCard(
                    title: "Reports offen",
                    value: "${data[2]}",
                    icon: Icons.flag_outlined,
                    color: Colors.redAccent,
                  ),
                  AdminStatCard(
                    title: "Support offen",
                    value: "${data[3]}",
                    icon: Icons.support_agent,
                    color: C.green,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          GradientButton(
            text: "Abgelaufene Events löschen",
            onPressed: () => deleteExpiredEvents(context),
          ),

          const SizedBox(height: 26),

          const AdminSectionTitle(
            title: "Verifizierung & Creator",
            subtitle: "Offene Anfragen schnell prüfen.",
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("users").snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }

              final pending = snap.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data["verificationPending"] == true ||
                    data["creatorPending"] == true;
              }).toList();

              if (pending.isEmpty) {
                return const InfoCard(
                  title: "Keine Anfragen",
                  text: "Aktuell gibt es keine offenen Creator- oder Verifizierungsanfragen.",
                );
              }

              return Column(
                children: pending.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final username = data["username"] ?? "user";
                  final email = data["email"] ?? "";

                  return AdminActionCard(
                    color: C.cyan,
                    icon: Icons.verified_user,
                    title: "@$username",
                    subtitle: email,
                    body:
                        "Verifizierung: ${data["verificationPending"] == true ? "offen" : "nein"}\nCreator: ${data["creatorPending"] == true ? "offen" : "nein"}",
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          updateUser(doc.id, {
                            "verified": true,
                            "identityVerified": true,
                            "verificationPending": false,
                            "updatedAt": Timestamp.now(),
                          }, context);
                        },
                        child: const Text("Verifizieren"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          updateUser(doc.id, {
                            "creator": true,
                            "creatorPending": false,
                            "creatorLevel": "starter",
                            "creatorReferralCode": username.toString().toUpperCase(),
                            "updatedAt": Timestamp.now(),
                          }, context);
                        },
                        child: const Text("Creator geben"),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 26),

          const AdminSectionTitle(
            title: "User Verwaltung",
            subtitle: "Safety, Rollen und Sperren verwalten.",
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("users").snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }

              final users = snap.data!.docs.toList();

              users.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final db = b.data() as Map<String, dynamic>;

                final ra = da["reportedCount"] ?? 0;
                final rb = db["reportedCount"] ?? 0;

                return rb.compareTo(ra);
              });

              return Column(
                children: users.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final username = data["username"] ?? "user";
                  final email = data["email"] ?? "";
                  final verified = data["verified"] == true;
                  final creator = data["creator"] == true;
                  final banned = data["isBanned"] == true;
                  final reports = data["reportedCount"] ?? 0;
                  final trustScore = data["trustScore"] ?? 100;
                  final color = banned ? Colors.redAccent : safetyColor(trustScore);

                  return AdminActionCard(
                    color: color,
                    icon: banned ? Icons.block : Icons.person,
                    title: "@$username",
                    subtitle: email,
                    body:
                        "Safety: $trustScore • ${safetyLabel(trustScore)}\nReports: $reports\nVerified: ${verified ? "ja" : "nein"} • Creator: ${creator ? "ja" : "nein"}",
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          updateUser(doc.id, {
                            "verified": !verified,
                            "updatedAt": Timestamp.now(),
                          }, context);
                        },
                        child: Text(verified ? "Unverify" : "Verify"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          updateUser(doc.id, {
                            "creator": !creator,
                            "creatorLevel": !creator ? "starter" : "none",
                            "updatedAt": Timestamp.now(),
                          }, context);
                        },
                        child: Text(creator ? "Creator weg" : "Creator"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: banned ? C.green : Colors.redAccent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          updateUser(doc.id, {
                            "isBanned": !banned,
                            "updatedAt": Timestamp.now(),
                          }, context);
                        },
                        child: Text(banned ? "Entsperren" : "Sperren"),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 26),

          const AdminSectionTitle(
            title: "Support",
            subtitle: "Nachrichten von Usern bearbeiten.",
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("support").snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }

              final tickets = snap.data!.docs.toList();

              tickets.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final db = b.data() as Map<String, dynamic>;

                final ta = da["createdAt"];
                final tb = db["createdAt"];

                if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                return 0;
              });

              if (tickets.isEmpty) {
                return const InfoCard(
                  title: "Kein Support",
                  text: "Aktuell gibt es keine Support-Anfragen.",
                );
              }

              return Column(
                children: tickets.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final email = (data["email"] ?? "Keine E-Mail").toString();
                  final uid = (data["uid"] ?? "").toString();
                  final message = (data["message"] ?? "").toString();
                  final status = (data["status"] ?? "open").toString();
                  final closed = status == "closed";

                  return AdminActionCard(
                    color: closed ? C.green : C.orange,
                    icon: closed ? Icons.check_circle : Icons.support_agent,
                    title: closed ? "Support erledigt" : "Support offen",
                    subtitle: email,
                    body:
                        "${uid.isNotEmpty ? "UID: $uid\n\n" : ""}$message",
                    actions: [
                      ElevatedButton.icon(
                        onPressed: closed
                            ? null
                            : () {
                                doc.reference.set({
                                  "status": "closed",
                                  "closedAt": Timestamp.now(),
                                }, SetOptions(merge: true));
                              },
                        icon: const Icon(Icons.check),
                        label: const Text("Erledigt"),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.18),
                          foregroundColor: Colors.redAccent,
                        ),
                        onPressed: () => doc.reference.delete(),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Löschen"),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 26),

          const AdminSectionTitle(
            title: "Reports",
            subtitle: "Meldungen prüfen und schließen.",
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("reports").snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }

              final reports = snap.data!.docs.toList();

              reports.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final db = b.data() as Map<String, dynamic>;

                final ta = da["createdAt"];
                final tb = db["createdAt"];

                if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                return 0;
              });

              if (reports.isEmpty) {
                return const InfoCard(
                  title: "Keine Reports",
                  text: "Aktuell gibt es keine Meldungen.",
                );
              }

              return Column(
                children: reports.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final type = data["type"] ?? "";
                  final reason = data["reason"] ?? "";
                  final status = data["status"] ?? "open";
                  final closed = status == "closed";

                  return AdminActionCard(
                    color: closed ? C.green : Colors.redAccent,
                    icon: Icons.flag_outlined,
                    title: "Report: $type",
                    subtitle: "Status: $status",
                    body: "Grund: $reason",
                    actions: [
                      ElevatedButton(
                        onPressed: closed
                            ? null
                            : () {
                                doc.reference.set({
                                  "status": "closed",
                                  "closedAt": Timestamp.now(),
                                }, SetOptions(merge: true));
                              },
                        child: const Text("Schließen"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.18),
                          foregroundColor: Colors.redAccent,
                        ),
                        onPressed: () => doc.reference.delete(),
                        child: const Text("Löschen"),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const AdminSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 34,
            decoration: BoxDecoration(
              color: C.cyan,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: C.cyan,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminActionCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final List<Widget> actions;

  const AdminActionCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.18),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
        ],
      ),
    );
  }
}


class SimplePage extends StatelessWidget {
  final String title;
  final String text;

  const SimplePage({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: InfoCard(title: title, text: text),
      ),
    );
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final message = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<void> sendSupport() async {
    if (sending) return;

    final text = message.text.trim();
    if (text.isEmpty) return;

    setState(() => sending = true);

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection("support").add({
      "uid": user?.uid,
      "email": user?.email,
      "message": text,
      "createdAt": Timestamp.now(),
      "status": "open",
      "type": "support",
    });

    message.clear();

    if (!mounted) return;

    setState(() => sending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Support-Anfrage gesendet ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: const Text("Hilfe & Support"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InfoCard(
              title: "Support",
              text:
                  "Beschreibe dein Problem. Deine Anfrage wird gespeichert und kann vom Outly-Team geprüft werden.",
            ),
            const SizedBox(height: 18),
            TextField(
              controller: message,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: "Was ist passiert?",
              ),
            ),
            const SizedBox(height: 18),
            GradientButton(
              text: sending ? "Wird gesendet..." : "Anfrage senden",
              onPressed: sendSupport,
            ),
          ],
        ),
      ),
    );
  }
}

class LegalTextPage extends StatelessWidget {
  final String title;
  final String text;

  const LegalTextPage({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        title: Text(title),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: C.cyan.withOpacity(0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: C.cyan,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.6,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SafetyBanner extends StatelessWidget {
  const SafetyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.orange.withOpacity(0.35)),
      ),
      child: const Text(
        "Safety Hinweis: Teile keine privaten Daten und triff dich nur an sicheren öffentlichen Orten.",
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const ProfileStat(this.value, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: C.cyan, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.white54)),
      ],
    );
  }
}

class SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SettingsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        leading: Icon(icon, color: C.cyan),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}