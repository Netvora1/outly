import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../core/app_colors.dart';
import '../../services/storage_service.dart';
import '../../widgets/auth/gradient_button.dart';
import '../../widgets/common/outly_avatar.dart';
import '../chat/private_chat_screen.dart' as chat;
import 'settings_screen.dart';
import '../../core/event_utils.dart';

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
  bool uploadingMoment = false;
  int tab = 0;

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

  String outlyLevel(Map<String, dynamic> data, int eventCount) {
    final followers = List.from(data["followers"] ?? []).length;
    final vibes = List.from(data["interests"] ?? []).length;

    if (followers >= 150 || eventCount >= 40) return "Legend";
    if (followers >= 60 || eventCount >= 20) return "Explorer";
    if (followers >= 20 || eventCount >= 8) return "Social";
    if (followers >= 5 || vibes >= 4) return "Active";
    return "New";
  }

  Color outlyLevelColor(String level) {
    switch (level) {
      case "Legend":
        return C.orange;
      case "Explorer":
        return C.purple;
      case "Social":
        return C.pink;
      case "Active":
        return C.cyan;
      default:
        return Colors.white54;
    }
  }

  IconData outlyLevelIcon(String level) {
    switch (level) {
      case "Legend":
        return Icons.workspace_premium_rounded;
      case "Explorer":
        return Icons.explore_rounded;
      case "Social":
        return Icons.local_fire_department_rounded;
      case "Active":
        return Icons.bolt_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
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

  Future<void> uploadMoment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || uploadingMoment) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );

    if (picked == null) return;

    setState(() => uploadingMoment = true);

    try {
      final bytes = await picked.readAsBytes();

      final url = await uploadImageBytes(
        bytes: bytes,
        path:
            "moments/${user.uid}/moment_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      if (url == null || url.trim().isEmpty) {
        throw Exception("Upload URL leer");
      }

      await FirebaseFirestore.instance.collection("moments").add({
        "userId": user.uid,
        "imageUrl": url.trim(),
        "type": "photo",
        "likes": [],
        "createdAt": Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Moment hochgeladen 🔥")),
      );
    } catch (e) {
      debugPrint("Moment Upload Fehler: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Moment konnte nicht hochgeladen werden.")),
      );
    } finally {
      if (mounted) setState(() => uploadingMoment = false);
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
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: C.cyan),
          );
        }

        final data = userSnap.data!.data() as Map<String, dynamic>? ?? {};
        final vibes = List<String>.from(
          data["interests"] ?? ["Sport", "Chill", "Gaming"],
        );

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("activities")
              .snapshots(),
          builder: (context, eventSnap) {
            final eventCount = eventSnap.data?.docs.length ?? 0;
            final level = outlyLevel(data, eventCount);
            final levelColor = outlyLevelColor(level);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: C.bg,
                  expandedHeight: 370,
                  pinned: true,
                  elevation: 0,
                  title: Text(
                    isMe ? "Mein Profil" : "@${data["username"] ?? "user"}",
                  ),
                  actions: [
                    if (isMe)
                      IconButton(
                        icon: const Icon(Icons.settings_rounded),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
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
                      level: level,
                      levelColor: levelColor,
                      levelIcon: outlyLevelIcon(level),
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

                        const SizedBox(height: 18),

                        ProfileStats(
                          userId: widget.userId,
                          data: data,
                          eventCount: eventCount,
                        ),

                        const SizedBox(height: 18),

                        ProfileLevelCard(
                          level: level,
                          color: levelColor,
                          icon: outlyLevelIcon(level),
                        ),

                        const SizedBox(height: 18),

                        ProfileVibes(
                          vibes: vibes,
                          isMe: isMe,
                          onEdit: () => openVibeEditor(vibes),
                        ),

                        const SizedBox(height: 18),

                        ProfileTabs(
                          active: tab,
                          onChanged: (v) => setState(() => tab = v),
                        ),

                        const SizedBox(height: 16),

                        if (tab == 0) ...[
                          if (isMe)
                            UploadMomentBox(
                              uploading: uploadingMoment,
                              onTap: uploadMoment,
                            ),
                          if (isMe) const SizedBox(height: 14),
                          ProfileMomentsGrid(userId: widget.userId),
                        ] else
                          ProfileEventGrid(userId: widget.userId),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
  final String level;
  final Color levelColor;
  final IconData levelIcon;

  const ProfileHero({
    super.key,
    required this.data,
    required this.isMe,
    required this.uploadingImage,
    required this.onImageTap,
    required this.level,
    required this.levelColor,
    required this.levelIcon,
  });

  @override
  Widget build(BuildContext context) {
    final username = (data["username"] ?? "user").toString();
    final bio = (data["bio"] ?? "Neu bei Outly 🔥").toString();
    final city = (data["city"] ?? "Keine Stadt").toString();
    final photoUrl = (data["photoUrl"] ?? "").toString().trim();

    final verified = data["verified"] == true; // blauer Haken nur Creator/Firmen
    final creator = data["creator"] == true;
    final trusted = data["trusted"] == true;
    final legend = data["legend"] == true;
    final vip = data["vip"] == true;
    final team = data["team"] == true;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                C.purple.withOpacity(0.95),
                C.pink.withOpacity(0.38),
                C.cyan.withOpacity(0.25),
                C.bg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        Positioned(
          right: -55,
          top: 65,
          child: Icon(
            levelIcon,
            size: 215,
            color: Colors.white.withOpacity(0.07),
          ),
        ),

        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.05),
                  C.bg.withOpacity(0.18),
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
                      width: 132,
                      height: 132,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [levelColor, C.cyan, C.purple],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: levelColor.withOpacity(0.42),
                            blurRadius: 38,
                          ),
                        ],
                      ),
                      child: OutlyAvatar(
                        photoUrl: photoUrl,
                        radius: 62,
                      ),
                    ),

                    if (uploadingImage)
                      Container(
                        width: 132,
                        height: 132,
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
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 13),

              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          "@$username",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      if (verified)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.verified_rounded,
                            color: Colors.blueAccent,
                            size: 24,
                          ),
                        ),
                    ],
                  ),

                  if (creator)
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: C.orange,
                      size: 23,
                    ),

                  if (trusted)
                    const Icon(
                      Icons.shield_rounded,
                      color: C.cyan,
                      size: 22,
                    ),

                  if (legend)
                    const Icon(
                      Icons.whatshot_rounded,
                      color: C.pink,
                      size: 22,
                    ),

                  if (vip)
                    const Icon(
                      Icons.diamond_rounded,
                      color: Colors.purpleAccent,
                      size: 22,
                    ),

                  if (team)
                    const Icon(
                      Icons.bolt_rounded,
                      color: Colors.greenAccent,
                      size: 22,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              OutlyLevelBadge(
                level: level,
                color: levelColor,
                icon: levelIcon,
              ),

              const SizedBox(height: 8),

              Text(
                city,
                style: const TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w700,
                ),
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

class OutlyLevelBadge extends StatelessWidget {
  final String level;
  final Color color;
  final IconData icon;

  const OutlyLevelBadge({
    super.key,
    required this.level,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            "Outly $level",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
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
      SnackBar(
        content: Text(isFollowing ? "Entfolgt" : "Du folgst jetzt 🔥"),
      ),
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
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(myUid)
          .snapshots(),
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
                      color: isFollowing
                          ? C.cyan.withOpacity(0.35)
                          : Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isFollowing ? C.cyan : C.purple)
                            .withOpacity(0.22),
                        blurRadius: 22,
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
                      builder: (_) => chat.PrivateChatScreen(
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
                        color: C.pink.withOpacity(0.16),
                        blurRadius: 20,
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
              icon: followsMe
                  ? Icons.favorite_rounded
                  : Icons.more_horiz_rounded,
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
              color: color.withOpacity(0.16),
              blurRadius: 20,
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
  final int eventCount;

  const ProfileStats({
    super.key,
    required this.userId,
    required this.data,
    required this.eventCount,
  });

  @override
  Widget build(BuildContext context) {
    final followers = List.from(data["followers"] ?? []);
    final following = List.from(data["following"] ?? []);

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
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileLevelCard extends StatelessWidget {
  final String level;
  final Color color;
  final IconData icon;

  const ProfileLevelCard({
    super.key,
    required this.level,
    required this.color,
    required this.icon,
  });

  String description() {
    switch (level) {
      case "Legend":
        return "Sehr aktiv in der Outly Community.";
      case "Explorer":
        return "Erstellt Events und entdeckt neue Leute.";
      case "Social":
        return "Aktiv, sozial und oft dabei.";
      case "Active":
        return "Hat schon starke Vibes auf Outly.";
      default:
        return "Neu dabei. Noch am Entdecken.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.14),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Outly $level",
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description(),
                  style: const TextStyle(
                    color: Colors.white60,
                    height: 1.3,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Vibes",
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isMe)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: C.cyan,
                    size: 18,
                  ),
                  label: const Text(
                    "Ändern",
                    style: TextStyle(color: C.cyan),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (vibes.isEmpty)
            const Text(
              "Noch keine Vibes ausgewählt.",
              style: TextStyle(color: Colors.white54),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vibes.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: C.cyan.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: C.cyan.withOpacity(0.28)),
                  ),
                  child: Text(
                    "#$item",
                    style: const TextStyle(
                      color: C.cyan,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class ProfileTabs extends StatelessWidget {
  final int active;
  final ValueChanged<int> onChanged;

  const ProfileTabs({
    super.key,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProfileTabButton(
              text: "Momente",
              icon: Icons.grid_on_rounded,
              active: active == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _ProfileTabButton(
              text: "Events",
              icon: Icons.local_fire_department_rounded,
              active: active == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ProfileTabButton({
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
          borderRadius: BorderRadius.circular(17),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: C.cyan.withOpacity(0.24),
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
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          return const _EmptyProfileBox(
            icon: Icons.photo_library_rounded,
            title: "Momente Fehler",
            text: "Momente konnten gerade nicht geladen werden.",
          );
        }

        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: C.cyan),
            ),
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
          return const _EmptyProfileBox(
            icon: Icons.photo_library_rounded,
            title: "Noch keine Momente",
            text: "Hier erscheinen später Fotos und Videos vom Profil.",
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;

            final imageUrl = (data["imageUrl"] ?? "")
                .toString()
                .trim()
                .replaceAll("\n", "")
                .replaceAll("\r", "")
                .replaceAll(" ", "");

            final type = (data["type"] ?? "photo").toString();
            final likes = List<String>.from(data["likes"] ?? []);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MomentViewerScreen(
                      momentId: docs[i].id,
                      data: data,
                    ),
                  ),
                );
              },
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: C.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _MomentFallback(),
                      )
                    else
                      const _MomentFallback(),

                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.55),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    if (type == "video")
                      const Positioned(
                        right: 8,
                        top: 8,
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),

                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${likes.length}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
          },
        );
      },
    );
  }
}

class MomentViewerScreen extends StatefulWidget {
  final String momentId;
  final Map<String, dynamic> data;

  const MomentViewerScreen({
    super.key,
    required this.momentId,
    required this.data,
  });

  @override
  State<MomentViewerScreen> createState() => _MomentViewerScreenState();
}

class _MomentViewerScreenState extends State<MomentViewerScreen> {
  late Map<String, dynamic> data;

  @override
  void initState() {
    super.initState();
    data = Map<String, dynamic>.from(widget.data);
  }

  Future<void> toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final likes = List<String>.from(data["likes"] ?? []);
    final liked = likes.contains(uid);

    setState(() {
      if (liked) {
        likes.remove(uid);
      } else {
        likes.add(uid);
      }

      data["likes"] = likes;
    });

    await FirebaseFirestore.instance
        .collection("moments")
        .doc(widget.momentId)
        .set({
      "likes": liked
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteMoment(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ownerId = (data["userId"] ?? "").toString();

    if (uid != ownerId) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        title: const Text("Moment löschen?"),
        content: const Text("Dieser Moment wird dauerhaft gelöscht."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Löschen",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection("moments")
        .doc(widget.momentId)
        .delete();

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("moments")
          .doc(widget.momentId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasData && snap.data!.data() != null) {
          data = snap.data!.data() as Map<String, dynamic>;
        }

        final imageUrl = (data["imageUrl"] ?? "")
            .toString()
            .trim()
            .replaceAll("\n", "")
            .replaceAll("\r", "")
            .replaceAll(" ", "");

        final ownerId = (data["userId"] ?? "").toString();
        final isMine = ownerId == uid;
        final likes = List<String>.from(data["likes"] ?? []);
        final liked = likes.contains(uid);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: imageUrl.isNotEmpty
                    ? InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: SizedBox.expand(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) =>
                                const _MomentFallback(),
                          ),
                        ),
                      )
                    : const _MomentFallback(),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.45),
                          Colors.transparent,
                          Colors.black.withOpacity(0.65),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.55),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      const Spacer(),

                      if (isMine)
                        CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.55),
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => deleteMoment(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Positioned(
                left: 18,
                right: 18,
                bottom: 34,
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: toggleLike,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: liked
                                ? C.pink.withOpacity(0.25)
                                : Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: liked ? C.pink : Colors.white24,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: liked ? C.pink : Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${likes.length}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          "Moment",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
              child: CircularProgressIndicator(color: C.cyan),
            ),
          );
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const _EmptyProfileBox(
            icon: Icons.local_fire_department_rounded,
            title: "Noch keine Events",
            text: "Events von diesem Profil erscheinen hier.",
          );
        }

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

        return GridView.builder(
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
            final color = catColor(category);

            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withOpacity(0.22)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.10),
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
                      errorBuilder: (_, __, ___) => _EventFallback(color: color),
                    )
                  else
                    _EventFallback(color: color),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.88),
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
                          style: TextStyle(
                            color: color,
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
        );
      },
    );
  }
}

class _EmptyProfileBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _EmptyProfileBox({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: C.cyan.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          Icon(icon, color: C.cyan, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _MomentFallback extends StatelessWidget {
  const _MomentFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.card2,
      child: const Center(
        child: Icon(
          Icons.photo_rounded,
          color: Colors.white38,
          size: 34,
        ),
      ),
    );
  }
}

class _EventFallback extends StatelessWidget {
  final Color color;

  const _EventFallback({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.85),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class UploadMomentBox extends StatelessWidget {
  final bool uploading;
  final VoidCallback onTap;

  const UploadMomentBox({
    super.key,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: C.cyan.withOpacity(0.22)),
          boxShadow: [
            BoxShadow(
              color: C.cyan.withOpacity(0.08),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [C.cyan, C.purple],
                ),
              ),
              child: uploading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(
                      Icons.add_a_photo_rounded,
                      color: Colors.black,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uploading ? "Lade Moment hoch..." : "Moment hochladen",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Foto zu deinem Profil hinzufügen",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}