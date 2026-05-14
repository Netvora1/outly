import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../core/legal_texts.dart';
import '../legal/legal_text_page.dart';
import 'admin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supportSubject = TextEditingController();
  final supportMessage = TextEditingController();

  final editUsername = TextEditingController();
  final editCity = TextEditingController();
  final editBio = TextEditingController();
  final emailController = TextEditingController();

  bool sending = false;

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
    supportSubject.dispose();
    supportMessage.dispose();
    editUsername.dispose();
    editCity.dispose();
    editBio.dispose();
    emailController.dispose();
    super.dispose();
  }

  bool canAccessAdmin(String role, String uid) {
    return uid == "roduqZRk4GgXLCQIZGIFAWN0UUg1" ||
        role == "owner" ||
        role == "admin" ||
        role == "moderator" ||
        role == "support";
  }

  Future<void> openWeb(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> updateUserSettings(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
      ...data,
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<bool> confirm(BuildContext context, String title, String text) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Bestätigen", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<void> resetPassword(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passwort Reset E-Mail gesendet ✅")),
    );
  }

  Future<void> logout(BuildContext context) async {
    final ok = await confirm(
      context,
      "Abmelden?",
      "Du wirst aus deinem Account ausgeloggt.",
    );

    if (!ok) return;

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  Future<void> deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ok = await confirm(
      context,
      "Account wirklich löschen?",
      "Dein Account wird deaktiviert und danach gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.",
    );

    if (!ok) return;

    try {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "isDeleted": true,
        "deletedAt": Timestamp.now(),
        "email": user.email ?? "",
        "username": "deleted_user",
        "bio": "",
        "photoUrl": "",
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));

      await user.delete();

      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bitte neu einloggen und dann erneut löschen.")),
      );
    }
  }

  void openEditProfileSheet(Map<String, dynamic> data) {
    editUsername.text = (data["username"] ?? "").toString();
    editCity.text = (data["city"] ?? "").toString();
    editBio.text = (data["bio"] ?? "").toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _PremiumSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              const _SheetTitle(
                icon: Icons.person_rounded,
                title: "Profil bearbeiten",
                subtitle: "Name, Stadt und Bio aktualisieren.",
                color: C.cyan,
              ),
              const SizedBox(height: 16),
              _SettingsInput(
                controller: editUsername,
                hint: "Benutzername",
                icon: Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 12),
              _SettingsInput(
                controller: editCity,
                hint: "Stadt / Land",
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 12),
              _SettingsInput(
                controller: editBio,
                hint: "Bio",
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _MainButton(
                text: "Profil speichern",
                icon: Icons.save_rounded,
                color: C.cyan,
                onTap: () async {
                  await updateUserSettings({
                    "username": editUsername.text.trim(),
                    "city": editCity.text.trim(),
                    "bio": editBio.text.trim(),
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void openVibeSheet(Map<String, dynamic> data) {
    final selected = List<String>.from(data["interests"] ?? []).toSet();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return _PremiumSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 18),
                  const _SheetTitle(
                    icon: Icons.auto_awesome_rounded,
                    title: "Vibes & Interessen",
                    subtitle: "Wähle aus, was zu dir passt.",
                    color: C.purple,
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: allVibes.map((vibe) {
                      final active = selected.contains(vibe);

                      return GestureDetector(
                        onTap: () {
                          setSheet(() {
                            active ? selected.remove(vibe) : selected.add(vibe);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                          decoration: BoxDecoration(
                            color: active ? C.cyan : C.card,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: active ? C.cyan : Colors.white.withOpacity(0.10),
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: C.cyan.withOpacity(0.25),
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
                  const SizedBox(height: 20),
                  _MainButton(
                    text: "Vibes speichern",
                    icon: Icons.check_rounded,
                    color: C.cyan,
                    onTap: () async {
                      await updateUserSettings({
                        "interests": selected.toList(),
                      });

                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void openEmailSheet() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    emailController.text = user.email ?? "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _PremiumSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              const _SheetTitle(
                icon: Icons.email_rounded,
                title: "E-Mail ändern",
                subtitle: "Du bekommst einen Bestätigungslink an die neue E-Mail.",
                color: C.purple,
              ),
              const SizedBox(height: 16),
              _SettingsInput(
                controller: emailController,
                hint: "Neue E-Mail",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 14),
              _InfoBox(
                icon: Icons.info_outline_rounded,
                color: C.orange,
                text: "Aus Sicherheitsgründen kann Firebase verlangen, dass du dich neu einloggst.",
              ),
              const SizedBox(height: 16),
              _MainButton(
                text: "Bestätigung senden",
                icon: Icons.mark_email_read_rounded,
                color: C.cyan,
                onTap: () async {
                  final newEmail = emailController.text.trim();

                  if (newEmail.isEmpty || !newEmail.contains("@")) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Bitte gültige E-Mail eingeben")),
                    );
                    return;
                  }

                  try {
                    await user.verifyBeforeUpdateEmail(newEmail);

                    await updateUserSettings({
                      "pendingEmail": newEmail,
                    });

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Bestätigungslink gesendet ✅")),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Bitte neu einloggen und erneut versuchen.")),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> createSupportTicket({
    required BuildContext context,
    required String type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    supportSubject.clear();
    supportMessage.clear();

    final config = _SupportTypeConfig.fromType(type);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _PremiumSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              _SheetTitle(
                icon: config.icon,
                title: config.title,
                subtitle: config.subtitle,
                color: config.color,
              ),
              const SizedBox(height: 16),
              _SettingsInput(
                controller: supportSubject,
                hint: config.subjectHint,
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 12),
              _SettingsInput(
                controller: supportMessage,
                hint: config.messageHint,
                icon: config.icon,
                maxLines: 5,
              ),
              const SizedBox(height: 14),
              _InfoBox(
                icon: Icons.shield_rounded,
                color: C.cyan,
                text: "Deine Anfrage wird sicher an das Outly Support Team gesendet.",
              ),
              const SizedBox(height: 16),
              _MainButton(
                text: sending ? "Wird gesendet..." : "An Outly senden",
                icon: Icons.send_rounded,
                color: config.color,
                loading: sending,
                onTap: sending
                    ? null
                    : () async {
                        final subject = supportSubject.text.trim();
                        final message = supportMessage.text.trim();

                        if (subject.isEmpty || message.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Bitte alles ausfüllen")),
                          );
                          return;
                        }

                        setState(() => sending = true);

                        try {
                          await FirebaseFirestore.instance.collection("support").add({
                            "uid": user.uid,
                            "email": user.email ?? "",
                            "type": type,
                            "subject": subject,
                            "message": message,
                            "status": "open",
                            "priority": type == "bug" || type == "safety" ? "urgent" : "normal",
                            "adminReply": "",
                            "adminNote": "",
                            "assignedTo": "",
                            "createdAt": Timestamp.now(),
                            "updatedAt": Timestamp.now(),
                            "resolvedAt": null,
                          });

                          if (!context.mounted) return;
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Ticket gesendet ✅")),
                          );
                        } finally {
                          if (mounted) setState(() => sending = false);
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  void openSupportCenter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _PremiumSheet(
          maxHeight: 0.88,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              const _SheetTitle(
                icon: Icons.support_agent_rounded,
                title: "Support & Hilfe",
                subtitle: "Alles rund um Hilfe, Bugs, Feedback und Sicherheit.",
                color: C.green,
              ),
              const SizedBox(height: 16),
              _SupportActionCard(
                icon: Icons.support_agent_rounded,
                color: C.green,
                title: "Support kontaktieren",
                subtitle: "Account, Events, Chat oder technische Hilfe.",
                onTap: () {
                  Navigator.pop(context);
                  createSupportTicket(context: context, type: "support");
                },
              ),
              _SupportActionCard(
                icon: Icons.confirmation_number_rounded,
                color: C.cyan,
                title: "Meine Tickets",
                subtitle: "Status und Antworten vom Outly Team ansehen.",
                onTap: () {
                  Navigator.pop(context);
                  openSupportTickets();
                },
              ),
              _SupportActionCard(
                icon: Icons.bug_report_rounded,
                color: C.orange,
                title: "Bug melden",
                subtitle: "Fehler, Crash, Upload-Problem oder Anzeige-Bug.",
                onTap: () {
                  Navigator.pop(context);
                  createSupportTicket(context: context, type: "bug");
                },
              ),
              _SupportActionCard(
                icon: Icons.feedback_rounded,
                color: C.purple,
                title: "Feedback senden",
                subtitle: "Ideen, Wünsche oder Verbesserungsvorschläge.",
                onTap: () {
                  Navigator.pop(context);
                  createSupportTicket(context: context, type: "feedback");
                },
              ),
              _SupportActionCard(
                icon: Icons.shield_rounded,
                color: Colors.redAccent,
                title: "Safety Problem melden",
                subtitle: "Gefährliches Verhalten, Fake User oder Spam.",
                onTap: () {
                  Navigator.pop(context);
                  createSupportTicket(context: context, type: "safety");
                },
              ),
              _SupportActionCard(
                icon: Icons.public_rounded,
                color: C.purple2,
                title: "Support Center online",
                subtitle: "Offizielle Outly Hilfe-Seite öffnen.",
                onTap: () => openWeb("https://outly.site/support.html"),
              ),
            ],
          ),
        );
      },
    );
  }

  void openPrivacyCenter(Map<String, dynamic> data) {
    final contact = (data["privacyContact"] ?? "friends").toString();
    final profile = (data["privacyProfile"] ?? "public").toString();
    final events = (data["privacyEvents"] ?? "public").toString();
    final location = data["nearbyEnabled"] != false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        String contactValue = contact;
        String profileValue = profile;
        String eventsValue = events;
        bool locationValue = location;

        return StatefulBuilder(
          builder: (context, setSheet) {
            return _PremiumSheet(
              maxHeight: 0.88,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 18),
                  const _SheetTitle(
                    icon: Icons.privacy_tip_rounded,
                    title: "Datenschutz & Privatsphäre",
                    subtitle: "Kontrolliere, wer dich sieht und kontaktieren darf.",
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 16),
                  _OptionDropdown(
                    title: "Nachrichten von",
                    value: contactValue,
                    items: const {
                      "all": "Alle",
                      "friends": "Nur Freunde",
                      "none": "Niemand",
                    },
                    onChanged: (v) => setSheet(() => contactValue = v),
                  ),
                  _OptionDropdown(
                    title: "Profil sichtbar für",
                    value: profileValue,
                    items: const {
                      "public": "Alle",
                      "friends": "Nur Freunde",
                      "private": "Privat",
                    },
                    onChanged: (v) => setSheet(() => profileValue = v),
                  ),
                  _OptionDropdown(
                    title: "Events sichtbar für",
                    value: eventsValue,
                    items: const {
                      "public": "Alle",
                      "followers": "Follower",
                      "private": "Privat",
                    },
                    onChanged: (v) => setSheet(() => eventsValue = v),
                  ),
                  _SwitchCard(
                    icon: Icons.location_on_rounded,
                    color: C.green,
                    title: "Nähe & Standort",
                    subtitle: "Events in deiner Nähe anzeigen.",
                    value: locationValue,
                    onChanged: (v) => setSheet(() => locationValue = v),
                  ),
                  const SizedBox(height: 10),
                  _MainButton(
                    text: "Datenschutz speichern",
                    icon: Icons.lock_rounded,
                    color: Colors.blueAccent,
                    onTap: () async {
                      await updateUserSettings({
                        "privacyContact": contactValue,
                        "privacyProfile": profileValue,
                        "privacyEvents": eventsValue,
                        "nearbyEnabled": locationValue,
                      });

                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _SupportActionCard(
                    icon: Icons.policy_rounded,
                    color: C.cyan,
                    title: "Datenschutzerklärung",
                    subtitle: "Offizielle Datenschutz-Seite öffnen.",
                    onTap: () => openWeb("https://outly.site/privacy.html"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void openNotificationCenter(Map<String, dynamic> data) {
    bool push = data["notifyPush"] != false;
    bool events = data["notifyEvents"] != false;
    bool chats = data["notifyChats"] != false;
    bool social = data["notifySocial"] != false;
    bool support = data["notifySupport"] != false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return _PremiumSheet(
              maxHeight: 0.86,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 18),
                  const _SheetTitle(
                    icon: Icons.notifications_active_rounded,
                    title: "Benachrichtigungen",
                    subtitle: "Wähle aus, was Outly dir senden darf.",
                    color: C.cyan,
                  ),
                  const SizedBox(height: 16),
                  _SwitchCard(
                    icon: Icons.notifications_active_rounded,
                    color: C.cyan,
                    title: "Push Benachrichtigungen",
                    subtitle: "Hauptschalter für Push Nachrichten.",
                    value: push,
                    onChanged: (v) => setSheet(() => push = v),
                  ),
                  _SwitchCard(
                    icon: Icons.local_fire_department_rounded,
                    color: C.orange,
                    title: "Event Updates",
                    subtitle: "Join-Anfragen, Änderungen und Erinnerungen.",
                    value: events,
                    onChanged: (v) => setSheet(() => events = v),
                  ),
                  _SwitchCard(
                    icon: Icons.chat_bubble_rounded,
                    color: C.pink,
                    title: "Chat Nachrichten",
                    subtitle: "Private Chats und Event Chat Hinweise.",
                    value: chats,
                    onChanged: (v) => setSheet(() => chats = v),
                  ),
                  _SwitchCard(
                    icon: Icons.favorite_rounded,
                    color: C.purple,
                    title: "Social",
                    subtitle: "Follower, Likes und Profil-Aktivität.",
                    value: social,
                    onChanged: (v) => setSheet(() => social = v),
                  ),
                  _SwitchCard(
                    icon: Icons.support_agent_rounded,
                    color: C.green,
                    title: "Support Antworten",
                    subtitle: "Antworten vom Outly Team.",
                    value: support,
                    onChanged: (v) => setSheet(() => support = v),
                  ),
                  const SizedBox(height: 10),
                  _MainButton(
                    text: "Einstellungen speichern",
                    icon: Icons.save_rounded,
                    color: C.cyan,
                    onTap: () async {
                      await updateUserSettings({
                        "notifyPush": push,
                        "notifyEvents": events,
                        "notifyChats": chats,
                        "notifySocial": social,
                        "notifySupport": support,
                      });

                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void openBlockedUsersSheet(Map<String, dynamic> data) {
    final blocked = List<String>.from(data["blockedUsers"] ?? []);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _PremiumSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              const _SheetTitle(
                icon: Icons.block_rounded,
                title: "Blockierte Nutzer",
                subtitle: "Verwalte blockierte Personen.",
                color: Colors.redAccent,
              ),
              const SizedBox(height: 14),
              if (blocked.isEmpty)
                const _EmptySmall(text: "Du hast aktuell niemanden blockiert.")
              else
                ...blocked.map((uid) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: C.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      title: Text(uid),
                      trailing: TextButton(
                        onPressed: () async {
                          await updateUserSettings({
                            "blockedUsers": FieldValue.arrayRemove([uid]),
                          });

                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        child: const Text("Entblocken"),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void openSupportTickets() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _PremiumSheet(
          maxHeight: 0.82,
          scrollable: false,
          child: Column(
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              const _SheetTitle(
                icon: Icons.confirmation_number_rounded,
                title: "Meine Tickets",
                subtitle: "Status, Antworten und Verlauf.",
                color: C.cyan,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("support")
                      .where("uid", isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator(color: C.cyan));
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
                      return const _EmptySmall(text: "Noch keine Tickets vorhanden.");
                    }

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      children: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final subject = data["subject"] ?? "Ticket";
                        final status = data["status"] ?? "open";
                        final type = data["type"] ?? "support";
                        final message = data["message"] ?? "";
                        final reply = data["adminReply"] ?? "";
                        final config = _SupportTypeConfig.fromType(type.toString());

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: C.card,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: status == "answered"
                                  ? C.green.withOpacity(0.35)
                                  : config.color.withOpacity(0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(config.icon, color: config.color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      subject.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  _MiniStatus(text: status.toString()),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                message.toString(),
                                style: const TextStyle(color: Colors.white70, height: 1.4),
                              ),
                              if (reply.toString().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: C.green.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: C.green.withOpacity(0.25)),
                                  ),
                                  child: Text(
                                    "Outly Antwort:\n$reply",
                                    style: const TextStyle(color: Colors.white70, height: 1.35),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 26, 2, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: C.cyan,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        title: const Text(
          "Einstellungen",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection("users").doc(user?.uid).snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() as Map<String, dynamic>? ?? {};

          final username = (data["username"] ?? "Outly User").toString();
          final role = (data["role"] ?? "user").toString();
          final verified = data["verified"] == true;
          final creator = data["creator"] == true;
          final trusted = data["trusted"] == true;
          final vip = data["vip"] == true;
          final team = data["team"] == true;
          final uid = user?.uid ?? "";
          final isAdmin = canAccessAdmin(role, uid);

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              _SettingsHero(
                username: username,
                email: user?.email ?? "",
                role: role,
                verified: verified,
                creator: creator,
                trusted: trusted,
                vip: vip,
                team: team,
              ),
              const SizedBox(height: 16),
              _QuickGrid(
                items: [
                  _QuickAction(
                    icon: Icons.person_rounded,
                    label: "Profil",
                    color: C.cyan,
                    onTap: () => openEditProfileSheet(data),
                  ),
                  _QuickAction(
                    icon: Icons.support_agent_rounded,
                    label: "Hilfe",
                    color: C.green,
                    onTap: openSupportCenter,
                  ),
                  _QuickAction(
                    icon: Icons.privacy_tip_rounded,
                    label: "Privacy",
                    color: Colors.blueAccent,
                    onTap: () => openPrivacyCenter(data),
                  ),
                  _QuickAction(
                    icon: Icons.notifications_active_rounded,
                    label: "Push",
                    color: C.orange,
                    onTap: () => openNotificationCenter(data),
                  ),
                ],
              ),

              if (isAdmin) ...[
                section("Admin"),
                SettingsTile(
                  icon: Icons.admin_panel_settings_rounded,
                  color: Colors.amber,
                  title: "Admin Control Center",
                  subtitle: "User, Events, Reports, Support & Moderation",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    );
                  },
                ),
              ],

              section("Account"),
              SettingsTile(
                icon: Icons.person_rounded,
                color: C.cyan,
                title: "Profil bearbeiten",
                subtitle: "Name, Stadt und Bio aktualisieren",
                onTap: () => openEditProfileSheet(data),
              ),
              SettingsTile(
                icon: Icons.auto_awesome_rounded,
                color: C.purple,
                title: "Vibes & Interessen",
                subtitle: "Wähle deine Aktivitäten und Interessen",
                onTap: () => openVibeSheet(data),
              ),
              SettingsTile(
                icon: Icons.email_rounded,
                color: C.purple2,
                title: "E-Mail ändern",
                subtitle: user?.email ?? "Keine E-Mail verbunden",
                onTap: openEmailSheet,
              ),
              SettingsTile(
                icon: Icons.key_rounded,
                color: C.orange,
                title: "Passwort zurücksetzen",
                subtitle: "Reset-Link per E-Mail erhalten",
                onTap: () => resetPassword(context),
              ),

              section("Datenschutz & Sicherheit"),
              SettingsTile(
                icon: Icons.privacy_tip_rounded,
                color: Colors.blueAccent,
                title: "Datenschutz Center",
                subtitle: "Profil, Nachrichten, Events und Standort",
                onTap: () => openPrivacyCenter(data),
              ),
              SettingsTile(
                icon: Icons.block_rounded,
                color: Colors.redAccent,
                title: "Blockierte Nutzer",
                subtitle: "Blockierte Personen verwalten",
                onTap: () => openBlockedUsersSheet(data),
              ),
              SettingsTile(
                icon: Icons.shield_rounded,
                color: C.cyan,
                title: "Safety Center",
                subtitle: "Sicherheit, Reports und Community Schutz",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalTextPage(
                        title: "Safety Center",
                        text: securityText,
                      ),
                    ),
                  );
                },
              ),

              section("Benachrichtigungen"),
              SettingsTile(
                icon: Icons.notifications_active_rounded,
                color: C.cyan,
                title: "Benachrichtigungen verwalten",
                subtitle: "Push, Events, Chats, Social und Support",
                onTap: () => openNotificationCenter(data),
              ),

              section("Support & Hilfe"),
              SettingsTile(
                icon: Icons.help_center_rounded,
                color: C.green,
                title: "Hilfe Center",
                subtitle: "Support, Tickets, Bugs, Feedback und Safety",
                onTap: openSupportCenter,
              ),
              SettingsTile(
                icon: Icons.confirmation_number_rounded,
                color: C.cyan,
                title: "Meine Support Tickets",
                subtitle: "Status und Antworten vom Outly Team ansehen",
                onTap: openSupportTickets,
              ),

              section("Rechtliches"),
              SettingsTile(
                icon: Icons.public_rounded,
                color: C.cyan,
                title: "Outly Website",
                subtitle: "Offizielle Plattformseite öffnen",
                onTap: () => openWeb("https://outly.site"),
              ),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                color: Colors.blueAccent,
                title: "Datenschutzerklärung",
                subtitle: "Informationen zu Datenschutz und Datenverarbeitung",
                onTap: () => openWeb("https://outly.site/privacy.html"),
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                color: Colors.purpleAccent,
                title: "Nutzungsbedingungen",
                subtitle: "Regeln und Bedingungen für die Nutzung von Outly",
                onTap: () => openWeb("https://outly.site/agb.html"),
              ),
              SettingsTile(
                icon: Icons.gavel_rounded,
                color: Colors.redAccent,
                title: "Impressum",
                subtitle: "Rechtliche Angaben und Kontakt",
                onTap: () => openWeb("https://outly.site/impressum.html"),
              ),
              SettingsTile(
                icon: Icons.groups_rounded,
                color: C.green,
                title: "Community Guidelines",
                subtitle: "Regeln für Events, Chats und Profile",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalTextPage(
                        title: "Community Guidelines",
                        text: securityText,
                      ),
                    ),
                  );
                },
              ),
              SettingsTile(
                icon: Icons.info_outline_rounded,
                color: Colors.white70,
                title: "Über Outly",
                subtitle: "Version 1.0.0 • Real-Life Social Discovery Platform",
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

              section("Session"),
              SettingsTile(
                icon: Icons.logout_rounded,
                color: C.orange,
                title: "Abmelden",
                subtitle: "Aus deinem Account ausloggen",
                onTap: () => logout(context),
              ),

              const SizedBox(height: 10),
              _DangerZone(onDelete: () => deleteAccount(context)),
            ],
          );
        },
      ),
    );
  }
}

class _SupportTypeConfig {
  final String title;
  final String subtitle;
  final String subjectHint;
  final String messageHint;
  final IconData icon;
  final Color color;

  const _SupportTypeConfig({
    required this.title,
    required this.subtitle,
    required this.subjectHint,
    required this.messageHint,
    required this.icon,
    required this.color,
  });

  factory _SupportTypeConfig.fromType(String type) {
    switch (type) {
      case "bug":
        return const _SupportTypeConfig(
          title: "Bug melden",
          subtitle: "Melde Fehler, Abstürze oder Probleme in der App.",
          subjectHint: "Was funktioniert nicht?",
          messageHint: "Beschreib den Bug genau. Was hast du gemacht? Was ist passiert?",
          icon: Icons.bug_report_rounded,
          color: C.orange,
        );
      case "feedback":
        return const _SupportTypeConfig(
          title: "Feedback senden",
          subtitle: "Schick uns Ideen, Wünsche oder Verbesserungen.",
          subjectHint: "Deine Idee",
          messageHint: "Was sollen wir verbessern oder neu bauen?",
          icon: Icons.feedback_rounded,
          color: C.purple,
        );
      case "safety":
        return const _SupportTypeConfig(
          title: "Safety Problem melden",
          subtitle: "Melde Fake-User, Belästigung oder gefährliche Inhalte.",
          subjectHint: "Was ist passiert?",
          messageHint: "Beschreib die Situation. Wenn möglich: User, Event oder Chat erwähnen.",
          icon: Icons.shield_rounded,
          color: Colors.redAccent,
        );
      default:
        return const _SupportTypeConfig(
          title: "Support kontaktieren",
          subtitle: "Wir helfen dir bei Account, Events, Chats und Technik.",
          subjectHint: "Worum geht es?",
          messageHint: "Beschreib dein Problem möglichst genau.",
          icon: Icons.support_agent_rounded,
          color: C.green,
        );
    }
  }
}

class _SettingsHero extends StatelessWidget {
  final String username;
  final String email;
  final String role;
  final bool verified;
  final bool creator;
  final bool trusted;
  final bool vip;
  final bool team;

  const _SettingsHero({
    required this.username,
    required this.email,
    required this.role,
    required this.verified,
    required this.creator,
    required this.trusted,
    required this.vip,
    required this.team,
  });

  @override
  Widget build(BuildContext context) {
    final roleText = role == "owner"
        ? "Owner"
        : role == "admin"
            ? "Admin"
            : role == "moderator"
                ? "Moderator"
                : role == "support"
                    ? "Support"
                    : "User";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF18051F),
            Color(0xFF090E1A),
            Color(0xFF05060D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: C.cyan.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: C.purple.withOpacity(0.24),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -22,
            child: Icon(
              Icons.tune_rounded,
              size: 150,
              color: C.cyan.withOpacity(0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    colors: [
                      Color(0xFFFF4DFF),
                      Color(0xFFA970FF),
                      Color(0xFF33D6FF),
                    ],
                  ).createShader(bounds);
                },
                child: const Text(
                  "OUTLY",
                  style: TextStyle(
                    fontSize: 43,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                "Control Center",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Text(
                "@$username",
                style: const TextStyle(
                  color: C.cyan,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(
                    icon: Icons.person,
                    text: roleText,
                    color: role == "user" ? Colors.white54 : Colors.amber,
                  ),
                  if (verified)
                    const _HeroChip(
                      icon: Icons.verified_rounded,
                      text: "Verified",
                      color: Colors.blueAccent,
                    ),
                  if (creator)
                    const _HeroChip(
                      icon: Icons.workspace_premium_rounded,
                      text: "Creator",
                      color: C.orange,
                    ),
                  if (trusted)
                    const _HeroChip(
                      icon: Icons.shield_rounded,
                      text: "Trusted",
                      color: C.cyan,
                    ),
                  if (vip)
                    const _HeroChip(
                      icon: Icons.diamond_rounded,
                      text: "VIP",
                      color: Colors.purpleAccent,
                    ),
                  if (team)
                    const _HeroChip(
                      icon: Icons.bolt_rounded,
                      text: "Team",
                      color: C.green,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickGrid extends StatelessWidget {
  final List<_QuickAction> items;

  const _QuickGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, i) {
        final item = items[i];

        return GestureDetector(
          onTap: item.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: item.color.withOpacity(0.22)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: item.color),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12.5),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}

class _PremiumSheet extends StatelessWidget {
  final Widget child;
  final double maxHeight;
  final bool scrollable;

  const _PremiumSheet({
    required this.child,
    this.maxHeight = 0.78,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * maxHeight,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: C.bg,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: C.cyan.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: C.cyan.withOpacity(0.14),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: scrollable
          ? SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: child,
            )
          : child,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        14,
        14,
        MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      child: SafeArea(child: box),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SheetTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: Colors.white54, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, activeColor: color, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MainButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  const _MainButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: onTap,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : Icon(icon),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoBox({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _HeroChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  final VoidCallback onDelete;

  const _DangerZone({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Account löschen",
            style: TextStyle(color: Colors.redAccent, fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          const Text(
            "Dein Account wird deaktiviert und anschließend gelöscht.",
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.16),
              foregroundColor: Colors.redAccent,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text("Account löschen", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _SettingsInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _SettingsInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: C.cyan),
        filled: true,
        fillColor: C.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _OptionDropdown extends StatelessWidget {
  final String title;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  const _OptionDropdown({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.cyan.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: C.card,
            underline: const SizedBox.shrink(),
            items: items.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  final String text;

  const _MiniStatus({required this.text});

  @override
  Widget build(BuildContext context) {
    final color = text == "answered"
        ? C.green
        : text == "closed"
            ? Colors.white54
            : C.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _EmptySmall extends StatelessWidget {
  final String text;

  const _EmptySmall({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.cyan.withOpacity(0.14)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }
}