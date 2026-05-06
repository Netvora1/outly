import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_colors.dart';
import '../../core/legal_texts.dart';
import '../../core/admin_utils.dart';

import '../legal/legal_text_page.dart';
import 'admin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pop(context);
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

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        title: const Text("Einstellungen"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  C.purple.withOpacity(0.5),
                  C.card,
                  C.cyan.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: C.cyan.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [C.purple, C.cyan]),
                  ),
                  child: const Icon(Icons.settings, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Outly Settings",
                        style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isAdminUser()) ...[
            section("Admin"),
            SettingsTile(
              icon: Icons.admin_panel_settings,
              color: Colors.amber,
              title: "Admin Panel",
              subtitle: "Reports, User & Safety verwalten",
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

          section("Sicherheit"),
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
            icon: Icons.lock_outline_rounded,
            color: Colors.blueAccent,
            title: "Datenschutz",
            subtitle: "Wie deine Daten genutzt werden",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalTextPage(
                    title: "Datenschutz",
                    text: privacyText,
                  ),
                ),
              );
            },
          ),

          section("Rechtliches"),
          SettingsTile(
            icon: Icons.description_outlined,
            color: Colors.purpleAccent,
            title: "Nutzungsbedingungen",
            subtitle: "AGB & Plattform Regeln",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalTextPage(
                    title: "AGB",
                    text: termsText,
                  ),
                ),
              );
            },
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
            subtitle: "Version & Plattform Infos",
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.12),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            onPressed: () {},
            icon: const Icon(Icons.delete_forever),
            label: const Text(
              "Account löschen",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 40),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
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