import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../core/app_colors.dart';
import '../../services/storage_service.dart';

import '../../widgets/auth/gradient_button.dart';
import '../../widgets/common/outly_avatar.dart';
import '../../widgets/common/verified_name.dart';

import 'settings_screen.dart';

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

  final allVibes = const [
    "Sport",
    "Chill",
    "Party",
    "Gaming",
    "Gym",
    "Food",
    "Travel",
    "Music",
    "Study",
    "Business",
    "Outdoor",
    "Creative",
  ];

  @override
  void dispose() {
    username.dispose();
    city.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> uploadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: "Profilbild anpassen",
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: C.cyan,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: "Profilbild anpassen",
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: const CropperSize(
            width: 420,
            height: 420,
          ),
        ),
      ],
    );

    if (cropped == null) return;

    if (!mounted) return;
    setState(() => uploadingImage = true);

    try {
      final bytes = await cropped.readAsBytes();

      final url = await uploadImageBytes(
        bytes: bytes,
        path: "profile_images/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      if (url != null && url.trim().isNotEmpty) {
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          "photoUrl": url.trim(),
          "updatedAt": Timestamp.now(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            url != null
                ? "Profilbild aktualisiert ✅"
                : "Profilbild konnte nicht hochgeladen werden ❌",
          ),
        ),
      );
    } catch (e) {
      debugPrint("Profilbild Upload Fehler: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fehler beim Profilbild Upload ❌"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => uploadingImage = false);
      }
    }
  }

  void openEdit(Map<String, dynamic> data) {
    username.text = data["username"] ?? "";
    city.text = data["city"] ?? "";
    bio.text = data["bio"] ?? "";

    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 22,
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: C.cyan.withOpacity(0.22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Profil bearbeiten",
                    style: TextStyle(
                      color: C.cyan,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: username,
                    decoration: const InputDecoration(
                      hintText: "Benutzername",
                      prefixIcon: Icon(Icons.person_outline, color: C.cyan),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: city,
                    decoration: const InputDecoration(
                      hintText: "Stadt / Land",
                      prefixIcon: Icon(Icons.location_on_outlined, color: C.cyan),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bio,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Bio",
                      prefixIcon: Icon(Icons.notes_outlined, color: C.cyan),
                    ),
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
            ),
          ),
        );
      },
    );
  }

  void openVibeEditor(List<String> currentVibes) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final selected = currentVibes.toSet();

    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: C.cyan.withOpacity(0.22)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Vibes ändern",
                        style: TextStyle(
                          color: C.cyan,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Wähle, was zu dir passt.",
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: allVibes.map((vibe) {
                          final active = selected.contains(vibe);

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (active) {
                                  selected.remove(vibe);
                                } else {
                                  selected.add(vibe);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: active ? C.cyan : C.card2,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: active ? C.cyan : Colors.white12,
                                ),
                                boxShadow: active
                                    ? [
                                        BoxShadow(
                                          color: C.cyan.withOpacity(0.35),
                                          blurRadius: 18,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                "#$vibe",
                                style: TextStyle(
                                  color: active ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      GradientButton(
                        text: "Vibes speichern",
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection("users").doc(uid).set({
                            "interests": selected.toList(),
                            "updatedAt": Timestamp.now(),
                          }, SetOptions(merge: true));

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          setState(() {});
                        },
                      ),
                    ],
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
    final isMe = widget.userId == myUid;

    return Scaffold(
      backgroundColor: C.bg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection("users").doc(widget.userId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final vibes = List<String>.from(data["interests"] ?? ["Sport", "Chill", "Gaming"]);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: C.bg,
                expandedHeight: 350,
                pinned: true,
                elevation: 0,
                title: Text(isMe ? "Mein Profil" : "@${data["username"] ?? "user"}"),
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
                flexibleSpace: FlexibleSpaceBar(
                  background: ProfileHero(
                    data: data,
                    isMe: isMe,
                    uploadingImage: uploadingImage,
                    onImageTap: uploadProfileImage,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 130),
                  child: Column(
                    children: [
                      ProfileActionButtons(
                        isMe: isMe,
                        data: data,
                        userId: widget.userId,
                        onEdit: () => openEdit(data),
                      ),
                      const SizedBox(height: 22),
                      ProfileStats(userId: widget.userId, data: data),
                      const SizedBox(height: 22),
                      ProfileBadges(data: data),
                      const SizedBox(height: 22),
                      ProfileVibes(
                        vibes: vibes,
                        isMe: isMe,
                        onEdit: () => openVibeEditor(vibes),
                      ),
                      const SizedBox(height: 22),
                      ProfileEventGrid(userId: widget.userId),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProfileHero extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final bool uploadingImage;
  final VoidCallback onImageTap;

  const ProfileHero({
    super.key,
    required this.data,
    required this.isMe,
    required this.uploadingImage,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final username = data["username"] ?? "user";
    final bio = data["bio"] ?? "Neu bei Outly 🔥";
    final city = data["city"] ?? "Keine Stadt";
    final photoUrl = (data["photoUrl"] ?? "").toString().trim();
    final verified = data["verified"] == true;
    final creator = data["creator"] == true;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                C.purple.withOpacity(0.95),
                C.pink.withOpacity(0.45),
                C.cyan.withOpacity(0.30),
                C.bg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          right: -40,
          top: 60,
          child: Icon(
            Icons.auto_awesome,
            size: 190,
            color: Colors.white.withOpacity(0.07),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.05),
                  C.bg.withOpacity(0.15),
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
          bottom: 24,
          child: Column(
            children: [
              GestureDetector(
                onTap: isMe ? onImageTap : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [C.pink, C.cyan, C.purple],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: C.cyan.withOpacity(0.50),
                            blurRadius: 42,
                          ),
                        ],
                      ),
                      child: OutlyAvatar(photoUrl: photoUrl, radius: 60),
                    ),
                    if (uploadingImage)
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: C.cyan),
                        ),
                      ),
                    if (isMe)
                      Positioned(
                        right: 0,
                        bottom: 8,
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: C.cyan,
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  verifiedName(username, verified, size: 30),
                  if (creator) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.workspace_premium, color: C.orange, size: 25),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                city,
                style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w600),
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileActionButtons extends StatelessWidget {
  final bool isMe;
  final Map<String, dynamic> data;
  final String userId;
  final VoidCallback onEdit;

  const ProfileActionButtons({
    super.key,
    required this.isMe,
    required this.data,
    required this.userId,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (isMe) {
      return Row(
        children: [
          Expanded(
            child: GradientButton(
              text: "Profil bearbeiten",
              onPressed: onEdit,
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: C.card,
            child: IconButton(
              icon: const Icon(Icons.share, color: C.cyan),
              onPressed: () {},
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: GradientButton(
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
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: C.card,
              foregroundColor: C.cyan,
              padding: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text("Follow"),
          ),
        ),
      ],
    );
  }
}

class ProfileStats extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;

  const ProfileStats({
    super.key,
    required this.userId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final followers = List.from(data["followers"] ?? []);
    final following = List.from(data["following"] ?? []);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("activities").where("creatorId", isEqualTo: userId).snapshots(),
      builder: (context, snap) {
        final eventCount = snap.data?.docs.length ?? 0;

        return Row(
          children: [
            Expanded(
              child: ProfileStatBox(
                value: "$eventCount",
                label: "Events",
                icon: Icons.local_fire_department,
                color: C.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ProfileStatBox(
                value: "${followers.length}",
                label: "Follower",
                icon: Icons.groups_2,
                color: C.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ProfileStatBox(
                value: "${following.length}",
                label: "Following",
                icon: Icons.person_add_alt_1,
                color: C.purple2,
              ),
            ),
          ],
        );
      },
    );
  }
}

class ProfileStatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const ProfileStatBox({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 18),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 23, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class ProfileBadges extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProfileBadges({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final verified = data["verified"] == true;
    final creator = data["creator"] == true;
    final trust = data["trustScore"] ?? 100;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        ProfileChip(icon: Icons.shield_outlined, text: "Safety $trust", color: C.cyan),
        if (verified) const ProfileChip(icon: Icons.verified, text: "Verifiziert", color: Colors.blueAccent),
        if (creator) const ProfileChip(icon: Icons.workspace_premium, text: "Creator", color: C.orange),
        const ProfileChip(icon: Icons.public, text: "Real Life", color: C.green),
      ],
    );
  }
}

class ProfileChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const ProfileChip({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class ProfileVibes extends StatelessWidget {
  final List<String> vibes;
  final bool isMe;
  final VoidCallback onEdit;

  const ProfileVibes({
    super.key,
    required this.vibes,
    required this.isMe,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: C.cyan.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Vibes",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              if (isMe)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.tune, color: C.cyan, size: 18),
                  label: const Text("Ändern", style: TextStyle(color: C.cyan)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vibes.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: C.cyan.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: C.cyan.withOpacity(0.28)),
                ),
                child: Text(
                  "#$item",
                  style: const TextStyle(color: C.cyan, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class ProfileEventGrid extends StatelessWidget {
  final String userId;

  const ProfileEventGrid({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("activities").where("creatorId", isEqualTo: userId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: C.cyan));
        }

        final docs = snap.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Posts & Events",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: C.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  "Noch keine Events erstellt.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final title = data["title"] ?? "Event";
                  final category = data["category"] ?? "Chill";
                  final imageUrl = (data["imageUrl"] ?? "").toString().trim();

                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: C.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: C.cyan.withOpacity(0.16)),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl.isNotEmpty)
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;

                              return Container(
                                color: C.card2,
                                child: const Center(
                                  child: CircularProgressIndicator(color: C.cyan),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint("Event Bild Fehler: $error");
                              debugPrint("Event Bild URL: $imageUrl");

                              return const OutlyEventFallback();
                            },
                          )
                        else
                          const OutlyEventFallback(),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.82),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: const TextStyle(
                                  color: C.cyan,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class OutlyEventFallback extends StatelessWidget {
  const OutlyEventFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            C.purple.withOpacity(0.85),
            C.card,
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_fire_department,
          color: Colors.white54,
          size: 54,
        ),
      ),
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
    final ids = [a, b]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  Future<void> sendMessage() async {
    final text = msg.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final chatId = getChatId(user.uid, widget.otherUserId);
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
      resizeToAvoidBottomInset: true,
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection("users").doc(widget.otherUserId).snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data() as Map<String, dynamic>? ?? {};
            final username = data["username"] ?? widget.otherUsername;
            final photoUrl = (data["photoUrl"] ?? "").toString().trim();
            final city = data["city"] ?? "";

            return Row(
              children: [
                OutlyAvatar(photoUrl: photoUrl, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("@$username", style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (city.toString().isNotEmpty)
                        Text(
                          city,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            decoration: BoxDecoration(
              color: C.orange.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: C.orange.withOpacity(0.28)),
            ),
            child: const Text(
              "Safety Hinweis: Teile keine privaten Daten und triff dich nur an sicheren öffentlichen Orten.",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
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
                    child: Text(
                      "Noch keine Nachrichten",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
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
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? C.cyan : C.card,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 5),
                            bottomRight: Radius.circular(isMe ? 5 : 18),
                          ),
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
          SafeArea(
            child: Container(
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
          ),
        ],
      ),
    );
  }
}