import 'package:flutter/material.dart';
import '../../main.dart';

import 'package:flutter/material.dart';
import '../../main.dart';

Widget verifiedName(String name, bool verified, {double size = 16}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Text(
          name,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      if (verified) ...[
        const SizedBox(width: 5),
        Icon(Icons.verified, color: C.cyan, size: size),
      ],
    ],
  );
}