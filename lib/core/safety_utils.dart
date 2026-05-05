import 'package:flutter/material.dart';
import 'app_colors.dart';

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