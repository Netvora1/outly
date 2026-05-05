import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/auth/gradient_button.dart';
import '../../widgets/common/circle_icon_button.dart';
import '../../widgets/common/info_card.dart';
import '../../widgets/common/outly_avatar.dart';
import '../../widgets/common/verified_name.dart';
import '../profile/user_profile_screen.dart';
import '../../widgets/auth/outly_logo.dart';


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

  String sectionTitle() {
    if (selectedTime == "Heute") return "Heute in deiner Nähe";
    return "Demnächst";
  }

  String sectionSubtitle(int count) {
    if (count == 0) return "Noch nichts gefunden.";
    if (selectedTime == "Heute") return "$count echte Möglichkeiten für heute.";
    return "$count Events warten auf dich.";
  }

  Widget _homeHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            C.purple.withOpacity(0.55),
            C.card,
            C.cyan.withOpacity(0.16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: C.cyan.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: C.purple.withOpacity(0.24),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
             OutlyLogo(),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Was geht heute? 🔥",
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Finde echte Events in deiner Nähe.",
                      style: TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.notifications_none, color: C.cyan),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>  NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.23),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: _HomeTrustPill(
                    icon: Icons.bolt,
                    title: "Live",
                    subtitle: "Events",
                    color: C.green,
                  ),
                ),
                _HomeSmallDivider(),
                Expanded(
                  child: _HomeTrustPill(
                    icon: Icons.shield_outlined,
                    title: "Safe",
                    subtitle: "Treffen",
                    color: C.cyan,
                  ),
                ),
                _HomeSmallDivider(),
                Expanded(
                  child: _HomeTrustPill(
                    icon: Icons.groups_2_outlined,
                    title: "Real",
                    subtitle: "People",
                    color: C.orange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: const InputDecoration(
              hintText: "Suche Events, Orte oder Vibes...",
              prefixIcon: Icon(Icons.search, color: C.cyan),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HomeTimeButton(
                    text: "Heute",
                    icon: Icons.local_fire_department,
                    active: selectedTime == "Heute",
                    color: C.cyan,
                    onTap: () => setState(() => selectedTime = "Heute"),
                  ),
                ),
                Expanded(
                  child: _HomeTimeButton(
                    text: "Demnächst",
                    icon: Icons.calendar_month,
                    active: selectedTime == "Demnächst",
                    color: C.purple2,
                    onTap: () => setState(() => selectedTime = "Demnächst"),
                  ),
                ),
              ],
            ),
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

              if (ta is Timestamp && tb is Timestamp) return ta.compareTo(tb);
              return 0;
            });

            final fomoCount = almostFullCount(docs);

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 150),
              children: [
                _homeHeader(context),

                CategorySelector(
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onChanged: (cat) => setState(() => selectedCategory = cat),
                ),

                if (docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
                    child: InfoCard(
                      title: "Noch nichts los",
                      text: search.isNotEmpty
                          ? "Versuch eine andere Suche oder Kategorie."
                          : "Erstelle das erste Event und bring Leute raus 🔥",
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sectionTitle(),
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                sectionSubtitle(docs.length),
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: C.cyan.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: C.cyan.withOpacity(0.35),
                            ),
                          ),
                          child: Text(
                            "${docs.length}",
                            style: const TextStyle(
                              color: C.cyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (fomoCount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: C.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: C.orange.withOpacity(0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: C.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "$fomoCount Event${fomoCount == 1 ? "" : "s"} fast voll – warte nicht zu lange.",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 8, 18, 0),
                    child: Text(
                      "Top Pick",
                      style: TextStyle(
                        color: C.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Builder(
                    builder: (_) {
                      final data = docs.first.data() as Map<String, dynamic>;

                      return ActivityCard(
                        id: docs.first.id,
                        title: data["title"] ?? "",
                        place: data["place"] ?? "",
                        date: data["date"] ?? "",
                        time: data["time"] ?? "",
                        category: data["category"] ?? "Chill",
                        participants: List.from(data["participants"] ?? []),
                        max: data["maxPeople"] ?? 0,
                        imageUrl: data["imageUrl"] ?? "",
                        visibility: data["visibility"] ?? "public",
                      );
                    },
                  ),

                  if (docs.length > 1)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 10, 18, 0),
                      child: Text(
                        "Mehr Events",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  ...docs.skip(1).map((doc) {
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

bool isEventActive(Map<String, dynamic> data) {
  final deleteAt = data["deleteAt"];
  if (deleteAt is Timestamp) {
    return deleteAt.toDate().isAfter(DateTime.now());
  }
  return true;
}

Color catColor(String cat) {
  switch (cat) {
    case "Sport":
      return C.green;
    case "Chill":
      return C.purple2;
    case "Party":
      return C.pink;
    case "Gaming":
      return Colors.blueAccent;
    case "Gym":
      return C.cyan;
    default:
      return C.purple;
  }
}

IconData catIcon(String cat) {
  switch (cat) {
    case "Sport":
      return Icons.sports_soccer;
    case "Chill":
      return Icons.local_fire_department;
    case "Party":
      return Icons.celebration;
    case "Gaming":
      return Icons.sports_esports;
    case "Gym":
      return Icons.fitness_center;
    default:
      return Icons.explore;
  }
}


class _HomeTrustPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _HomeTrustPill({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _HomeSmallDivider extends StatelessWidget {
  const _HomeSmallDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withOpacity(0.08),
    );
  }
}

class _HomeTimeButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _HomeTimeButton({
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
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.28),
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
              size: 18,
              color: active ? Colors.black : Colors.white54,
            ),
            const SizedBox(width: 7),
            Text(
              text,
              style: TextStyle(
                color: active ? Colors.black : Colors.white54,
                fontWeight: FontWeight.bold,
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
      height: 55,
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
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isSelected ? color.withOpacity(0.20) : C.card,
                border: Border.all(
                  color: isSelected ? color : Colors.white.withOpacity(0.12),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.35),
                          blurRadius: 16,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    cat == "Alle" ? Icons.auto_awesome : catIcon(cat),
                    color: isSelected ? color : Colors.white54,
                    size: 17,
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
  });

 @override
Widget build(BuildContext context) {
  final color = catColor(category);
  final full = max > 0 && participants.length >= max;
  final almostFull = max > 0 && participants.length >= max * 0.7 && !full;
  final cleanImageUrl = imageUrl.trim();

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
          size: 76,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 236,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.32),
            blurRadius: 26,
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
                        return const Center(
                          child: CircularProgressIndicator(color: C.cyan),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print("BILD FEHLER ActivityCard: $error");
                        print("URL WAR: $cleanImageUrl");
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
                      Colors.black.withOpacity(0.08),
                      Colors.black.withOpacity(0.30),
                      Colors.black.withOpacity(0.78),
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
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.38),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Icon(
                  visibility == "public"
                      ? Icons.public
                      : visibility == "followers"
                          ? Icons.group
                          : Icons.lock,
                  color: Colors.white70,
                  size: 19,
                ),
              ),
            ),

            if (almostFull || full)
              Positioned(
                left: 14,
                top: 58,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: full ? Colors.redAccent : C.orange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    full ? "Voll" : "Fast voll",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                        width: 76,
                        height: 28,
                        child: Stack(
                          children: List.generate(
                            participants.length.clamp(0, 3),
                            (i) => Positioned(
                              left: i * 20,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white24,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(Icons.person, size: 14),
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
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: full ? Colors.white24 : color,
                          foregroundColor: full ? Colors.white70 : Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                              builder: (_) => ActivityDetailScreen(activityId: id),
                            ),
                          );
                        },
                        child: Text(
                          full ? "Voll" : "Ansehen",
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/* ACTIVITY DETAIL */

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final msg = TextEditingController();

  @override
  void dispose() {
    msg.dispose();
    super.dispose();
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
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final userData = userDoc.data() ?? {};

    await FirebaseFirestore.instance
        .collection("activities")
        .doc(widget.activityId)
        .collection("chat")
        .add({
      "text": text,
      "senderId": user.uid,
      "email": user.email ?? "",
      "username": userData["username"] ?? "user",
      "photoUrl": userData["photoUrl"] ?? "",
      "createdAt": Timestamp.now(),
    });

    await FirebaseFirestore.instance
        .collection("activities")
        .doc(widget.activityId)
        .set({
      "hasChat": true,
      "lastMessage": text,
      "lastMessageAt": Timestamp.now(),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    msg.clear();
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
            child: const Text("Löschen", style: TextStyle(color: Colors.redAccent)),
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
        if (!userSnap.hasData) {
          return const SizedBox.shrink();
        }

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
                  icon: Icon(Icons.cancel, color: Colors.redAccent),
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
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
        ],
      ),
    );
  }

  Widget activityChat(String uid) {
    return Container(
      height: 310,
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
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }

          final messages = chatSnap.data!.docs;

          if (messages.isEmpty) {
            return const Center(
              child: Text(
                "Noch keine Nachrichten",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 8),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.9), C.bg],
                ),
              ),
              child: Icon(catIcon(category), size: 90, color: Colors.white),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.9), C.bg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(catIcon(category), size: 90, color: Colors.white),
          ),
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

    return Scaffold(
      backgroundColor: C.bg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("activities")
            .doc(widget.activityId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }

          if (!snap.data!.exists) {
            return const Center(child: Text("Aktivität wurde gelöscht"));
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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
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
                                border: Border.all(color: color.withOpacity(0.22)),
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
                            onPressed: full && !joined ? () {} : () => joinOrLeave(data),
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

                          const Text(
                            "Event Chat",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: C.cyan,
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (!joined)
                             InfoCard(
                              title: "Chat gesperrt",
                              text: "Du musst beim Event dabei sein, um den Chat zu sehen.",
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
                MessageInput(
                  controller: msg,
                  onSend: sendMessage,
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
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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

Future<void> seedFakeEvents() async {
  final col = FirebaseFirestore.instance.collection("activities");
  final uid = FirebaseAuth.instance.currentUser?.uid ?? "test";
  final now = DateTime.now();

  final List<Map<String, dynamic>> events = [
    {
      "title": "Fußball im Park",
      "place": "St. Pölten",
      "lat": 48.203,
      "lng": 15.625,
      "category": "Sport",
    },
    {
      "title": "Chill am See",
      "place": "Neusiedler See",
      "lat": 47.842,
      "lng": 16.766,
      "category": "Chill",
    },
    {
      "title": "Gaming Night",
      "place": "Wien",
      "lat": 48.2082,
      "lng": 16.3738,
      "category": "Gaming",
    },
  ];

  for (final e in events) {
    final startAt = now.add(const Duration(hours: 2));
    final deleteAt = startAt.add(const Duration(hours: 3));

    await col.add({
      "title": e["title"],
      "place": e["place"],
      "lat": e["lat"],
      "lng": e["lng"],
      "category": e["category"],
      "date": "Heute",
      "time": "20:00",
      "description": "Test Event für Map 🔥",
      "participants": [uid],
      "pendingRequests": [],
      "creatorId": uid,
      "creatorFollowers": [],
      "visibility": "public",
      "allowedUsers": [],
      "joinMode": "open",
      "maxPeople": 10,
      "hasChat": false,
      "imageUrl": "",
      "startAt": Timestamp.fromDate(startAt),
      "deleteAt": Timestamp.fromDate(deleteAt),
      "createdAt": Timestamp.now(),
      "updatedAt": Timestamp.now(),
      "reportedCount": 0,
      "riskFlags": [],
    });
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

                    if (type == "follow" && fromUserId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: const Text("Profil"),
                            ),
                            body: const Center(
                              child: Text("Coming soon"),
                            ),
                          ),
                        ),
                      );
                    }

                    if ((type == "join" || type == "request") &&
                        targetId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ActivityDetailScreen(activityId: targetId),
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
