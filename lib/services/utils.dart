import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// 🌍 GLOBAL GEOCODING (jede Adresse weltweit)
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
    },
  );

  final response = await http.get(
    uri,
    headers: {
      "User-Agent": "OutlyApp/1.0",
    },
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

/// 📍 USER LOCATION
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

/// 📏 DISTANZ IN KM
double distanceInKm(LatLng a, LatLng b) {
  final distance = const Distance();
  return distance.as(LengthUnit.Kilometer, a, b);
}

/// 🔄 HELPER: String → LatLng (fallback)
Future<LatLng> placeToLatLng(String place) async {
  final result = await geocodeAddress(place);

  // fallback falls nichts gefunden wird
  return result ?? const LatLng(48.2082, 16.3738); // Wien fallback
}