import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_colors.dart';
import '../../core/event_utils.dart';
import '../../services/location_service.dart';
import '../../widgets/auth/outly_logo.dart';
import '../../widgets/common/info_card.dart';
import '../home/home_screen.dart';

class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  String selectedCategory = "Alle";
  String search = "";
  double radiusKm = 10;
  LatLng? myPosition;
  bool loadingLocation = false;

  final MapController mapController = MapController();

  final List<String> categories = const [
    "Alle",
    "Sport",
    "Chill",
    "Party",
    "Gaming",
    "Gym",
  ];

  Future<void> loadMyPosition() async {
    setState(() => loadingLocation = true);

    final position = await getUserPosition();

    if (!mounted) return;

    if (position != null) {
      final point = LatLng(position.latitude, position.longitude);

      setState(() {
        myPosition = point;
        loadingLocation = false;
      });

      mapController.move(point, 13);
    } else {
      setState(() => loadingLocation = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Standort konnte nicht geladen werden")),
      );
    }
  }

  LatLng activityPoint(Map<String, dynamic> data) {
    final lat = data["lat"];
    final lng = data["lng"];

    if (lat is num && lng is num) {
      return LatLng(lat.toDouble(), lng.toDouble());
    }

    return const LatLng(48.2082, 16.3738);
  }

  bool matchesRadius(Map<String, dynamic> data) {
    if (myPosition == null) return true;

    final point = activityPoint(data);
    final km = distanceInKm(myPosition!, point);

    return km <= radiusKm;
  }

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

  bool matchesCategory(Map<String, dynamic> data) {
    final cat = (data["category"] ?? "").toString().toLowerCase();
    final selected = selectedCategory.toLowerCase();

    return selected == "alle" || cat == selected;
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

  String distanceText(Map<String, dynamic> data) {
    if (myPosition == null) return "Standort aus";

    final point = activityPoint(data);
    final km = distanceInKm(myPosition!, point);

    if (km < 1) return "${(km * 1000).round()} m entfernt";
    return "${km.toStringAsFixed(1)} km entfernt";
  }

  double zoomForRadius(double radius) {
    if (radius <= 5) return 13.5;
    if (radius <= 10) return 12.5;
    if (radius <= 20) return 11.5;
    if (radius <= 50) return 10;
    return 8.8;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final center = myPosition ?? const LatLng(48.2082, 16.3738);

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
                  matchesCategory(data) &&
                  matchesSearch(data) &&
                  matchesRadius(data);
            }).toList();

            docs.sort((a, b) {
              final da = a.data() as Map<String, dynamic>;
              final db = b.data() as Map<String, dynamic>;

              final ta = da["startAt"] ?? da["createdAt"];
              final tb = db["startAt"] ?? db["createdAt"];

              if (ta is Timestamp && tb is Timestamp) return ta.compareTo(tb);
              return 0;
            });

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    gradient: LinearGradient(
                      colors: [
                        C.purple.withOpacity(0.62),
                        C.card,
                        C.cyan.withOpacity(0.16),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: C.cyan.withOpacity(0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: C.cyan.withOpacity(0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const OutlyLogo(),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Entdecken 🗺️",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Finde Events auf deiner Map.",
                              style: TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: C.card2,
                        child: IconButton(
                          icon: loadingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: C.cyan,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location, color: C.cyan),
                          onPressed: loadingLocation ? null : loadMyPosition,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  onChanged: (v) => setState(() => search = v),
                  decoration: const InputDecoration(
                    hintText: "Suche Ort, Event oder Vibe...",
                    prefixIcon: Icon(Icons.search, color: C.cyan),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  height: 420,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: C.cyan.withOpacity(0.30)),
                    boxShadow: [
                      BoxShadow(
                        color: C.cyan.withOpacity(0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 12,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            userAgentPackageName: "com.outly.app",
                            maxZoom: 18,
                          ),

                          CircleLayer(
                            circles: [
                              if (myPosition != null)
                                CircleMarker(
                                  point: myPosition!,
                                  radius: radiusKm * 1000,
                                  useRadiusInMeter: true,
                                  color: C.cyan.withOpacity(0.08),
                                  borderColor: C.cyan.withOpacity(0.55),
                                  borderStrokeWidth: 2,
                                ),
                            ],
                          ),

                          MarkerLayer(
                            markers: [
                              if (myPosition != null)
                                Marker(
                                  point: myPosition!,
                                  width: 58,
                                  height: 58,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: C.cyan,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: C.cyan.withOpacity(0.55),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_pin_circle,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),

                              ...docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final category = data["category"] ?? "Chill";
                                final color = catColor(category);
                                final point = activityPoint(data);
                                final participants =
                                    List.from(data["participants"] ?? []);

                                return Marker(
                                  point: point,
                                  width: 62,
                                  height: 62,
                                  child: GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => _MapPreviewSheet(
                                          activityId: doc.id,
                                          data: data,
                                          distance: distanceText(data),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withOpacity(0.35),
                                        border: Border.all(
                                          color: color.withOpacity(0.85),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(0.65),
                                            blurRadius: 18,
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: color,
                                            radius: 23,
                                            child: Icon(
                                              catIcon(category),
                                              color: Colors.white,
                                              size: 21,
                                            ),
                                          ),
                                          if (participants.length >= 2)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: C.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  "${participants.length}",
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),

                      Positioned(
                        left: 14,
                        right: 14,
                        top: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.48),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.radar, color: C.cyan, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  myPosition == null
                                      ? "Standort aktivieren für Nähe"
                                      : "${docs.length} Events im Umkreis von ${radiusKm.round()} km",
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
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    const Text(
                      "Radius",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${radiusKm.round()} km",
                      style: const TextStyle(
                        color: C.cyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                Slider(
                  value: radiusKm,
                  min: 2,
                  max: 100,
                  divisions: 49,
                  activeColor: C.cyan,
                  inactiveColor: Colors.white24,
                  label: "${radiusKm.round()} km",
                  onChanged: (v) {
                    setState(() => radiusKm = v);

                    if (myPosition != null) {
                      mapController.move(myPosition!, zoomForRadius(v));
                    }
                  },
                ),

                const SizedBox(height: 8),

                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      final c = categories[i];
                      final active = selectedCategory == c;
                      final color = c == "Alle" ? C.cyan : catColor(c);

                      return GestureDetector(
                        onTap: () => setState(() => selectedCategory = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? color : C.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: active ? color : color.withOpacity(0.45),
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.28),
                                      blurRadius: 18,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                c == "Alle" ? Icons.auto_awesome : catIcon(c),
                                color: active ? Colors.black : color,
                                size: 18,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                c,
                                style: TextStyle(
                                  color:
                                      active ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Events auf der Map",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "${docs.length} gefunden",
                      style: const TextStyle(
                        color: C.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (docs.isEmpty)
                  const InfoCard(
                    title: "Keine Events gefunden",
                    text: "Aktiviere deinen Standort oder ändere die Filter.",
                  )
                else
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return ActivityCard(
                      id: doc.id,
                      title: data["title"] ?? "",
                      place: "${data["place"] ?? ""} • ${distanceText(data)}",
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
            );
          },
        ),
      ),
    );
  }
}

class _MapPreviewSheet extends StatelessWidget {
  final String activityId;
  final Map<String, dynamic> data;
  final String distance;

  const _MapPreviewSheet({
    required this.activityId,
    required this.data,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final category = data["category"] ?? "Chill";
    final color = catColor(category);
    final participants = List.from(data["participants"] ?? []);
    final max = data["maxPeople"] ?? 0;
    final full = max > 0 && participants.length >= max;

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 5,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  radius: 28,
                  child: Icon(catIcon(category), color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data["title"] ?? "Event",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "📍 ${data["place"] ?? ""}\n⏰ ${data["date"] ?? ""} ${data["time"] ?? ""}\n📏 $distance",
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.groups_2_outlined, color: color),
                const SizedBox(width: 8),
                Text(
                  max > 0
                      ? "${participants.length}/$max gehen hin"
                      : "${participants.length} gehen hin",
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ActivityDetailScreen(activityId: activityId),
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
    );
  }
}