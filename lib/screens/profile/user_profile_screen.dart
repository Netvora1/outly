import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../core/event_utils.dart';
import '../../services/storage_service.dart';
import '../../widgets/auth/gradient_button.dart';

import 'settings_screen.dart';
import 'widgets/profile_hero.dart';
import 'widgets/profile_tabs.dart';
import 'widgets/upload_moment_box.dart';
import 'widgets/profile_action_buttons.dart';
import 'widgets/profile_vibes.dart';
import 'widgets/profile_moments_grid.dart';
import 'widgets/profile_shared_widgets.dart';
import 'widgets/profile_events_grid.dart';
import 'widgets/profile_social_links.dart';
import 'widgets/profile_neon_background.dart';
import 'widgets/profile_ui_helpers.dart';

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
  final instagram = TextEditingController();
  final tiktok = TextEditingController();
  final website = TextEditingController();

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
    instagram.dispose();
    tiktok.dispose();
    website.dispose();
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

  Future<void> openUrl(String raw) async {
    var url = raw.trim();
    if (url.isEmpty) return;

    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      url = "https://$url";
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> uploadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || uploadingImage) return;

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
          activeControlsWidgetColor: C.pink,
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
    } catch (e) {
      debugPrint("Profilbild Upload Fehler: $e");
    } finally {
      if (mounted) setState(() => uploadingImage = false);
    }
  }

  Future<void> uploadMoment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || uploadingMoment) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
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
        "views": [],
        "createdAt": Timestamp.now(),
        "updatedAt": Timestamp.now(),
      });
    } catch (e) {
      debugPrint("Moment Upload Fehler: $e");
    } finally {
      if (mounted) setState(() => uploadingMoment = false);
    }
  }

  void openEdit(Map<String, dynamic> data) {
    username.text = (data["username"] ?? "").toString();
    city.text = (data["city"] ?? "").toString();
    bio.text = (data["bio"] ?? "").toString();
    instagram.text = (data["instagram"] ?? "").toString();
    tiktok.text = (data["tiktok"] ?? "").toString();
    website.text = (data["website"] ?? "").toString();

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
                border: Border.all(color: C.pink.withOpacity(0.34)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Profil bearbeiten",
                      style: TextStyle(
                        color: C.pink,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlyProfileField(controller: username, hint: "Benutzername", icon: Icons.person_rounded),
                    const SizedBox(height: 12),
                    OutlyProfileField(controller: city, hint: "Stadt / Land", icon: Icons.location_on_rounded),
                    const SizedBox(height: 12),
                    OutlyProfileField(controller: bio, hint: "Bio", icon: Icons.notes_rounded, maxLines: 3),
                    const SizedBox(height: 12),
                    OutlyProfileField(controller: instagram, hint: "Instagram Link oder @name", icon: Icons.camera_alt_rounded),
                    const SizedBox(height: 12),
                    OutlyProfileField(controller: tiktok, hint: "TikTok Link oder @name", icon: Icons.music_note_rounded),
                    const SizedBox(height: 12),
                    OutlyProfileField(controller: website, hint: "Website / Link", icon: Icons.link_rounded),
                    const SizedBox(height: 18),
                    GradientButton(
                      text: "Speichern",
                      onPressed: () async {
                        final uid = FirebaseAuth.instance.currentUser!.uid;

                        await FirebaseFirestore.instance.collection("users").doc(uid).set({
                          "username": username.text.trim(),
                          "city": city.text.trim(),
                          "bio": bio.text.trim(),
                          "instagram": instagram.text.trim(),
                          "tiktok": tiktok.text.trim(),
                          "website": website.text.trim(),
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
                    border: Border.all(color: C.purple.withOpacity(0.34)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Deine Vibes",
                        style: TextStyle(
                          color: C.pink,
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
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                              decoration: BoxDecoration(
                                color: active ? C.pink : C.card,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: active ? C.pink : Colors.white12),
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
      body: Stack(
        children: [
          const ProfileNeonBackground(),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection("users").doc(widget.userId).snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) {
                return const Center(child: CircularProgressIndicator(color: C.pink));
              }

              final data = userSnap.data!.data() as Map<String, dynamic>? ?? {};
              final vibes = List<String>.from(data["interests"] ?? ["Sport", "Chill", "Gaming"]);

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("activities").snapshots(),
                builder: (context, eventSnap) {
                  final eventCount = eventSnap.data?.docs.length ?? 0;
                  final level = outlyLevel(data, eventCount);
                  final levelColor = outlyLevelColor(level);

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        expandedHeight: 370,
                        pinned: true,
                        elevation: 0,
                        title: Text(
                          isMe ? "Mein Profil" : "@${data["username"] ?? "user"}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                        actions: [
                          if (isMe)
                            IconButton(
                              icon: const Icon(Icons.settings_rounded, color: Colors.white),
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
                            level: level,
                            levelColor: levelColor,
                            levelIcon: outlyLevelIcon(level),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
                          child: Column(
                            children: [
                              ProfileSocialLinksCard(data: data, onOpen: openUrl),
                              const SizedBox(height: 14),
                              ProfileActionButtons(
                                isMe: isMe,
                                data: data,
                                userId: widget.userId,
                                onEdit: () => openEdit(data),
                              ),
                              const SizedBox(height: 18),
                              ProfileVibes(
                                vibes: vibes,
                                isMe: isMe,
                                onEdit: () => openVibeEditor(vibes),
                              ),
                              const SizedBox(height: 18),
                              ProfileSectionHeader(
                                icon: tab == 0 ? Icons.auto_awesome_rounded : Icons.event_available_rounded,
                                title: tab == 0 ? "Momente" : "Events",
                                subtitle: tab == 0 ? "Echte Highlights aus dem Leben" : "Geplante Aktivitäten",
                              ),
                              const SizedBox(height: 12),
                              ProfileTabs(
                                selectedTab: tab,
                                onTabSelected: (value) => setState(() => tab = value),
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
        ],
      ),
    );
  }
}
