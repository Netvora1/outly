import 'package:flutter/material.dart';
import '../../main.dart';

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
