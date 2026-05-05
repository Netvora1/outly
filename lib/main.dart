import 'app.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

import 'firebase_options.dart';

const String adminUid = "roduqZRk4GgXLCQIZGIFAWN0UUg1";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const OutlyApp());
}

class C {
  static const bg = Color(0xFF07080F);
  static const card = Color(0xFF12131D);
  static const card2 = Color(0xFF1A1B27);
  static const purple = Color(0xFF7C2DFF);
  static const purple2 = Color(0xFF9B4DFF);
  static const cyan = Color(0xFF00F5D4);
  static const green = Color(0xFF5CFF7A);
  static const pink = Color(0xFFFF3D9A);
  static const orange = Color(0xFFFFA726);
  static const red = Colors.redAccent;
}

bool isAdminUser() {
  return FirebaseAuth.instance.currentUser?.uid == adminUid;
}

int calculateAge(DateTime birthDate) {
  final now = DateTime.now();
  var age = now.year - birthDate.year;

  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }

  return age;
}

DateTime? parseBirthDate(String input) {
  final parts = input.trim().split(".");
  if (parts.length != 3) return null;

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) return null;

  final parsed = DateTime.tryParse(
    "${year.toString().padLeft(4, "0")}-${month.toString().padLeft(2, "0")}-${day.toString().padLeft(2, "0")}",
  );

  if (parsed == null) return null;
  if (parsed.day != day || parsed.month != month || parsed.year != year) {
    return null;
  }

  return parsed;
}

String safetyLabel(int score) {
  if (score >= 90) return "Sehr sicher";
  if (score >= 70) return "Sicher";
  if (score >= 40) return "Achtung";
  return "Risiko";
}

Color safetyColor(int score) {
  if (score >= 90) return C.green;
  if (score >= 70) return C.cyan;
  if (score >= 40) return C.orange;
  return C.red;
}

bool isEventActive(Map<String, dynamic> data) {
  final deleteAt = data["deleteAt"];
  if (deleteAt is Timestamp) {
    return deleteAt.toDate().isAfter(DateTime.now());
  }
  return true;
}

bool isBlockedByData(Map<String, dynamic>? myData, String otherUserId) {
  final blocked = List<String>.from(myData?["blockedUsers"] ?? []);
  return blocked.contains(otherUserId);
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

LatLng placeToLatLng(String place) {
  final p = place.toLowerCase().trim();

  if (p.contains("wien") || p.contains("vienna")) return const LatLng(48.2082, 16.3738);
  if (p.contains("st. pölten") || p.contains("st pölten") || p.contains("sankt pölten")) return const LatLng(48.2031, 15.6256);
  if (p.contains("krems")) return const LatLng(48.4100, 15.6000);
  if (p.contains("tulln")) return const LatLng(48.3297, 16.0570);
  if (p.contains("wiener neustadt")) return const LatLng(47.8112, 16.2430);
  if (p.contains("baden")) return const LatLng(48.0069, 16.2349);
  if (p.contains("mödling") || p.contains("moedling")) return const LatLng(48.0854, 16.2833);
  if (p.contains("amstetten")) return const LatLng(48.1229, 14.8721);
  if (p.contains("melk")) return const LatLng(48.2276, 15.3319);
  if (p.contains("linz")) return const LatLng(48.3069, 14.2858);
  if (p.contains("graz")) return const LatLng(47.0707, 15.4395);
  if (p.contains("salzburg")) return const LatLng(47.8095, 13.0550);
  if (p.contains("innsbruck")) return const LatLng(47.2692, 11.4041);

  if (p.contains("berlin")) return const LatLng(52.5200, 13.4050);
  if (p.contains("hamburg")) return const LatLng(53.5511, 9.9937);
  if (p.contains("münchen") || p.contains("munich")) return const LatLng(48.1351, 11.5820);
  if (p.contains("köln") || p.contains("koeln")) return const LatLng(50.9375, 6.9603);
  if (p.contains("frankfurt")) return const LatLng(50.1109, 8.6821);

  if (p.contains("zürich") || p.contains("zurich")) return const LatLng(47.3769, 8.5417);
  if (p.contains("basel")) return const LatLng(47.5596, 7.5886);
  if (p.contains("bern")) return const LatLng(46.9480, 7.4474);

  return const LatLng(48.2082, 16.3738);
}

Future<LatLng?> geocodeAddress(String address) async {
  final query = address.trim();
  if (query.isEmpty) return null;

  final uri = Uri.https(
    "nominatim.openstreetmap.org",
    "/search",
    {
      "q": query,
      "format": "json",
      "limit": "1",
      "addressdetails": "1",
      "countrycodes": "at,de,ch",
      "email": "outly@gmail.com",
    },
  );

  final response = await http.get(
    uri,
    headers: {"User-Agent": "OutlyApp/1.0 (outly@gmail.com)"},
  );

  if (response.statusCode != 200) return null;

  final data = jsonDecode(response.body);
  if (data is! List || data.isEmpty) return null;

  final first = data.first as Map<String, dynamic>;
  final lat = double.tryParse(first["lat"].toString());
  final lng = double.tryParse(first["lon"].toString());

  if (lat == null || lng == null) return null;

  return LatLng(lat, lng);
}

Future<String?> uploadImageBytes({
  required Uint8List bytes,
  required String path,
}) async {
  final ref = FirebaseStorage.instance.ref(path);

  await ref.putData(
    bytes,
    SettableMetadata(contentType: "image/jpeg"),
  );

  return ref.getDownloadURL();
}

/* AUTH */

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;

        if (user == null) return  LoginScreen();
        if (!user.emailVerified) return const VerifyEmailScreen();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection("users").doc(user.uid).get(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const Scaffold(
                backgroundColor: C.bg,
                body: Center(child: CircularProgressIndicator(color: C.cyan)),
              );
            }

            final data = userSnap.data!.data() as Map<String, dynamic>? ?? {};

            if (data["isBanned"] == true) {
              return const BannedScreen();
            }

            return const MainNavigation();
          },
        );
      },
    );
  }
}

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, color: Colors.redAccent, size: 80),
          const SizedBox(height: 18),
          const Text(
            "Account gesperrt",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Dein Account wurde aus Sicherheitsgründen gesperrt.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: "Abmelden",
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    );
  }
}


class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool loading = false;
  String msg = "";

  Future<void> checkVerification() async {
    setState(() {
      loading = true;
      msg = "";
    });

    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    setState(() => loading = false);

    if (refreshedUser?.emailVerified == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (_) => false,
      );
    } else {
      setState(() {
        msg = "Noch nicht bestätigt. Öffne den Link in deiner E-Mail und versuch es nochmal.";
      });
    }
  }

  Future<void> resendEmail() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();

    if (!mounted) return;

    setState(() {
      msg = "Bestätigungs-Mail wurde erneut gesendet. Prüfe auch deinen Spam-Ordner.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const OutlyLogo(big: true),
          const SizedBox(height: 26),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: C.cyan.withOpacity(0.30)),
              boxShadow: [
                BoxShadow(
                  color: C.cyan.withOpacity(0.18),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.mark_email_read_outlined, color: C.cyan, size: 62),
                const SizedBox(height: 16),
                const Text(
                  "E-Mail bestätigen",
                  style: TextStyle(
                    color: C.cyan,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Wir haben dir einen Bestätigungslink geschickt. Öffne die Mail, bestätige deine Adresse und komm dann zurück zu Outly.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Tipp: Schau auch im Spam-Ordner nach.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: C.orange, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 22),

                GradientButton(
                  text: loading ? "Prüfe..." : "Ich habe bestätigt",
                  onPressed: loading ? () {} : checkVerification,
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: resendEmail,
                  child: const Text(
                    "E-Mail nochmal senden",
                    style: TextStyle(color: C.cyan),
                  ),
                ),

                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text(
                    "Zurück zum Login",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),

                if (msg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthHeroCard extends StatelessWidget {
  final bool compact;

  const AuthHeroCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            C.purple.withOpacity(0.55),
            C.card,
            C.cyan.withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: C.cyan.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: C.purple.withOpacity(0.25),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 54 : 64,
            height: compact ? 54 : 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [C.purple, C.cyan]),
            ),
            child: Icon(
              Icons.explore,
              color: Colors.white,
              size: compact ? 30 : 36,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Live. Safe. Real.",
                  style: TextStyle(
                    color: C.cyan,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Events, Leute und echte Momente in deiner Nähe.",
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCheckTile extends StatelessWidget {
  final bool value;
  final Color color;
  final IconData icon;
  final String title;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTapText;

  const AuthCheckTile({
    super.key,
    required this.value,
    required this.color,
    required this.icon,
    required this.title,
    required this.onChanged,
    this.onTapText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.13) : C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? color.withOpacity(0.65) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onTapText,
                child: Text(
                  title,
                  style: TextStyle(
                    color: onTapText == null ? Colors.white70 : C.cyan,
                    fontWeight: onTapText == null ? FontWeight.w500 : FontWeight.bold,
                  ),
                ),
              ),
            ),
            Checkbox(
              value: value,
              activeColor: color,
              onChanged: (v) => onChanged(v ?? false),
            ),
          ],
        ),
      ),
    );
  }
}

/* MAIN NAVIGATION */

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;

  final screens = const [
    HomeScreen(),
    ExploreMapScreen(),
    CreateActivityScreen(),
    ChatsFriendsStoryScreen(),
    ProfileScreen(),
  ];

  void changeTab(int i) {
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: screens[index],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: C.cyan.withOpacity(0.16)),
            boxShadow: [
              BoxShadow(
                color: C.purple.withOpacity(0.28),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _OutlyNavItem(
                icon: Icons.home_rounded,
                label: "Home",
                active: index == 0,
                color: C.cyan,
                onTap: () => changeTab(0),
              ),
              _OutlyNavItem(
                icon: Icons.explore_rounded,
                label: "Map",
                active: index == 1,
                color: C.green,
                onTap: () => changeTab(1),
              ),

              Expanded(
                child: GestureDetector(
                  onTap: () => changeTab(2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 58,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [C.purple, C.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: C.cyan.withOpacity(index == 2 ? 0.55 : 0.30),
                          blurRadius: index == 2 ? 24 : 16,
                        ),
                      ],
                    ),
                    child: Icon(
                      index == 2 ? Icons.add_circle : Icons.add,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),

              _OutlyNavItem(
                icon: Icons.chat_bubble_rounded,
                label: "Chats",
                active: index == 3,
                color: C.pink,
                onTap: () => changeTab(3),
              ),
              _OutlyNavItem(
                icon: Icons.person_rounded,
                label: "Profil",
                active: index == 4,
                color: C.orange,
                onTap: () => changeTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlyNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _OutlyNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 58,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: active
                ? Border.all(color: color.withOpacity(0.35))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? color : Colors.white38,
                size: active ? 25 : 23,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? color : Colors.white38,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* HOME */

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
              const OutlyLogo(),
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
                        builder: (_) => const NotificationsScreen(),
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
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(
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
                      ),
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
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: const Icon(Icons.person, size: 14),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Text(
                          max > 0 ? "${participants.length}/$max" : "${participants.length}",
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

/* CREATE ACTIVITY */

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
                  const OutlyLogo(),
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
                  icon: const Icon(Icons.check_circle, color: C.green),
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
                            const InfoCard(
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
/* MAP / ENTDECKEN */

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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) mapController.move(point, 13);
      });
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

    return placeToLatLng(data["place"] ?? "");
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

  bool matchesRadius(Map<String, dynamic> data) {
    if (myPosition == null) return true;

    final point = activityPoint(data);
    final km = distanceInKm(myPosition!, point);

    return km <= radiusKm;
  }

  double zoomForRadius(double radius) {
    if (radius <= 5) return 13.5;
    if (radius <= 10) return 12.5;
    if (radius <= 20) return 11.5;
    if (radius <= 50) return 10;
    return 8.8;
  }

  String distanceText(Map<String, dynamic> data) {
    if (myPosition == null) return "Standort aus";

    final point = activityPoint(data);
    final km = distanceInKm(myPosition!, point);

    if (km < 1) return "${(km * 1000).round()} m entfernt";
    return "${km.toStringAsFixed(1)} km entfernt";
  }

  @override
  Widget build(BuildContext context) {
    final center = myPosition ?? const LatLng(48.2082, 16.3738);
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
              return const Center(child: CircularProgressIndicator(color: C.cyan));
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                Row(
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
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Finde Events auf deiner Map.",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: C.card,
                      child: IconButton(
                        icon: loadingLocation
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: C.cyan,
                                ),
                              )
                            : const Icon(Icons.my_location, color: C.cyan),
                        onPressed: loadingLocation ? null : loadMyPosition,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

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
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: C.cyan.withOpacity(0.30)),
                    boxShadow: [
                      BoxShadow(
                        color: C.cyan.withOpacity(0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
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
                            keepBuffer: 2,
                          ),
                          CircleLayer(
                            circles: [
                              if (myPosition != null)
                                CircleMarker(
                                  point: myPosition!,
                                  radius: radiusKm * 1000,
                                  useRadiusInMeter: true,
                                  color: C.cyan.withOpacity(0.08),
                                  borderColor: C.cyan.withOpacity(0.50),
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
                                        builder: (_) {
                                          return _MapPreviewSheet(
                                            activityId: doc.id,
                                            data: data,
                                            distance: distanceText(data),
                                          );
                                        },
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
                                                padding: const EdgeInsets.symmetric(
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      "${radiusKm.round()} km",
                      style: const TextStyle(
                        color: C.cyan,
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

                const SizedBox(height: 4),

                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      final c = categories[i];
                      final active = selectedCategory == c;
                      final color = c == "Alle" ? C.cyan : catColor(c);

                      return GestureDetector(
                        onTap: () => setState(() => selectedCategory = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 9),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: active ? color : C.card,
                            border: Border.all(
                              color: active ? color : color.withOpacity(0.4),
                            ),
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
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Events auf der Map",
                        style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
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
                  InfoCard(
                    title: "Keine Events gefunden",
                    text: myPosition == null
                        ? "Aktiviere deinen Standort oder ändere die Filter."
                        : "Im Umkreis von ${radiusKm.round()} km ist gerade nichts Passendes.",
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

class _ExploreMiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _ExploreMiniStat({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withOpacity(0.10),
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
    final imageUrl = (data["imageUrl"] ?? "").toString();
    final full = max > 0 && participants.length >= max;

    Widget fallbackImage({bool broken = false}) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
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
        child: Center(
          child: Icon(
            broken ? Icons.broken_image : catIcon(category),
            color: Colors.white,
            size: 58,
          ),
        ),
      );
    }

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

            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => fallbackImage(broken: true),
                    )
                  : fallbackImage(),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.45)),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(width: 8),

                if (full)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.45)),
                    ),
                    child: const Text(
                      "Voll",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const Spacer(),

                Text(
                  distance,
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.right,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                data["title"] ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "📍 ${data["place"] ?? ""}\n⏰ ${data["date"] ?? ""} ${data["time"] ?? ""}",
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
                        builder: (_) => ActivityDetailScreen(activityId: activityId),
                      ),
                    );
                  },
                  child: const Text(
                    "Ansehen",
                    style: TextStyle(fontWeight: FontWeight.bold),
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

/* CHATS / FREUNDE / STORIES */

class ChatsFriendsStoryScreen extends StatefulWidget {
  const ChatsFriendsStoryScreen({super.key});

  @override
  State<ChatsFriendsStoryScreen> createState() => _ChatsFriendsStoryScreenState();
}

class _ChatsFriendsStoryScreenState extends State<ChatsFriendsStoryScreen> {
  int tab = 0;
  String search = "";

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: ListView(
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
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const OutlyLogo(),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Deine Leute 💬",
                              style: TextStyle(
                                fontSize: 29,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Chats, Freunde und echte Connections.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SegmentButton(
                            text: "Chats",
                            active: tab == 0,
                            onTap: () => setState(() => tab = 0),
                          ),
                        ),
                        Expanded(
                          child: SegmentButton(
                            text: "Freunde",
                            active: tab == 1,
                            onTap: () => setState(() => tab = 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const InstagramStoryBar(),
            const SizedBox(height: 14),

            if (tab == 0)
              ChatsList(uid: uid)
            else
              FriendsSearch(
                uid: uid,
                search: search,
                onSearch: (v) => setState(() => search = v),
              ),
          ],
        ),
      ),
    );
  }
}

class _SocialTabButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _SocialTabButton({
    required this.text,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: active ? C.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: C.cyan.withOpacity(0.30),
                    blurRadius: 18,
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

class ChatsList extends StatelessWidget {
  final String uid;

  const ChatsList({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("privateChats")
          .where("participants", arrayContains: uid)
          .snapshots(),
      builder: (context, privateSnap) {
        if (!privateSnap.hasData) {
          return const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator(color: C.cyan)),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("activities")
              .where("participants", arrayContains: uid)
              .snapshots(),
          builder: (context, activitySnap) {
            if (!activitySnap.hasData) {
              return const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator(color: C.cyan)),
              );
            }

            final privateChats = privateSnap.data!.docs.toList();
            final activityChats = activitySnap.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data["hasChat"] == true && isEventActive(data);
            }).toList();

            if (privateChats.isEmpty && activityChats.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 50),
                child: InfoCard(
                  title: "Noch keine Chats",
                  text: "Private Chats und Event-Chats erscheinen hier.",
                ),
              );
            }

            return Column(
              children: [
                ...privateChats.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final participants = List<String>.from(data["participants"] ?? []);

                  final otherUserId = participants.firstWhere(
                    (id) => id != uid,
                    orElse: () => "",
                  );

                  if (otherUserId.isEmpty) return const SizedBox.shrink();

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("users")
                        .doc(otherUserId)
                        .get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox.shrink();

                      final userData =
                          userSnap.data!.data() as Map<String, dynamic>? ?? {};

                      if (userData["isBanned"] == true) {
                        return const SizedBox.shrink();
                      }

                      final username = userData["username"] ?? "user";

                      return ChatTile(
                        color: C.cyan,
                        icon: Icons.person,
                        title: "@$username",
                        subtitle: data["lastMessage"] ?? "Privater Chat",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrivateChatScreen(
                                otherUserId: otherUserId,
                                otherUsername: username,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }),

                ...activityChats.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final category = data["category"] ?? "Chill";

                  return ChatTile(
                    color: catColor(category),
                    icon: catIcon(category),
                    title: data["title"] ?? "Event",
                    subtitle: data["place"] ?? "Event-Chat öffnen",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivityDetailScreen(activityId: doc.id),
                        ),
                      );
                    },
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class ChatTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.color,
    required this.icon,
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
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 16,
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.18),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}

class _FollowingList extends StatelessWidget {
  final String uid;
  final List<String> following;
  final List<String> followers;

  const _FollowingList({
    required this.uid,
    required this.following,
    required this.followers,
  });

  @override
  Widget build(BuildContext context) {
    if (following.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: const [
          InfoCard(
            title: "Noch keine Freunde",
            text: "Folge Leuten, dann erscheinen sie hier direkt. Du musst sie nicht jedes Mal neu suchen.",
          ),
        ],
      );
    }

    final visibleIds = following.take(10).toList();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .where(FieldPath.documentId, whereIn: visibleIds)
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

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                "Deine Freunde",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ...users.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final followsBack = followers.contains(doc.id);

              return FriendUserCard(
                userId: doc.id,
                data: data,
                followsBack: followsBack,
              );
            }),

            if (following.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: InfoCard(
                  title: "Mehr Freunde vorhanden",
                  text:
                      "Aktuell werden die ersten 10 angezeigt. Später machen wir Pagination, damit alle sauber geladen werden.",
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UserSearchResults extends StatelessWidget {
  final String uid;
  final String search;

  const _UserSearchResults({
    required this.uid,
    required this.search,
  });

  bool matchesSearch(Map<String, dynamic> data, String search) {
    final q = search.trim().toLowerCase();

    final username = (data["username"] ?? "").toString().toLowerCase();
    final city = (data["city"] ?? "").toString().toLowerCase();
    final bio = (data["bio"] ?? "").toString().toLowerCase();

    return username.contains(q) || city.contains(q) || bio.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: C.cyan),
          );
        }

        final users = snap.data!.docs.where((doc) {
          if (doc.id == uid) return false;

          final data = doc.data() as Map<String, dynamic>;

          if (data["isBanned"] == true) return false;

          final blockedBy = List<String>.from(data["blockedBy"] ?? []);
          if (blockedBy.contains(uid)) return false;

          return matchesSearch(data, search);
        }).toList();

        if (users.isEmpty) {
          return const Center(
            child: InfoCard(
              title: "Nichts gefunden",
              text: "Kein User passt zu deiner Suche.",
            ),
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                "Suchergebnisse",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...users.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return FriendUserCard(
                userId: doc.id,
                data: data,
                followsBack: false,
              );
            }),
          ],
        );
      },
    );
  }
}

class FriendUserCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;
  final bool followsBack;

  const FriendUserCard({
    super.key,
    required this.userId,
    required this.data,
    required this.followsBack,
  });

  String chatId(String a, String b) {
    final ids = [a, b]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  @override
  Widget build(BuildContext context) {
    final username = (data["username"] ?? "user").toString();
    final city = (data["city"] ?? "Keine Stadt").toString();
    final bio = (data["bio"] ?? "").toString();
    final photoUrl = (data["photoUrl"] ?? "").toString();
    final verified = data["verified"] == true;
    final trustScore = data["trustScore"] ?? 100;
    final color = safetyColor(trustScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: userId),
                ),
              );
            },
            child: OutlyAvatar(
              photoUrl: photoUrl,
              radius: 29,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(userId: userId),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  verifiedName(username, verified, size: 17),
                  const SizedBox(height: 4),
                  Text(
                    city,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      MiniBadge(
                        text: safetyLabel(trustScore),
                        icon: Icons.shield_outlined,
                        color: color,
                      ),
                      if (followsBack)
                        const MiniBadge(
                          text: "folgt dir",
                          icon: Icons.favorite,
                          color: C.pink,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          Column(
            children: [
              CircleAvatar(
                backgroundColor: C.cyan,
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivateChatScreen(
                          otherUserId: userId,
                          otherUsername: username,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.08),
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white70),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(userId: userId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _FriendStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FriendsSearch extends StatelessWidget {
  final String uid;
  final String search;
  final ValueChanged<String> onSearch;

  const FriendsSearch({
    super.key,
    required this.uid,
    required this.search,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: TextField(
            onChanged: (v) => onSearch(v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: "Username suchen...",
              prefixIcon: Icon(Icons.search, color: C.cyan),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("users").snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }

              final users = snap.data!.docs.where((doc) {
                if (doc.id == uid) return false;
                final data = doc.data() as Map<String, dynamic>;
                if (data["isBanned"] == true) return false;

                final name = (data["username"] ?? "").toString().toLowerCase();

                if (search.isEmpty) {
                  final myFollowing = List<String>.from(data["followers"] ?? []);
                  return myFollowing.contains(uid);
                }

                return name.contains(search);
              }).toList();

              if (users.isEmpty) {
                return const Center(
                  child: InfoCard(
                    title: "Keine Freunde gefunden",
                    text: "Suche nach Usern oder folge Leuten.",
                  ),
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 140),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final doc = users[i];
                  final data = doc.data() as Map<String, dynamic>;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: C.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: C.cyan.withOpacity(0.22)),
                    ),
                    child: ListTile(
                      leading: OutlyAvatar(
                        photoUrl: (data["photoUrl"] ?? "").toString(),
                        radius: 25,
                      ),
                      title: verifiedName(
                        data["username"] ?? "user",
                        data["verified"] == true,
                      ),
                      subtitle: Text(
                        data["city"] ?? "Keine Stadt",
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(userId: doc.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(backgroundColor: C.bg, title: const Text("Profil")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(userId).get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final followers = List.from(data["followers"] ?? []);
          final following = List.from(data["following"] ?? []);
          final interests = List<String>.from(data["interests"] ?? ["Sport", "Chill", "Gaming"]);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                ProfileBox(
                  data: data,
                  followers: followers.length,
                  following: following.length,
                  userId: userId,
                  showActions: myUid != userId,
                ),
                if (myUid != userId) ...[
                  const SizedBox(height: 14),
                  FollowButton(targetUserId: userId),
                  const SizedBox(height: 12),
                  ReportUserButton(targetUserId: userId),
                  const SizedBox(height: 12),
                  BlockUserButton(targetUserId: userId),
                  const SizedBox(height: 12),
                  GradientButton(
                    text: "Nachricht",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrivateChatScreen(
                            otherUserId: userId,
                            otherUsername: data["username"] ?? "user",
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 22),
                InterestsWrap(interests: interests),
              ],
            ),
          );
        },
      ),
    );
  }
}
class PrivateChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUsername;

  const PrivateChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final msg = TextEditingController();

  @override
  void dispose() {
    msg.dispose();
    super.dispose();
  }

  String getChatId(String a, String b) {
    final ids = [a, b];
    ids.sort();
    return "${ids[0]}_${ids[1]}";
  }

  Future<bool> isBlocked() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final myDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final otherDoc = await FirebaseFirestore.instance.collection("users").doc(widget.otherUserId).get();

    final myData = myDoc.data() ?? {};
    final otherData = otherDoc.data() ?? {};

    final myBlocked = List<String>.from(myData["blockedUsers"] ?? []);
    final otherBlocked = List<String>.from(otherData["blockedUsers"] ?? []);

    return myBlocked.contains(widget.otherUserId) || otherBlocked.contains(uid);
  }

  Future<void> sendMessage() async {
    if (msg.text.trim().isEmpty) return;

    final blocked = await isBlocked();

    if (blocked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chat ist blockiert")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final chatId = getChatId(user.uid, widget.otherUserId);
    final text = msg.text.trim();
    final chatRef = FirebaseFirestore.instance.collection("privateChats").doc(chatId);

    await chatRef.set({
      "participants": [user.uid, widget.otherUserId],
      "lastMessage": text,
      "lastMessageAt": Timestamp.now(),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    await chatRef.collection("messages").add({
      "text": text,
      "senderId": user.uid,
      "receiverId": widget.otherUserId,
      "createdAt": Timestamp.now(),
    });

    msg.clear();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final chatId = getChatId(uid, widget.otherUserId);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: Text("@${widget.otherUsername}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserProfileScreen(userId: widget.otherUserId)),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: isBlocked(),
        builder: (context, blockSnap) {
          final blocked = blockSnap.data == true;

          return Column(
            children: [
              if (blocked)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: InfoCard(
                    title: "Chat blockiert",
                    text: "Ihr könnt euch aktuell keine Nachrichten senden.",
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SafetyBanner(),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("privateChats")
                      .doc(chatId)
                      .collection("messages")
                      .orderBy("createdAt")
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator(color: C.cyan));
                    }

                    final messages = snap.data!.docs;

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text("Noch keine Nachrichten", style: TextStyle(color: Colors.white54)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final m = messages[i].data() as Map<String, dynamic>;
                        final isMe = m["senderId"] == uid;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                            decoration: BoxDecoration(
                              color: isMe ? C.cyan : C.card2,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              m["text"] ?? "",
                              style: TextStyle(
                                color: isMe ? Colors.black : Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (!blocked) MessageInput(controller: msg, onSend: sendMessage),
            ],
          );
        },
      ),
    );
  }
}

class SafetyBanner extends StatelessWidget {
  const SafetyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.orange.withOpacity(0.35)),
      ),
      child: const Text(
        "Safety Hinweis: Teile keine privaten Daten und triff dich nur an sicheren öffentlichen Orten.",
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}

class InstagramStoryBar extends StatefulWidget {
  const InstagramStoryBar({super.key});

  @override
  State<InstagramStoryBar> createState() => _InstagramStoryBarState();
}

class _InstagramStoryBarState extends State<InstagramStoryBar> {
  final storyText = TextEditingController();
  XFile? storyImage;
  bool posting = false;

  @override
  void dispose() {
    storyText.dispose();
    super.dispose();
  }

  Future<void> pickStoryImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
    );

    if (picked != null) {
      setState(() => storyImage = picked);
    }
  }

  Future<void> createStory() async {
    if (posting) return;

    final user = FirebaseAuth.instance.currentUser!;
    final text = storyText.text.trim();

    if (text.isEmpty && storyImage == null) return;

    setState(() => posting = true);

    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    final userData = userDoc.data() ?? {};

    String imageUrl = "";

    if (storyImage != null) {
      final bytes = await storyImage!.readAsBytes();

      imageUrl = await uploadImageBytes(
            bytes: bytes,
            path: "story_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg",
          ) ??
          "";
    }

    await FirebaseFirestore.instance.collection("stories").add({
      "userId": user.uid,
      "email": user.email ?? "",
      "username": userData["username"] ?? "user",
      "photoUrl": userData["photoUrl"] ?? "",
      "text": text,
      "imageUrl": imageUrl,
      "createdAt": Timestamp.now(),
      "expiresAt": Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
    });

    storyText.clear();

    if (!mounted) return;

    setState(() {
      storyImage = null;
      posting = false;
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Story gepostet 🔥")),
    );
  }

  void openCreateStory() {
    storyText.clear();
    storyImage = null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              decoration: const BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              ),
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

                  const SizedBox(height: 18),

                  const Text(
                    "Story erstellen",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  GestureDetector(
                    onTap: () async {
                      await pickStoryImage();
                      sheetSetState(() {});
                    },
                    child: Container(
                      height: 190,
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: C.card,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: C.cyan.withOpacity(0.28)),
                      ),
                      child: storyImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  color: C.cyan,
                                  size: 52,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Bild hinzufügen",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Optional, macht deine Story stärker.",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            )
                          : FutureBuilder<Uint8List>(
                              future: storyImage!.readAsBytes(),
                              builder: (context, snap) {
                                if (!snap.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: C.cyan,
                                    ),
                                  );
                                }

                                return Image.memory(
                                  snap.data!,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: storyText,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Was machst du gerade?",
                      prefixIcon: Icon(Icons.auto_awesome, color: C.cyan),
                    ),
                  ),

                  const SizedBox(height: 16),

                  GradientButton(
                    text: posting ? "Poste..." : "Story posten 🔥",
                    onPressed: createStory,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return SizedBox(
      height: 116,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("stories").snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: C.cyan),
            );
          }

          final docs = snap.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final expiresAt = data["expiresAt"];

            if (expiresAt is Timestamp) {
              return expiresAt.toDate().isAfter(DateTime.now());
            }

            return true;
          }).toList();

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

          return ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            children: [
              StoryBubble(
                label: "Deine",
                icon: Icons.add,
                onTap: openCreateStory,
                isAdd: true,
              ),

              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return StoryBubble(
                  label: data["username"] ?? "Story",
                  icon: Icons.person,
                  photoUrl: (data["photoUrl"] ?? "").toString(),
                  imageUrl: (data["imageUrl"] ?? "").toString(),
                  isMine: data["userId"] == myUid,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(
                          storyId: doc.id,
                          data: data,
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class StoryViewerScreen extends StatelessWidget {
  final String storyId;
  final Map<String, dynamic> data;

  const StoryViewerScreen({
    super.key,
    required this.storyId,
    required this.data,
  });

  Future<void> deleteStory(BuildContext context) async {
    await FirebaseFirestore.instance.collection("stories").doc(storyId).delete();

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    final username = (data["username"] ?? "Story").toString();
    final text = (data["text"] ?? "").toString();
    final photoUrl = (data["photoUrl"] ?? "").toString();
    final imageUrl = (data["imageUrl"] ?? "").toString();
    final isMine = data["userId"] == myUid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [C.purple, Colors.black],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [C.purple, Colors.black, C.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                    Colors.black.withOpacity(0.75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      OutlyAvatar(photoUrl: photoUrl, radius: 23),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "@$username",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isMine)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => deleteStory(context),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const Spacer(),

                  if (text.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.42),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          height: 1.25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FollowButton extends StatefulWidget {
  final String targetUserId;

  const FollowButton({super.key, required this.targetUserId});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool loading = true;
  bool following = false;

  @override
  void initState() {
    super.initState();
    check();
  }

  Future<void> check() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final list = List<String>.from(doc.data()?["following"] ?? []);

    if (!mounted) return;

    setState(() {
      following = list.contains(widget.targetUserId);
      loading = false;
    });
  }

  Future<void> toggle() async {
    if (loading) return;

    setState(() => loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final myRef = FirebaseFirestore.instance.collection("users").doc(uid);
    final targetRef =
        FirebaseFirestore.instance.collection("users").doc(widget.targetUserId);

    try {
      if (following) {
        await myRef.set({
          "following": FieldValue.arrayRemove([widget.targetUserId]),
          "updatedAt": Timestamp.now(),
        }, SetOptions(merge: true));

        await targetRef.set({
          "followers": FieldValue.arrayRemove([uid]),
          "updatedAt": Timestamp.now(),
        }, SetOptions(merge: true));

        if (!mounted) return;

        setState(() {
          following = false;
          loading = false;
        });
      } else {
        await myRef.set({
          "following": FieldValue.arrayUnion([widget.targetUserId]),
          "updatedAt": Timestamp.now(),
        }, SetOptions(merge: true));

        await targetRef.set({
          "followers": FieldValue.arrayUnion([uid]),
          "updatedAt": Timestamp.now(),
        }, SetOptions(merge: true));

        await sendNotification(
          toUserId: widget.targetUserId,
          fromUserId: uid,
          type: "follow",
          text: "folgt dir jetzt.",
        );

        if (!mounted) return;

        setState(() {
          following = true;
          loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aktion fehlgeschlagen")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: loading ? null : toggle,
      icon: loading
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: C.cyan,
              ),
            )
          : Icon(
              following ? Icons.check_circle : Icons.person_add_alt_1,
            ),
      label: Text(
        loading
            ? "Lädt..."
            : following
                ? "Following"
                : "Follow",
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: following ? Colors.white12 : C.cyan,
        foregroundColor: following ? Colors.white : Colors.black,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class BlockUserButton extends StatefulWidget {
  final String targetUserId;

  const BlockUserButton({super.key, required this.targetUserId});

  @override
  State<BlockUserButton> createState() => _BlockUserButtonState();
}

class _BlockUserButtonState extends State<BlockUserButton> {
  bool loading = true;
  bool blocked = false;

  @override
  void initState() {
    super.initState();
    check();
  }

  Future<void> check() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final blockedUsers = List<String>.from(doc.data()?["blockedUsers"] ?? []);

    if (!mounted) return;

    setState(() {
      blocked = blockedUsers.contains(widget.targetUserId);
      loading = false;
    });
  }

  Future<void> toggleBlock() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final myRef = FirebaseFirestore.instance.collection("users").doc(uid);
    final targetRef = FirebaseFirestore.instance.collection("users").doc(widget.targetUserId);

    if (blocked) {
      await myRef.set({
        "blockedUsers": FieldValue.arrayRemove([widget.targetUserId]),
      }, SetOptions(merge: true));

      await targetRef.set({
        "blockedBy": FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));
    } else {
      await myRef.set({
        "blockedUsers": FieldValue.arrayUnion([widget.targetUserId]),
        "following": FieldValue.arrayRemove([widget.targetUserId]),
      }, SetOptions(merge: true));

      await targetRef.set({
        "blockedBy": FieldValue.arrayUnion([uid]),
        "followers": FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));
    }

    if (!mounted) return;

    setState(() => blocked = !blocked);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(blocked ? "User blockiert" : "Blockierung aufgehoben")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: toggleBlock,
      icon: Icon(blocked ? Icons.lock_open : Icons.block),
      label: Text(blocked ? "Blockierung aufheben" : "User blockieren"),
      style: ElevatedButton.styleFrom(
        backgroundColor: blocked ? Colors.white12 : Colors.red.withOpacity(0.14),
        foregroundColor: blocked ? Colors.white : Colors.redAccent,
        minimumSize: const Size(double.infinity, 46),
      ),
    );
  }
}

/* PROFILE */

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final username = TextEditingController();
  final city = TextEditingController();
  final bio = TextEditingController();

  bool uploadingImage = false;

  @override
  void dispose() {
    username.dispose();
    city.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> uploadProfileImage() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked == null) return;

    setState(() => uploadingImage = true);

    final bytes = await picked.readAsBytes();

    final url = await uploadImageBytes(
      bytes: bytes,
      path: "profile_images/$uid/profile.jpg",
    );

    if (url != null) {
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "photoUrl": url,
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));
    }

    if (!mounted) return;

    setState(() => uploadingImage = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profilbild aktualisiert ✅")),
    );
  }

  void openEdit(Map<String, dynamic> data) {
    username.text = data["username"] ?? "";
    city.text = data["city"] ?? "";
    bio.text = data["bio"] ?? "";

    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(context).viewInsets.bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Profil bearbeiten",
                style: TextStyle(
                  color: C.cyan,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: username,
                decoration: const InputDecoration(hintText: "Benutzername"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: city,
                decoration: const InputDecoration(hintText: "Stadt"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bio,
                maxLines: 3,
                decoration: const InputDecoration(hintText: "Über mich"),
              ),
              const SizedBox(height: 18),
              GradientButton(
                text: "Speichern",
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser!.uid;

                  await FirebaseFirestore.instance.collection("users").doc(uid).set({
                    "username": username.text.trim(),
                    "city": city.text.trim(),
                    "bio": bio.text.trim(),
                    "updatedAt": Timestamp.now(),
                  }, SetOptions(merge: true));

                  if (!mounted) return;

                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> applyVerification() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "verificationPending": true,
      "verificationAppliedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Verifizierung beantragt ✅")),
    );

    setState(() {});
  }

  Future<void> applyCreator() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "creatorPending": true,
      "creatorAppliedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Creator Bewerbung gesendet 🚀")),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: const Text("Profil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final followers = List.from(data["followers"] ?? []);
          final following = List.from(data["following"] ?? []);
          final interests = List<String>.from(
            data["interests"] ?? ["Sport", "Chill", "Gaming"],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                ProfileBox(
                  data: data,
                  followers: followers.length,
                  following: following.length,
                  userId: uid,
                  showActions: false,
                ),
                const SizedBox(height: 14),
                GradientButton(
                  text: uploadingImage ? "Bild wird hochgeladen..." : "Profilbild ändern",
                  onPressed: uploadingImage ? () {} : uploadProfileImage,
                ),
                const SizedBox(height: 14),
                GradientButton(
                  text: "Profil bearbeiten",
                  onPressed: () => openEdit(data),
                ),
                const SizedBox(height: 22),
                InterestsWrap(interests: interests),
                const SizedBox(height: 22),
                SettingsCard(
                  icon: Icons.verified,
                  title: data["verified"] == true
                      ? "Verifiziert"
                      : data["verificationPending"] == true
                          ? "Verifizierung läuft"
                          : "Verifizierung beantragen",
                  onTap: data["verificationPending"] == true ? () {} : applyVerification,
                ),
                SettingsCard(
                  icon: Icons.workspace_premium,
                  title: data["creator"] == true
                      ? "Creator aktiv"
                      : data["creatorPending"] == true
                          ? "Creator Bewerbung läuft"
                          : "Creator Programm beantragen",
                  onTap: data["creatorPending"] == true ? () {} : applyCreator,
                ),
                if (data["creator"] == true)
                  SettingsCard(
                    icon: Icons.paid,
                    title: "Creator Dashboard",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreatorDashboardScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CreatorDashboardScreen extends StatelessWidget {
  const CreatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: const Text("Creator Dashboard"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: C.cyan),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              InfoCard( // ❗ const entfernt
                title: "Creator Programm",
                text: "Hier siehst du später Einnahmen, Klicks und Einladungen.",
              ),
              const SizedBox(height: 18),

              CreatorStatCard(
                title: "Level",
                value: (data["creatorLevel"] ?? "none").toString(),
              ),
              CreatorStatCard(
                title: "Geschätzte Einnahmen",
                value: "${data["creatorEarnings"] ?? 0} €",
              ),
              CreatorStatCard(
                title: "Views",
                value: "${data["creatorViews"] ?? 0}",
              ),
              CreatorStatCard(
                title: "Klicks",
                value: "${data["creatorClicks"] ?? 0}",
              ),
              CreatorStatCard(
                title: "Referral Code",
                value: (data["creatorReferralCode"] ?? "Noch keiner").toString(),
              ),
            ],
          );
        },
      ),
    );
  }
}
class CreatorStatCard extends StatelessWidget {
  final String title;
  final String value;

  const CreatorStatCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.cyan.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(value, style: const TextStyle(color: C.cyan, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

Future<Position?> getUserPosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  return Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

double distanceInKm(LatLng a, LatLng b) {
  final distance = const Distance();
  return distance.as(LengthUnit.Kilometer, a, b);
}
/* SETTINGS + HELPERS */

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> resetPassword(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passwort-Link wurde gesendet")),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  Future<void> deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (user == null || uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        title: const Text("Account löschen"),
        content: const Text(
          "Dein Account wird dauerhaft gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.",
        ),
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

    try {
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "isDeleted": true,
        "email": "",
        "username": "deleted_user",
        "photoUrl": "",
        "bio": "",
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));

      await user.delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account gelöscht")),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bitte neu einloggen und Account löschen nochmal versuchen."),
        ),
      );
    }
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: C.cyan,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget dangerButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.14),
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.redAccent.withOpacity(0.35)),
          ),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? "Nicht verfügbar";

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
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  C.purple.withOpacity(0.55),
                  C.card,
                  C.cyan.withOpacity(0.20),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: C.cyan.withOpacity(0.30)),
              boxShadow: [
                BoxShadow(color: C.purple.withOpacity(0.25), blurRadius: 28),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [C.purple, C.cyan]),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Outly Sicherheit",
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
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
            sectionTitle("Admin"),
            SettingsCard(
              icon: Icons.admin_panel_settings,
              title: "Admin Panel",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                );
              },
            ),
          ],

          sectionTitle("Rechtliches"),
          SettingsCard(
            icon: Icons.lock_outline,
            title: "Datenschutzerklärung",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalTextPage(
                    title: "Datenschutzerklärung",
                    text: privacyText,
                  ),
                ),
              );
            },
          ),
          SettingsCard(
            icon: Icons.description_outlined,
            title: "Nutzungsbedingungen",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalTextPage(
                    title: "Nutzungsbedingungen",
                    text: termsText,
                  ),
                ),
              );
            },
          ),
          SettingsCard(
            icon: Icons.badge_outlined,
            title: "Impressum",
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

          sectionTitle("Schutz & Hilfe"),
          SettingsCard(
            icon: Icons.security,
            title: "Sicherheit",
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
          SettingsCard(
            icon: Icons.help_outline,
            title: "Hilfe & Support",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              );
            },
          ),
          SettingsCard(
            icon: Icons.notifications_none,
            title: "Benachrichtigungen",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),

          sectionTitle("Account"),
          SettingsCard(
            icon: Icons.info_outline,
            title: "Über Outly",
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
          SettingsCard(
            icon: Icons.key,
            title: "Passwort zurücksetzen",
            onTap: () => resetPassword(context),
          ),

          const SizedBox(height: 12),
          dangerButton(text: "Account löschen", onTap: () => deleteAccount(context)),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: () => logout(context),
            child: const Text("Abmelden", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

Future<void> sendNotification({
  required String toUserId,
  required String fromUserId,
  required String type,
  required String text,
  String targetId = "",
}) async {
  if (toUserId == fromUserId) return;

  await FirebaseFirestore.instance.collection("notifications").add({
    "toUserId": toUserId,
    "fromUserId": fromUserId,
    "type": type,
    "text": text,
    "targetId": targetId,
    "read": false,
    "createdAt": Timestamp.now(),
  });
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> updateUser(
    String userId,
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    if (!isAdminUser()) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .set(data, SetOptions(merge: true));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User aktualisiert ✅")),
    );
  }

  Future<void> deleteExpiredEvents(BuildContext context) async {
    if (!isAdminUser()) return;

    final snap = await FirebaseFirestore.instance.collection("activities").get();
    int count = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final deleteAt = data["deleteAt"];

      if (deleteAt is Timestamp && deleteAt.toDate().isBefore(DateTime.now())) {
        await doc.reference.delete();
        count++;
      }
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$count alte Events gelöscht ✅")),
    );
  }

  Future<int> countCollection(String name) async {
    final snap = await FirebaseFirestore.instance.collection(name).get();
    return snap.docs.length;
  }

  Future<int> countOpen(String name) async {
    final snap = await FirebaseFirestore.instance
        .collection(name)
        .where("status", isEqualTo: "open")
        .get();

    return snap.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdminUser()) {
      return const SimplePage(
        title: "Kein Zugriff",
        text: "Du hast keinen Zugriff auf diesen Bereich.",
      );
    }

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        title: const Text(
          "Admin Center",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  C.purple.withOpacity(0.55),
                  C.card,
                  C.cyan.withOpacity(0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: C.cyan.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: C.purple.withOpacity(0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
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
                        "User, Safety, Reports, Support und Creator verwalten.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          FutureBuilder<List<int>>(
            future: Future.wait([
              countCollection("users"),
              countCollection("activities"),
              countOpen("reports"),
              countOpen("support"),
            ]),
            builder: (context, snap) {
              final data = snap.data ?? [0, 0, 0, 0];

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.65,
                children: [
                  AdminStatCard(
                    title: "User",
                    value: "${data[0]}",
                    icon: Icons.groups_2_outlined,
                    color: C.cyan,
                  ),
                  AdminStatCard(
                    title: "Events",
                    value: "${data[1]}",
                    icon: Icons.local_fire_department,
                    color: C.orange,
                  ),
                  AdminStatCard(
                    title: "Reports offen",
                    value: "${data[2]}",
                    icon: Icons.flag_outlined,
                    color: Colors.redAccent,
                  ),
                  AdminStatCard(
                    title: "Support offen",
                    value: "${data[3]}",
                    icon: Icons.support_agent,
                    color: C.green,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          GradientButton(
            text: "Abgelaufene Events löschen",
            onPressed: () => deleteExpiredEvents(context),
          ),

          const SizedBox(height: 26),

          const AdminSectionTitle(
            title: "Verifizierung & Creator",
            subtitle: "Offene Anfragen schnell prüfen.",
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("users").snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }

              final pending = snap.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data["verificationPending"] == true ||
                    data["creatorPending"] == true;
              }).toList();

              if (pending.isEmpty) {
                return const InfoCard(
                  title: "Keine Anfragen",
                  text: "Aktuell gibt es keine offenen Creator- oder Verifizierungsanfragen.",
                );
              }

              return Column(
                children: pending.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final username = data["username"] ?? "user";
                  final email = data["email"] ?? "";

                  return AdminActionCard(
                    color: C.cyan,
                    icon: Icons.verified_user,
                    title: "@$username",
                    subtitle: email,
                    body:
                        "Verifizierung: ${data["verificationPending"] == true ? "offen" : "nein"}\nCreator: ${data["creatorPending"] == true ? "offen" : "nein"}",
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          updateUser(doc.id, {
                            "verified": true,
                            "identityVerified": true,
                            "verificationPending": false,
                            "updatedAt": Timestamp.now(),
                          }, context);
                        },
                        child: const Text("Verifizieren"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          updateUser(doc.id, {
                            "creator": true,
                            "creatorPending": false,
                            "creatorLevel": "starter",
                            "creatorReferralCode": username.toString().toUpperCase(),
                            "updatedAt": Timestamp.now(),
                          }, context);
                        },
                        child: const Text("Creator geben"),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 26),

          const AdminSectionTitle(
            title: "User Verwaltung",
            subtitle: "Safety, Rollen und Sperren verwalten.",
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("users").snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }

              final users = snap.data!.docs.toList();

              users.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final db = b.data() as Map<String, dynamic>;

                final ra = da["reportedCount"] ?? 0;
                final rb = db["reportedCount"] ?? 0;

                return rb.compareTo(ra);
              });

              return Column(
                children: users.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final username = data["username"] ?? "user";
                  final email = data["email"] ?? "";
                  final verified = data["verified"] == true;
                  final creator = data["creator"] == true;
                  final banned = data["isBanned"] == true;
                  final reports = data["reportedCount"] ?? 0;
                  final trustScore = data["trustScore"] ?? 100;
                  final color = banned ? Colors.redAccent : safetyColor(trustScore);

                  return AdminActionCard(
                    color: color,
                    icon: banned ? Icons.block : Icons.person,
                    title: "@$username",
                    subtitle: email,
                    body:
                        "Safety: $trustScore • ${safetyLabel(trustScore)}\nReports: $reports\nVerified: ${verified ? "ja" : "nein"} • Creator: ${creator ? "ja" : "nein"}",
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          updateUser(doc.id, {
                            "verified": !verified,
                            "updatedAt": Timestamp.now(),
                          }, context);
                        },
                        child: Text(verified ? "Unverify" : "Verify"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          updateUser(doc.id, {
                            "creator": !creator,
                            "creatorLevel": !creator ? "starter" : "none",
                            "updatedAt": Timestamp.now(),
                          }, context);
                        },
                        child: Text(creator ? "Creator weg" : "Creator"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: banned ? C.green : Colors.redAccent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          updateUser(doc.id, {
                            "isBanned": !banned,
                            "updatedAt": Timestamp.now(),
                          }, context);
                        },
                        child: Text(banned ? "Entsperren" : "Sperren"),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 26),

          const AdminSectionTitle(
            title: "Support",
            subtitle: "Nachrichten von Usern bearbeiten.",
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("support").snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }

              final tickets = snap.data!.docs.toList();

              tickets.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final db = b.data() as Map<String, dynamic>;

                final ta = da["createdAt"];
                final tb = db["createdAt"];

                if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                return 0;
              });

              if (tickets.isEmpty) {
                return const InfoCard(
                  title: "Kein Support",
                  text: "Aktuell gibt es keine Support-Anfragen.",
                );
              }

              return Column(
                children: tickets.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final email = (data["email"] ?? "Keine E-Mail").toString();
                  final uid = (data["uid"] ?? "").toString();
                  final message = (data["message"] ?? "").toString();
                  final status = (data["status"] ?? "open").toString();
                  final closed = status == "closed";

                  return AdminActionCard(
                    color: closed ? C.green : C.orange,
                    icon: closed ? Icons.check_circle : Icons.support_agent,
                    title: closed ? "Support erledigt" : "Support offen",
                    subtitle: email,
                    body:
                        "${uid.isNotEmpty ? "UID: $uid\n\n" : ""}$message",
                    actions: [
                      ElevatedButton.icon(
                        onPressed: closed
                            ? null
                            : () {
                                doc.reference.set({
                                  "status": "closed",
                                  "closedAt": Timestamp.now(),
                                }, SetOptions(merge: true));
                              },
                        icon: const Icon(Icons.check),
                        label: const Text("Erledigt"),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.18),
                          foregroundColor: Colors.redAccent,
                        ),
                        onPressed: () => doc.reference.delete(),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Löschen"),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 26),

          const AdminSectionTitle(
            title: "Reports",
            subtitle: "Meldungen prüfen und schließen.",
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("reports").snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }

              final reports = snap.data!.docs.toList();

              reports.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final db = b.data() as Map<String, dynamic>;

                final ta = da["createdAt"];
                final tb = db["createdAt"];

                if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                return 0;
              });

              if (reports.isEmpty) {
                return const InfoCard(
                  title: "Keine Reports",
                  text: "Aktuell gibt es keine Meldungen.",
                );
              }

              return Column(
                children: reports.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final type = data["type"] ?? "";
                  final reason = data["reason"] ?? "";
                  final status = data["status"] ?? "open";
                  final closed = status == "closed";

                  return AdminActionCard(
                    color: closed ? C.green : Colors.redAccent,
                    icon: Icons.flag_outlined,
                    title: "Report: $type",
                    subtitle: "Status: $status",
                    body: "Grund: $reason",
                    actions: [
                      ElevatedButton(
                        onPressed: closed
                            ? null
                            : () {
                                doc.reference.set({
                                  "status": "closed",
                                  "closedAt": Timestamp.now(),
                                }, SetOptions(merge: true));
                              },
                        child: const Text("Schließen"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.18),
                          foregroundColor: Colors.redAccent,
                        ),
                        onPressed: () => doc.reference.delete(),
                        child: const Text("Löschen"),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const AdminSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
                  style: const TextStyle(
                    color: C.cyan,
                    fontSize: 22,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.18),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
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
            child: const Text(
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
            return const Center(
              child: CircularProgressIndicator(color: C.cyan),
            );
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

          if (docs.isEmpty) {
            return const Center(
              child: InfoCard(
                title: "Noch nichts da",
                text: "Hier erscheinen neue Follower, Event-Updates, Join-Anfragen und Chat-Hinweise.",
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
                            builder: (_) => UserProfileScreen(userId: fromUserId),
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
class SimplePage extends StatelessWidget {
  final String title;
  final String text;

  const SimplePage({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: InfoCard(title: title, text: text),
      ),
    );
  }
}

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Nachricht schreiben...",
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: C.cyan),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final message = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<void> sendSupport() async {
    if (sending) return;

    final text = message.text.trim();
    if (text.isEmpty) return;

    setState(() => sending = true);

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection("support").add({
      "uid": user?.uid,
      "email": user?.email,
      "message": text,
      "createdAt": Timestamp.now(),
      "status": "open",
      "type": "support",
    });

    message.clear();

    if (!mounted) return;

    setState(() => sending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Support-Anfrage gesendet ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: const Text("Hilfe & Support"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InfoCard(
              title: "Support",
              text:
                  "Beschreibe dein Problem. Deine Anfrage wird gespeichert und kann vom Outly-Team geprüft werden.",
            ),
            const SizedBox(height: 18),
            TextField(
              controller: message,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: "Was ist passiert?",
              ),
            ),
            const SizedBox(height: 18),
            GradientButton(
              text: sending ? "Wird gesendet..." : "Anfrage senden",
              onPressed: sendSupport,
            ),
          ],
        ),
      ),
    );
  }
}
class LegalTextPage extends StatelessWidget {
  final String title;
  final String text;

  const LegalTextPage({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        title: Text(title),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: C.cyan.withOpacity(0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: C.cyan,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.6,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OutlyAvatar extends StatelessWidget {
  final String photoUrl;
  final String fallbackIcon;
  final double radius;

  const OutlyAvatar({
    super.key,
    required this.photoUrl,
    this.fallbackIcon = "",
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = photoUrl.trim();
    final hasImage = cleanUrl.isNotEmpty && cleanUrl.startsWith("http");

    return CircleAvatar(
      radius: radius,
      backgroundColor: C.card2,
      child: ClipOval(
        child: hasImage
            ? Image.network(
                cleanUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Icon(Icons.person, color: C.cyan, size: radius);
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    width: radius * 2,
                    height: radius * 2,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: C.cyan,
                      ),
                    ),
                  );
                },
              )
            : Icon(Icons.person, color: C.cyan, size: radius),
      ),
    );
  }
}

Widget verifiedName(String username, bool verified, {double size = 16}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Text(
          "@$username",
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size,
          ),
        ),
      ),
      if (verified) ...[
        const SizedBox(width: 5),
        const Icon(Icons.verified, color: Colors.blue, size: 18),
      ],
    ],
  );
}

class ProfileBox extends StatelessWidget {
  final Map<String, dynamic> data;
  final int followers;
  final int following;
  final String userId;
  final bool showActions;

  const ProfileBox({
    super.key,
    required this.data,
    required this.followers,
    required this.following,
    required this.userId,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    final username = (data["username"] ?? "user").toString();
    final city = (data["city"] ?? "Keine Stadt").toString();
    final bio = (data["bio"] ?? "Neu bei Outly 🔥").toString();
    final photoUrl = (data["photoUrl"] ?? "").toString();
    final coverUrl = (data["coverUrl"] ?? "").toString();

    final trustScore = data["trustScore"] ?? 100;
    final creator = data["creator"] == true;
    final verified = data["verified"] == true;
    final identityVerified = data["identityVerified"] == true;
    final ageVerified = data["ageVerified"] == true;

    final color = safetyColor(trustScore);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: color.withOpacity(0.34)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.20),
            blurRadius: 34,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 155,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.75),
                      C.purple.withOpacity(0.55),
                      Colors.black,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: coverUrl.trim().isNotEmpty && coverUrl.startsWith("http")
                      ? DecorationImage(
                          image: NetworkImage(coverUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.35),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -35,
                      top: -30,
                      child: Icon(
                        Icons.explore,
                        size: 150,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_outlined, color: color, size: 17),
                            const SizedBox(width: 6),
                            Text(
                              city,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: -54,
                child: Center(
                  child: Container(
                    width: 116,
                    height: 116,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [color, C.cyan, C.purple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.45),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: OutlyAvatar(
                      photoUrl: photoUrl,
                      radius: 54,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 66),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                verifiedName(username, verified, size: 27),

                const SizedBox(height: 8),

                Text(
                  bio,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SafetyBadge(score: trustScore),
                    if (verified)
                      const MiniBadge(
                        text: "Verifiziert",
                        icon: Icons.verified,
                        color: Colors.blue,
                      ),
                    if (identityVerified)
                      const MiniBadge(
                        text: "Identität geprüft",
                        icon: Icons.verified_user,
                        color: C.green,
                      ),
                    if (ageVerified)
                      const MiniBadge(
                        text: "Alter geprüft",
                        icon: Icons.cake_outlined,
                        color: C.orange,
                      ),
                    if (creator)
                      const MiniBadge(
                        text: "Creator",
                        icon: Icons.workspace_premium,
                        color: C.orange,
                      ),
                  ],
                ),

                const SizedBox(height: 22),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("activities")
                              .where("creatorId", isEqualTo: userId)
                              .snapshots(),
                          builder: (context, aSnap) {
                            final count = aSnap.data?.docs.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return isEventActive(data);
                                }).length ??
                                0;

                            return _ProfileBigStat(
                              value: "$count",
                              label: "Events",
                              icon: Icons.local_fire_department,
                              color: C.orange,
                            );
                          },
                        ),
                      ),
                      _ProfileStatDivider(),
                      Expanded(
                        child: _ProfileBigStat(
                          value: "$followers",
                          label: "Follower",
                          icon: Icons.groups_2_outlined,
                          color: C.cyan,
                        ),
                      ),
                      _ProfileStatDivider(),
                      Expanded(
                        child: _ProfileBigStat(
                          value: "$following",
                          label: "Following",
                          icon: Icons.person_add_alt_1,
                          color: C.purple2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color.withOpacity(0.30)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Safety Status: ${safetyLabel(trustScore)}",
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "$trustScore/100",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBigStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _ProfileBigStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ProfileStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withOpacity(0.10),
    );
  }
}

class SafetyBadge extends StatelessWidget {
  final int score;

  const SafetyBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = safetyColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            "Safety $score",
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class MiniBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const MiniBadge({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class InterestsWrap extends StatelessWidget {
  final List<String> interests;

  const InterestsWrap({super.key, required this.interests});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Interessen",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: interests.map((i) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: C.cyan.withOpacity(0.35)),
              ),
              child: Text(i, style: const TextStyle(color: C.cyan)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class StoryBubble extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAdd;
  final String photoUrl;
  final String imageUrl;
  final bool isMine;

  const StoryBubble({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isAdd = false,
    this.photoUrl = "",
    this.imageUrl = "",
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPreview = imageUrl.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              height: 66,
              width: 66,
              padding: isAdd ? EdgeInsets.zero : const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAdd ? C.card : null,
                gradient: isAdd
                    ? null
                    : LinearGradient(
                        colors: isMine
                            ? [C.orange, C.cyan]
                            : [C.purple, C.cyan],
                      ),
                border: isAdd ? Border.all(color: C.cyan, width: 2) : null,
              ),
              child: CircleAvatar(
                backgroundColor: isAdd ? C.card : C.bg,
                backgroundImage: hasPreview
                    ? NetworkImage(imageUrl)
                    : photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                child: !hasPreview && photoUrl.isEmpty
                    ? Icon(
                        icon,
                        color: isAdd ? C.cyan : Colors.white,
                        size: isAdd ? 32 : 24,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isMine ? C.orange : Colors.white70,
                fontWeight: isMine ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthShell extends StatelessWidget {
  final Widget child;
  final bool showBack;

  const AuthShell({
    super.key,
    required this.child,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: showBack ? AppBar(backgroundColor: C.bg, elevation: 0) : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [C.purple.withOpacity(0.22), C.bg],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }
}
class OutlyLogo extends StatelessWidget {
  final bool big;

  const OutlyLogo({super.key, this.big = false});

  @override
  Widget build(BuildContext context) {
    final size = big ? 96.0 : 52.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [C.purple, C.cyan]),
            boxShadow: [BoxShadow(color: C.cyan.withOpacity(0.35), blurRadius: 30)],
          ),
          child: Icon(Icons.explore, color: Colors.white, size: big ? 54 : 30),
        ),
        if (big) ...[
          const SizedBox(height: 14),
          const Text(
            "Outly",
            style: TextStyle(color: C.cyan, fontSize: 42, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const GradientButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [C.purple, C.cyan]),
        boxShadow: [BoxShadow(color: C.purple.withOpacity(0.35), blurRadius: 18)],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String text;

  const InfoCard({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: C.cyan.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(color: C.cyan, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SettingsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        leading: Icon(icon, color: C.cyan),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const ProfileStat(this.value, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: C.cyan, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.white54)),
      ],
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.black.withOpacity(0.35),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}

class SegmentButton extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const SegmentButton({
    super.key,
    required this.text,
    required this.active,
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
          color: active ? C.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class ReportUserButton extends StatefulWidget {
  final String targetUserId;

  const ReportUserButton({
    super.key,
    required this.targetUserId,
  });

  @override
  State<ReportUserButton> createState() => _ReportUserButtonState();
}

class _ReportUserButtonState extends State<ReportUserButton> {
  bool loading = false;

  Future<void> reportUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        title: const Text("User melden"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            reportReasonButton(context, "Belästigung"),
            reportReasonButton(context, "Fake Profil"),
            reportReasonButton(context, "Verdächtiges Verhalten"),
            reportReasonButton(context, "Gefährlicher Inhalt"),
          ],
        ),
      ),
    );

    if (reason == null) return;

    setState(() => loading = true);

    await FirebaseFirestore.instance.collection("reports").add({
      "type": "user",
      "targetUserId": widget.targetUserId,
      "reportedBy": currentUser.uid,
      "reason": reason,
      "status": "open",
      "createdAt": Timestamp.now(),
    });

    await FirebaseFirestore.instance.collection("users").doc(widget.targetUserId).set({
      "reportedCount": FieldValue.increment(1),
      "riskFlags": FieldValue.arrayUnion(["reported"]),
      "trustScore": FieldValue.increment(-10),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User wurde gemeldet ✅")),
    );
  }

  Widget reportReasonButton(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, text),
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: loading ? null : reportUser,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.flag_outlined),
      label: const Text("User melden"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.withOpacity(0.14),
        foregroundColor: Colors.redAccent,
        minimumSize: const Size(double.infinity, 46),
        padding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.35)),
        ),
      ),
    );
  }
}

const String privacyText = """
Datenschutzerklärung – Outly

Outly verarbeitet Daten, die für die Nutzung der App notwendig sind.

Verarbeitete Daten:
- E-Mail-Adresse
- Benutzername
- Stadt / Ort
- Profilangaben
- Profilbilder und Eventbilder
- Aktivitäten
- Sichtbarkeitseinstellungen von Aktivitäten
- Chatnachrichten
- Storys
- Support-Anfragen
- Meldungen und Safety-Daten
- technische Daten, die für Firebase notwendig sind

Zweck der Verarbeitung:
- Erstellung und Verwaltung von Accounts
- Anzeige von Aktivitäten
- Kommunikation zwischen Nutzern
- Schutz und Sicherheit der Community
- Support und Fehlerbehebung
- Prüfung von Meldungen und Missbrauch

Technische Anbieter:
Outly verwendet Firebase-Dienste von Google zur Authentifizierung, Datenspeicherung, Hosting und Speicherung von Bildern.

Weitergabe:
Daten werden nicht verkauft. Eine Weitergabe erfolgt nur, wenn sie technisch notwendig ist oder gesetzlich verlangt wird.

Account löschen:
Du kannst deinen Account in den Einstellungen löschen. Dabei wird dein User-Profil anonymisiert oder entfernt. Manche Inhalte können aus Sicherheits- oder Nachweisgründen vorübergehend gespeichert bleiben.

Kontakt:
outly@gmail.com
""";

const String termsText = """
Nutzungsbedingungen – Outly

1. Allgemeines
Outly ist eine Plattform, mit der Nutzer Aktivitäten im echten Leben finden, erstellen und daran teilnehmen können.

2. Mindestalter
Die Nutzung von Outly ist erst ab 14 Jahren erlaubt. Nutzer müssen wahrheitsgemäße Angaben machen.

3. Verantwortung der Nutzer
Jeder Nutzer ist selbst für sein Verhalten, seine Inhalte und seine Teilnahme an Aktivitäten verantwortlich.

4. Aktivitäten
Aktivitäten können öffentlich, nur für Follower oder privat für ausgewählte Personen erstellt werden. Nutzer dürfen keine gefährlichen, illegalen oder schädlichen Treffen erstellen.

5. Verbotene Inhalte und Verhalten
Nicht erlaubt sind:
- illegale Aktivitäten
- Belästigung, Drohungen oder Hass
- sexuelle Inhalte gegenüber Minderjährigen
- falsche Identitäten
- Spam oder Betrug
- gefährliche oder schädliche Treffen
- Ausnutzung, Grooming oder Kontaktaufnahme mit Minderjährigen zu sexuellen Zwecken

6. Safety System
Outly kann Meldungen, Reports, Sperren und Safety-Punkte nutzen, um die Community zu schützen.

7. Haftung
Outly stellt lediglich die technische Plattform zur Verfügung.
Outly organisiert keine Treffen selbst und übernimmt keine Haftung für Aktivitäten, Treffen, Inhalte oder Verhalten von Nutzern.

8. Creator Programm
Creator-Funktionen können Werbung, Empfehlungen oder Einnahmen enthalten. Eine Auszahlung oder Teilnahme kann geprüft, geändert oder abgelehnt werden.

9. Sperrung und Löschung
Accounts können bei Missbrauch, falschen Angaben oder gefährlichem Verhalten gesperrt oder gelöscht werden.

Kontakt:
outly@gmail.com
""";

const String imprintText = """
Impressum

Angaben gemäß §5 ECG Österreich

App:
Outly

Verantwortlich:
Lundrim Hamdiu

Ort:
Niederösterreich, Österreich

Kontakt:
outly@gmail.com

Haftungshinweis:
Outly ist eine Plattform zur Erstellung und Entdeckung von Aktivitäten.
Outly organisiert keine eigenen Events und übernimmt keine Haftung für Inhalte, Treffen oder Verhalten von Nutzern.
""";

const String securityText = """
Sicherheit bei Outly

Outly soll echte Menschen sicher verbinden.

Wichtige Regeln:
- Triff dich möglichst an öffentlichen Orten.
- Teile keine sensiblen Daten wie Adresse, Passwörter oder private Dokumente.
- Melde verdächtige Nutzer oder Inhalte.
- Blockiere Nutzer, wenn du dich unwohl fühlst.
- Minderjährige sollen besonders vorsichtig sein und keine privaten Treffen mit unbekannten Erwachsenen vereinbaren.

Nicht erlaubt:
- Belästigung
- sexuelle Inhalte gegenüber Minderjährigen
- Grooming
- Drohungen
- Fake-Profile
- gefährliche Aktivitäten
- illegale Treffen

Outly kann Accounts prüfen, sperren oder löschen, wenn gegen Regeln verstoßen wird.

Kontakt für Meldungen:
outly@gmail.com
""";

const String aboutText = """
Outly ist eine Real-Life-App.

Die Idee:
Weniger scrollen. Mehr erleben.

Mit Outly kannst du:
- Aktivitäten in deiner Nähe finden
- eigene Events erstellen
- öffentliche oder private Events planen
- Fotos zu Profil und Events hinzufügen
- neuen Leuten beitreten
- direkt über Chats kommunizieren
- Storys teilen
- Creator-Funktionen nutzen

Outly verbindet Menschen für echte Aktivitäten im echten Leben.
""";