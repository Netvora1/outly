import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_colors.dart';
import '../../core/event_utils.dart';
import '../../services/notification_service.dart';
import '../../widgets/auth/gradient_button.dart';
import '../../widgets/auth/outly_logo.dart';
import '../../widgets/common/circle_icon_button.dart';
import '../../widgets/common/info_card.dart';
import '../../widgets/common/outly_avatar.dart';
import '../../widgets/common/verified_name.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "Alle";
  String selectedTime = "Heute";
  String search = "";

  final List<String> categories = const [
    "Alle",
    "Sport",
    "Chill",
    "Party",
    "Gaming",
    "Gym",
  ];

  bool canSeeActivity(Map<String, dynamic> data, String uid) {
    final visibility = data["visibility"] ?? "public";
    final creatorId = data["creatorId"] ?? "";

    if (creatorId == uid) return true;
    if (visibility == "public") return true;

    if (visibility == "followers") {
      final creatorFollowers = List<String>.from(data["creatorFollowers"] ?? []);
      return creatorFollowers.contains(uid);
    }

    if (visibility == "private") {
      final allowedUsers = List<String>.from(data["allowedUsers"] ?? []);
      return allowedUsers.contains(uid);
    }

    return false;
  }

  bool isTodayEvent(Map<String, dynamic> data) {
    final startAt = data["startAt"];
    if (startAt is! Timestamp) return true;

    final d = startAt.toDate();
    final now = DateTime.now();

    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool matchesTime(Map<String, dynamic> data) {
    if (selectedTime == "Heute") return isTodayEvent(data);
    return true;
  }

  bool matchesSearch(Map<String, dynamic> data) {
    if (search.trim().isEmpty) return true;

    final q = search.trim().toLowerCase();
    final title = (data["title"] ?? "").toString().toLowerCase();
    final place = (data["place"] ?? "").toString().toLowerCase();
    final category = (data["category"] ?? "").toString().toLowerCase();
    final description = (data["description"] ?? "").toString().toLowerCase();

    return title.contains(q) ||
        place.contains(q) ||
        category.contains(q) ||
        description.contains(q);
  }

  bool matchesCategory(Map<String, dynamic> data) {
    final cat = (data["category"] ?? "").toString().trim().toLowerCase();
    final selected = selectedCategory.trim().toLowerCase();

    return selected == "alle" || cat == selected;
  }

  int almostFullCount(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List.from(data["participants"] ?? []);
      final max = data["maxPeople"] ?? 0;

      return max > 0 && participants.length >= max * 0.7;
    }).length;
  }

  int peopleOutCount(List<QueryDocumentSnapshot> docs) {
    int total = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += List.from(data["participants"] ?? []).length;
    }

    return total;
  }

  Widget _homeHeader({
    required int eventCount,
    required int peopleCount,
    required int fomoCount,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF151020),
            Color(0xFF08111D),
            Color(0xFF05060D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: C.cyan.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: C.cyan.withOpacity(0.10),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -30,
            child: Icon(
              Icons.explore_rounded,
              size: 145,
              color: C.cyan.withOpacity(0.045),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const OutlyLogo(),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(color: C.cyan.withOpacity(0.25)),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: C.cyan,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                "Was geht heute in deiner Nähe?",
                style: TextStyle(
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Echte Leute. Echte Aktivitäten. Weniger scrollen, mehr erleben.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniStatPill(
                    icon: Icons.bolt_rounded,
                    text: "$eventCount Live",
                    color: C.green,
                  ),
                  _MiniStatPill(
                    icon: Icons.groups_2_rounded,
                    text: "$peopleCount Leute",
                    color: C.cyan,
                  ),
                  _MiniStatPill(
                    icon: Icons.local_fire_department_rounded,
                    text: "$fomoCount fast voll",
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("activities")
              .where("deleteAt", isGreaterThan: Timestamp.now())
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: C.cyan),
              );
            }

            final docs = snap.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return isEventActive(data) &&
                  canSeeActivity(data, uid) &&
                  matchesTime(data) &&
                  matchesCategory(data) &&
                  matchesSearch(data);
            }).toList();

            docs.sort((a, b) {
              final da = a.data() as Map<String, dynamic>;
              final db = b.data() as Map<String, dynamic>;

              final ta = da["startAt"] ?? da["createdAt"];
              final tb = db["startAt"] ?? db["createdAt"];

              if (ta is Timestamp && tb is Timestamp) {
                return ta.compareTo(tb);
              }

              return 0;
            });

            final fomoCount = almostFullCount(docs);
            final peopleCount = peopleOutCount(docs);

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 150),
              children: [
                _homeHeader(
                  eventCount: docs.length,
                  peopleCount: peopleCount,
                  fomoCount: fomoCount,
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: TextField(
                    onChanged: (v) => setState(() => search = v),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: "Suche Events, Orte oder Vibes...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: C.cyan,
                      ),
                      filled: true,
                      fillColor: C.card.withOpacity(0.92),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: C.cyan.withOpacity(0.45),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HomeFilterPill(
                          text: "Heute",
                          icon: Icons.local_fire_department_rounded,
                          active: selectedTime == "Heute",
                          color: C.orange,
                          onTap: () => setState(() => selectedTime = "Heute"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HomeFilterPill(
                          text: "Demnächst",
                          icon: Icons.calendar_month_rounded,
                          active: selectedTime == "Demnächst",
                          color: C.purple2,
                          onTap: () => setState(() => selectedTime = "Demnächst"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                CategorySelector(
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onChanged: (cat) => setState(() => selectedCategory = cat),
                ),

                if (docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 46, 24, 24),
                    child: InfoCard(
                      title: "Noch nichts los",
                      text: search.isNotEmpty
                          ? "Versuch eine andere Suche oder Kategorie."
                          : "Erstelle das erste Event und bring Leute raus.",
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 2),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Heute live",
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: C.cyan.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: C.cyan.withOpacity(0.32),
                            ),
                          ),
                          child: Text(
                            "${docs.length} gefunden",
                            style: const TextStyle(
                              color: C.cyan,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return ActivityCard(
                      id: doc.id,
                      title: data["title"] ?? "",
                      place: data["place"] ?? "",
                      date: data["date"] ?? "",
                      time: data["time"] ?? "",
                      category: data["category"] ?? "Chill",
                      participants: List.from(data["participants"] ?? []),
                      max: data["maxPeople"] ?? 0,
                      imageUrl: data["imageUrl"] ?? "",
                      visibility: data["visibility"] ?? "public",
                      likes: List<String>.from(data["likes"] ?? []),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MiniStatPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeFilterPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _HomeFilterPill({
    required this.text,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? color : C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? color : color.withOpacity(0.25)),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.22),
                    blurRadius: 16,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? Colors.black : color,
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              text,
              style: TextStyle(
                color: active ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = selectedCategory == cat;
          final color = cat == "Alle" ? C.cyan : catColor(cat);

          return GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isSelected ? color.withOpacity(0.18) : C.card,
                border: Border.all(
                  color: isSelected ? color : Colors.white.withOpacity(0.10),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    cat == "Alle"
                        ? Icons.auto_awesome_rounded
                        : catIcon(cat),
                    color: isSelected ? color : Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================
// TEIL 2 / 3
// ACTIVITY CARD + ACTION BUTTON
// ============================

class ActivityCard extends StatelessWidget {
  final String id;
  final String title;
  final String place;
  final String date;
  final String time;
  final String category;
  final List participants;
  final int max;
  final String imageUrl;
  final String visibility;
  final List<String> likes;

  const ActivityCard({
    super.key,
    required this.id,
    required this.title,
    required this.place,
    required this.date,
    required this.time,
    required this.category,
    required this.participants,
    required this.max,
    this.imageUrl = "",
    this.visibility = "public",
    this.likes = const [],
  });

  Future<void> toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance.collection("activities").doc(id);

    if (likes.contains(uid)) {
      await ref.set({
        "likes": FieldValue.arrayRemove([uid]),
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));
    } else {
      await ref.set({
        "likes": FieldValue.arrayUnion([uid]),
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));
    }
  }

  void shareEvent() {
    Share.share(
      "Outly Event\n\n"
      "$title\n"
      "Kategorie: $category\n"
      "Ort: $place\n"
      "Zeit: $date $time\n\n"
      "Komm mit auf Outly und sei dabei!",
      subject: "Outly Event: $title",
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final color = catColor(category);

    final full = max > 0 && participants.length >= max;
    final almostFull = max > 0 && participants.length >= max * 0.7 && !full;
    final liked = likes.contains(uid);

    final cleanImageUrl = imageUrl
        .trim()
        .replaceAll("\n", "")
        .replaceAll("\r", "")
        .replaceAll(" ", "");

    Widget fallbackImage() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.85),
              C.card,
              Colors.black,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            catIcon(category),
            size: 78,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActivityDetailScreen(activityId: id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        height: 265,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.24),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned.fill(
                child: cleanImageUrl.isNotEmpty
                    ? Image.network(
                        cleanImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;

                          return Container(
                            color: C.card2,
                            child: const Center(
                              child: CircularProgressIndicator(color: C.cyan),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint("BILD FEHLER ActivityCard: $error");
                          return fallbackImage();
                        },
                      )
                    : fallbackImage(),
              ),

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.25),
                        Colors.black.withOpacity(0.88),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 14,
                left: 14,
                child: Row(
                  children: [
                    _cardBadge(
                      category,
                      color,
                      textColor: Colors.black,
                    ),
                    const SizedBox(width: 7),
                    _cardBadge(
                      "$date • $time",
                      Colors.white,
                      textColor: Colors.black,
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 14,
                right: 14,
                child: Column(
                  children: [
                    _CircleActionButton(
                      icon: liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? C.pink : Colors.white,
                      onTap: toggleLike,
                    ),
                    const SizedBox(height: 9),
                    _CircleActionButton(
                      icon: Icons.ios_share,
                      color: C.cyan,
                      onTap: shareEvent,
                    ),
                  ],
                ),
              ),

              if (almostFull || full)
                Positioned(
                  left: 14,
                  top: 56,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: full ? Colors.redAccent : C.orange,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      full ? "Voll" : "Fast voll",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 13),

                    Row(
                      children: [
                        SizedBox(
                          width: 78,
                          height: 30,
                          child: Stack(
                            children: List.generate(
                              participants.length.clamp(0, 3),
                              (i) => Positioned(
                                left: i * 21,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white24,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Text(
                          max > 0
                              ? "${participants.length}/$max"
                              : "${participants.length}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 13),

                        Icon(
                          Icons.favorite,
                          color: liked ? C.pink : Colors.white54,
                          size: 18,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          "${likes.length}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Spacer(),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: full ? Colors.white24 : color,
                            foregroundColor: full ? Colors.white70 : Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 11,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActivityDetailScreen(
                                  activityId: id,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            full ? "Voll" : "Ansehen",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardBadge(
    String text,
    Color color, {
    Color textColor = Colors.black,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.42),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: 16,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 21,
        ),
      ),
    );
  }
}

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailScreen({
    super.key,
    required this.activityId,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final msg = TextEditingController();
  final ScrollController pageScroll = ScrollController();
  final ScrollController chatScroll = ScrollController();

  bool sendingMessage = false;

  @override
  void dispose() {
    msg.dispose();
    pageScroll.dispose();
    chatScroll.dispose();
    super.dispose();
  }

  void scrollChatToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || !chatScroll.hasClients) return;

      chatScroll.animateTo(
        chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> joinOrLeave(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final participants = List<String>.from(data["participants"] ?? []);
    final pending = List<String>.from(data["pendingRequests"] ?? []);
    final maxPeople = data["maxPeople"] ?? 0;
    final joinMode = data["joinMode"] ?? "open";
    final creatorId = (data["creatorId"] ?? "").toString();

    final ref = FirebaseFirestore.instance
        .collection("activities")
        .doc(widget.activityId);

    if (participants.contains(uid)) {
      await ref.update({
        "participants": FieldValue.arrayRemove([uid]),
        "updatedAt": Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Du bist nicht mehr dabei")),
      );
      return;
    }

    if (maxPeople > 0 && participants.length >= maxPeople) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event ist voll")),
      );
      return;
    }

    if (joinMode == "request") {
      if (pending.contains(uid)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Anfrage wurde bereits gesendet")),
        );
        return;
      }

      await ref.update({
        "pendingRequests": FieldValue.arrayUnion([uid]),
        "updatedAt": Timestamp.now(),
      });

      await sendNotification(
        toUserId: creatorId,
        fromUserId: uid,
        type: "request",
        text: "möchte deinem Event beitreten 👀",
        targetId: widget.activityId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Beitrittsanfrage gesendet ✅")),
      );
      return;
    }

    await ref.update({
      "participants": FieldValue.arrayUnion([uid]),
      "spotsLeft": maxPeople > 0 ? FieldValue.increment(-1) : 0,
      "updatedAt": Timestamp.now(),
    });

    await sendNotification(
      toUserId: creatorId,
      fromUserId: uid,
      type: "join",
      text: "ist deinem Event beigetreten 🔥",
      targetId: widget.activityId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Du bist dabei 🔥")),
    );
  }

  Future<void> acceptRequest(String userId) async {
    final ref = FirebaseFirestore.instance
        .collection("activities")
        .doc(widget.activityId);

    await ref.update({
      "pendingRequests": FieldValue.arrayRemove([userId]),
      "participants": FieldValue.arrayUnion([userId]),
      "updatedAt": Timestamp.now(),
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await sendNotification(
      toUserId: userId,
      fromUserId: uid,
      type: "join",
      text: "hat deine Beitrittsanfrage angenommen ✅",
      targetId: widget.activityId,
    );
  }

  Future<void> declineRequest(String userId) async {
    final ref = FirebaseFirestore.instance
        .collection("activities")
        .doc(widget.activityId);

    await ref.update({
      "pendingRequests": FieldValue.arrayRemove([userId]),
      "updatedAt": Timestamp.now(),
    });
  }

  Future<void> sendMessage() async {
    final text = msg.text.trim();
    if (text.isEmpty || sendingMessage) return;

    setState(() => sendingMessage = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      final activityRef = FirebaseFirestore.instance
          .collection("activities")
          .doc(widget.activityId);

      await activityRef.collection("chat").add({
        "text": text,
        "senderId": user.uid,
        "email": user.email ?? "",
        "username": userData["username"] ?? "user",
        "photoUrl": userData["photoUrl"] ?? "",
        "createdAt": Timestamp.now(),
      });

      await activityRef.set({
        "hasChat": true,
        "lastMessage": text,
        "lastMessageAt": Timestamp.now(),
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));

      msg.clear();
      scrollChatToBottom();
    } catch (e) {
      debugPrint("Event Chat Fehler: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nachricht konnte nicht gesendet werden ❌")),
      );
    } finally {
      if (mounted) setState(() => sendingMessage = false);
    }
  }

  Future<void> deleteActivity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        title: const Text("Event löschen?"),
        content: const Text("Dieses Event wird dauerhaft entfernt."),
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

    await FirebaseFirestore.instance
        .collection("activities")
        .doc(widget.activityId)
        .delete();

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> reportActivity() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection("reports").add({
      "type": "activity",
      "targetActivityId": widget.activityId,
      "reportedBy": uid,
      "reason": "suspicious",
      "status": "open",
      "createdAt": Timestamp.now(),
    });

    await FirebaseFirestore.instance
        .collection("activities")
        .doc(widget.activityId)
        .set({
      "reportedCount": FieldValue.increment(1),
      "riskFlags": FieldValue.arrayUnion(["reported"]),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event wurde gemeldet ✅")),
    );
  }

  void shareActivity(Map<String, dynamic> data) {
    Share.share(
      "🔥 Outly Event\n\n"
      "${data["title"] ?? "Aktivität"}\n"
      "Kategorie: ${data["category"] ?? "Aktivität"}\n"
      "📍 ${data["place"] ?? ""}\n"
      "⏰ ${data["date"] ?? ""} ${data["time"] ?? ""}\n\n"
      "Komm mit auf Outly und sei dabei!",
      subject: "Outly Event: ${data["title"] ?? "Aktivität"}",
    );
  }

  Widget pendingUserTile(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(userId).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox.shrink();

        final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
        if (userData["isBanned"] == true) return const SizedBox.shrink();

        final username = (userData["username"] ?? "User").toString();
        final photoUrl = (userData["photoUrl"] ?? "").toString();
        final city = (userData["city"] ?? "").toString();
        final verified = userData["verified"] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: C.cyan.withOpacity(0.25)),
          ),
          child: ListTile(
            leading: OutlyAvatar(photoUrl: photoUrl, radius: 24),
            title: verifiedName(username, verified),
            subtitle: Text(
              city.isNotEmpty ? "$city • möchte beitreten" : "möchte beitreten",
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle, color: C.green),
                  onPressed: () => acceptRequest(userId),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  onPressed: () => declineRequest(userId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget chatBubble({
    required Map<String, dynamic> message,
    required bool isMe,
  }) {
    final text = (message["text"] ?? "").toString();
    final username = (message["username"] ?? "User").toString();
    final photoUrl = (message["photoUrl"] ?? "").toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            OutlyAvatar(photoUrl: photoUrl, radius: 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isMe ? C.cyan : C.card2,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? C.cyan : C.purple).withOpacity(0.12),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "@$username",
                        style: const TextStyle(
                          color: C.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 8,
              backgroundColor: C.cyan,
              child: Icon(Icons.check, size: 10, color: Colors.black),
            ),
          ],
        ],
      ),
    );
  }

  Widget activityChat(String uid) {
    return Container(
      height: 360,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: C.cyan.withOpacity(0.18)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("activities")
            .doc(widget.activityId)
            .collection("chat")
            .orderBy("createdAt")
            .snapshots(),
        builder: (context, chatSnap) {
          if (!chatSnap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: C.cyan),
            );
          }

          final messages = chatSnap.data!.docs;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollChatToBottom();
          });

          if (messages.isEmpty) {
            return const Center(
              child: Text(
                "Noch keine Nachrichten",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            controller: chatScroll,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 10),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final message = messages[i].data() as Map<String, dynamic>;

              return chatBubble(
                message: message,
                isMe: message["senderId"] == uid,
              );
            },
          );
        },
      ),
    );
  }

  Widget heroImage(String imageUrl, String category, Color color) {
    final cleanImageUrl = imageUrl
        .trim()
        .replaceAll("\n", "")
        .replaceAll("\r", "")
        .replaceAll(" ", "");

    Widget fallback() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.9),
              C.card,
              C.bg,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(
          catIcon(category),
          size: 90,
          color: Colors.white,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (cleanImageUrl.isNotEmpty)
          Image.network(
            cleanImageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;

              return Container(
                color: C.card2,
                child: const Center(
                  child: CircularProgressIndicator(color: C.cyan),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint("BILD FEHLER Detail Hero: $error");
              debugPrint("URL WAR: $cleanImageUrl");
              return fallback();
            },
          )
        else
          fallback(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.20),
                Colors.black.withOpacity(0.70),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: C.bg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("activities")
            .doc(widget.activityId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: C.cyan),
            );
          }

          if (!snap.data!.exists) {
            return const Center(
              child: Text("Aktivität wurde gelöscht"),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final category = data["category"] ?? "Chill";
          final color = catColor(category);
          final participants = List<String>.from(data["participants"] ?? []);
          final pending = List<String>.from(data["pendingRequests"] ?? []);
          final joined = participants.contains(uid);
          final isOwner = data["creatorId"] == uid;
          final maxPeople = data["maxPeople"] ?? 0;
          final full = maxPeople > 0 && participants.length >= maxPeople;
          final imageUrl = (data["imageUrl"] ?? "").toString();
          final joinMode = data["joinMode"] ?? "open";
          final description = (data["description"] ?? "").toString();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: pageScroll,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: joined ? 120 + keyboard : 24,
                  ),
                  children: [
                    SizedBox(
                      height: 330,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: heroImage(imageUrl, category, color),
                          ),
                          Positioned(
                            left: 16,
                            top: 44,
                            child: CircleIconButton(
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                          Positioned(
                            right: 16,
                            top: 44,
                            child: CircleIconButton(
                              icon: Icons.ios_share,
                              onTap: () => shareActivity(data),
                            ),
                          ),
                          Positioned(
                            right: 16,
                            top: 96,
                            child: CircleIconButton(
                              icon: isOwner ? Icons.delete : Icons.flag_outlined,
                              onTap: isOwner ? deleteActivity : reportActivity,
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.92),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  data["title"] ?? "",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "📍 ${data["place"] ?? ""}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "⏰ ${data["date"] ?? ""} ${data["time"] ?? ""}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _DetailMiniCard(
                                icon: Icons.groups_2_outlined,
                                title: maxPeople > 0
                                    ? "${participants.length}/$maxPeople"
                                    : "${participants.length}",
                                subtitle: "dabei",
                                color: color,
                              ),
                              const SizedBox(width: 10),
                              _DetailMiniCard(
                                icon: joinMode == "request"
                                    ? Icons.how_to_reg
                                    : Icons.bolt,
                                title: joinMode == "request" ? "Anfrage" : "Direkt",
                                subtitle: "Beitritt",
                                color: joinMode == "request" ? C.orange : C.green,
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          if (description.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: C.card,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: color.withOpacity(0.22),
                                ),
                              ),
                              child: Text(
                                description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.45,
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          GradientButton(
                            text: joined
                                ? "Nicht mehr dabei"
                                : full
                                    ? "Event voll"
                                    : joinMode == "request"
                                        ? "Anfrage senden"
                                        : "Ich bin dabei 🔥",
                            onPressed:
                                full && !joined ? () {} : () => joinOrLeave(data),
                          ),

                          if (isOwner && pending.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              "Beitrittsanfragen",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: C.cyan,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...pending.map((userId) => pendingUserTile(userId)),
                          ],

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Event Chat",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: C.cyan,
                                  ),
                                ),
                              ),
                              if (joined)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: C.cyan.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: C.cyan.withOpacity(0.25),
                                    ),
                                  ),
                                  child: const Text(
                                    "Live",
                                    style: TextStyle(
                                      color: C.cyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          if (!joined)
                            const InfoCard(
                              title: "Chat gesperrt",
                              text:
                                  "Du musst beim Event dabei sein, um den Chat zu sehen.",
                            )
                          else
                            activityChat(uid),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (joined)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.96),
                      border: Border(
                        top: BorderSide(
                          color: C.cyan.withOpacity(0.16),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: msg,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => sendMessage(),
                            decoration: const InputDecoration(
                              hintText: "In den Event Chat schreiben...",
                              prefixIcon: Icon(
                                Icons.chat_bubble_outline,
                                color: C.cyan,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: sendingMessage ? null : sendMessage,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sendingMessage ? Colors.white24 : C.cyan,
                              boxShadow: [
                                if (!sendingMessage)
                                  BoxShadow(
                                    color: C.cyan.withOpacity(0.35),
                                    blurRadius: 18,
                                  ),
                              ],
                            ),
                            child: sendingMessage
                                ? const Padding(
                                    padding: EdgeInsets.all(13),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _DetailMiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
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

class OutlySelectBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const OutlySelectBox({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: C.card2,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: C.cyan, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData iconForType(String type) {
    switch (type) {
      case "follow":
        return Icons.person_add_alt_1;
      case "join":
        return Icons.local_fire_department;
      case "request":
        return Icons.how_to_reg;
      case "chat":
        return Icons.chat_bubble_outline;
      case "admin":
        return Icons.admin_panel_settings;
      default:
        return Icons.notifications_none;
    }
  }

  Color colorForType(String type) {
    switch (type) {
      case "follow":
        return C.cyan;
      case "join":
        return C.orange;
      case "request":
        return C.green;
      case "chat":
        return C.pink;
      case "admin":
        return C.purple2;
      default:
        return C.cyan;
    }
  }

  Future<void> markAsRead(DocumentReference ref) async {
    await ref.set({
      "read": true,
      "readAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllAsRead(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection("notifications")
        .where("toUserId", isEqualTo: uid)
        .where("read", isEqualTo: false)
        .get();

    for (final doc in snap.docs) {
      await doc.reference.set({
        "read": true,
        "readAt": Timestamp.now(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        title: const Text(
          "Benachrichtigungen",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => markAllAsRead(uid),
            child: Text(
              "Alle gelesen",
              style: TextStyle(color: C.cyan),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("toUserId", isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(
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
            return const Center(
              child: InfoCard(
                title: "Noch nichts da",
                text:
                    "Hier erscheinen neue Follower, Event-Updates, Join-Anfragen und Chat-Hinweise.",
              ),
            );
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final type = (data["type"] ?? "").toString();
              final text = (data["text"] ?? "").toString();
              final fromUserId = (data["fromUserId"] ?? "").toString();
              final targetId = (data["targetId"] ?? "").toString();
              final read = data["read"] == true;
              final color = colorForType(type);

              return FutureBuilder<DocumentSnapshot>(
                future: fromUserId.isEmpty
                    ? null
                    : FirebaseFirestore.instance
                        .collection("users")
                        .doc(fromUserId)
                        .get(),
                builder: (context, userSnap) {
                  final userData =
                      userSnap.data?.data() as Map<String, dynamic>? ?? {};

                  final username = userData["username"] ?? "Outly";
                  final photoUrl = (userData["photoUrl"] ?? "").toString();

                  return GestureDetector(
                    onTap: () async {
                      await markAsRead(doc.reference);

                      if ((type == "join" || type == "request") &&
                          targetId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActivityDetailScreen(
                              activityId: targetId,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: read ? C.card : color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: read
                              ? Colors.white.withOpacity(0.08)
                              : color.withOpacity(0.45),
                        ),
                        boxShadow: [
                          if (!read)
                            BoxShadow(
                              color: color.withOpacity(0.18),
                              blurRadius: 18,
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              OutlyAvatar(photoUrl: photoUrl, radius: 25),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: color,
                                  child: Icon(
                                    iconForType(type),
                                    size: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "@$username",
                                  style: TextStyle(
                                    color: read ? Colors.white70 : color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  text,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!read)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}