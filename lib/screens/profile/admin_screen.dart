import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_colors.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<int> countCollection(String name) async {
    final snap =
        await FirebaseFirestore.instance.collection(name).get();

    return snap.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: const Text("Admin Panel"),
      ),
      body: FutureBuilder<List<int>>(
        future: Future.wait([
          countCollection("users"),
          countCollection("activities"),
          countCollection("reports"),
          countCollection("support"),
        ]),
        builder: (context, snap) {
          final stats = snap.data ?? [0, 0, 0, 0];

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [

              /// HEADER
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: [
                      C.purple.withOpacity(0.5),
                      C.card,
                      C.cyan.withOpacity(0.15),
                    ],
                  ),
                  border: Border.all(
                    color: C.cyan.withOpacity(0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: C.cyan,
                      size: 42,
                    ),

                    SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Outly Admin",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            "User, Safety & Reports verwalten",
                            style: TextStyle(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              /// STATS
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [

                  AdminStatCard(
                    title: "User",
                    value: "${stats[0]}",
                    icon: Icons.people_alt_rounded,
                    color: C.cyan,
                  ),

                  AdminStatCard(
                    title: "Events",
                    value: "${stats[1]}",
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),

                  AdminStatCard(
                    title: "Reports",
                    value: "${stats[2]}",
                    icon: Icons.flag_rounded,
                    color: Colors.redAccent,
                  ),

                  AdminStatCard(
                    title: "Support",
                    value: "${stats[3]}",
                    icon: Icons.support_agent,
                    color: Colors.greenAccent,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// USERS
              const Text(
                "Alle User",
                style: TextStyle(
                  color: C.cyan,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: C.cyan,
                        ),
                      ),
                    );
                  }

                  final users = snap.data!.docs;

                  return Column(
                    children: users.map((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>;

                      final username =
                          data["username"] ?? "user";

                      final email =
                          data["email"] ?? "";

                      final banned =
                          data["isBanned"] == true;

                      return Container(
                        margin:
                            const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: C.card,
                          borderRadius:
                              BorderRadius.circular(22),
                          border: Border.all(
                            color: banned
                                ? Colors.redAccent
                                : Colors.white10,
                          ),
                        ),
                        child: Column(
                          children: [

                            Row(
                              children: [

                                CircleAvatar(
                                  backgroundColor:
                                      banned
                                          ? Colors.redAccent
                                          : C.cyan,
                                  child: Icon(
                                    banned
                                        ? Icons.block
                                        : Icons.person,
                                    color: Colors.black,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [

                                      Text(
                                        username,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),

                                      Text(
                                        email,
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            Row(
                              children: [

                                Expanded(
                                  child: ElevatedButton(
                                    style:
                                        ElevatedButton
                                            .styleFrom(
                                      backgroundColor:
                                          banned
                                              ? Colors
                                                  .greenAccent
                                              : Colors
                                                  .redAccent,
                                      foregroundColor:
                                          Colors.black,
                                    ),
                                    onPressed: () async {
                                      await FirebaseFirestore
                                          .instance
                                          .collection(
                                              "users")
                                          .doc(doc.id)
                                          .set({
                                        "isBanned":
                                            !banned,
                                      },
                                              SetOptions(
                                                  merge:
                                                      true));
                                    },
                                    child: Text(
                                      banned
                                          ? "Entsperren"
                                          : "Sperren",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
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
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Icon(
            icon,
            color: color,
            size: 30,
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}