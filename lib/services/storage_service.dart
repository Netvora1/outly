import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

Future<String?> uploadImageBytes({
  required Uint8List bytes,
  required String path,
}) async {
  try {
    final ref = FirebaseStorage.instance.ref().child(path);

    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: "image/jpeg"),
    );

    return await task.ref.getDownloadURL();
  } catch (e) {
    debugPrint("Upload Fehler: $e");
    return null;
  }
}