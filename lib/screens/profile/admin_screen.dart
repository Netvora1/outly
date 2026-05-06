import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late int tab;

  final broadcastTitle = TextEditingController();
  final broadcastMessage = TextEditingController();

  bool sendingBroadcast = false;

  final tabs = const [
    "Dashboard",
    "Support",
    "Meldungen",
    "Nutzer",
    "Events",
    "Broadcast",
  ];

  @override
  void initState() {
    super.initState();
    tab = widget.initialTab;
  }

  @override
  void dispose() {
    broadcastTitle.dispose();
    broadcastMessage.dispose();
    super.dispose();
  }

  Future<int> count(String col) async {
    final snap = await FirebaseFirestore.instance.collection(col).get();
    return snap.docs.length;
  }

  Future<int> countOpen(String col) async {
    final snap = await FirebaseFirestore.instance
        .collection(col)
        .where("status", isEqualTo: "open")
        .get();

    return snap.docs.length;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).set(
      {
        ...data,
        "updatedAt": Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> closeDoc(DocumentReference ref) async {
    await ref.set(
      {
        "status": "closed",
        "closedAt": Timestamp.now(),
        "updatedAt": Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateDoc(DocumentReference ref, Map<String, dynamic> data) async {
    await ref.set(
      {
        ...data,
        "updatedAt": Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteEvent(String id) async {
    await FirebaseFirestore.instance.collection("activities").doc(id).delete();
  }

  Future<void> sendBroadcastToAllUsers() async {
    final title = broadcastTitle.text.trim();
    final message = broadcastMessage.text.trim();

    if (title.isEmpty || message.isEmpty || sendingBroadcast) return;

    setState(() => sendingBroadcast = true);

    try {
      final usersSnap = await FirebaseFirestore.instance.collection("users").get();
      final batch = FirebaseFirestore.instance.batch();

      for (final userDoc in usersSnap.docs) {
        final data = userDoc.data();

        if (data["isBanned"] == true || data["isDeleted"] == true) continue;

        final ref = FirebaseFirestore.instance.collection("notifications").doc();

        batch.set(ref, {
          "toUserId": userDoc.id,
          "fromUserId": "admin",
          "type": "admin",
          "title": title,
          "text": message,
          "targetId": "",
          "read": false,
          "createdAt": Timestamp.now(),
        });
      }

      await batch.commit();

      await FirebaseFirestore.instance.collection("adminLogs").add({
        "action": "broadcast_sent",
        "title": title,
        "message": message,
        "createdAt": Timestamp.now(),
      });

      broadcastTitle.clear();
      broadcastMessage.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nachricht an alle Nutzer gesendet")),
      );
    } catch (e) {
      debugPrint("Broadcast Fehler: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Broadcast konnte nicht gesendet werden")),
      );
    } finally {
      if (mounted) setState(() => sendingBroadcast = false);
    }
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: C.cyan,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget adminChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        title: const Text(
          "Outly Admin Bereich",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 58,
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: C.cyan.withOpacity(0.14)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, i) {
                final active = tab == i;

                return GestureDetector(
                  onTap: () => setState(() => tab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? C.cyan : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: C.cyan.withOpacity(0.28),
                                blurRadius: 16,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        color: active ? Colors.black : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: tab,
              children: [
                dashboard(),
                support(),
                reports(),
                users(),
                events(),
                broadcast(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget dashboard() {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        count("users"),
        count("activities"),
        countOpen("support"),
        countOpen("reports"),
      ]),
      builder: (context, snap) {
        final data = snap.data ?? [0, 0, 0, 0];

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: LinearGradient(
                  colors: [
                    C.purple.withOpacity(0.65),
                    C.card,
                    C.cyan.withOpacity(0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: C.cyan.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: C.cyan.withOpacity(0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: C.cyan, size: 48),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Kontrollzentrum",
                          style: TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Nutzer, Events, Support und Meldungen verwalten.",
                          style: TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                AdminStatCard(
                  title: "Nutzer",
                  value: "${data[0]}",
                  icon: Icons.people_alt,
                  color: C.cyan,
                ),
                AdminStatCard(
                  title: "Events",
                  value: "${data[1]}",
                  icon: Icons.local_fire_department,
                  color: C.orange,
                ),
                AdminStatCard(
                  title: "Support offen",
                  value: "${data[2]}",
                  icon: Icons.support_agent,
                  color: C.green,
                ),
                AdminStatCard(
                  title: "Meldungen offen",
                  value: "${data[3]}",
                  icon: Icons.flag,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget support() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("support")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: C.cyan));
        }

        final docs = snap.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            sectionTitle("Support Tickets"),
            if (docs.isEmpty)
              const AdminEmpty(text: "Keine Support-Anfragen vorhanden.")
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final email = data["email"] ?? "Keine E-Mail";
                final subject = data["subject"] ?? "Kein Betreff";
                final message = data["message"] ?? "";
                final status = data["status"] ?? "open";
                final priority = data["priority"] ?? "normal";
                final closed = status == "closed";

                return AdminActionCard(
                  color: closed ? C.green : C.orange,
                  icon: closed ? Icons.check_circle : Icons.support_agent,
                  title: subject,
                  subtitle: "$email • Status: $status • Priorität: $priority",
                  body: message,
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        updateDoc(doc.reference, {"status": "reviewing"});
                      },
                      child: const Text("Prüfen"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        updateDoc(doc.reference, {"priority": "urgent"});
                      },
                      child: const Text("Dringend"),
                    ),
                    if (!closed)
                      ElevatedButton(
                        onPressed: () => closeDoc(doc.reference),
                        child: const Text("Erledigen"),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => doc.reference.delete(),
                      child: const Text("Löschen"),
                    ),
                  ],
                );
              }),
          ],
        );
      },
    );
  }

  Widget reports() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("reports")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: C.cyan));
        }

        final docs = snap.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            sectionTitle("Meldungen & Moderation"),
            if (docs.isEmpty)
              const AdminEmpty(text: "Keine Meldungen vorhanden.")
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final type = data["type"] ?? "Meldung";
                final reason = data["reason"] ?? "";
                final targetUserId = data["targetUserId"] ?? "";
                final targetActivityId = data["targetActivityId"] ?? "";
                final status = data["status"] ?? "open";
                final closed = status == "closed";

                return AdminActionCard(
                  color: closed ? C.green : Colors.redAccent,
                  icon: Icons.flag_outlined,
                  title: "Meldung: $type",
                  subtitle: closed ? "Geschlossen" : "Offen",
                  body:
                      "Grund: $reason\nNutzer: $targetUserId\nEvent: $targetActivityId",
                  actions: [
                    if (!closed)
                      ElevatedButton(
                        onPressed: () => closeDoc(doc.reference),
                        child: const Text("Schließen"),
                      ),
                    if (targetUserId.toString().isNotEmpty)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          updateUser(targetUserId, {"isBanned": true});
                        },
                        child: const Text("Nutzer bannen"),
                      ),
                    if (targetActivityId.toString().isNotEmpty)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => deleteEvent(targetActivityId),
                        child: const Text("Event löschen"),
                      ),
                    ElevatedButton(
                      onPressed: () => doc.reference.delete(),
                      child: const Text("Meldung löschen"),
                    ),
                  ],
                );
              }),
          ],
        );
      },
    );
  }

  Widget users() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: C.cyan));
        }

        final docs = snap.data!.docs.toList();

        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final db = b.data() as Map<String, dynamic>;
          final ra = da["reportedCount"] ?? 0;
          final rb = db["reportedCount"] ?? 0;
          return rb.compareTo(ra);
        });

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            sectionTitle("Nutzer Verwaltung"),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final username = data["username"] ?? "user";
              final email = data["email"] ?? "";
              final banned = data["isBanned"] == true;
              final verified = data["verified"] == true;
              final creator = data["creator"] == true;
              final reports = data["reportedCount"] ?? 0;
              final trust = data["trustScore"] ?? 100;
              final role = data["role"] ?? "user";

              return AdminActionCard(
                color: banned ? Colors.redAccent : C.cyan,
                icon: banned ? Icons.block : Icons.person,
                title: "@$username",
                subtitle: "$email • Rolle: $role",
                body:
                    "UID: ${doc.id}\nMeldungen: $reports\nSafety: $trust/100\nVerifiziert: ${verified ? "ja" : "nein"}\nCreator: ${creator ? "ja" : "nein"}",
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      updateUser(doc.id, {"verified": !verified});
                    },
                    child: Text(verified ? "Nicht verifizieren" : "Verifizieren"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      updateUser(doc.id, {
                        "creator": !creator,
                        "creatorLevel": !creator ? "starter" : "none",
                      });
                    },
                    child: Text(creator ? "Creator entfernen" : "Creator geben"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showRoleSheet(doc.id, role.toString());
                    },
                    child: const Text("Rolle ändern"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: banned ? C.green : Colors.redAccent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      updateUser(doc.id, {"isBanned": !banned});
                    },
                    child: Text(banned ? "Entsperren" : "Bannen"),
                  ),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  void showRoleSheet(String uid, String currentRole) {
    final roles = ["user", "support", "moderator", "admin"];

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
                const Text(
                  "Rolle ändern",
                  style: TextStyle(
                    color: C.cyan,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                ...roles.map((role) {
                  final active = currentRole == role;

                  return ListTile(
                    title: Text(
                      role == "user"
                          ? "Nutzer"
                          : role == "support"
                              ? "Support"
                              : role == "moderator"
                                  ? "Moderator"
                                  : "Admin",
                    ),
                    trailing: active
                        ? const Icon(Icons.check_circle, color: C.cyan)
                        : null,
                    onTap: () async {
                      await updateUser(uid, {"role": role});
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget events() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("activities")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: C.cyan));
        }

        final docs = snap.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            sectionTitle("Events verwalten"),
            if (docs.isEmpty)
              const AdminEmpty(text: "Keine Events vorhanden.")
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = data["title"] ?? "Event";
                final place = data["place"] ?? "";
                final category = data["category"] ?? "";
                final creatorId = data["creatorId"] ?? "";
                final reports = data["reportedCount"] ?? 0;
                final hidden = data["hidden"] == true;
                final featured = data["featured"] == true;

                return AdminActionCard(
                  color: reports > 0 ? Colors.redAccent : C.orange,
                  icon: Icons.local_fire_department,
                  title: title,
                  subtitle: "$category • $place",
                  body:
                      "ID: ${doc.id}\nCreator: $creatorId\nMeldungen: $reports\nVersteckt: ${hidden ? "ja" : "nein"}\nFeatured: ${featured ? "ja" : "nein"}",
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        updateDoc(doc.reference, {"featured": !featured});
                      },
                      child: Text(featured ? "Featured entfernen" : "Featured"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        updateDoc(doc.reference, {"hidden": !hidden});
                      },
                      child: Text(hidden ? "Einblenden" : "Verstecken"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => deleteEvent(doc.id),
                      child: const Text("Löschen"),
                    ),
                  ],
                );
              }),
          ],
        );
      },
    );
  }

  Widget broadcast() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        sectionTitle("Nachricht an alle Nutzer"),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: C.cyan.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: C.cyan.withOpacity(0.08),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.campaign, color: C.cyan, size: 34),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Broadcast senden",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: broadcastTitle,
                decoration: const InputDecoration(
                  hintText: "Titel z.B. Neue Funktion verfügbar",
                  prefixIcon: Icon(Icons.title, color: C.cyan),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: broadcastMessage,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Nachricht an alle Nutzer...",
                  prefixIcon: Icon(Icons.message_outlined, color: C.cyan),
                ),
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
                onPressed: sendingBroadcast ? null : sendBroadcastToAllUsers,
                icon: sendingBroadcast
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  sendingBroadcast ? "Wird gesendet..." : "An alle senden",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "Diese Nachricht erscheint bei allen aktiven Nutzern in den Benachrichtigungen.",
          style: TextStyle(color: Colors.white54),
        ),
      ],
    );
  }
}

class AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }
}

class AdminActionCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final List<Widget> actions;

  const AdminActionCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.16),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
        ],
      ),
    );
  }
}

class AdminEmpty extends StatelessWidget {
  final String text;

  const AdminEmpty({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white60),
      ),
    );
  }
}