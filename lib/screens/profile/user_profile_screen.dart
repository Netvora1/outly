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

    final picked = await ImagePicker().pickImage(
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
        ),
        IOSUiSettings(
          title: "Profilbild anpassen",
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: const CropperSize(width: 420, height: 420),
        ),
      ],
    );

    if (cropped == null) return;

    setState(() => uploadingImage = true);

    try {
      final bytes = await cropped.readAsBytes();

      final url = await uploadImageBytes(
        bytes: bytes,
        path:
            "profile_images/${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      if (url != null && url.trim().isNotEmpty) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "photoUrl": url.trim(),
          "updatedAt": Timestamp.now(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profilbild aktualisiert 🔥")),
      );
    } catch (e) {
      debugPrint("Profilbild Upload Fehler: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profilbild konnte nicht gespeichert werden.")),
      );
    } finally {
      if (mounted) setState(() => uploadingImage = false);
    }
  }

  void openEdit(Map<String, dynamic> data) {
    username.text = (data["username"] ?? "").toString();
    city.text = (data["city"] ?? "").toString();
    bio.text = (data["bio"] ?? "").toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 14,
          ),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: C.cyan.withOpacity(0.28)),
                boxShadow: [
                  BoxShadow(
                    color: C.cyan.withOpacity(0.18),
                    blurRadius: 34,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
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
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _OutlyField(
                      controller: username,
                      hint: "Benutzername",
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 12),
                    _OutlyField(
                      controller: city,
                      hint: "Stadt / Land",
                      icon: Icons.location_on_rounded,
                    ),
                    const SizedBox(height: 12),
                    _OutlyField(
                      controller: bio,
                      hint: "Bio",
                      icon: Icons.notes_rounded,
                      maxLines: 3,
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
                      },
                    ),
                  ],
                ),
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(14),
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: C.bg,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: C.purple.withOpacity(0.32)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Deine Vibes",
                          style: TextStyle(
                            color: C.cyan,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
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
                                  active ? selected.remove(vibe) : selected.add(vibe);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: active ? C.cyan : C.card,
                                  borderRadius: BorderRadius.circular(999),
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
                                    fontWeight: FontWeight.w900,
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
                          },
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
                expandedHeight: 380,
                pinned: true,
                elevation: 0,
                title: Text(isMe ? "Mein Profil" : "@${data["username"] ?? "user"}"),
                actions: [
                  if (isMe)
                    IconButton(
                      icon: const Icon(Icons.settings_rounded),
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
    final username = (data["username"] ?? "user").toString();
    final bio = (data["bio"] ?? "Neu bei Outly 🔥").toString();
    final city = (data["city"] ?? "Keine Stadt").toString();
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
                C.purple.withOpacity(0.98),
                C.pink.withOpacity(0.48),
                C.cyan.withOpacity(0.30),
                C.bg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          right: -55,
          top: 70,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 210,
            color: Colors.white.withOpacity(0.07),
          ),
        ),
        Positioned(
          left: -50,
          top: 90,
          child: Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: C.cyan.withOpacity(0.11),
              boxShadow: [
                BoxShadow(
                  color: C.cyan.withOpacity(0.22),
                  blurRadius: 90,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.05),
                  C.bg.withOpacity(0.16),
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
                      width: 134,
                      height: 134,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [C.pink, C.cyan, C.purple],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: C.cyan.withOpacity(0.48),
                            blurRadius: 42,
                          ),
                        ],
                      ),
                      child: OutlyAvatar(photoUrl: photoUrl, radius: 62),
                    ),
                    if (uploadingImage)
                      Container(
                        width: 134,
                        height: 134,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.50),
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
                          radius: 20,
                          backgroundColor: C.cyan,
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: verifiedName(username, verified, size: 30)),
                  if (creator) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.workspace_premium_rounded, color: C.orange, size: 25),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                city,
                style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700),
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

  Future<void> toggleFollow(BuildContext context, bool isFollowing) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    final myRef = FirebaseFirestore.instance.collection("users").doc(myUid);
    final otherRef = FirebaseFirestore.instance.collection("users").doc(userId);

    final batch = FirebaseFirestore.instance.batch();

    if (isFollowing) {
      batch.set(myRef, {
        "following": FieldValue.arrayRemove([userId]),
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));

      batch.set(otherRef, {
        "followers": FieldValue.arrayRemove([myUid]),
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));
    } else {
      batch.set(myRef, {
        "following": FieldValue.arrayUnion([userId]),
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));

      batch.set(otherRef, {
        "followers": FieldValue.arrayUnion([myUid]),
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));
    }

    await batch.commit();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isFollowing ? "Entfolgt" : "Du folgst jetzt 🔥")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

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
          _NeonIconButton(
            icon: Icons.settings_rounded,
            color: C.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      );
    }

    final followers = List<String>.from(data["followers"] ?? []);
    final followsMe = followers.contains(myUid);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("users").doc(myUid).snapshots(),
      builder: (context, mySnap) {
        final myData = mySnap.data?.data() as Map<String, dynamic>? ?? {};
        final following = List<String>.from(myData["following"] ?? []);
        final isFollowing = following.contains(userId);

        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => toggleFollow(context, isFollowing),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: isFollowing
                        ? null
                        : const LinearGradient(
                            colors: [C.cyan, C.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isFollowing ? C.card : null,
                    border: Border.all(
                      color: isFollowing ? C.cyan.withOpacity(0.35) : Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isFollowing ? C.cyan : C.purple).withOpacity(0.25),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isFollowing
                            ? Icons.person_remove_alt_1_rounded
                            : Icons.person_add_alt_1_rounded,
                        color: isFollowing ? C.cyan : Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFollowing ? "Entfolgen" : "Folgen",
                        style: TextStyle(
                          color: isFollowing ? C.cyan : Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
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
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: C.card,
                    border: Border.all(color: C.pink.withOpacity(0.30)),
                    boxShadow: [
                      BoxShadow(
                        color: C.pink.withOpacity(0.18),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_rounded, color: C.pink),
                      SizedBox(width: 8),
                      Text(
                        "Nachricht",
                        style: TextStyle(
                          color: C.pink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _NeonIconButton(
              icon: followsMe ? Icons.favorite_rounded : Icons.more_horiz_rounded,
              color: followsMe ? C.pink : C.orange,
              onTap: () {},
            ),
          ],
        );
      },
    );
  }
}

class _NeonIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NeonIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: C.card,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.32)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: 22,
            ),
          ],
        ),
        child: Icon(icon, color: color),
      ),
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
      stream: FirebaseFirestore.instance
          .collection("activities")
          .where("creatorId", isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        final eventCount = snap.data?.docs.length ?? 0;

        return Row(
          children: [
            Expanded(
              child: ProfileStatBox(
                value: "$eventCount",
                label: "Events",
                icon: Icons.local_fire_department_rounded,
                color: C.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ProfileStatBox(
                value: "${followers.length}",
                label: "Follower",
                icon: Icons.groups_2_rounded,
                color: C.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ProfileStatBox(
                value: "${following.length}",
                label: "Folgt",
                icon: Icons.person_add_alt_1_rounded,
                color: C.purple,
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
        borderRadius: BorderRadius.circular(24),
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
            style: TextStyle(color: color, fontSize: 23, fontWeight: FontWeight.w900),
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
        ProfileChip(icon: Icons.shield_rounded, text: "Safety $trust", color: C.cyan),
        if (verified) const ProfileChip(icon: Icons.verified_rounded, text: "Verifiziert", color: Colors.blueAccent),
        if (creator) const ProfileChip(icon: Icons.workspace_premium_rounded, text: "Creator", color: C.orange),
        const ProfileChip(icon: Icons.public_rounded, text: "Real Life", color: C.green),
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
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
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
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: C.cyan.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: C.cyan.withOpacity(0.08),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Vibes",
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
              ),
              if (isMe)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.tune_rounded, color: C.cyan, size: 18),
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
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: C.cyan.withOpacity(0.28)),
                ),
                child: Text(
                  "#$item",
                  style: const TextStyle(color: C.cyan, fontWeight: FontWeight.w900),
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
      stream: FirebaseFirestore.instance
          .collection("activities")
          .where("creatorId", isEqualTo: userId)
          .snapshots(),
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
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: C.card,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: C.cyan.withOpacity(0.14)),
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
                  final title = (data["title"] ?? "Event").toString();
                  final category = (data["category"] ?? "Chill").toString();
                  final imageUrl = (data["imageUrl"] ?? "").toString().trim();

                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: C.card,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: C.cyan.withOpacity(0.16)),
                      boxShadow: [
                        BoxShadow(
                          color: C.cyan.withOpacity(0.08),
                          blurRadius: 18,
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
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: C.card,
                                child: const Center(
                                  child: CircularProgressIndicator(color: C.cyan),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
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
                                Colors.black.withOpacity(0.86),
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
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w900),
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
          Icons.local_fire_department_rounded,
          color: Colors.white54,
          size: 54,
        ),
      ),
    );
  }
}

class _OutlyField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _OutlyField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: C.cyan.withOpacity(0.18)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: C.cyan),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
  final scroll = ScrollController();

  @override
  void dispose() {
    msg.dispose();
    scroll.dispose();
    super.dispose();
  }

  String getChatId(String a, String b) {
    final ids = [a, b]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  void jumpBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> sendMessage() async {
    final text = msg.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final chatId = getChatId(user.uid, widget.otherUserId);
    final chatRef = FirebaseFirestore.instance.collection("privateChats").doc(chatId);

    msg.clear();

    await chatRef.set({
      "participants": [user.uid, widget.otherUserId],
      "lastMessage": text,
      "lastMessageAt": Timestamp.now(),
      "updatedAt": Timestamp.now(),
      "unread": {
        widget.otherUserId: FieldValue.increment(1),
        user.uid: 0,
      },
    }, SetOptions(merge: true));

    await chatRef.collection("messages").add({
      "text": text,
      "senderId": user.uid,
      "receiverId": widget.otherUserId,
      "createdAt": Timestamp.now(),
      "seen": false,
    });

    jumpBottom();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final chatId = getChatId(uid, widget.otherUserId);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: C.bg,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.25,
                colors: [
                  C.purple.withOpacity(0.35),
                  C.bg,
                  Colors.black,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _ChatHeader(otherUserId: widget.otherUserId, fallbackName: widget.otherUsername),
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
                    "Safety: Teile keine privaten Daten und triff dich nur an sicheren öffentlichen Orten.",
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
                      jumpBottom();

                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            "Sag Hi 👋",
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scroll,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i].data() as Map<String, dynamic>;
                          final isMe = m["senderId"] == uid;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.74,
                              ),
                              decoration: BoxDecoration(
                                gradient: isMe
                                    ? const LinearGradient(colors: [C.cyan, C.purple])
                                    : null,
                                color: isMe ? null : C.card,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                                  bottomRight: Radius.circular(isMe ? 6 : 20),
                                ),
                                border: Border.all(
                                  color: isMe ? Colors.transparent : C.cyan.withOpacity(0.14),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isMe ? C.cyan : Colors.black).withOpacity(0.16),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: Text(
                                (m["text"] ?? "").toString(),
                                style: TextStyle(
                                  color: isMe ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: _MessageComposer(
                    controller: msg,
                    onSend: sendMessage,
                    onTap: jumpBottom,
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

class _ChatHeader extends StatelessWidget {
  final String otherUserId;
  final String fallbackName;

  const _ChatHeader({
    required this.otherUserId,
    required this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("users").doc(otherUserId).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final username = (data["username"] ?? fallbackName).toString();
        final photoUrl = (data["photoUrl"] ?? "").toString();
        final city = (data["city"] ?? "").toString();
        final verified = data["verified"] == true;

        return Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 10),
          decoration: BoxDecoration(
            color: C.bg.withOpacity(0.88),
            border: Border(
              bottom: BorderSide(color: C.cyan.withOpacity(0.10)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              OutlyAvatar(photoUrl: photoUrl, radius: 22),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: otherUserId),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      verifiedName(username, verified, size: 17),
                      Text(
                        city.isEmpty ? "Outly Chat" : city,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onTap;

  const _MessageComposer({
    required this.controller,
    required this.onSend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.92),
        border: Border(
          top: BorderSide(color: C.cyan.withOpacity(0.13)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: C.cyan.withOpacity(0.22)),
              ),
              child: TextField(
                controller: controller,
                onTap: onTap,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Nachricht schreiben...",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSend,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [C.cyan, C.purple]),
                boxShadow: [
                  BoxShadow(
                    color: C.cyan.withOpacity(0.28),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}