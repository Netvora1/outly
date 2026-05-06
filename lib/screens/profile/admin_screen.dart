import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int tab = 0;

  final tabs = const [
    "Dashboard",
    "Support",
    "Reports",
    "User",
  ];

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
      },
      SetOptions(merge: true),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: C.cyan,
          fontSize: 21,
          fontWeight: FontWeight.bold,
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
        title: const Text("Admin Center"),
      ),
      body: Column(
        children: [
          Container(
            height: 52,
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final active = tab == i;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => tab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? C.cyan : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
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
                  ),
                );
              }),
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
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [
                    C.purple.withOpacity(0.55),
                    C.card,
                    C.cyan.withOpacity(0.18),
                  ],
                ),
                border: Border.all(color: C.cyan.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: C.cyan, size: 46),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Outly Kontrolle",
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Support, Reports, User und Rechte verwalten.",
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
                  title: "User",
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
                  title: "Reports offen",
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
              const AdminEmpty(text: "Keine Support-Anfragen.")
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final email = data["email"] ?? "Keine E-Mail";
                final message = data["message"] ?? "";
                final status = data["status"] ?? "open";
                final closed = status == "closed";

                return AdminActionCard(
                  color: closed ? C.green : C.orange,
                  icon: closed ? Icons.check_circle : Icons.support_agent,
                  title: closed ? "Erledigt" : "Offen",
                  subtitle: email,
                  body: message,
                  actions: [
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
            sectionTitle("Moderation / Reports"),
            if (docs.isEmpty)
              const AdminEmpty(text: "Keine Reports vorhanden.")
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final type = data["type"] ?? "report";
                final reason = data["reason"] ?? "";
                final targetUserId = data["targetUserId"] ?? "";
                final targetActivityId = data["targetActivityId"] ?? "";
                final status = data["status"] ?? "open";
                final closed = status == "closed";

                return AdminActionCard(
                  color: closed ? C.green : Colors.redAccent,
                  icon: Icons.flag_outlined,
                  title: "Report: $type",
                  subtitle: closed ? "Geschlossen" : "Offen",
                  body:
                      "Grund: $reason\nUser: $targetUserId\nActivity: $targetActivityId",
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
                        child: const Text("User bannen"),
                      ),
                    ElevatedButton(
                      onPressed: () => doc.reference.delete(),
                      child: const Text("Report löschen"),
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
            sectionTitle("User Verwaltung"),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final username = data["username"] ?? "user";
              final email = data["email"] ?? "";
              final banned = data["isBanned"] == true;
              final verified = data["verified"] == true;
              final creator = data["creator"] == true;
              final reports = data["reportedCount"] ?? 0;
              final trust = data["trustScore"] ?? 100;

              return AdminActionCard(
                color: banned ? Colors.redAccent : C.cyan,
                icon: banned ? Icons.block : Icons.person,
                title: "@$username",
                subtitle: email,
                body:
                    "UID: ${doc.id}\nReports: $reports\nSafety: $trust/100\nVerified: ${verified ? "ja" : "nein"}\nCreator: ${creator ? "ja" : "nein"}",
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      updateUser(doc.id, {"verified": !verified});
                    },
                    child: Text(verified ? "Unverify" : "Verify"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      updateUser(doc.id, {
                        "creator": !creator,
                        "creatorLevel": !creator ? "starter" : "none",
                      });
                    },
                    child: Text(creator ? "Creator weg" : "Creator"),
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