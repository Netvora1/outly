import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../services/storage_service.dart';
import '../common/outly_avatar.dart';


class InstagramStoryBar extends StatefulWidget {
  const InstagramStoryBar({super.key});

  @override
  State<InstagramStoryBar> createState() => _InstagramStoryBarState();
}

class _InstagramStoryBarState extends State<InstagramStoryBar> {
  final storyText = TextEditingController();
  XFile? storyImage;
  bool posting = false;

  @override
  void dispose() {
    storyText.dispose();
    super.dispose();
  }

  Future<void> pickStoryImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
    );

    if (picked != null) {
      setState(() => storyImage = picked);
    }
  }

  Future<void> createStory() async {
    if (posting) return;

    final user = FirebaseAuth.instance.currentUser!;
    final text = storyText.text.trim();

    if (text.isEmpty && storyImage == null) return;

    setState(() => posting = true);

    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    final userData = userDoc.data() ?? {};

    String imageUrl = "";

    if (storyImage != null) {
      final bytes = await storyImage!.readAsBytes();

      imageUrl = await uploadImageBytes(
            bytes: bytes,
            path: "story_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg",
          ) ??
          "";
    }

    await FirebaseFirestore.instance.collection("stories").add({
      "userId": user.uid,
      "email": user.email ?? "",
      "username": userData["username"] ?? "user",
      "photoUrl": userData["photoUrl"] ?? "",
      "text": text,
      "imageUrl": imageUrl,
      "createdAt": Timestamp.now(),
      "expiresAt": Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
    });

    storyText.clear();

    if (!mounted) return;

    setState(() {
      storyImage = null;
      posting = false;
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Story gepostet 🔥")),
    );
  }

  void openCreateStory() {
    storyText.clear();
    storyImage = null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              decoration: const BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Story erstellen",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  GestureDetector(
                    onTap: () async {
                      await pickStoryImage();
                      sheetSetState(() {});
                    },
                    child: Container(
                      height: 190,
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: C.card,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: C.cyan.withOpacity(0.28)),
                      ),
                      child: storyImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  color: C.cyan,
                                  size: 52,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Bild hinzufügen",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Optional, macht deine Story stärker.",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            )
                          : FutureBuilder<Uint8List>(
                              future: storyImage!.readAsBytes(),
                              builder: (context, snap) {
                                if (!snap.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: C.cyan,
                                    ),
                                  );
                                }

                                return Image.memory(
                                  snap.data!,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: storyText,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Was machst du gerade?",
                      prefixIcon: Icon(Icons.auto_awesome, color: C.cyan),
                    ),
                  ),

                  const SizedBox(height: 16),

                  GradientButton(
                    text: posting ? "Poste..." : "Story posten 🔥",
                    onPressed: createStory,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return SizedBox(
      height: 116,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("stories").snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: C.cyan),
            );
          }

          final docs = snap.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final expiresAt = data["expiresAt"];

            if (expiresAt is Timestamp) {
              return expiresAt.toDate().isAfter(DateTime.now());
            }

            return true;
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

          return ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            children: [
              StoryBubble(
                label: "Deine",
                icon: Icons.add,
                onTap: openCreateStory,
                isAdd: true,
              ),

              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return StoryBubble(
                  label: data["username"] ?? "Story",
                  icon: Icons.person,
                  photoUrl: (data["photoUrl"] ?? "").toString(),
                  imageUrl: (data["imageUrl"] ?? "").toString(),
                  isMine: data["userId"] == myUid,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(
                          storyId: doc.id,
                          data: data,
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class StoryViewerScreen extends StatelessWidget {
  final String storyId;
  final Map<String, dynamic> data;

  const StoryViewerScreen({
    super.key,
    required this.storyId,
    required this.data,
  });

  Future<void> deleteStory(BuildContext context) async {
    await FirebaseFirestore.instance.collection("stories").doc(storyId).delete();

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    final username = (data["username"] ?? "Story").toString();
    final text = (data["text"] ?? "").toString();
    final photoUrl = (data["photoUrl"] ?? "").toString();
    final imageUrl = (data["imageUrl"] ?? "").toString();
    final isMine = data["userId"] == myUid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [C.purple, Colors.black],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [C.purple, Colors.black, C.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                    Colors.black.withOpacity(0.75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      OutlyAvatar(photoUrl: photoUrl, radius: 23),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "@$username",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isMine)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => deleteStory(context),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const Spacer(),

                  if (text.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.42),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          height: 1.25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoryBubble extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAdd;
  final String photoUrl;
  final String imageUrl;
  final bool isMine;

  const StoryBubble({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isAdd = false,
    this.photoUrl = "",
    this.imageUrl = "",
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPreview = imageUrl.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              height: 66,
              width: 66,
              padding: isAdd ? EdgeInsets.zero : const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAdd ? C.card : null,
                gradient: isAdd
                    ? null
                    : LinearGradient(
                        colors: isMine
                            ? [C.orange, C.cyan]
                            : [C.purple, C.cyan],
                      ),
                border: isAdd ? Border.all(color: C.cyan, width: 2) : null,
              ),
              child: CircleAvatar(
                backgroundColor: isAdd ? C.card : C.bg,
                backgroundImage: hasPreview
                    ? NetworkImage(imageUrl)
                    : photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                child: !hasPreview && photoUrl.isEmpty
                    ? Icon(
                        icon,
                        color: isAdd ? C.cyan : Colors.white,
                        size: isAdd ? 32 : 24,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isMine ? C.orange : Colors.white70,
                fontWeight: isMine ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}