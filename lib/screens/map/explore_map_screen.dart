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
  final MapController mapController = MapController();
  final searchController = TextEditingController();

  String selectedCategory = "Alle";
  String search = "";
  double radiusKm = 10;
  LatLng? myPosition;
  bool loadingLocation = false;
  bool onlyToday = false;
  bool mapLocked = true;

  final List<String> categories = const [
    "Alle",
    "Sport",
    "Chill",
    "Party",
    "Gaming",
    "Gym",
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadMyPosition() async {
    setState(() => loadingLocation = true);

    final position = await getUserPosition();

    if (!mounted) return;

    if (position == null) {
      setState(() => loadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Standort konnte nicht geladen werden")),
      );
      return;
    }

    final point = LatLng(position.latitude, position.longitude);

    setState(() {
      myPosition = point;
      loadingLocation = false;
    });

    mapController.move(point, zoomForRadius(radiusKm));
  }

  LatLng activityPoint(Map<String, dynamic> data) {
    final lat = data["lat"];
    final lng = data["lng"];

    if (lat is num && lng is num) {
      return LatLng(lat.toDouble(), lng.toDouble());
    }

    return const LatLng(48.2082, 16.3738);
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

  bool matchesRadius(Map<String, dynamic> data) {
    if (myPosition == null) return true;
    final km = distanceInKm(myPosition!, activityPoint(data));
    return km <= radiusKm;
  }

  bool matchesCategory(Map<String, dynamic> data) {
    final cat = (data["category"] ?? "").toString().trim().toLowerCase();
    final selected = selectedCategory.trim().toLowerCase();
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

  bool matchesToday(Map<String, dynamic> data) {
    if (!onlyToday) return true;

    final startAt = data["startAt"];
    if (startAt is! Timestamp) return false;

    final d = startAt.toDate();
    final now = DateTime.now();

    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String distanceText(Map<String, dynamic> data) {
    if (myPosition == null) return "Standort aus";

    final km = distanceInKm(myPosition!, activityPoint(data));
    if (km < 1) return "${(km * 1000).round()} m entfernt";
    return "${km.toStringAsFixed(1)} km entfernt";
  }

  double zoomForRadius(double radius) {
    if (radius <= 3) return 14.2;
    if (radius <= 5) return 13.5;
    if (radius <= 10) return 12.5;
    if (radius <= 20) return 11.4;
    if (radius <= 50) return 10;
    return 8.7;
  }

  void focusAllEvents(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return;

    final first = activityPoint(docs.first.data() as Map<String, dynamic>);
    mapController.move(first, 12.5);
  }

  void openFullMap(List<QueryDocumentSnapshot> docs, LatLng center) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullOutlyMapScreen(
          docs: docs,
          center: center,
          myPosition: myPosition,
          radiusKm: radiusKm,
          activityPoint: activityPoint,
          distanceText: distanceText,
        ),
      ),
    );
  }

  Widget buildMap({
    required List<QueryDocumentSnapshot> docs,
    required LatLng center,
    required bool fullscreen,
  }) {
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: !fullscreen && mapLocked,
          child: FlutterMap(
            mapController: fullscreen ? MapController() : mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: fullscreen ? 12.8 : 12,
              minZoom: 3,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.clipza.outly",
                maxZoom: 19,
                tileProvider: NetworkTileProvider(),
              ),
              CircleLayer(
                circles: [
                  if (myPosition != null)
                    CircleMarker(
                      point: myPosition!,
                      radius: radiusKm * 1000,
                      useRadiusInMeter: true,
                      color: C.cyan.withOpacity(0.08),
                      borderColor: C.cyan.withOpacity(0.60),
                      borderStrokeWidth: 2,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (myPosition != null)
                    Marker(
                      point: myPosition!,
                      width: 74,
                      height: 74,
                      child: _UserPulseMarker(),
                    ),
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final category = data["category"] ?? "Chill";
                    final color = catColor(category);
                    final point = activityPoint(data);
                    final participants = List.from(data["participants"] ?? []);
                    final max = data["maxPeople"] ?? 0;
                    final full = max > 0 && participants.length >= max;

                    return Marker(
                      point: point,
                      width: 78,
                      height: 78,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _MapPreviewSheet(
                              activityId: doc.id,
                              data: data,
                              distance: distanceText(data),
                            ),
                          );
                        },
                        child: _OutlyEventMarker(
                          color: color,
                          icon: catIcon(category),
                          count: participants.length,
                          full: full,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        Positioned(
          left: 14,
          right: 14,
          top: 14,
          child: _MapGlassBar(
            text: myPosition == null
                ? "Standort aktivieren für Events in deiner Nähe"
                : "${docs.length} Events im Umkreis von ${radiusKm.round()} km",
            icon: myPosition == null ? Icons.location_off : Icons.radar,
          ),
        ),

        if (!fullscreen && mapLocked)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => mapLocked = false),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: C.cyan.withOpacity(0.40)),
                      boxShadow: [
                        BoxShadow(
                          color: C.cyan.withOpacity(0.20),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_rounded, color: C.cyan),
                        SizedBox(width: 10),
                        Text(
                          "Map antippen zum Bewegen",
                          style: TextStyle(
                            color: C.cyan,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        Positioned(
          left: 14,
          bottom: 14,
          child: _MapStatusChip(
            text: onlyToday ? "Nur heute" : "Alle Tage",
            icon: onlyToday ? Icons.local_fire_department : Icons.calendar_month,
            color: onlyToday ? C.orange : C.cyan,
          ),
        ),

        Positioned(
          right: 14,
          top: 66,
          child: Column(
            children: [
              _FloatingMapButton(
                icon: fullscreen ? Icons.close_fullscreen : Icons.open_in_full_rounded,
                onTap: () {
                  if (fullscreen) {
                    Navigator.pop(context);
                  } else {
                    openFullMap(docs, center);
                  }
                },
              ),
              const SizedBox(height: 10),
              if (!fullscreen)
                _FloatingMapButton(
                  icon: mapLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  onTap: () => setState(() => mapLocked = !mapLocked),
                ),
            ],
          ),
        ),

        if (!fullscreen)
          Positioned(
            right: 14,
            bottom: 14,
            child: Column(
              children: [
                _FloatingMapButton(
                  icon: Icons.add,
                  onTap: mapLocked
                      ? () => setState(() => mapLocked = false)
                      : () {
                          final cam = mapController.camera;
                          mapController.move(cam.center, cam.zoom + 1);
                        },
                ),
                const SizedBox(height: 10),
                _FloatingMapButton(
                  icon: Icons.remove,
                  onTap: mapLocked
                      ? () => setState(() => mapLocked = false)
                      : () {
                          final cam = mapController.camera;
                          mapController.move(cam.center, cam.zoom - 1);
                        },
                ),
                const SizedBox(height: 10),
                _FloatingMapButton(
                  icon: Icons.my_location,
                  onTap: loadingLocation ? () {} : loadMyPosition,
                ),
              ],
            ),
          ),
      ],
    );
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
              return const Center(child: CircularProgressIndicator(color: C.cyan));
            }

            final docs = snap.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return isEventActive(data) &&
                  canSeeActivity(data, uid) &&
                  matchesCategory(data) &&
                  matchesSearch(data) &&
                  matchesRadius(data) &&
                  matchesToday(data);
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
                _OutlyHeroHeader(
                  eventCount: docs.length,
                  onlyToday: onlyToday,
                  hasLocation: myPosition != null,
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: searchController,
                  onChanged: (v) => setState(() => search = v),
                  decoration: InputDecoration(
                    hintText: "Suche Ort, Event oder Vibe...",
                    prefixIcon: const Icon(Icons.search, color: C.cyan),
                    suffixIcon: search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () {
                              searchController.clear();
                              setState(() => search = "");
                            },
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _NeonActionPill(
                        active: onlyToday,
                        icon: Icons.local_fire_department,
                        title: "Heute",
                        subtitle: "Live",
                        color: C.orange,
                        onTap: () => setState(() => onlyToday = !onlyToday),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NeonActionPill(
                        active: myPosition != null,
                        loading: loadingLocation,
                        icon: Icons.my_location,
                        title: "Standort",
                        subtitle: myPosition == null ? "finden" : "aktiv",
                        color: C.cyan,
                        onTap: loadingLocation ? () {} : loadMyPosition,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NeonActionPill(
                        active: false,
                        icon: Icons.center_focus_strong,
                        title: "Fokus",
                        subtitle: "Map",
                        color: C.purple2,
                        onTap: () => focusAllEvents(docs),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  height: MediaQuery.of(context).size.height * 0.38,
                  constraints: const BoxConstraints(
                    minHeight: 270,
                    maxHeight: 360,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: C.cyan.withOpacity(0.34)),
                    boxShadow: [
                      BoxShadow(
                        color: C.cyan.withOpacity(0.15),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: C.purple.withOpacity(0.14),
                        blurRadius: 34,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: buildMap(
                    docs: docs,
                    center: center,
                    fullscreen: false,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: C.cyan.withOpacity(0.16)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        mapLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                        color: mapLocked ? C.orange : C.green,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          mapLocked
                              ? "Map ist gesperrt – du kannst normal scrollen."
                              : "Map ist aktiv – tippe auf Schloss, wenn Scrollen stört.",
                          style: const TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _RadiusControl(
                  radiusKm: radiusKm,
                  onChanged: (v) {
                    setState(() => radiusKm = v);
                    if (myPosition != null) {
                      mapController.move(myPosition!, zoomForRadius(v));
                    }
                  },
                ),

                const SizedBox(height: 12),

                _CategoryChips(
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onChanged: (c) => setState(() => selectedCategory = c),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Events auf der Map",
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: C.cyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: C.cyan.withOpacity(0.30)),
                      ),
                      child: Text(
                        "${docs.length} gefunden",
                        style: const TextStyle(
                          color: C.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (docs.isEmpty)
                  const InfoCard(
                    title: "Keine Events gefunden",
                    text: "Aktiviere deinen Standort oder ändere Radius, Suche und Kategorie.",
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

class _FullOutlyMapScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final LatLng center;
  final LatLng? myPosition;
  final double radiusKm;
  final LatLng Function(Map<String, dynamic>) activityPoint;
  final String Function(Map<String, dynamic>) distanceText;

  const _FullOutlyMapScreen({
    required this.docs,
    required this.center,
    required this.myPosition,
    required this.radiusKm,
    required this.activityPoint,
    required this.distanceText,
  });

  @override
  State<_FullOutlyMapScreen> createState() => _FullOutlyMapScreenState();
}

class _FullOutlyMapScreenState extends State<_FullOutlyMapScreen> {
  final MapController controller = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: controller,
                  options: MapOptions(
                    initialCenter: widget.center,
                    initialZoom: 12.8,
                    minZoom: 3,
                    maxZoom: 19,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: "com.clipza.outly",
                      maxZoom: 19,
                      tileProvider: NetworkTileProvider(),
                    ),
                    CircleLayer(
                      circles: [
                        if (widget.myPosition != null)
                          CircleMarker(
                            point: widget.myPosition!,
                            radius: widget.radiusKm * 1000,
                            useRadiusInMeter: true,
                            color: C.cyan.withOpacity(0.08),
                            borderColor: C.cyan.withOpacity(0.60),
                            borderStrokeWidth: 2,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        if (widget.myPosition != null)
                          Marker(
                            point: widget.myPosition!,
                            width: 74,
                            height: 74,
                            child: _UserPulseMarker(),
                          ),
                        ...widget.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final category = data["category"] ?? "Chill";
                          final color = catColor(category);
                          final point = widget.activityPoint(data);
                          final participants = List.from(data["participants"] ?? []);
                          final max = data["maxPeople"] ?? 0;
                          final full = max > 0 && participants.length >= max;

                          return Marker(
                            point: point,
                            width: 78,
                            height: 78,
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _MapPreviewSheet(
                                    activityId: doc.id,
                                    data: data,
                                    distance: widget.distanceText(data),
                                  ),
                                );
                              },
                              child: _OutlyEventMarker(
                                color: color,
                                icon: catIcon(category),
                                count: participants.length,
                                full: full,
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
                  child: _MapGlassBar(
                    text: "${widget.docs.length} Events auf Outly",
                    icon: Icons.public_rounded,
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 72,
                  child: Column(
                    children: [
                      _FloatingMapButton(
                        icon: Icons.close_fullscreen_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 10),
                      _FloatingMapButton(
                        icon: Icons.add,
                        onTap: () {
                          final cam = controller.camera;
                          controller.move(cam.center, cam.zoom + 1);
                        },
                      ),
                      const SizedBox(height: 10),
                      _FloatingMapButton(
                        icon: Icons.remove,
                        onTap: () {
                          final cam = controller.camera;
                          controller.move(cam.center, cam.zoom - 1);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlyHeroHeader extends StatelessWidget {
  final int eventCount;
  final bool onlyToday;
  final bool hasLocation;

  const _OutlyHeroHeader({
    required this.eventCount,
    required this.onlyToday,
    required this.hasLocation,
  });

  @override
  Widget build(BuildContext context) {
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
            color: C.purple.withOpacity(0.32),
            blurRadius: 38,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: C.cyan.withOpacity(0.16),
            blurRadius: 44,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -22,
            child: Icon(
              Icons.public,
              size: 170,
              color: C.cyan.withOpacity(0.055),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 6,
            child: Icon(
              Icons.auto_awesome,
              size: 72,
              color: C.pink.withOpacity(0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const OutlyLogo(),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.09)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: C.cyan, size: 18),
                        const SizedBox(width: 7),
                        Text(
                          "$eventCount LIVE",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
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
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "DIE WELT IST DEIN SPIELPLATZ.",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Finde echte Aktivitäten, neue Leute und Live-Momente in deiner Nähe.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _HeroMiniStat(
                    icon: Icons.local_fire_department,
                    text: onlyToday ? "Heute aktiv" : "Alle Events",
                    color: C.orange,
                  ),
                  const SizedBox(width: 10),
                  _HeroMiniStat(
                    icon: Icons.my_location,
                    text: hasLocation ? "Standort aktiv" : "Standort aus",
                    color: C.cyan,
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

class _HeroMiniStat extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _HeroMiniStat({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonActionPill extends StatelessWidget {
  final bool active;
  final bool loading;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NeonActionPill({
    required this.active,
    this.loading = false,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.18) : Colors.white.withOpacity(0.045),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: active ? color : Colors.white.withOpacity(0.10)),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.30),
                    blurRadius: 24,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            loading
                ? SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      color: color,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(icon, color: color, size: 23),
            const SizedBox(height: 7),
            Text(
              title,
              style: TextStyle(
                color: active ? color : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserPulseMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: C.cyan.withOpacity(0.16),
            boxShadow: [
              BoxShadow(
                color: C.cyan.withOpacity(0.55),
                blurRadius: 24,
              ),
            ],
          ),
        ),
        Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: C.cyan,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.person_pin_circle, color: Colors.black),
        ),
      ],
    );
  }
}

class _OutlyEventMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final int count;
  final bool full;

  const _OutlyEventMarker({
    required this.color,
    required this.icon,
    required this.count,
    required this.full,
  });

  @override
  Widget build(BuildContext context) {
    final markerColor = full ? Colors.redAccent : color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.45),
        border: Border.all(color: markerColor, width: 2.4),
        boxShadow: [
          BoxShadow(
            color: markerColor.withOpacity(0.70),
            blurRadius: 24,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            backgroundColor: markerColor,
            radius: 26,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (count > 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: full ? Colors.redAccent : C.orange,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Text(
                  "$count",
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
    );
  }
}

class _MapGlassBar extends StatelessWidget {
  final String text;
  final IconData icon;

  const _MapGlassBar({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: C.cyan, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapStatusChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _MapStatusChip({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingMapButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.62),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: C.cyan.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: C.cyan.withOpacity(0.12),
                blurRadius: 16,
              ),
            ],
          ),
          child: Icon(icon, color: C.cyan),
        ),
      ),
    );
  }
}

class _RadiusControl extends StatelessWidget {
  final double radiusKm;
  final ValueChanged<double> onChanged;

  const _RadiusControl({
    required this.radiusKm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 8),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: C.cyan.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.radar, color: C.cyan),
              const SizedBox(width: 8),
              const Text(
                "Radius",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  const _CategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
            onTap: () => onChanged(c),
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
                      color: active ? Colors.black : Colors.white70,
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
    final imageUrl = (data["imageUrl"] ?? "").toString().trim();

    return Container(
      margin: const EdgeInsets.all(14),
      clipBehavior: Clip.antiAlias,
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
              height: 165,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.85),
                    C.card,
                    Colors.black,
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        catIcon(category),
                        size: 72,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(
                      catIcon(category),
                      size: 72,
                      color: Colors.white,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.75),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        height: 5,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white38,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color,
                          radius: 26,
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
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                children: [
                  _SheetInfoRow(
                    icon: Icons.location_on_outlined,
                    text: data["place"] ?? "",
                  ),
                  const SizedBox(height: 7),
                  _SheetInfoRow(
                    icon: Icons.access_time,
                    text: "${data["date"] ?? ""} ${data["time"] ?? ""}",
                  ),
                  const SizedBox(height: 7),
                  _SheetInfoRow(
                    icon: Icons.near_me_outlined,
                    text: distance,
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
                              builder: (_) => ActivityDetailScreen(
                                activityId: activityId,
                              ),
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
    );
  }
}

class _SheetInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SheetInfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 2),
        Icon(icon, color: C.cyan, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ),
      ],
    );
  }
}