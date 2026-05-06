import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

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
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.6,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}