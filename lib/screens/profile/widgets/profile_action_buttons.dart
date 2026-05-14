import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_colors.dart';
import '../../../widgets/auth/gradient_button.dart';
import '../settings_screen.dart';
import '../../chat/private_chat_screen.dart' as chat;

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final myUid = user.uid;

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
        backgroundColor: C.card,
        behavior: SnackBarBehavior.floating,
        content: Text(
          isFollowing ? "Du folgst nicht mehr" : "Du folgst jetzt 🔥",
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Future<void> blockUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final myUid = user.uid;
    if (myUid == userId) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "User blockieren?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          "Diese Person kann dich danach nicht mehr kontaktieren.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Blockieren",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final myRef = FirebaseFirestore.instance.collection("users").doc(myUid);
    final otherRef = FirebaseFirestore.instance.collection("users").doc(userId);
    final batch = FirebaseFirestore.instance.batch();

    batch.set(myRef, {
      "blockedUsers": FieldValue.arrayUnion([userId]),
      "following": FieldValue.arrayRemove([userId]),
      "followers": FieldValue.arrayRemove([userId]),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    batch.set(otherRef, {
      "blockedBy": FieldValue.arrayUnion([myUid]),
      "following": FieldValue.arrayRemove([myUid]),
      "followers": FieldValue.arrayRemove([myUid]),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    await batch.commit();

    if (!context.mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: C.card,
        behavior: SnackBarBehavior.floating,
        content: Text("User wurde blockiert."),
      ),
    );
  }

  Future<void> unblockUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final myUid = user.uid;

    final myRef = FirebaseFirestore.instance.collection("users").doc(myUid);
    final otherRef = FirebaseFirestore.instance.collection("users").doc(userId);
    final batch = FirebaseFirestore.instance.batch();

    batch.set(myRef, {
      "blockedUsers": FieldValue.arrayRemove([userId]),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    batch.set(otherRef, {
      "blockedBy": FieldValue.arrayRemove([myUid]),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    await batch.commit();

    if (!context.mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: C.card,
        behavior: SnackBarBehavior.floating,
        content: Text("User wurde entblockiert ✅"),
      ),
    );
  }

  Future<void> reportUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final myUid = user.uid;
    if (myUid == userId) return;

    await FirebaseFirestore.instance.collection("reports").add({
      "type": "user",
      "targetUserId": userId,
      "reportedBy": myUid,
      "reason": "profile_report",
      "status": "open",
      "createdAt": Timestamp.now(),
    });

    await FirebaseFirestore.instance.collection("users").doc(userId).set({
      "reportedCount": FieldValue.increment(1),
      "riskFlags": FieldValue.arrayUnion(["reported"]),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    if (!context.mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: C.card,
        behavior: SnackBarBehavior.floating,
        content: Text("User wurde gemeldet ✅"),
      ),
    );
  }

  void showUserOptions(BuildContext context, bool isBlocked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
                boxShadow: [
                  BoxShadow(
                    color: C.purple.withOpacity(0.16),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "User Optionen",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _OptionTile(
                    icon: Icons.flag_rounded,
                    color: C.orange,
                    title: "User melden",
                    text: "Profil an Outly Safety senden",
                    onTap: () => reportUser(context),
                  ),
                  const SizedBox(height: 10),
                  if (isBlocked)
                    _OptionTile(
                      icon: Icons.lock_open_rounded,
                      color: C.green,
                      title: "User entblockieren",
                      text: "Blockierung entfernen",
                      onTap: () => unblockUser(context),
                    )
                  else
                    _OptionTile(
                      icon: Icons.block_rounded,
                      color: Colors.redAccent,
                      title: "User blockieren",
                      text: "Kontakt und Verbindung blockieren",
                      onTap: () => blockUser(context),
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final myUid = user.uid;

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
          _CleanIconButton(
            icon: Icons.settings_rounded,
            color: C.cyan,
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
      stream:
          FirebaseFirestore.instance.collection("users").doc(myUid).snapshots(),
      builder: (context, mySnap) {
        final myData = mySnap.data?.data() as Map<String, dynamic>? ?? {};
        final following = List<String>.from(myData["following"] ?? []);
        final blockedUsers = List<String>.from(myData["blockedUsers"] ?? []);
        final isFollowing = following.contains(userId);
        final isBlocked = blockedUsers.contains(userId);

        return Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: C.purple.withOpacity(0.12),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _MainActionButton(
                  active: !isFollowing && !isBlocked,
                  icon: isBlocked
                      ? Icons.block_rounded
                      : isFollowing
                          ? Icons.check_rounded
                          : Icons.person_add_alt_1_rounded,
                  text: isBlocked
                      ? "Blockiert"
                      : isFollowing
                          ? "Folge ich"
                          : "Folgen",
                  onTap:
                      isBlocked ? () {} : () => toggleFollow(context, isFollowing),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SecondActionButton(
                  icon: Icons.chat_bubble_rounded,
                  text: "Nachricht",
                  color: isBlocked ? Colors.white38 : C.pink,
                  onTap: isBlocked
                      ? () {}
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => chat.PrivateChatScreen(
                                otherUserId: userId,
                                otherUsername:
                                    (data["username"] ?? "user").toString(),
                              ),
                            ),
                          );
                        },
                ),
              ),
              const SizedBox(width: 8),
              _CleanIconButton(
                icon: isBlocked
                    ? Icons.lock_open_rounded
                    : followsMe
                        ? Icons.local_fire_department_rounded
                        : Icons.more_horiz_rounded,
                color: isBlocked
                    ? C.green
                    : followsMe
                        ? C.orange
                        : Colors.white70,
                onTap: () => showUserOptions(context, isBlocked),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MainActionButton extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _MainActionButton({
    required this.active,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: active
              ? const LinearGradient(
                  colors: [C.purple, C.cyan],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: active ? null : Colors.white.withOpacity(0.075),
          border: Border.all(
            color: active ? Colors.transparent : Colors.white.withOpacity(0.12),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: C.cyan.withOpacity(0.20),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? Colors.black : Colors.white, size: 19),
            const SizedBox(width: 7),
            Text(
              text,
              style: TextStyle(
                color: active ? Colors.black : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _SecondActionButton({
    required this.icon,
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = color == Colors.white38;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(disabled ? 0.06 : 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(disabled ? 0.12 : 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CleanIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CleanIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.24)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}