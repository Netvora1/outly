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

  @override
  void dispose() {
    supportSubject.dispose();
    supportMessage.dispose();
    super.dispose();
  }

  Future<void> resetPassword(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passwort Reset E-Mail gesendet")),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  Future<void> sendSupportTicket(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    supportSubject.clear();
    supportMessage.clear();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: C.cyan.withOpacity(0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Support kontaktieren",
                    style: TextStyle(
                      color: C.cyan,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: supportSubject,
                    decoration: const InputDecoration(
                      hintText: "Betreff",
                      prefixIcon: Icon(Icons.title, color: C.cyan),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: supportMessage,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: "Beschreib dein Problem...",
                      prefixIcon: Icon(Icons.support_agent, color: C.cyan),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.cyan,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text(
                      "Support Ticket senden",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final subject = supportSubject.text.trim();
                      final message = supportMessage.text.trim();

                      if (subject.isEmpty || message.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Bitte alles ausfüllen")),
                        );
                        return;
                      }

                      await FirebaseFirestore.instance.collection("support").add({
                        "uid": user.uid,
                        "email": user.email ?? "",
                        "subject": subject,
                        "message": message,
                        "status": "open",
                        "priority": "normal",
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
                        const SnackBar(content: Text("Support Ticket gesendet")),
                      );
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

  Future<void> deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        title: const Text("Account wirklich löschen?"),
        content: const Text(
          "Dein Account wird gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.",
        ),
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

    try {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "isDeleted": true,
        "deletedAt": Timestamp.now(),
        "email": user.email ?? "",
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

  bool canAccessAdmin(String role, String uid) {
    return uid == "roduqZRk4GgXLCQIZGIFAWN0UUg1" ||
        role == "owner" ||
        role == "admin" ||
        role == "moderator" ||
        role == "support";
  }

  Widget section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: C.cyan,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> openWeb(String url) async {
    final uri = Uri.parse(url);

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  return Scaffold(
    backgroundColor: C.bg,
    appBar: AppBar(
      backgroundColor: C.bg,
      elevation: 0,
      title: const Text("Einstellungen"),
    ),
    body: StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final username = data["username"] ?? "Outly User";
        final role = (data["role"] ?? "user").toString();
        final verified = data["verified"] == true;
        final creator = data["creator"] == true;
        final uid = user?.uid ?? "";
        final isAdmin = canAccessAdmin(role, uid);

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _SettingsHero(
              username: username,
              email: user?.email ?? "",
              role: role,
              verified: verified,
              creator: creator,
            ),

            if (isAdmin) ...[
              section("Outly Admin HQ"),
              SettingsTile(
                icon: Icons.admin_panel_settings,
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
              icon: Icons.key_rounded,
              color: C.cyan,
              title: "Passwort zurücksetzen",
              subtitle: "Reset Link per Mail erhalten",
              onTap: () => resetPassword(context),
            ),
            SettingsTile(
              icon: Icons.logout_rounded,
              color: Colors.orange,
              title: "Abmelden",
              subtitle: "Aus deinem Account ausloggen",
              onTap: () => logout(context),
            ),

            section("Support"),
            SettingsTile(
              icon: Icons.support_agent,
              color: C.cyan,
              title: "Support Ticket erstellen",
              subtitle: "Problem direkt an Outly melden",
              onTap: () => sendSupportTicket(context),
            ),
            SettingsTile(
              icon: Icons.public,
              color: C.purple2,
              title: "support.html öffnen",
              subtitle: "Offizielle Support Webseite",
              onTap: () => openWeb("https://outly.site/support.html"),
            ),
            SettingsTile(
              icon: Icons.bug_report_outlined,
              color: C.orange,
              title: "Bug melden",
              subtitle: "Fehler oder App-Probleme melden",
              onTap: () => sendSupportTicket(context),
            ),

            section("Sicherheit & Rechtliches"),
            SettingsTile(
              icon: Icons.security_rounded,
              color: Colors.greenAccent,
              title: "Sicherheit",
              subtitle: "Safety & Community Regeln",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalTextPage(
                      title: "Sicherheit",
                      text: securityText,
                    ),
                  ),
                );
              },
            ),
            SettingsTile(
              icon: Icons.privacy_tip_outlined,
              color: Colors.blueAccent,
              title: "Datenschutz",
              subtitle: "privacy.html / Datenschutzerklärung",
              onTap: () => openWeb("https://outly.site/privacy.html"),
            ),
            SettingsTile(
              icon: Icons.description_outlined,
              color: Colors.purpleAccent,
              title: "AGB",
              subtitle: "agb.html / Nutzungsbedingungen",
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
              icon: Icons.info_outline_rounded,
              color: Colors.white,
              title: "Über Outly",
              subtitle: "Version, Plattform & App Infos",
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

            section("Danger Zone"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Account löschen",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                    onPressed: () => deleteAccount(context),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text(
                      "Account löschen",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        );
      },
    ),
  );
}

class _SettingsHero extends StatelessWidget {
  final String username;
  final String email;
  final String role;
  final bool verified;
  final bool creator;

  const _SettingsHero({
    required this.username,
    required this.email,
    required this.role,
    required this.verified,
    required this.creator,
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
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A0826),
            Color(0xFF090E1A),
            Color(0xFF05060D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: C.cyan.withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: C.purple.withOpacity(0.30),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: C.cyan.withOpacity(0.12),
            blurRadius: 40,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -20,
            child: Icon(
              Icons.settings,
              size: 150,
              color: C.cyan.withOpacity(0.055),
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
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Control Center",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "@$username",
                style: const TextStyle(
                  color: C.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                      icon: Icons.verified,
                      text: "Verified",
                      color: Colors.blueAccent,
                    ),
                  if (creator)
                    const _HeroChip(
                      icon: Icons.workspace_premium,
                      text: "Creator",
                      color: C.orange,
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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 18,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}