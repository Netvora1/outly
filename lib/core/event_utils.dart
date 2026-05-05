import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_colors.dart';

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