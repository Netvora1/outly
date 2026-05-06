import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/legal_texts.dart';
import '../../services/storage_service.dart';
import 'settings_screen.dart';

import '../../widgets/auth/gradient_button.dart';
import '../../widgets/common/outly_avatar.dart';
import '../../widgets/common/verified_name.dart';

import '../legal/legal_text_page.dart';


class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

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
                decoration: const InputDecoration(hintText: "Stadt / Land"),
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

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final isMe = widget.userId == myUid;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: Text(isMe ? "Mein Profil" : "Profil"),
        actions: [
          if (isMe)
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
        future: FirebaseFirestore.instance.collection("users").doc(widget.userId).get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: C.cyan),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                ProfileHeader(
                  data: data,
                  userId: widget.userId,
                ),

                const SizedBox(height: 14),

                if (isMe) ...[
                  GradientButton(
                    text: uploadingImage ? "Bild wird hochgeladen..." : "Profilbild ändern",
                    onPressed: uploadingImage ? () {} : uploadProfileImage,
                  ),
                  const SizedBox(height: 12),
                  GradientButton(
                    text: "Profil bearbeiten",
                    onPressed: () => openEdit(data),
                  ),
                ] else ...[
                  GradientButton(
                    text: "Nachricht schreiben",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrivateChatScreen(
                            otherUserId: widget.userId,
                            otherUsername: data["username"] ?? "user",
                          ),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 22),

                ProfileInterests(data: data),

                const SizedBox(height: 22),

                ProfileEvents(userId: widget.userId),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> data;
  final String userId;

  const ProfileHeader({
    super.key,
    required this.data,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final username = data["username"] ?? "user";
    final bio = data["bio"] ?? "Neu bei Outly 🔥";
    final city = data["city"] ?? "Keine Stadt";
    final photoUrl = data["photoUrl"] ?? "";
    final verified = data["verified"] == true;
    final creator = data["creator"] == true;
    final trustScore = data["trustScore"] ?? 100;

    final followers = List.from(data["followers"] ?? []);
    final following = List.from(data["following"] ?? []);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: C.cyan.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: C.cyan.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 135,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  C.purple.withOpacity(0.9),
                  C.cyan.withOpacity(0.35),
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -48),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [C.purple, C.cyan]),
                  ),
                  child: OutlyAvatar(photoUrl: photoUrl, radius: 54),
                ),

                const SizedBox(height: 10),

                verifiedName(username, verified, size: 26),

                const SizedBox(height: 6),

                Text(
                  city,
                  style: const TextStyle(color: Colors.white54),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ProfileBadge(
                      icon: Icons.shield_outlined,
                      text: "Safety $trustScore",
                      color: C.cyan,
                    ),
                    if (verified)
                      const ProfileBadge(
                        icon: Icons.verified,
                        text: "Verifiziert",
                        color: Colors.blueAccent,
                      ),
                    if (creator)
                      const ProfileBadge(
                        icon: Icons.workspace_premium,
                        text: "Creator",
                        color: C.orange,
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: ProfileStatCard(
                          value: "${followers.length}",
                          label: "Follower",
                          icon: Icons.groups_2_outlined,
                          color: C.cyan,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ProfileStatCard(
                          value: "${following.length}",
                          label: "Following",
                          icon: Icons.person_add_alt_1,
                          color: C.purple2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const ProfileStatCard({
    super.key,
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
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class ProfileBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const ProfileBadge({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileInterests extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProfileInterests({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final interests = List<String>.from(
      data["interests"] ?? ["Sport", "Chill", "Gaming"],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Interessen",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: interests.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: C.cyan.withOpacity(0.35)),
              ),
              child: Text(
                item,
                style: const TextStyle(
                  color: C.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ProfileEvents extends StatelessWidget {
  final String userId;

  const ProfileEvents({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("activities")
          .where("creatorId", isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: C.cyan),
          );
        }

        final docs = snap.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Eigene Events",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (docs.isEmpty)
              const Text(
                "Noch keine Events erstellt.",
                style: TextStyle(color: Colors.white54),
              )
            else
              ...docs.take(3).map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: C.cyan.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: C.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data["title"] ?? "Event",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
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

  Future<void> sendMessage() async {
    if (msg.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final chatId = getChatId(user.uid, widget.otherUserId);
    final text = msg.text.trim();

    final chatRef =
        FirebaseFirestore.instance.collection("privateChats").doc(chatId);

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
      ),
      body: Column(
        children: [
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
                  return const Center(
                    child: CircularProgressIndicator(color: C.cyan),
                  );
                }

                final messages = snap.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "Noch keine Nachrichten",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i].data() as Map<String, dynamic>;
                    final isMe = m["senderId"] == uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? C.cyan : C.card,
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

          /// INPUT
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msg,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Nachricht schreiben...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: C.cyan),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}