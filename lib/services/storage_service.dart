import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

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