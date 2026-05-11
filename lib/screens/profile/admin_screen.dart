import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_colors.dart';
import '../home/home_screen.dart';
import '../profile/user_profile_screen.dart';

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
  final searchUser = TextEditingController();

  bool sendingBroadcast = false;
  String userSearch = "";

  final tabs = const [
    "Dashboard",
    "Support",
    "Reports",
    "User",
    "Events",
    "Momente",
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
    searchUser.dispose();
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
    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      ...data,
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> updateDoc(DocumentReference ref, Map<String, dynamic> data) async {
    await ref.set({
      ...data,
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> closeDoc(DocumentReference ref) async {
    await ref.set({
      "status": "closed",
      "closedAt": Timestamp.now(),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDoc(DocumentReference ref) async {
    await ref.delete();
  }

  void openUser(String uid) {
    if (uid.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: uid),
      ),
    );
  }

  void openEvent(String eventId) {
    if (eventId.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activityId: eventId),
      ),
    );
  }

  Future<bool> confirm(String title, String text) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        title: const Text(
          "Outly Admin Control",
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
                moments(),
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
        count("moments"),
        countOpen("support"),
        countOpen("reports"),
      ]),
      builder: (context, snap) {
        final data = snap.data ?? [0, 0, 0, 0, 0];

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
                          "Alles verwalten: User, Events, Reports, Support und Momente.",
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
                  title: "Momente",
                  value: "${data[2]}",
                  icon: Icons.photo_library_rounded,
                  color: C.pink,
                ),
                AdminStatCard(
                  title: "Support offen",
                  value: "${data[3]}",
                  icon: Icons.support_agent,
                  color: C.green,
                ),
                AdminStatCard(
                  title: "Reports offen",
                  value: "${data[4]}",
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
      stream: FirebaseFirestore.instance.collection("support").snapshots(),
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
          if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
          return 0;
        });

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            sectionTitle("Support Tickets"),
            if (docs.isEmpty)
              const AdminEmpty(text: "Keine Support-Anfragen vorhanden.")
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final uid = (data["uid"] ?? data["userId"] ?? "").toString();
                final email = (data["email"] ?? "Keine E-Mail").toString();
                final subject = (data["subject"] ?? "Kein Betreff").toString();
                final message = (data["message"] ?? "").toString();
                final status = (data["status"] ?? "open").toString();
                final priority = (data["priority"] ?? "normal").toString();
                final adminReply = (data["adminReply"] ?? "").toString();
                final closed = status == "closed";

                return AdminActionCard(
                  color: closed ? C.green : C.orange,
                  icon: closed ? Icons.check_circle : Icons.support_agent,
                  title: subject,
                  subtitle: "$email • $status • $priority",
                  body:
                      "$message\n\nUser: $uid${adminReply.isNotEmpty ? "\n\nAntwort: $adminReply" : ""}",
                  actions: [
                    ElevatedButton(
                      onPressed: uid.isEmpty ? null : () => openUser(uid),
                      child: const Text("User öffnen"),
                    ),
                    ElevatedButton(
                      onPressed: () => updateDoc(doc.reference, {
                        "status": "reviewing",
                      }),
                      child: const Text("Prüfen"),
                    ),
                    ElevatedButton(
                      onPressed: () => updateDoc(doc.reference, {
                        "priority": "urgent",
                      }),
                      child: const Text("Dringend"),
                    ),
                    ElevatedButton(
                      onPressed: () => showSupportReplySheet(doc.reference, uid),
                      child: const Text("Antworten"),
                    ),
                    if (!closed)
                      ElevatedButton(
                        onPressed: () => closeDoc(doc.reference),
                        child: const Text("Schließen"),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final ok = await confirm(
                          "Ticket löschen?",
                          "Dieses Support Ticket wird gelöscht.",
                        );
                        if (ok) deleteDoc(doc.reference);
                      },
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

  void showSupportReplySheet(DocumentReference ref, String uid) {
    final reply = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Support Antwort",
                  style: TextStyle(
                    color: C.cyan,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reply,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: "Antwort schreiben...",
                    prefixIcon: Icon(Icons.reply_rounded, color: C.cyan),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.cyan,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: () async {
                    final text = reply.text.trim();
                    if (text.isEmpty) return;

                    await updateDoc(ref, {
                      "adminReply": text,
                      "status": "answered",
                    });

                    if (uid.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection("notifications")
                          .add({
                        "toUserId": uid,
                        "fromUserId": "admin",
                        "type": "admin",
                        "title": "Support Antwort",
                        "text": text,
                        "targetId": "",
                        "read": false,
                        "createdAt": Timestamp.now(),
                      });
                    }

                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text("Antwort senden"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget reports() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("reports").snapshots(),
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
          if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
          return 0;
        });

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            sectionTitle("Reports & Moderation"),
            if (docs.isEmpty)
              const AdminEmpty(text: "Keine Meldungen vorhanden.")
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final type = (data["type"] ?? "report").toString();
                final reason = (data["reason"] ?? "").toString();
                final reportedBy = (data["reportedBy"] ?? "").toString();
                final targetUserId = (data["targetUserId"] ?? "").toString();
                final targetActivityId = (data["targetActivityId"] ?? "").toString();
                final targetMomentId = (data["targetMomentId"] ?? "").toString();
                final status = (data["status"] ?? "open").toString();
                final closed = status == "closed";

                return AdminActionCard(
                  color: closed ? C.green : Colors.redAccent,
                  icon: Icons.flag_outlined,
                  title: "Report: $type",
                  subtitle: closed ? "Geschlossen" : "Offen",
                  body:
                      "Grund: $reason\nGemeldet von: $reportedBy\nUser: $targetUserId\nEvent: $targetActivityId\nMoment: $targetMomentId",
                  actions: [
                    ElevatedButton(
                      onPressed: reportedBy.isEmpty ? null : () => openUser(reportedBy),
                      child: const Text("Reporter"),
                    ),
                    ElevatedButton(
                      onPressed: targetUserId.isEmpty ? null : () => openUser(targetUserId),
                      child: const Text("User öffnen"),
                    ),
                    ElevatedButton(
                      onPressed: targetActivityId.isEmpty
                          ? null
                          : () => openEvent(targetActivityId),
                      child: const Text("Event öffnen"),
                    ),
                    if (targetActivityId.isNotEmpty)
                      ElevatedButton(
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection("activities")
                              .doc(targetActivityId)
                              .set({
                            "hidden": true,
                            "updatedAt": Timestamp.now(),
                          }, SetOptions(merge: true));
                        },
                        child: const Text("Event verstecken"),
                      ),
                    if (targetUserId.isNotEmpty)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => updateUser(targetUserId, {
                          "isBanned": true,
                        }),
                        child: const Text("User bannen"),
                      ),
                    if (!closed)
                      ElevatedButton(
                        onPressed: () => closeDoc(doc.reference),
                        child: const Text("Schließen"),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
          child: TextField(
            controller: searchUser,
            onChanged: (v) => setState(() => userSearch = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: "User suchen: Name, E-Mail oder UID...",
              prefixIcon: Icon(Icons.search, color: C.cyan),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("users").snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }

              final docs = snap.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final q = userSearch;

                if (q.isEmpty) return true;

                final username = (data["username"] ?? "").toString().toLowerCase();
                final email = (data["email"] ?? "").toString().toLowerCase();
                final uid = doc.id.toLowerCase();

                return username.contains(q) || email.contains(q) || uid.contains(q);
              }).toList();

              docs.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final db = b.data() as Map<String, dynamic>;
                final ra = da["reportedCount"] ?? 0;
                final rb = db["reportedCount"] ?? 0;
                return rb.compareTo(ra);
              });

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                children: [
                  sectionTitle("User Verwaltung"),
                  if (docs.isEmpty)
                    const AdminEmpty(text: "Kein User gefunden.")
                  else
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final username = (data["username"] ?? "user").toString();
                      final email = (data["email"] ?? "").toString();
                      final banned = data["isBanned"] == true;
                      final verified = data["verified"] == true;
                      final creator = data["creator"] == true;
                      final company = data["company"] == true || data["partner"] == true;
                      final trusted = data["trusted"] == true;
                      final vip = data["vip"] == true;
                      final team = data["team"] == true;
                      final reports = data["reportedCount"] ?? 0;
                      final trust = data["trustScore"] ?? 100;
                      final role = (data["role"] ?? "user").toString();

                      return AdminActionCard(
                        color: banned ? Colors.redAccent : C.cyan,
                        icon: banned ? Icons.block : Icons.person,
                        title: "@$username",
                        subtitle: "$email • Rolle: $role",
                        body:
                            "UID: ${doc.id}\nReports: $reports\nSafety: $trust/100\nVerified: ${verified ? "ja" : "nein"}\nCreator: ${creator ? "ja" : "nein"}\nFirma: ${company ? "ja" : "nein"}\nTrusted: ${trusted ? "ja" : "nein"}\nVIP: ${vip ? "ja" : "nein"}\nTeam: ${team ? "ja" : "nein"}",
                        actions: [
                          ElevatedButton(
                            onPressed: () => openUser(doc.id),
                            child: const Text("Profil"),
                          ),
                          ElevatedButton(
                            onPressed: () => showRoleSheet(doc.id, role),
                            child: const Text("Rolle"),
                          ),
                          ElevatedButton(
                            onPressed: () => showBadgeSheet(doc.id, data),
                            child: const Text("Badges"),
                          ),
                          ElevatedButton(
                            onPressed: () => showTrustSheet(doc.id, trust),
                            child: const Text("Trust"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: banned ? C.green : Colors.redAccent,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () => updateUser(doc.id, {
                              "isBanned": !banned,
                            }),
                            child: Text(banned ? "Entbannen" : "Bannen"),
                          ),
                        ],
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void showRoleSheet(String uid, String currentRole) {
    final roles = ["user", "support", "moderator", "admin", "owner"];

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
                    title: Text(role),
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

  void showBadgeSheet(String uid, Map<String, dynamic> data) {
    final badges = {
      "verified": "Blauer Haken",
      "creator": "Creator",
      "company": "Firma",
      "partner": "Partner",
      "trusted": "Trusted",
      "vip": "VIP",
      "team": "Outly Team",
    };

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
                  "Badges verwalten",
                  style: TextStyle(
                    color: C.cyan,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                ...badges.entries.map((entry) {
                  final active = data[entry.key] == true;

                  return SwitchListTile(
                    value: active,
                    activeColor: C.cyan,
                    title: Text(entry.value),
                    onChanged: (v) {
                      updateUser(uid, {entry.key: v});
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

  void showTrustSheet(String uid, dynamic currentTrust) {
    final controller = TextEditingController(text: "$currentTrust");

    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "TrustScore ändern",
                  style: TextStyle(
                    color: C.cyan,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "0 - 100",
                    prefixIcon: Icon(Icons.shield_rounded, color: C.cyan),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.cyan,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: () async {
                    final value = int.tryParse(controller.text.trim()) ?? 100;
                    await updateUser(uid, {
                      "trustScore": value.clamp(0, 100),
                    });
                    if (!mounted) return;
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
  }

  Widget events() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("activities").snapshots(),
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
          if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
          return 0;
        });

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            sectionTitle("Events verwalten"),
            if (docs.isEmpty)
              const AdminEmpty(text: "Keine Events vorhanden.")
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = (data["title"] ?? "Event").toString();
                final place = (data["place"] ?? "").toString();
                final category = (data["category"] ?? "").toString();
                final creatorId = (data["creatorId"] ?? "").toString();
                final reports = data["reportedCount"] ?? 0;
                final hidden = data["hidden"] == true;
                final featured = data["featured"] == true;

                return AdminActionCard(
                  color: reports > 0 ? Colors.redAccent : C.orange,
                  icon: Icons.local_fire_department,
                  title: title,
                  subtitle: "$category • $place",
                  body:
                      "ID: ${doc.id}\nCreator: $creatorId\nReports: $reports\nVersteckt: ${hidden ? "ja" : "nein"}\nFeatured: ${featured ? "ja" : "nein"}",
                  actions: [
                    ElevatedButton(
                      onPressed: () => openEvent(doc.id),
                      child: const Text("Öffnen"),
                    ),
                    ElevatedButton(
                      onPressed: creatorId.isEmpty ? null : () => openUser(creatorId),
                      child: const Text("Creator"),
                    ),
                    ElevatedButton(
                      onPressed: () => showEditEventSheet(doc.reference, data),
                      child: const Text("Ändern"),
                    ),
                    ElevatedButton(
                      onPressed: () => updateDoc(doc.reference, {
                        "featured": !featured,
                      }),
                      child: Text(featured ? "Unfeatured" : "Featured"),
                    ),
                    ElevatedButton(
                      onPressed: () => updateDoc(doc.reference, {
                        "hidden": !hidden,
                      }),
                      child: Text(hidden ? "Einblenden" : "Verstecken"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final ok = await confirm(
                          "Event löschen?",
                          "Dieses Event wird dauerhaft gelöscht.",
                        );
                        if (ok) doc.reference.delete();
                      },
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

  void showEditEventSheet(DocumentReference ref, Map<String, dynamic> data) {
    final title = TextEditingController(text: (data["title"] ?? "").toString());
    final place = TextEditingController(text: (data["place"] ?? "").toString());
    final category = TextEditingController(text: (data["category"] ?? "").toString());
    final description =
        TextEditingController(text: (data["description"] ?? "").toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    "Event bearbeiten",
                    style: TextStyle(
                      color: C.cyan,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AdminTextField(controller: title, hint: "Titel"),
                  const SizedBox(height: 10),
                  AdminTextField(controller: place, hint: "Ort"),
                  const SizedBox(height: 10),
                  AdminTextField(controller: category, hint: "Kategorie"),
                  const SizedBox(height: 10),
                  AdminTextField(
                    controller: description,
                    hint: "Beschreibung",
                    maxLines: 4,
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.cyan,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    onPressed: () async {
                      await updateDoc(ref, {
                        "title": title.text.trim(),
                        "place": place.text.trim(),
                        "category": category.text.trim(),
                        "description": description.text.trim(),
                      });
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    child: const Text("Speichern"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget moments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("moments").snapshots(),
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
          if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
          return 0;
        });

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            sectionTitle("Momente verwalten"),
            if (docs.isEmpty)
              const AdminEmpty(text: "Keine Momente vorhanden.")
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final imageUrl = (data["imageUrl"] ?? "").toString();
                  final uid = (data["userId"] ?? "").toString();

                  return GestureDetector(
                    onTap: () => showMomentSheet(docs[i].reference, data),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: C.card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: C.cyan.withOpacity(0.16)),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl.isNotEmpty)
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                              ),
                            )
                          else
                            const Icon(Icons.photo, color: Colors.white54),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                uid,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  void showMomentSheet(DocumentReference ref, Map<String, dynamic> data) {
    final uid = (data["userId"] ?? "").toString();
    final imageUrl = (data["imageUrl"] ?? "").toString();

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
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.network(
                      imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  "User: $uid",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: uid.isEmpty ? null : () => openUser(uid),
                        child: const Text("User öffnen"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          final ok = await confirm(
                            "Moment löschen?",
                            "Dieser Moment wird entfernt.",
                          );
                          if (ok) {
                            await ref.delete();
                            if (!mounted) return;
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Löschen"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget broadcast() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        sectionTitle("Nachricht an alle User"),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: C.cyan.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              TextField(
                controller: broadcastTitle,
                decoration: const InputDecoration(
                  hintText: "Titel",
                  prefixIcon: Icon(Icons.title, color: C.cyan),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: broadcastMessage,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Nachricht...",
                  prefixIcon: Icon(Icons.message_outlined, color: C.cyan),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.cyan,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 54),
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

      broadcastTitle.clear();
      broadcastMessage.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Broadcast gesendet ✅")),
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
}

class AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const AdminTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
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