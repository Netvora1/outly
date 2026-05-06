import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

Future<String?> uploadImageBytes({
  required Uint8List bytes,
  required String path,
}) async {
  try {
    final cleanPath = path
        .trim()
        .replaceAll("\\", "/")
        .replaceAll("//", "/")
        .replaceAll(" ", "_");

    final ref = FirebaseStorage.instance.ref().child(cleanPath);

    final task = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: "image/jpeg",
        cacheControl: "public,max-age=3600",
      ),
    );

    final url = await task.ref.getDownloadURL();

    final cleanUrl = url
        .trim()
        .replaceAll("\n", "")
        .replaceAll("\r", "")
        .replaceAll(" ", "");

    debugPrint("UPLOAD URL: $cleanUrl");

    return cleanUrl;
  } catch (e, stack) {
    debugPrint("Upload Fehler: $e");
    debugPrintStack(stackTrace: stack);
    return null;
  }
}
