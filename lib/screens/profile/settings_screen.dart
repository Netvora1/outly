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

  final feedbackSubject = TextEditingController();
  final feedbackMessage = TextEditingController();

  bool sending = false;

  @override
  void dispose() {
    supportSubject.dispose();
    supportMessage.dispose();
    feedbackSubject.dispose();
    feedbackMessage.dispose();
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
            child: const Text(
              "Bestätigen",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    return result == true;
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
        const SnackBar(
          content: Text("Bitte neu einloggen und dann erneut löschen."),
        ),
      );
    }
  }

  Future<void> createSupportTicket({
    required BuildContext context,
    required String type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    supportSubject.clear();
    supportMessage.clear();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            14,
            14,
            14,
            MediaQuery.of(context).viewInsets.bottom + 14,
          ),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: C.cyan.withOpacity(0.25)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 18),
                    Text(
                      type == "bug"
                          ? "Bug melden"
                          : type == "feedback"
                              ? "Feedback senden"
                              : "Support kontaktieren",
                      style: const TextStyle(
                        color: C.cyan,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsInput(
                      controller: supportSubject,
                      hint: "Betreff",
                      icon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 12),
                    _SettingsInput(
                      controller: supportMessage,
                      hint: "Beschreib es genau...",
                      icon: Icons.support_agent_rounded,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.cyan,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text(
                        "Senden",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      onPressed: sending
                          ? null
                          : () async {
                              final subject = supportSubject.text.trim();
                              final message = supportMessage.text.trim();

                              if (subject.isEmpty || message.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Bitte alles ausfüllen"),
                                  ),
                                );
                                return;
                              }

                              setState(() => sending = true);

                              try {
                                await FirebaseFirestore.instance
                                    .collection("support")
                                    .add({
                                  "uid": user.uid,
                                  "email": user.email ?? "",
                                  "type": type,
                                  "subject": subject,
                                  "message": message,
                                  "status": "open",
                                  "priority": type == "bug" ? "urgent" : "normal",
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
                                  const SnackBar(
                                    content: Text("Ticket gesendet ✅"),
                                  ),
                                );
                              } finally {
                                if (mounted) setState(() => sending = false);
                              }
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

  void openPrivacySheet(Map<String, dynamic> data) {
    final contact = (data["privacyContact"] ?? "friends").toString();
    final profile = (data["privacyProfile"] ?? "public").toString();
    final events = (data["privacyEvents"] ?? "public").toString();
    final location = data["nearbyEnabled"] != false;

    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      builder: (_) {
        String contactValue = contact;
        String profileValue = profile;
        String eventsValue = events;
        bool locationValue = location;

        return StatefulBuilder(
          builder: (context, setSheet) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 16),
                    const Text(
                      "Privatsphäre",
                      style: TextStyle(
                        color: C.cyan,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _OptionDropdown(
                      title: "Wer darf mich kontaktieren?",
                      value: contactValue,
                      items: const {
                        "all": "Alle",
                        "friends": "Nur Freunde",
                        "none": "Niemand",
                      },
                      onChanged: (v) => setSheet(() => contactValue = v),
                    ),
                    _OptionDropdown(
                      title: "Wer darf mein Profil sehen?",
                      value: profileValue,
                      items: const {
                        "public": "Alle",
                        "friends": "Nur Freunde",
                        "private": "Privat",
                      },
                      onChanged: (v) => setSheet(() => profileValue = v),
                    ),
                    _OptionDropdown(
                      title: "Wer darf meine Events sehen?",
                      value: eventsValue,
                      items: const {
                        "public": "Alle",
                        "followers": "Follower",
                        "private": "Privat",
                      },
                      onChanged: (v) => setSheet(() => eventsValue = v),
                    ),
                    SwitchListTile(
                      value: locationValue,
                      activeColor: C.cyan,
                      title: const Text("Nähe / Standort aktiv"),
                      subtitle: const Text(
                        "Events in deiner Nähe anzeigen",
                        style: TextStyle(color: Colors.white54),
                      ),
                      onChanged: (v) => setSheet(() => locationValue = v),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.cyan,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      onPressed: () async {
                        await updateUserSettings({
                          "privacyContact": contactValue,
                          "privacyProfile": profileValue,
                          "privacyEvents": eventsValue,
                          "nearbyEnabled": locationValue,
                        });

                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text("Speichern"),
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

  void openNotificationSheet(Map<String, dynamic> data) {
    bool push = data["notifyPush"] != false;
    bool events = data["notifyEvents"] != false;
    bool chats = data["notifyChats"] != false;
    bool social = data["notifySocial"] != false;
    bool support = data["notifySupport"] != false;

    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 16),
                    const Text(
                      "Benachrichtigungen",
                      style: TextStyle(
                        color: C.cyan,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      value: push,
                      activeColor: C.cyan,
                      title: const Text("Push Benachrichtigungen"),
                      onChanged: (v) => setSheet(() => push = v),
                    ),
                    SwitchListTile(
                      value: events,
                      activeColor: C.orange,
                      title: const Text("Event Updates"),
                      onChanged: (v) => setSheet(() => events = v),
                    ),
                    SwitchListTile(
                      value: chats,
                      activeColor: C.pink,
                      title: const Text("Chat Nachrichten"),
                      onChanged: (v) => setSheet(() => chats = v),
                    ),
                    SwitchListTile(
                      value: social,
                      activeColor: C.purple,
                      title: const Text("Follower / Likes"),
                      onChanged: (v) => setSheet(() => social = v),
                    ),
                    SwitchListTile(
                      value: support,
                      activeColor: C.green,
                      title: const Text("Support Antworten"),
                      onChanged: (v) => setSheet(() => support = v),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.cyan,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      onPressed: () async {
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
                      child: const Text("Speichern"),
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

  void openBlockedUsersSheet(Map<String, dynamic> data) {
    final blocked = List<String>.from(data["blockedUsers"] ?? []);

    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 16),
                const Text(
                  "Blockierte Nutzer",
                  style: TextStyle(
                    color: C.cyan,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                if (blocked.isEmpty)
                  const _EmptySmall(text: "Du hast aktuell niemanden blockiert.")
                else
                  ...blocked.map((uid) {
                    return ListTile(
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
                    );
                  }),
              ],
            ),
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
      backgroundColor: C.bg,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 16),
                  const Text(
                    "Meine Support Tickets",
                    style: TextStyle(
                      color: C.cyan,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
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
                          return const Center(
                            child: CircularProgressIndicator(color: C.cyan),
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
                          return const _EmptySmall(
                            text: "Noch keine Tickets vorhanden.",
                          );
                        }

                        return ListView(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final subject = data["subject"] ?? "Ticket";
                            final status = data["status"] ?? "open";
                            final message = data["message"] ?? "";
                            final reply = data["adminReply"] ?? "";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: C.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: status == "answered"
                                      ? C.green.withOpacity(0.35)
                                      : C.cyan.withOpacity(0.18),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Status: $status",
                                    style: const TextStyle(color: C.cyan),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    message.toString(),
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  if (reply.toString().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: C.green.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: C.green.withOpacity(0.25),
                                        ),
                                      ),
                                      child: Text(
                                        "Antwort: $reply",
                                        style: const TextStyle(color: Colors.white70),
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
            ),
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
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user?.uid)
            .snapshots(),
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
                    onTap: () => Navigator.pop(context),
                  ),
                  _QuickAction(
                    icon: Icons.support_agent_rounded,
                    label: "Support",
                    color: C.green,
                    onTap: () => createSupportTicket(
                      context: context,
                      type: "support",
                    ),
                  ),
                  _QuickAction(
                    icon: Icons.privacy_tip_rounded,
                    label: "Privacy",
                    color: Colors.blueAccent,
                    onTap: () => openPrivacySheet(data),
                  ),
                  if (isAdmin)
                    _QuickAction(
                      icon: Icons.admin_panel_settings_rounded,
                      label: "Admin",
                      color: Colors.amber,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminScreen(),
                          ),
                        );
                      },
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
                subtitle: "Name, Bio, Profilbild und Vibes im Profil ändern",
                onTap: () => Navigator.pop(context),
              ),
              SettingsTile(
                icon: Icons.email_rounded,
                color: C.purple,
                title: "E-Mail",
                subtitle: user?.email ?? "Keine E-Mail",
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.key_rounded,
                color: C.orange,
                title: "Passwort zurücksetzen",
                subtitle: "Reset Link per Mail erhalten",
                onTap: () => resetPassword(context),
              ),

              section("Safety & Privacy"),
              SettingsTile(
                icon: Icons.block_rounded,
                color: Colors.redAccent,
                title: "Blockierte Nutzer",
                subtitle: "Nutzer entblocken und verwalten",
                onTap: () => openBlockedUsersSheet(data),
              ),
              SettingsTile(
                icon: Icons.lock_rounded,
                color: Colors.blueAccent,
                title: "Privatsphäre",
                subtitle: "Profil, Kontakt und Event Sichtbarkeit",
                onTap: () => openPrivacySheet(data),
              ),
              SettingsTile(
                icon: Icons.location_on_rounded,
                color: C.green,
                title: "Standort & Nähe",
                subtitle: data["nearbyEnabled"] == false
                    ? "Nähe ist deaktiviert"
                    : "Events in deiner Nähe aktiv",
                onTap: () => openPrivacySheet(data),
              ),
              SettingsTile(
                icon: Icons.shield_rounded,
                color: C.cyan,
                title: "Safety Center",
                subtitle: "Sicherheit, Community Regeln und Verhalten",
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
                title: "Notification Einstellungen",
                subtitle: "Push, Events, Chats, Likes und Support",
                onTap: () => openNotificationSheet(data),
              ),

              section("Support & Hilfe"),
              SettingsTile(
                icon: Icons.support_agent_rounded,
                color: C.green,
                title: "Support Ticket erstellen",
                subtitle: "Problem direkt an Outly senden",
                onTap: () => createSupportTicket(
                  context: context,
                  type: "support",
                ),
              ),
              SettingsTile(
                icon: Icons.confirmation_number_rounded,
                color: C.cyan,
                title: "Meine Support Tickets",
                subtitle: "Antworten und Status ansehen",
                onTap: openSupportTickets,
              ),
              SettingsTile(
                icon: Icons.bug_report_rounded,
                color: C.orange,
                title: "Bug melden",
                subtitle: "Fehler oder App-Probleme melden",
                onTap: () => createSupportTicket(
                  context: context,
                  type: "bug",
                ),
              ),
              SettingsTile(
                icon: Icons.feedback_rounded,
                color: C.purple,
                title: "Feedback senden",
                subtitle: "Ideen, Wünsche und Verbesserungen",
                onTap: () => createSupportTicket(
                  context: context,
                  type: "feedback",
                ),
              ),
              SettingsTile(
                icon: Icons.public_rounded,
                color: C.purple2,
                title: "Support Webseite",
                subtitle: "outly.site/support.html",
                onTap: () => openWeb("https://outly.site/support.html"),
              ),

              section("Rechtliches"),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                color: Colors.blueAccent,
                title: "Datenschutz",
                subtitle: "outly.site/privacy.html",
                onTap: () => openWeb("https://outly.site/privacy.html"),
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                color: Colors.purpleAccent,
                title: "Nutzungsbedingungen",
                subtitle: "AGB / Terms",
                onTap: () => openWeb("https://outly.site/agb.html"),
              ),
              SettingsTile(
                icon: Icons.gavel_rounded,
                color: Colors.redAccent,
                title: "Impressum",
                subtitle: "Unternehmensinformationen",
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
                subtitle: "Version 1.0.0 • Outly",
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

              _DangerZone(
                onDelete: () => deleteAccount(context),
              ),
            ],
          );
        },
      ),
    );
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
                "Settings Hub",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12.5),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white38,
        ),
        onTap: onTap,
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
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
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
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text(
              "Account löschen",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
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
      decoration: InputDecoration(
        hintText: hint,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.cyan.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(999),
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