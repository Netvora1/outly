import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../services/storage_service.dart';
import '../../widgets/auth/gradient_button.dart';
import '../common/outly_avatar.dart';
import '../../screens/profile/user_profile_screen.dart';

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

  Future<void> pickStoryImage(StateSetter sheetSetState) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: C.bg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: C.cyan.withOpacity(0.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded, color: C.cyan),
                  title: const Text("Kamera öffnen"),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: C.purple),
                  title: const Text("Aus Galerie wählen"),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1400,
    );

    if (picked == null) return;

    sheetSetState(() => storyImage = picked);
    if (mounted) setState(() {});
  }

  Future<void> createStory() async {
    if (posting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final text = storyText.text.trim();
    if (text.isEmpty && storyImage == null) return;

    setState(() => posting = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      String imageUrl = "";

      if (storyImage != null) {
        final bytes = await storyImage!.readAsBytes();

        imageUrl = await uploadImageBytes(
              bytes: bytes,
              path: "stories/${user.uid}/story_${DateTime.now().millisecondsSinceEpoch}.jpg",
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
        "views": [],
        "likes": [],
        "isHidden": false,
        "createdAt": Timestamp.now(),
        "expiresAt": Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
      });

      storyText.clear();

      if (!mounted) return;

      setState(() {
        storyImage = null;
        posting = false;
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Story ist live 🔥")),
      );
    } catch (e) {
      debugPrint("Story Fehler: $e");

      if (!mounted) return;

      setState(() => posting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Story konnte nicht gepostet werden.")),
      );
    }
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
            return Padding(
              padding: EdgeInsets.only(
                left: 14,
                right: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 14,
              ),
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: C.bg,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: C.cyan.withOpacity(0.28)),
                  ),
                  child: SingleChildScrollView(
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
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => pickStoryImage(sheetSetState),
                          child: Container(
                            height: 210,
                            width: double.infinity,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: C.card,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: C.cyan.withOpacity(0.28)),
                            ),
                            child: storyImage == null
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_rounded, color: C.cyan, size: 54),
                                      SizedBox(height: 10),
                                      Text(
                                        "Bild hinzufügen",
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Optional, aber macht mehr Vibe.",
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                    ],
                                  )
                                : FutureBuilder<Uint8List>(
                                    future: storyImage!.readAsBytes(),
                                    builder: (context, snap) {
                                      if (!snap.hasData) {
                                        return const Center(
                                          child: CircularProgressIndicator(color: C.cyan),
                                        );
                                      }

                                      return Image.memory(snap.data!, fit: BoxFit.cover);
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: storyText,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Was geht gerade ab?",
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.auto_awesome, color: C.cyan),
                            filled: true,
                            fillColor: C.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GradientButton(
                          text: posting ? "Poste..." : "Story posten 🔥",
                          onPressed: createStory,
                        ),
                      ],
                    ),
                  ),
                ),
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
        stream: FirebaseFirestore.instance
            .collection("stories")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }

          final rawDocs = snap.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            if (data["isHidden"] == true) return false;

            final expiresAt = data["expiresAt"];
            if (expiresAt is Timestamp) {
              return expiresAt.toDate().isAfter(DateTime.now());
            }

            return true;
          }).toList();

          final Map<String, List<QueryDocumentSnapshot>> grouped = {};

          for (final doc in rawDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final uid = (data["userId"] ?? data["uid"] ?? "").toString();
            if (uid.isEmpty) continue;
            grouped.putIfAbsent(uid, () => []);
            grouped[uid]!.add(doc);
          }

          final myStories = grouped[myUid] ?? [];

          final otherEntries = grouped.entries.where((e) => e.key != myUid).toList();

          return ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            children: [
              StoryBubble(
                label: "Deine",
                icon: myStories.isEmpty ? Icons.add_rounded : Icons.auto_awesome_rounded,
                onTap: () {
                  if (myStories.isEmpty) {
                    openCreateStory();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(
                          stories: myStories,
                          initialIndex: 0,
                        ),
                      ),
                    );
                  }
                },
                isAdd: myStories.isEmpty,
                isMine: myStories.isNotEmpty,
                photoUrl: myStories.isNotEmpty
                    ? ((myStories.first.data() as Map<String, dynamic>)["photoUrl"] ?? "").toString()
                    : "",
                imageUrl: myStories.isNotEmpty
                    ? ((myStories.first.data() as Map<String, dynamic>)["imageUrl"] ?? "").toString()
                    : "",
              ),
              ...otherEntries.map((entry) {
                final firstData = entry.value.first.data() as Map<String, dynamic>;

                return StoryBubble(
                  label: (firstData["username"] ?? "Story").toString(),
                  icon: Icons.person_rounded,
                  photoUrl: (firstData["photoUrl"] ?? "").toString(),
                  imageUrl: (firstData["imageUrl"] ?? "").toString(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(
                          stories: entry.value,
                          initialIndex: 0,
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

class StoryViewerScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late int index;
  late AnimationController progress;
  late AnimationController heartAnim;

  bool showHeart = false;

  QueryDocumentSnapshot get currentDoc => widget.stories[index];

  Map<String, dynamic> get currentData =>
      currentDoc.data() as Map<String, dynamic>;

  @override
  void initState() {
    super.initState();

    index = widget.initialIndex;

    progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    heartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    progress.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        nextStory();
      }
    });

    markViewed();
    progress.forward(from: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      preloadNextImage();
    });
  }

  @override
  void dispose() {
    progress.dispose();
    heartAnim.dispose();
    super.dispose();
  }

  void preloadNextImage() {
    if (index >= widget.stories.length - 1) return;

    final nextData =
        widget.stories[index + 1].data() as Map<String, dynamic>;

    final nextImage = (nextData["imageUrl"] ?? "").toString();

    if (nextImage.isNotEmpty) {
      precacheImage(NetworkImage(nextImage), context);
    }
  }

  Future<void> markViewed() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    await FirebaseFirestore.instance.collection("stories").doc(currentDoc.id).set({
      "views": FieldValue.arrayUnion([myUid]),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  void nextStory() {
    if (index < widget.stories.length - 1) {
      setState(() => index++);
      markViewed();
      preloadNextImage();
      progress.forward(from: 0);
    } else {
      Navigator.pop(context);
    }
  }

  void previousStory() {
    if (index > 0) {
      setState(() => index--);
      markViewed();
      progress.forward(from: 0);
    } else {
      progress.forward(from: 0);
    }
  }

  Future<void> toggleLike({bool burst = false}) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final data = currentData;
    final likes = List<String>.from(data["likes"] ?? []);
    final liked = likes.contains(myUid);

    if (burst && !liked) {
      setState(() => showHeart = true);
      heartAnim.forward(from: 0).then((_) {
        if (mounted) setState(() => showHeart = false);
      });
    }

    await FirebaseFirestore.instance.collection("stories").doc(currentDoc.id).set({
      "likes": liked
          ? FieldValue.arrayRemove([myUid])
          : FieldValue.arrayUnion([myUid]),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteStory() async {
    await FirebaseFirestore.instance.collection("stories").doc(currentDoc.id).delete();

    if (!mounted) return;
    Navigator.pop(context);
  }

  void openProfile(String userId) {
    if (userId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: userId),
      ),
    );
  }

  void openViewersSheet(List views) {
    progress.stop();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: C.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
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
                Text(
                  "${views.length} Aufrufe",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                if (views.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "Noch keine Aufrufe.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: views.length,
                      itemBuilder: (context, i) {
                        final uid = views[i].toString();

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
                          builder: (context, snap) {
                            final userData =
                                snap.data?.data() as Map<String, dynamic>? ?? {};

                            final username =
                                (userData["username"] ?? "User").toString();
                            final photoUrl =
                                (userData["photoUrl"] ?? "").toString();

                            return ListTile(
                              onTap: () => openProfile(uid),
                              leading: OutlyAvatar(photoUrl: photoUrl, radius: 22),
                              title: Text(
                                "@$username",
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white54,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) progress.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("stories")
          .doc(currentDoc.id)
          .snapshots(),
      builder: (context, snap) {
        final liveData =
            snap.data?.data() as Map<String, dynamic>? ?? currentData;

        final username = (liveData["username"] ?? "Story").toString();
        final text = (liveData["text"] ?? "").toString();
        final photoUrl = (liveData["photoUrl"] ?? "").toString();
        final imageUrl = (liveData["imageUrl"] ?? "").toString();
        final userId = (liveData["userId"] ?? liveData["uid"] ?? "").toString();

        final isMine = userId == myUid;
        final views = List.from(liveData["views"] ?? []);
        final likes = List<String>.from(liveData["likes"] ?? []);
        final liked = likes.contains(myUid);

        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 300) {
                Navigator.pop(context);
              }
            },
            onDoubleTap: () => toggleLike(burst: true),
            onLongPressStart: (_) => progress.stop(),
            onLongPressEnd: (_) => progress.forward(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            key: ValueKey(imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _StoryFallback(),
                          )
                        : const _StoryFallback(),
                  ),
                ),

                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.72),
                          Colors.transparent,
                          Colors.black.withOpacity(0.92),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: previousStory,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: nextStory,
                      ),
                    ),
                  ],
                ),

                if (showHeart)
                  Center(
                    child: _HeartBurst(animation: heartAnim),
                  ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(widget.stories.length, (i) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    height: 3.8,
                                    color: Colors.white24,
                                    child: i < index
                                        ? Container(color: Colors.white)
                                        : i == index
                                            ? AnimatedBuilder(
                                                animation: progress,
                                                builder: (_, __) {
                                                  return FractionallySizedBox(
                                                    alignment: Alignment.centerLeft,
                                                    widthFactor: progress.value,
                                                    child: Container(color: Colors.white),
                                                  );
                                                },
                                              )
                                            : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => openProfile(userId),
                              child: OutlyAvatar(photoUrl: photoUrl, radius: 23),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => openProfile(userId),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "@$username",
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const Text(
                                      "OUTLY Story",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white54,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMine)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                ),
                                onPressed: deleteStory,
                              ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
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
                              color: Colors.black.withOpacity(0.48),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white12),
                              boxShadow: [
                                BoxShadow(
                                  color: C.cyan.withOpacity(0.14),
                                  blurRadius: 34,
                                ),
                              ],
                            ),
                            child: Text(
                              text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 25,
                                height: 1.25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),

                        const SizedBox(height: 22),

                        Row(
                          children: [
                            if (isMine)
                              GestureDetector(
                                onTap: () => openViewersSheet(views),
                                child: _StoryActionPill(
                                  icon: Icons.remove_red_eye_rounded,
                                  text: "${views.length}",
                                ),
                              ),

                            const Spacer(),

                            GestureDetector(
                              onTap: () => toggleLike(),
                              child: _StoryActionPill(
                                icon: liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                text: "${likes.length}",
                                active: liked,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        width: 78,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              height: 70,
              width: 70,
              padding: isAdd ? EdgeInsets.zero : const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAdd ? C.card : null,
                gradient: isAdd
                    ? null
                    : LinearGradient(
                        colors: isMine ? [C.orange, C.cyan] : [C.purple, C.cyan, C.pink],
                      ),
                border: isAdd ? Border.all(color: C.cyan, width: 2) : null,
                boxShadow: [
                  BoxShadow(
                    color: (isMine ? C.orange : C.cyan).withOpacity(0.24),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
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
                  if (isMine || isAdd)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 22,
                        width: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAdd ? C.cyan : C.orange,
                          border: Border.all(color: C.bg, width: 2),
                        ),
                        child: Icon(
                          isAdd ? Icons.add_rounded : Icons.auto_awesome_rounded,
                          color: Colors.black,
                          size: 15,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isMine ? C.orange : Colors.white70,
                fontWeight: isMine ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryActionPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool active;

  const _StoryActionPill({
    required this.icon,
    required this.text,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(
        color: active ? Colors.pinkAccent.withOpacity(0.24) : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? Colors.pinkAccent : Colors.white12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: active ? Colors.pinkAccent : Colors.white,
            size: 22,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _HeartBurst extends StatelessWidget {
  final Animation<double> animation;

  const _HeartBurst({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final scale = 0.6 + (animation.value * 1.15);
        final opacity = animation.value < 0.75 ? 1.0 : 1.0 - animation.value;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Icon(
              Icons.favorite_rounded,
              color: Colors.pinkAccent.withOpacity(0.92),
              size: 118,
              shadows: [
                Shadow(
                  color: Colors.pinkAccent.withOpacity(0.75),
                  blurRadius: 38,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StoryFallback extends StatelessWidget {
  const _StoryFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.purple, Colors.black, C.cyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}