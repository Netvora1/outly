import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_colors.dart';
import '../../core/event_utils.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/auth/gradient_button.dart';
import '../../widgets/auth/outly_logo.dart';
import '../../widgets/common/info_card.dart';
import '../../widgets/common/outly_avatar.dart';
import '../../widgets/common/verified_name.dart';
import '../home/home_screen.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final title = TextEditingController();
  final place = TextEditingController();
  final description = TextEditingController();

  String category = "Sport";
  String visibility = "public";
  String joinMode = "open";

  int maxPeople = 10;
  int durationHours = 3;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  XFile? imageFile;

  bool loading = false;
  List<String> selectedPrivateUsers = [];

  final categories = ["Sport", "Chill", "Party", "Gaming", "Gym"];

  @override
  void dispose() {
    title.dispose();
    place.dispose();
    description.dispose();
    super.dispose();
  }

  String get dateText {
    if (selectedDate == null) return "Datum";
    final d = selectedDate!;
    return "${d.day.toString().padLeft(2, "0")}.${d.month.toString().padLeft(2, "0")}.${d.year}";
  }

  String get timeText {
    if (selectedTime == null) return "Uhrzeit";
    return "${selectedTime!.hour.toString().padLeft(2, "0")}:${selectedTime!.minute.toString().padLeft(2, "0")}";
  }

  int get vibeScore {
    int score = 40;
    if (imageFile != null) score += 20;
    if (title.text.trim().length >= 6) score += 10;
    if (description.text.trim().length >= 20) score += 15;
    if (place.text.trim().isNotEmpty) score += 10;
    if (selectedDate != null && selectedTime != null) score += 5;
    return score.clamp(0, 100);
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: selectedDate ?? now,
    );

    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
    );

    if (picked != null) {
      setState(() => imageFile = picked);
    }
  }

  Future<void> openFriendPicker() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PrivateFriendsPicker(
        initialSelected: selectedPrivateUsers,
      ),
    );

    if (result != null) {
      setState(() => selectedPrivateUsers = result);
    }
  }

  Future<void> createActivity() async {
    if (loading) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (title.text.trim().isEmpty ||
        place.text.trim().isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bitte Titel, Ort, Datum und Uhrzeit ausfüllen")),
      );
      return;
    }

    if (visibility == "private" && selectedPrivateUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wähle mindestens einen Freund für ein privates Event aus")),
      );
      return;
    }

    setState(() => loading = true);

    final address = place.text.trim();

    LatLng? point = await geocodeAddress(address);
    point ??= placeToLatLng(address);

    final startAt = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final deleteAt = startAt.add(Duration(hours: durationHours));

    String imageUrl = "";

    if (imageFile != null) {
      final bytes = await imageFile!.readAsBytes();

      imageUrl = await uploadImageBytes(
            bytes: bytes,
            path: "activity_images/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg",
          ) ??
          "";
    }

    final myDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final myData = myDoc.data() ?? {};
    final myFollowers = List<String>.from(myData["followers"] ?? []);

    final allowedUsers = visibility == "private"
        ? [...selectedPrivateUsers, uid]
        : <String>[];

    await FirebaseFirestore.instance.collection("activities").add({
      "title": title.text.trim(),
      "place": address,
      "date": dateText,
      "time": timeText,
      "description": description.text.trim(),
      "category": category,
      "maxPeople": maxPeople,
      "spotsLeft": maxPeople - 1,
      "durationHours": durationHours,
      "vibeScore": vibeScore,
      "participants": [uid],
      "pendingRequests": [],
      "creatorId": uid,
      "creatorFollowers": myFollowers,
      "visibility": visibility,
      "allowedUsers": allowedUsers,
      "joinMode": joinMode,
      "hasChat": false,
      "imageUrl": imageUrl,
      "lat": point.latitude,
      "lng": point.longitude,
      "startAt": Timestamp.fromDate(startAt),
      "deleteAt": Timestamp.fromDate(deleteAt),
      "createdAt": Timestamp.now(),
      "updatedAt": Timestamp.now(),
      "reportedCount": 0,
      "riskFlags": [],
    });

    title.clear();
    place.clear();
    description.clear();

    if (!mounted) return;

    setState(() {
      selectedDate = null;
      selectedTime = null;
      imageFile = null;
      visibility = "public";
      joinMode = "open";
      maxPeople = 10;
      durationHours = 3;
      selectedPrivateUsers = [];
      loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event erstellt 🔥")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = catColor(category);

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.62),
                    C.card,
                    C.purple.withOpacity(0.25),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: color.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.30),
                    blurRadius: 34,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                   OutlyLogo(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Starte einen Plan 🔥",
                          style: TextStyle(fontSize: 29, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Mach aus einer Idee ein echtes Treffen.",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _CreatePreviewCard(
              color: color,
              title: title.text.trim().isEmpty ? "Dein Event-Titel" : title.text.trim(),
              place: place.text.trim().isEmpty ? "Ort auswählen" : place.text.trim(),
              date: dateText,
              time: timeText,
              category: category,
              imageFile: imageFile,
              maxPeople: maxPeople,
              vibeScore: vibeScore,
              onImageTap: pickImage,
            ),

            const SizedBox(height: 18),

            _CreateSectionTitle(
              title: "Basics",
              subtitle: "Sag kurz, was abgeht.",
            ),

            const SizedBox(height: 12),

            TextField(
              controller: title,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: "Titel z.B. Basketball im Park",
                prefixIcon: Icon(Icons.local_fire_department, color: C.cyan),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: place,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: "Ort / Adresse",
                prefixIcon: Icon(Icons.place_outlined, color: C.cyan),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlySelectBox(
                    text: dateText,
                    icon: Icons.calendar_month,
                    onTap: pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlySelectBox(
                    text: timeText,
                    icon: Icons.access_time,
                    onTap: pickTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: description,
              onChanged: (_) => setState(() {}),
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Beschreib kurz den Vibe...",
                prefixIcon: Icon(Icons.notes_outlined, color: C.cyan),
              ),
            ),

            const SizedBox(height: 22),

            _CreateSectionTitle(
              title: "Vibe wählen",
              subtitle: "Deine Kategorie steuert Look und Marker.",
            ),

            const SizedBox(height: 12),

            Row(
              children: categories.map((c) {
                final active = category == c;
                final cColor = catColor(c);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => category = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: active ? cColor : C.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cColor.withOpacity(0.55)),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: cColor.withOpacity(0.35),
                                  blurRadius: 18,
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            catIcon(c),
                            color: active ? Colors.black : cColor,
                            size: 21,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            c,
                            style: TextStyle(
                              fontSize: 10,
                              color: active ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 22),

            _CreateSectionTitle(
              title: "Dauer & Plätze",
              subtitle: "Mach es klar und verbindlich.",
            ),

            const SizedBox(height: 12),

            _CreateStepperCard(
              title: "Max. Teilnehmer",
              value: "$maxPeople",
              icon: Icons.groups_2_outlined,
              color: C.cyan,
              onMinus: () {
                if (maxPeople > 2) setState(() => maxPeople--);
              },
              onPlus: () => setState(() => maxPeople++),
            ),

            const SizedBox(height: 10),

            _CreateStepperCard(
              title: "Event-Dauer",
              value: "$durationHours h",
              icon: Icons.timer_outlined,
              color: C.orange,
              onMinus: () {
                if (durationHours > 1) setState(() => durationHours--);
              },
              onPlus: () {
                if (durationHours < 24) setState(() => durationHours++);
              },
            ),

            const SizedBox(height: 22),

            _CreateSectionTitle(
              title: "Sichtbarkeit",
              subtitle: "Wer darf dein Event sehen?",
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _CreateOptionCard(
                    title: "Öffentlich",
                    subtitle: "Alle sehen es",
                    icon: Icons.public,
                    active: visibility == "public",
                    color: C.cyan,
                    onTap: () => setState(() {
                      visibility = "public";
                      selectedPrivateUsers = [];
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CreateOptionCard(
                    title: "Follower",
                    subtitle: "Nur Follower",
                    icon: Icons.group,
                    active: visibility == "followers",
                    color: C.purple2,
                    onTap: () => setState(() {
                      visibility = "followers";
                      selectedPrivateUsers = [];
                    }),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _CreateOptionCard(
              title: "Privat",
              subtitle: selectedPrivateUsers.isEmpty
                  ? "Nur ausgewählte Freunde"
                  : "${selectedPrivateUsers.length} Freund${selectedPrivateUsers.length == 1 ? "" : "e"} ausgewählt",
              icon: Icons.lock,
              active: visibility == "private",
              color: C.orange,
              onTap: () async {
                setState(() => visibility = "private");
                await openFriendPicker();
              },
              fullWidth: true,
            ),

            if (visibility == "private") ...[
              const SizedBox(height: 10),
              GradientButton(
                text: selectedPrivateUsers.isEmpty
                    ? "Freunde auswählen"
                    : "Freunde ändern (${selectedPrivateUsers.length})",
                onPressed: openFriendPicker,
              ),
            ],

            const SizedBox(height: 22),

            _CreateSectionTitle(
              title: "Beitritt",
              subtitle: "Sollen Leute direkt rein oder anfragen?",
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _CreateOptionCard(
                    title: "Direkt",
                    subtitle: "Sofort dabei",
                    icon: Icons.bolt,
                    active: joinMode == "open",
                    color: C.green,
                    onTap: () => setState(() => joinMode = "open"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CreateOptionCard(
                    title: "Anfrage",
                    subtitle: "Du entscheidest",
                    icon: Icons.how_to_reg,
                    active: joinMode == "request",
                    color: C.pink,
                    onTap: () => setState(() => joinMode = "request"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _CreateSafetyBox(),

            const SizedBox(height: 18),

            GradientButton(
              text: loading ? "Event wird erstellt..." : "Event starten 🔥",
              onPressed: loading ? () {} : createActivity,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePreviewCard extends StatelessWidget {
  final Color color;
  final String title;
  final String place;
  final String date;
  final String time;
  final String category;
  final XFile? imageFile;
  final int maxPeople;
  final int vibeScore;
  final VoidCallback onImageTap;

  const _CreatePreviewCard({
    required this.color,
    required this.title,
    required this.place,
    required this.date,
    required this.time,
    required this.category,
    required this.imageFile,
    required this.maxPeople,
    required this.vibeScore,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onImageTap,
      child: Container(
        height: 235,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: C.card,
          border: Border.all(color: color.withOpacity(0.42)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.22),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: imageFile == null
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.82),
                            C.card,
                            Colors.black,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        catIcon(category),
                        color: Colors.white.withOpacity(0.9),
                        size: 72,
                      ),
                    )
                  : FutureBuilder<Uint8List>(
                      future: imageFile!.readAsBytes(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(color: C.cyan),
                          );
                        }

                        return Image.memory(snap.data!, fit: BoxFit.cover);
                      },
                    ),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.05),
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
                  _PreviewBadge(text: category, color: color),
                  const SizedBox(width: 7),
                  _PreviewBadge(text: "$date • $time", color: Colors.white),
                ],
              ),
            ),

            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.38),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  "Vibe $vibeScore%",
                  style: const TextStyle(
                    color: C.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 17),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$maxPeople Plätze",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (imageFile == null)
              const Positioned(
                right: 18,
                bottom: 74,
                child: Icon(Icons.add_a_photo_outlined, color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _PreviewBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = color == Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isWhite ? Colors.black : Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CreateSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CreateSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 34,
          decoration: BoxDecoration(
            color: C.cyan,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateStepperCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _CreateStepperCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: onMinus,
            icon: Icon(Icons.remove_circle_outline, color: color),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: onPlus,
            icon: Icon(Icons.add_circle_outline, color: color),
          ),
        ],
      ),
    );
  }
}

class _CreateSafetyBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: C.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: C.orange.withOpacity(0.30)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: C.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Safety-Tipp: Wähle öffentliche Orte und beschreibe klar, was geplant ist.",
              style: TextStyle(
                color: Colors.white70,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;

  const _CreateOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.18) : C.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? color : Colors.white.withOpacity(0.10),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 20,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: active ? color : C.card2,
              child: Icon(
                icon,
                color: active ? Colors.black : color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: active ? color : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}

class PrivateFriendsPicker extends StatefulWidget {
  final List<String> initialSelected;

  const PrivateFriendsPicker({
    super.key,
    required this.initialSelected,
  });

  @override
  State<PrivateFriendsPicker> createState() => _PrivateFriendsPickerState();
}

class _PrivateFriendsPickerState extends State<PrivateFriendsPicker> {
  late List<String> selected;

  @override
  void initState() {
    super.initState();
    selected = [...widget.initialSelected];
  }

  void toggle(String uid) {
    setState(() {
      if (selected.contains(uid)) {
        selected.remove(uid);
      } else {
        selected.add(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: const BoxDecoration(
        color: C.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Freunde auswählen",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: C.orange.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: C.orange.withOpacity(0.35)),
                ),
                child: Text(
                  "${selected.length} gewählt",
                  style: const TextStyle(
                    color: C.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Nur diese Personen können dein privates Event sehen.",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
              builder: (context, mySnap) {
                if (!mySnap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: C.cyan),
                  );
                }

                final myData = mySnap.data!.data() as Map<String, dynamic>? ?? {};
                final following = List<String>.from(myData["following"] ?? []);

                if (following.isEmpty) {
                  return const Center(
                    child: InfoCard(
                      title: "Keine Freunde",
                      text: "Folge zuerst Leuten, damit du private Events mit ihnen teilen kannst.",
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .where(FieldPath.documentId, whereIn: following.take(10).toList())
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: C.cyan),
                      );
                    }

                    final users = snap.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data["isBanned"] != true;
                    }).toList();

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: users.length,
                      itemBuilder: (context, i) {
                        final doc = users[i];
                        final data = doc.data() as Map<String, dynamic>;
                        final isSelected = selected.contains(doc.id);

                        return GestureDetector(
                          onTap: () => toggle(doc.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? C.orange.withOpacity(0.15)
                                  : C.card,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isSelected
                                    ? C.orange
                                    : Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                OutlyAvatar(
                                  photoUrl: (data["photoUrl"] ?? "").toString(),
                                  radius: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      verifiedName(
                                        data["username"] ?? "user",
                                        data["verified"] == true,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data["city"] ?? "Keine Stadt",
                                        style: const TextStyle(color: Colors.white54),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected ? C.orange : Colors.white30,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          GradientButton(
            text: "Auswahl übernehmen",
            onPressed: () => Navigator.pop(context, selected),
          ),
        ],
      ),
    );
  }
}
