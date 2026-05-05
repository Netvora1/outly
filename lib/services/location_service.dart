import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

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

 bool matchesRadius(Map<String, dynamic> data) {
    if (myPosition == null) return true;

    final point = activityPoint(data);
    final km = distanceInKm(myPosition!, point);

    return km <= radiusKm;
  }

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
